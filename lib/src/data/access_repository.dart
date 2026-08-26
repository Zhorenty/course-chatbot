import 'package:course_chatbot/src/domain/channel_access.dart';

abstract interface class ChannelAccessRepository {
  ChannelAccess? accessFor({required int userId, required int launchId});

  ChannelAccess upsertAccess({
    required int userId,
    required int launchId,
    required int orderId,
    String? inviteLink,
    DateTime? inviteCreatedAt,
    DateTime? joinedAt,
    DateTime? revokedAt,
  });

  void markJoined({
    required int userId,
    required int launchId,
    required DateTime joinedAt,
  });
}
