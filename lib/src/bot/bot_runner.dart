import 'dart:async';

import 'package:course_chatbot/src/bot/handlers/private_handlers.dart';
import 'package:course_chatbot/src/config/app_config.dart';
import 'package:course_chatbot/src/jobs/job_scheduler.dart';
import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';
import 'package:course_chatbot/src/telegram/telegram_client.dart';
import 'package:l/l.dart';

final class BotRunner {
  BotRunner({
    required AppConfig config,
    required TelegramClient client,
    required PrivateHandlers privateHandlers,
  })  : _config = config,
        _client = client,
        _privateHandlers = privateHandlers,
        _jobScheduler = JobScheduler();

  final AppConfig _config;
  final TelegramClient _client;
  final PrivateHandlers _privateHandlers;
  final JobScheduler _jobScheduler;

  static const int _maxConflictRetries = 3;

  bool _stopping = false;
  int _exitCode = 0;
  int _conflictRetries = 0;
  int _offset = 0;
  bool _clientClosed = false;

  int get exitCode => _exitCode;

  Future<void> start() async {
    await _initializeLongPolling();

    while (!_stopping) {
      try {
        final updates = await _client.getUpdates(
          offset: _offset,
          timeoutSeconds: _config.pollTimeoutSeconds,
          allowedUpdates: const {'message', 'callback_query', 'chat_member'},
        );
        for (final update in updates) {
          if (_stopping) {
            break;
          }
          final updateId = update['update_id'];
          try {
            await _jobScheduler.runTracked(() => _handleUpdate(update));
          } on Object catch (error, stackTrace) {
            l.e('Failed to handle update (update_id=$updateId): $error', stackTrace);
          } finally {
            if (updateId is int) {
              _offset = updateId + 1;
            }
          }
        }
      } on TelegramApiException catch (error, stackTrace) {
        if (error.statusCode == 409) {
          _conflictRetries += 1;
          if (_conflictRetries > _maxConflictRetries) {
            l.e(
              'Polling conflict (409) persists after $_maxConflictRetries retries. '
              'Stopping with error exit so the process can be restarted.',
              stackTrace,
            );
            _exitCode = 1;
            _stopping = true;
            break;
          }
          final delaySeconds = _conflictRetries * 15;
          l.w(
            'Polling conflict (409): another instance may be running. '
            'Retry $_conflictRetries/$_maxConflictRetries in ${delaySeconds}s.',
            stackTrace,
          );
          await Future<void>.delayed(Duration(seconds: delaySeconds));
          continue;
        }
        l.w('Telegram API error in polling loop: $error', stackTrace);
        await Future<void>.delayed(const Duration(seconds: 2));
      } on TimeoutException catch (error, stackTrace) {
        l.w('Polling timeout: $error', stackTrace);
      } on Object catch (error, stackTrace) {
        l.e('Unexpected polling error: $error', stackTrace);
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    await _jobScheduler.waitForIdle();
    _closeClient();
  }

  Future<void> _handleUpdate(Map<String, dynamic> update) async {
    await _privateHandlers.handle(update);
  }

  Future<void> stop() async {
    if (!_stopping) {
      _stopping = true;
      _closeClient();
      await _jobScheduler.waitForIdle();
    }
  }

  Future<void> _initializeLongPolling() async {
    try {
      await _client.deleteWebhook();
    } on Object catch (error, stackTrace) {
      l.w('Failed to reset Telegram webhook before polling: $error', stackTrace);
    }
  }

  void _closeClient() {
    if (_clientClosed) {
      return;
    }
    _clientClosed = true;
    _client.close();
  }
}
