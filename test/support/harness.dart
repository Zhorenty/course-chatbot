import 'package:course_chatbot/src/application/access_service.dart';
import 'package:course_chatbot/src/application/broadcast_service.dart';
import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/application/funnel_service.dart';
import 'package:course_chatbot/src/application/launch_catalog_admin_service.dart';
import 'package:course_chatbot/src/application/links_catalog_admin_service.dart';
import 'package:course_chatbot/src/application/payment_alert_notifier.dart';
import 'package:course_chatbot/src/application/warmup_service.dart';
import 'package:course_chatbot/src/bot/handlers/private/interaction_whitelist.dart';
import 'package:course_chatbot/src/bot/handlers/private_handlers.dart';
import 'package:course_chatbot/src/data/google_sheets_catalog_sync.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:course_chatbot/src/data/sqlite_course_repository.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/jobs/google_sheets_funnel_export_job.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:sqlite3/sqlite3.dart';

import 'fakes.dart';

final class HandlerHarness {
  HandlerHarness() {
    db = sqlite3.openInMemory();
    handle = SqliteDatabaseHandle.fromDatabase(db, path: ':memory:');
    course = SqliteCourseRepository(databaseHandle: handle);
    sender = FakeMessageSender();
    gateway = FakePaymentGateway();
    channel = FakeChannelApi();
  }

  late final Database db;
  late final SqliteDatabaseHandle handle;
  late final SqliteCourseRepository course;
  late final FakeMessageSender sender;
  late final FakePaymentGateway gateway;
  late final FakeChannelApi channel;
  late final PrivateHandlers handlers;
  late final CheckoutService checkout;
  late final FunnelService funnel;
  FakeGoogleSheetsWriter? sheetsWriter;
  FakeGoogleSheetsGateway? sheetsGateway;
  GoogleSheetsCatalogSync? catalogSync;

  Future<void> init({
    Set<int> adminUserIds = const <int>{1},
    int? adminChatId,
    InteractionWhitelist interactionWhitelist = InteractionWhitelist.permissive,
    int channelId = -1001,
    int priceFullKopecks = 1800000,
    int depositKopecks = 500000,
    DateTime? depositDueAt,
    DateTime? courseStartAt,
    String? leadMagnetFileId = 'file-guide',
    String? leadMagnetPath,
    bool enableSheets = false,
    String? botUsername,
    PaymentGatewayAlertPort? alertPort,
    Duration gatewayAlertCooldown = const Duration(minutes: 15),
    DateTime Function()? nowProvider,
  }) async {
    course.init();
    JobDedupeRepository(databaseHandle: handle).initSchema();
    course.upsertActiveLaunch(
      productCode: 'course',
      productTitle: 'Курс',
      launchCode: 'launch-1',
      launchTitle: 'Запуск',
      priceFullKopecks: priceFullKopecks,
      depositKopecks: depositKopecks,
      depositDueDays: 7,
      depositDueAt: depositDueAt ?? DateTime.utc(2026, 10, 5, 20, 59, 59),
      courseStartAt: courseStartAt ?? DateTime.utc(2026, 10, 12),
      channelId: channelId,
      leadMagnetFileId: leadMagnetFileId,
    );
    final links = AcquisitionLinkCatalog();
    funnel = FunnelService(course: course, links: links);
    final access = AccessService(course: course, telegram: channel);
    checkout = CheckoutService(
      course: course,
      gateway: gateway,
      access: access,
      alertPort: alertPort,
      gatewayAlertCooldown: gatewayAlertCooldown,
      nowProvider: nowProvider,
    );
    final warmup = WarmupService(
      course: course,
      dedupe: JobDedupeRepository(databaseHandle: handle),
    );
    GoogleSheetsFunnelExportJob? sheetsExportJob;
    if (enableSheets) {
      sheetsWriter = FakeGoogleSheetsWriter();
      sheetsGateway = FakeGoogleSheetsGateway(
        sheets: const <GoogleSheetsSheetInfo>[
          GoogleSheetsSheetInfo(title: CoursesSheet.tabTitle, sheetId: CoursesSheet.sheetId),
        ],
        valuesBySheetId: <int, List<List<Object?>>>{CoursesSheet.sheetId: CoursesSheet.seedRows()},
      );
      catalogSync = GoogleSheetsCatalogSync(
        gateway: sheetsGateway!,
        catalog: course,
        links: links,
        botUsername: botUsername,
        fallbackChannelId: channelId,
        fallbackLeadMagnetFileId: leadMagnetFileId,
      );
      sheetsExportJob = GoogleSheetsFunnelExportJob(course: course, writer: sheetsWriter!);
    }
    handlers = PrivateHandlers(
      sender: sender,
      templates: MessageTemplates(botUsername: botUsername),
      course: course,
      funnel: funnel,
      checkout: checkout,
      access: access,
      warmup: warmup,
      broadcast: BroadcastService(sender: sender, course: course),
      adminUserIds: adminUserIds,
      adminChatId: adminChatId,
      interactionWhitelist: interactionWhitelist,
      catalogSync: catalogSync,
      catalogAdmin: catalogSync == null
          ? null
          : LaunchCatalogAdminService(sync: catalogSync!, catalog: course),
      linksAdmin: catalogSync == null
          ? null
          : LinksCatalogAdminService(sync: catalogSync!, links: links, catalog: course),
      sheetsExportJob: sheetsExportJob,
      leadMagnetPath: leadMagnetPath,
      nowProvider: nowProvider,
      adminAlerts: alertPort is AdminAlertPort ? alertPort as AdminAlertPort : null,
    );
  }

  void dispose() {
    db.dispose();
  }
}
