import 'package:course_chatbot/src/data/catalog_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/launch_copy.dart';

Launch testLaunch({
  int id = 1,
  int productId = 1,
  String code = 'launch-1',
  String title = 'Запуск',
  int priceFullKopecks = 1900000,
  int? pricePromoKopecks,
  int depositKopecks = 0,
  int depositDueDays = 7,
  DateTime? depositDueAt,
  DateTime? courseStartAt,
  DateTime? webinarAt,
  String? webinarUrl,
  String? promoCheckoutUrl,
  DateTime? salesStartAt,
  DateTime? salesEndAt,
  int channelId = -1001,
  String? leadMagnetFileId,
  String? leadMagnetUrl,
  String? description,
  bool isActive = false,
  LaunchCopy copy = const LaunchCopy.empty(),
}) {
  final start = courseStartAt ?? DateTime.utc(2026, 10, 12);
  final webinar = webinarAt ?? DateTime.utc(2026, 9, 29, 16);
  return Launch(
    id: id,
    productId: productId,
    code: code,
    title: title,
    priceFullKopecks: priceFullKopecks,
    pricePromoKopecks: pricePromoKopecks ?? LaunchPrices.promoKopecks,
    depositKopecks: depositKopecks,
    depositDueDays: depositDueDays,
    depositDueAt: depositDueAt,
    courseStartAt: start,
    webinarAt: webinar,
    webinarUrl: webinarUrl,
    promoCheckoutUrl: promoCheckoutUrl,
    salesStartAt: salesStartAt ?? Launch.impliedSalesStartAt(webinar),
    salesEndAt: salesEndAt ?? Launch.impliedSalesEndAt(start),
    channelId: channelId,
    leadMagnetFileId: leadMagnetFileId,
    leadMagnetUrl: leadMagnetUrl,
    description: description ?? Launch.defaultDescription,
    isActive: isActive,
    copy: copy,
  );
}

CatalogLaunchDraft testDraft({
  String productCode = CoursesSheet.seedProductCode,
  String productTitle = CoursesSheet.seedProductTitle,
  String launchCode = 'nov-26',
  String launchTitle = 'Ноябрь',
  bool isActive = false,
  int priceFullKopecks = 2000000,
  int? pricePromoKopecks,
  int depositKopecks = 0,
  int depositDueDays = 7,
  DateTime? depositDueAt,
  DateTime? courseStartAt,
  DateTime? webinarAt,
  String? webinarUrl,
  DateTime? salesStartAt,
  DateTime? salesEndAt,
  int channelId = -1001,
  String? leadMagnetFileId,
  String? leadMagnetUrl,
}) {
  final start = courseStartAt ?? DateTime.utc(2026, 11, 1);
  final webinar = webinarAt ?? DateTime.utc(2026, 10, 29, 16);
  return CatalogLaunchDraft(
    productCode: productCode,
    productTitle: productTitle,
    launchCode: launchCode,
    launchTitle: launchTitle,
    isActive: isActive,
    priceFullKopecks: priceFullKopecks,
    pricePromoKopecks: pricePromoKopecks ?? LaunchPrices.promoKopecks,
    depositKopecks: depositKopecks,
    depositDueDays: depositDueDays,
    depositDueAt: depositDueAt,
    courseStartAt: start,
    webinarAt: webinar,
    webinarUrl: webinarUrl,
    salesStartAt: salesStartAt ?? Launch.impliedSalesStartAt(webinar),
    salesEndAt: salesEndAt ?? Launch.impliedSalesEndAt(start),
    channelId: channelId,
    leadMagnetFileId: leadMagnetFileId,
    leadMagnetUrl: leadMagnetUrl,
  );
}

void clearLaunchDozhim(CatalogRepository catalog, int launchId) {
  for (final message in catalog.listLaunchDozhim(launchId)) {
    catalog.deleteLaunchDozhim(message.id);
  }
}
