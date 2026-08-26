import 'dart:async';
import 'dart:io';

import 'package:course_chatbot/src/bot/bot_runner.dart';
import 'package:course_chatbot/src/bot/handlers/private_handlers.dart';
import 'package:course_chatbot/src/config/app_config.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:course_chatbot/src/telegram/telegram_client.dart';
import 'package:l/l.dart';

void main(List<String> args) {
  runZonedGuarded(
    () async {
      final config = AppConfig.fromArgs(args);
      final client = TelegramClient(token: config.botToken);
      final databaseHandle = SqliteDatabaseHandle.open(config.bookingsDbPath);
      JobDedupeRepository(databaseHandle: databaseHandle).initSchema();

      final runner = BotRunner(
        config: config,
        client: client,
        privateHandlers: PrivateHandlers(sender: client),
      );
      _registerShutdown(runner, databaseHandle);

      l.i('Course bot starting. payment=${config.paymentProvider.name}');
      await runner.start();
      databaseHandle.close();
      exit(runner.exitCode);
    },
    (error, stackTrace) {
      l.e('Uncaught error: $error', stackTrace);
      exit(1);
    },
  );
}

void _registerShutdown(BotRunner runner, SqliteDatabaseHandle databaseHandle) {
  Future<void> stop() {
    return runner.stop().whenComplete(databaseHandle.close).catchError(
      (Object error, StackTrace stackTrace) {
        l.e('Error while stopping: $error', stackTrace);
      },
    );
  }

  ProcessSignal.sigint.watch().listen((_) {
    l.i('SIGINT received, stopping bot...');
    unawaited(stop());
  });
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) {
      l.i('SIGTERM received, stopping bot...');
      unawaited(stop());
    });
  }
}
