import 'dart:async';

import 'package:course_chatbot/src/bot/handlers/private_handlers.dart';
import 'package:course_chatbot/src/config/app_config.dart';
import 'package:course_chatbot/src/data/google_sheets_writer.dart';
import 'package:course_chatbot/src/jobs/abandoned_payment_job.dart';
import 'package:course_chatbot/src/jobs/google_sheets_funnel_export_job.dart';
import 'package:course_chatbot/src/jobs/job_scheduler.dart';
import 'package:course_chatbot/src/jobs/remainder_reminder_job.dart';
import 'package:course_chatbot/src/jobs/sqlite_maintenance_job.dart';
import 'package:course_chatbot/src/jobs/unjoined_invite_job.dart';
import 'package:course_chatbot/src/jobs/warmup_nudge_job.dart';
import 'package:course_chatbot/src/payments/payment_webhook_server.dart';
import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';
import 'package:course_chatbot/src/telegram/telegram_client.dart';
import 'package:l/l.dart';

final class BotRunner {
  BotRunner({
    required AppConfig config,
    required TelegramClient client,
    required PrivateHandlers privateHandlers,
    JobScheduler? jobScheduler,
    WarmupNudgeJob? warmupNudgeJob,
    AbandonedPaymentJob? abandonedPaymentJob,
    RemainderReminderJob? remainderReminderJob,
    UnjoinedInviteJob? unjoinedInviteJob,
    GoogleSheetsFunnelExportJob? sheetsExportJob,
    SqliteMaintenanceJob? maintenanceJob,
    GoogleSheetsWriter? googleSheetsWriter,
    PaymentWebhookServer? paymentWebhookServer,
  }) : _config = config,
       _client = client,
       _privateHandlers = privateHandlers,
       _warmupNudgeJob = warmupNudgeJob,
       _abandonedPaymentJob = abandonedPaymentJob,
       _remainderReminderJob = remainderReminderJob,
       _unjoinedInviteJob = unjoinedInviteJob,
       _sheetsExportJob = sheetsExportJob,
       _maintenanceJob = maintenanceJob,
       _googleSheetsWriter = googleSheetsWriter,
       _paymentWebhookServer = paymentWebhookServer,
       _jobScheduler = jobScheduler ?? JobScheduler();

  final AppConfig _config;
  final TelegramClient _client;
  final PrivateHandlers _privateHandlers;
  final WarmupNudgeJob? _warmupNudgeJob;
  final AbandonedPaymentJob? _abandonedPaymentJob;
  final RemainderReminderJob? _remainderReminderJob;
  final UnjoinedInviteJob? _unjoinedInviteJob;
  final GoogleSheetsFunnelExportJob? _sheetsExportJob;
  final SqliteMaintenanceJob? _maintenanceJob;
  final GoogleSheetsWriter? _googleSheetsWriter;
  final PaymentWebhookServer? _paymentWebhookServer;
  final JobScheduler _jobScheduler;
  final List<Timer> _timers = <Timer>[];

  static const int _maxConflictRetries = 3;

  bool _stopping = false;
  bool _finalized = false;
  int _exitCode = 0;
  int _conflictRetries = 0;
  int _offset = 0;
  bool _clientClosed = false;
  bool _sheetsClosed = false;

  JobScheduler get jobScheduler => _jobScheduler;

  int get exitCode => _exitCode;

  Future<void> start() async {
    await _initializeLongPolling();
    await _paymentWebhookServer?.start();
    _scheduleJobs();

    while (!_stopping) {
      try {
        final updates = await _client.getUpdates(
          offset: _offset,
          timeoutSeconds: _config.pollTimeoutSeconds,
          allowedUpdates: const {'message', 'callback_query', 'chat_member', 'my_chat_member'},
        );
        _conflictRetries = 0;
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
    await _finalizeShutdown();
  }

  Future<void> _handleUpdate(Map<String, dynamic> update) async {
    await _privateHandlers.handle(update);
  }

  Future<void> stop() async {
    if (!_stopping) {
      _stopping = true;
      for (final timer in _timers) {
        timer.cancel();
      }
      _timers.clear();
    }
    await _finalizeShutdown();
  }

  Future<void> _finalizeShutdown() async {
    if (_finalized) {
      return;
    }
    _finalized = true;
    await _paymentWebhookServer?.stop();
    await _jobScheduler.waitForIdle(timeout: const Duration(seconds: 45));
    await _closeSheets();
    _closeClient();
  }

  void _scheduleJobs() {
    final warmup = _warmupNudgeJob;
    if (warmup != null) {
      _schedulePeriodic(const Duration(minutes: 5), 'warmup', warmup.run);
    }
    final abandon = _abandonedPaymentJob;
    if (abandon != null) {
      _schedulePeriodic(const Duration(minutes: 10), 'abandon', abandon.run);
    }
    final remainder = _remainderReminderJob;
    if (remainder != null) {
      _schedulePeriodic(const Duration(minutes: 15), 'remainder', remainder.run);
    }
    final unjoined = _unjoinedInviteJob;
    if (unjoined != null) {
      _schedulePeriodic(const Duration(minutes: 15), 'unjoined', unjoined.run);
    }
    final sheets = _sheetsExportJob;
    if (sheets != null) {
      final interval = Duration(seconds: _config.googleSheetsWriteIntervalSeconds);
      _schedulePeriodic(interval, 'sheets', sheets.run);
      _jobScheduler.launch('sheets', sheets.run);
    }
    final maintenance = _maintenanceJob;
    if (maintenance != null) {
      _schedulePeriodic(const Duration(hours: 1), 'maintenance', maintenance.run);
      _jobScheduler.launch('maintenance', maintenance.run);
    }
  }

  void _schedulePeriodic(Duration period, String name, Future<void> Function() action) {
    _timers.add(
      Timer.periodic(period, (_) {
        if (_stopping) {
          return;
        }
        _jobScheduler.launch(name, action);
      }),
    );
  }

  Future<void> _initializeLongPolling() async {
    try {
      await _client.deleteWebhook();
    } on Object catch (error, stackTrace) {
      l.w('Failed to reset Telegram webhook before polling: $error', stackTrace);
    }
  }

  Future<void> _closeSheets() async {
    if (_sheetsClosed) {
      return;
    }
    _sheetsClosed = true;
    await _googleSheetsWriter?.close();
  }

  void _closeClient() {
    if (_clientClosed) {
      return;
    }
    _clientClosed = true;
    _client.close();
  }
}
