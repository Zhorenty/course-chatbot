import 'package:course_chatbot/src/domain/catalog.dart';

abstract interface class CatalogRepository {
  Launch upsertActiveLaunch({
    required String productCode,
    required String productTitle,
    required String launchCode,
    required String launchTitle,
    required int priceFullKopecks,
    required int depositKopecks,
    required int depositDueDays,
    int? channelId,
    String? offerUrl,
    String? leadMagnetFileId,
    String? leadMagnetUrl,
  });

  Launch? activeLaunch();

  void setLeadMagnetFileId(String fileId);
}
