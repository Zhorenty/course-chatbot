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
import 'package:course_chatbot/src/jobs/job_scheduler.dart';
import 'package:course_chatbot/src/jobs/remainder_reminder_job.dart';
import 'package:course_chatbot/src/jobs/sqlite_maintenance_job.dart';
import 'package:course_chatbot/src/jobs/warmup_nudge_job.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:course_chatbot/src/payments/payment_gateway_factory.dart';
import 'package:course_chatbot/src/payments/payment_webhook_server.dart';
import 'package:course_chatbot/src/telegram/logging_message_sender.dart';
import 'package:course_chatbot/src/telegram/telegram_client.dart';
import 'package:l/l.dart';

final class CourseBotRuntime {
  CourseBotRuntime({
    required this.runner,
    required this.databaseHandle,
    required this.paymentGateway,
  });

  final BotRunner runner;
  final SqliteDatabaseHandle databaseHandle;
  final PaymentGateway paymentGateway;
  bool _closed = false;

  static Future<CourseBotRuntime> compose(AppConfig config) async {
    final errors = config.validationErrors();
    if (errors.isNotEmpty) {
      for (final error in errors) {
        stderr.writeln(error);
      }
      exit(2);
    }
    if (config.priceFullRub <= 0) {
      l.w('PRICE_FULL_RUB is 0; checkout will be refused until a price is set.');
    }
    final guidePath = config.leadMagnetPath;
    if (guidePath != null && guidePath.isNotEmpty && !File(guidePath).existsSync()) {
      l.w('LEAD_MAGNET_PATH is set but the file is missing: $guidePath');
    }

    final client = TelegramClient(token: config.botToken);
    String? botUsername;
    try {
      botUsername = await client.getBotUsername();
    } on Object catch (error, stackTrace) {
      l.w('Failed to resolve bot username: $error', stackTrace);
    }
    final templates = MessageTemplates(botUsername: botUsername);
    final databaseHandle = SqliteDatabaseHandle.open(config.sqlitePath);
    final jobDedupe = JobDedupeRepository(databaseHandle: databaseHandle)..initSchema();
    final course = SqliteCourseRepository(databaseHandle: databaseHandle);
    course.init();
    course.upsertActiveLaunch(
      productCode: config.productCode,
      productTitle: 'Курс',
      launchCode: config.launchCode,
      launchTitle: 'Запуск',
      priceFullKopecks: rubToKopecks(config.priceFullRub),
      depositKopecks: rubToKopecks(config.depositAmountRub),
      depositDueDays: config.depositDueDays,
      depositDueAt: config.depositDueAt,
      courseStartAt: config.courseStartAt,
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
    l.i(
      'Payment gateway in use: ${paymentGateway.providerId} '
      '(config=${config.paymentProvider.name})',
    );
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
      leadMagnetPath: config.leadMagnetPath,
      leadMagnetFilename: config.leadMagnetFilename,
    );
    final quietHours = QuietHours(
      timezoneOffsetHours: config.timezoneOffsetHours,
      fromHour: config.quietHoursFrom,
      toHour: config.quietHoursTo,
    );
    final jobScheduler = JobScheduler();
    final webhook = PaymentWebhookServer(
      bind: config.paymentWebhookBind,
      gateway: paymentGateway,
      checkout: checkout,
      course: course,
      notifier: handlers,
      secret: config.paymentWebhookSecret,
      callbackPath: config.paymentWebhookPath,
      scheduler: jobScheduler,
    );
    final runner = BotRunner(
      config: config,
      client: client,
      privateHandlers: handlers,
      jobScheduler: jobScheduler,
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
      maintenanceJob: SqliteMaintenanceJob(
        databaseHandle: databaseHandle,
        course: course,
        dedupe: jobDedupe,
        sqlitePath: config.sqlitePath,
        backupDir: config.sqliteBackupDir,
        keep: config.sqliteBackupKeep,
        interval: Duration(hours: config.sqliteBackupIntervalHours),
        backupEnabled: config.sqliteBackupEnabled,
      ),
      googleSheetsWriter: sheetsWriter,
      paymentWebhookServer: webhook,
    );
    return CourseBotRuntime(
      runner: runner,
      databaseHandle: databaseHandle,
      paymentGateway: paymentGateway,
    );
  }

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    paymentGateway.close();
    databaseHandle.close();
  }
}
