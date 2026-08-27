part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteAccessStore on _SqliteCourseStore implements ChannelAccessRepository {
  @override
  ChannelAccess? accessFor({required int userId, required int launchId}) {
    final rows = _db.select(
      'SELECT * FROM channel_access WHERE user_id = ? AND launch_id = ?;',
      <Object?>[userId, launchId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return mapAccess(rows.first);
  }

  @override
  ChannelAccess upsertAccess({
    required int userId,
    required int launchId,
    required int orderId,
    String? inviteLink,
    DateTime? inviteCreatedAt,
    DateTime? joinedAt,
    DateTime? revokedAt,
  }) {
    _db.execute(
      '''
      INSERT INTO channel_access (
        user_id, launch_id, order_id, invite_link, invite_created_at, joined_at, revoked_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(user_id, launch_id) DO UPDATE SET
        order_id = excluded.order_id,
        invite_link = excluded.invite_link,
        invite_created_at = excluded.invite_created_at,
        joined_at = COALESCE(excluded.joined_at, channel_access.joined_at),
        revoked_at = excluded.revoked_at;
      ''',
      <Object?>[
        userId,
        launchId,
        orderId,
        inviteLink,
        inviteCreatedAt?.toUtc().toIso8601String(),
        joinedAt?.toUtc().toIso8601String(),
        revokedAt?.toUtc().toIso8601String(),
      ],
    );
    return accessFor(userId: userId, launchId: launchId)!;
  }

  @override
  void markJoined({required int userId, required int launchId, required DateTime joinedAt}) {
    _db.execute(
      '''
      UPDATE channel_access
      SET joined_at = COALESCE(joined_at, ?)
      WHERE user_id = ? AND launch_id = ?;
      ''',
      <Object?>[joinedAt.toUtc().toIso8601String(), userId, launchId],
    );
  }
}
