import 'dart:async';
import 'dart:io';

import 'package:course_chatbot/src/bot/course_bot_runtime.dart';
import 'package:course_chatbot/src/config/app_config.dart';
import 'package:l/l.dart';

void main(List<String> args) {
  runZonedGuarded(
    () async {
      final config = AppConfig.fromArgs(args);
      final app = await CourseBotRuntime.compose(config);
      _registerShutdown(app);

      l.i(
        'Course bot starting. payment=${config.paymentProvider.name} '
        'channel=${config.courseChannelId} warmup=${config.warmupEnabled}',
      );
      await app.runner.start();
      app.close();
      exit(app.runner.exitCode);
    },
    (error, stackTrace) {
      l.e('Uncaught error: $error', stackTrace);
      exit(1);
    },
  );
}

void _registerShutdown(CourseBotRuntime app) {
  Future<void> stop() {
    return app.runner.stop().whenComplete(app.close).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      l.e('Error while stopping: $error', stackTrace);
    });
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
