import 'dart:async';
import 'dart:io';

import 'package:course_chatbot/src/application/access_service.dart';
import 'package:course_chatbot/src/application/broadcast_service.dart';
import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/application/funnel_service.dart';
import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/application/warmup_service.dart';
import 'package:course_chatbot/src/bot/bot_runner.dart';
import 'package:course_chatbot/src/bot/handlers/private_handlers.dart';
import 'package:course_chatbot/src/config/app_config.dart';
import 'package:course_chatbot/src/data/conversation_log_repository.dart';
import 'package:course_chatbot/src/data/google_sheets_api_writer.dart';
import 'package:course_chatbot/src/data/google_sheets_writer.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:course_chatbot/src/data/sqlite_course_repository.dart';
import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/jobs/abandoned_payment_job.dart';
import 'package:course_chatbot/src/jobs/google_sheets_funnel_export_job.dart';
import 'package:course_chatbot/src/jobs/remainder_reminder_job.dart';
import 'package:course_chatbot/src/jobs/warmup_nudge_job.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/payments/payment_gateway_factory.dart';
import 'package:course_chatbot/src/payments/payment_webhook_server.dart';
import 'package:course_chatbot/src/telegram/logging_message_sender.dart';
import 'package:course_chatbot/src/telegram/telegram_client.dart';
import 'package:l/l.dart';

void main(List<String> args) {
  runZonedGuarded(
    () async {
      final config = AppConfig.fromArgs(args);
      final client = TelegramClient(token: config.botToken);
      String? botUsername;
      try {
        botUsername = await client.getBotUsername();
      } on Object catch (error, stackTrace) {
        l.w('Failed to resolve bot username: $error', stackTrace);
      }
      final templates = MessageTemplates(botUsername: botUsername);
      final databaseHandle = SqliteDatabaseHandle.open(config.bookingsDbPath);
      final jobDedupe = JobDedupeRepository(databaseHandle: databaseHandle)..initSchema();
      final course = SqliteCourseRepository(databaseHandle: databaseHandle);
      await course.init();
      await course.upsertActiveLaunch(
        productCode: config.productCode,
        productTitle: 'Курс',
        launchCode: config.launchCode,
        launchTitle: 'Запуск',
        priceFullKopecks: rubToKopecks(config.priceFullRub),
        depositKopecks: rubToKopecks(config.depositAmountRub),
        depositDueDays: config.depositDueDays,
        channelId: config.courseChannelId,
        offerUrl: config.offerUrl,
        leadMagnetFileId: config.leadMagnetFileId,
        leadMagnetUrl: config.leadMagnetUrl,
      );

      GoogleSheetsWriter? sheetsWriter;
      if (config.googleSheetsWriteEnabled) {
        try {
          sheetsWriter = await GoogleSheetsApiWriter.connectFromConfig(config);
          l.i(
            'Google Sheets write enabled. spreadsheetId=${config.googleSheetsSpreadsheetId}',
          );
        } on Object catch (error, stackTrace) {
          l.e('Failed to enable Google Sheets write: $error', stackTrace);
        }
      }

      final sender = LoggingMessageSender(
        inner: client,
        conversationLog: CourseConversationLog(course),
      );
      final paymentGateway = createPaymentGateway(config);
      final funnel = FunnelService(course: course);
      final access = AccessService(course: course, telegram: client);
      final checkout = CheckoutService(
        course: course,
        gateway: paymentGateway,
        access: access,
        returnUrl:
            config.yookassaReturnUrl ?? (botUsername == null ? null : 'https://t.me/$botUsername'),
      );
      final warmup = WarmupService(course: course, dedupe: jobDedupe);
      final broadcast = BroadcastService(sender: sender, course: course);
      final handlers = PrivateHandlers(
        sender: sender,
        templates: templates,
        course: course,
        funnel: funnel,
        checkout: checkout,
        access: access,
        warmup: warmup,
        broadcast: broadcast,
        adminUserIds: config.adminUserIds,
      );
      final quietHours = QuietHours(
        timezoneOffsetHours: config.timezoneOffsetHours,
        fromHour: config.quietHoursFrom,
        toHour: config.quietHoursTo,
      );
      final webhook = PaymentWebhookServer(
        bind: config.paymentWebhookBind,
        gateway: paymentGateway,
        checkout: checkout,
        course: course,
        handlers: handlers,
      );
      final runner = BotRunner(
        config: config,
        client: client,
        privateHandlers: handlers,
        warmupNudgeJob: config.warmupEnabled
            ? WarmupNudgeJob(
                course: course,
                warmup: warmup,
                sender: sender,
                templates: templates,
                quietHours: quietHours,
              )
            : null,
        abandonedPaymentJob: AbandonedPaymentJob(
          course: course,
          dedupe: jobDedupe,
          sender: sender,
          templates: templates,
          quietHours: quietHours,
          firstDelay: Duration(hours: config.abandonFirstDelayHours),
          secondDelay: Duration(hours: config.abandonSecondDelayHours),
        ),
        remainderReminderJob: RemainderReminderJob(
          course: course,
          dedupe: jobDedupe,
          sender: sender,
          templates: templates,
          quietHours: quietHours,
        ),
        sheetsExportJob: sheetsWriter == null
            ? null
            : GoogleSheetsFunnelExportJob(
                course: course,
                writer: sheetsWriter,
                sheetTitle: config.googleSheetsWriteSheetTitle,
              ),
        googleSheetsWriter: sheetsWriter,
        paymentWebhookServer: webhook,
      );
      _registerShutdown(runner, databaseHandle);

      l.i(
        'Course bot starting. payment=${config.paymentProvider.name} '
        'channel=${config.courseChannelId} warmup=${config.warmupEnabled}',
      );
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
