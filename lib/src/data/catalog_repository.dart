import 'package:course_chatbot/src/domain/catalog.dart';

abstract interface class CatalogRepository {
  Launch upsertLaunch({
    required String productCode,
    required String productTitle,
    required String launchCode,
    required String launchTitle,
    required int priceFullKopecks,
    required int depositKopecks,
    required int depositDueDays,
    DateTime? depositDueAt,
    DateTime? courseStartAt,
    int? channelId,
    String? offerUrl,
    String? leadMagnetFileId,
    String? leadMagnetUrl,
    bool activate = false,
  });

  Launch upsertActiveLaunch({
    required String productCode,
    required String productTitle,
    required String launchCode,
    required String launchTitle,
    required int priceFullKopecks,
    required int depositKopecks,
    required int depositDueDays,
    DateTime? depositDueAt,
    DateTime? courseStartAt,
    int? channelId,
    String? offerUrl,
    String? leadMagnetFileId,
    String? leadMagnetUrl,
  });

  void setActiveLaunch(String launchCode);

  Launch? activeLaunch();

  Launch? getLaunch(int id);

  Launch? launchByCode(String code);

  Launch? launchByTitle(String title);

  Launch? launchByChannelId(int channelId);

  void setLeadMagnetFileId(String fileId, {int? launchId});
}
