import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/catalog_admin.dart';
import 'package:course_chatbot/src/domain/launch_dozhim.dart';
import 'package:course_chatbot/src/domain/stored_telegram_message.dart';

abstract interface class CatalogRepository {
  Launch upsertLaunch({
    required String productCode,
    required String productTitle,
    required String launchCode,
    required String launchTitle,
    required int priceFullKopecks,
    required int depositKopecks,
    required int depositDueDays,
    int pricePromoKopecks = 0,
    DateTime? depositDueAt,
    DateTime? courseStartAt,
    DateTime? webinarAt,
    String? webinarUrl,
    DateTime? salesStartAt,
    DateTime? salesEndAt,
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
    int pricePromoKopecks = 0,
    DateTime? depositDueAt,
    DateTime? courseStartAt,
    DateTime? webinarAt,
    String? webinarUrl,
    DateTime? salesStartAt,
    DateTime? salesEndAt,
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

  List<Launch> listLaunches();

  LaunchUsage launchUsage(int launchId);

  void renameLaunchCode({required String from, required String to});

  bool tryDeleteLaunch(int id);

  void setLeadMagnetFileId(String fileId, {int? launchId});

  void setLaunchDescription(String? text, {required int launchId});

  List<LaunchDozhimMessage> listLaunchDozhim(int launchId);

  LaunchDozhimMessage? getLaunchDozhim(int id);

  LaunchDozhimMessage addLaunchDozhim({
    required int launchId,
    required int sourceChatId,
    required int sourceMessageId,
    required BroadcastContentKind contentKind,
    List<int>? sourceMessageIds,
    String? previewText,
    StoredTelegramMessage? payload,
  });

  LaunchDozhimMessage? replaceLaunchDozhim({
    required int id,
    required int sourceChatId,
    required int sourceMessageId,
    required BroadcastContentKind contentKind,
    List<int>? sourceMessageIds,
    String? previewText,
    StoredTelegramMessage? payload,
  });

  bool deleteLaunchDozhim(int id);
}
