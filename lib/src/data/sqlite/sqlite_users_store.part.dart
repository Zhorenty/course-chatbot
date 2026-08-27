part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteUsersStore on _SqliteCourseStore implements UserRepository {
  @override
  UserProfile ensureUser({
    required int userId,
    String? username,
    String? firstName,
    String? source,
    required DateTime now,
  }) {
    final existing = getUser(userId);
    final nowIso = now.toUtc().toIso8601String();
    final normalized = normalizeTelegramUsername(username);
    if (existing == null) {
      _db.execute(
        '''
        INSERT INTO telegram_users (
          user_id, username, first_name, source, funnel_phase, warmup_opt_out,
          bot_blocked, first_started_at, last_seen_at, updated_at
        ) VALUES (?, ?, ?, ?, 'lead', 0, 0, ?, ?, ?);
        ''',
        <Object?>[userId, normalized, firstName, source, nowIso, nowIso, nowIso],
      );
      return getUser(userId)!;
    }
    _db.execute(
      '''
      UPDATE telegram_users
      SET username = COALESCE(?, username),
          first_name = COALESCE(?, first_name),
          last_seen_at = ?,
          updated_at = ?,
          bot_blocked = 0
      WHERE user_id = ?;
      ''',
      <Object?>[normalized, firstName, nowIso, nowIso, userId],
    );
    if ((existing.source == null || existing.source!.isEmpty) &&
        source != null &&
        source.isNotEmpty) {
      _db.execute('UPDATE telegram_users SET source = ? WHERE user_id = ?;', <Object?>[
        source,
        userId,
      ]);
    }
    return getUser(userId)!;
  }

  @override
  UserProfile? getUser(int userId) {
    final rows = _db.select('SELECT * FROM telegram_users WHERE user_id = ?;', <Object?>[userId]);
    if (rows.isEmpty) {
      return null;
    }
    return mapUser(rows.first);
  }

  @override
  void touchUser({
    required int userId,
    String? username,
    String? firstName,
    required DateTime now,
  }) {
    ensureUser(userId: userId, username: username, firstName: firstName, now: now);
  }

  @override
  void setFunnelPhase({required int userId, required FunnelPhase phase, DateTime? magnetIssuedAt}) {
    final existing = getUser(userId);
    final nextPhase = existing == null || existing.funnelPhase.canTransitionTo(phase)
        ? phase
        : existing.funnelPhase;
    if (magnetIssuedAt != null) {
      _db.execute(
        '''
        UPDATE telegram_users
        SET funnel_phase = ?, magnet_issued_at = COALESCE(magnet_issued_at, ?), updated_at = ?
        WHERE user_id = ?;
        ''',
        <Object?>[
          nextPhase.storageValue,
          magnetIssuedAt.toUtc().toIso8601String(),
          _nowProvider().toUtc().toIso8601String(),
          userId,
        ],
      );
      return;
    }
    if (existing != null && !existing.funnelPhase.canTransitionTo(phase)) {
      return;
    }
    _db.execute(
      '''
      UPDATE telegram_users
      SET funnel_phase = ?, updated_at = ?
      WHERE user_id = ?;
      ''',
      <Object?>[nextPhase.storageValue, _nowProvider().toUtc().toIso8601String(), userId],
    );
  }

  @override
  void setWarmupOptOut({required int userId, required bool optOut}) {
    _db.execute(
      'UPDATE telegram_users SET warmup_opt_out = ?, updated_at = ? WHERE user_id = ?;',
      <Object?>[optOut ? 1 : 0, _nowProvider().toUtc().toIso8601String(), userId],
    );
  }

  @override
  void setBotBlocked({required int userId, required bool blocked}) {
    _db.execute(
      'UPDATE telegram_users SET bot_blocked = ?, updated_at = ? WHERE user_id = ?;',
      <Object?>[blocked ? 1 : 0, _nowProvider().toUtc().toIso8601String(), userId],
    );
  }

  @override
  UserProfile? findUserByUsername(String username) {
    final normalized = normalizeTelegramUsername(username);
    if (normalized == null) {
      return null;
    }
    final rows = _db.select(
      '''
      SELECT * FROM telegram_users
      WHERE username = ? COLLATE NOCASE
      ORDER BY updated_at DESC LIMIT 1;
      ''',
      <Object?>[normalized],
    );
    if (rows.isEmpty) {
      return null;
    }
    return mapUser(rows.first);
  }

  @override
  List<UserProfile> searchUsers(String query, {int limit = 10}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <UserProfile>[];
    }
    final asId = int.tryParse(trimmed);
    if (asId != null) {
      final user = getUser(asId);
      return user == null ? const <UserProfile>[] : <UserProfile>[user];
    }
    final normalized = normalizeTelegramUsername(trimmed) ?? trimmed.toLowerCase();
    final rows = _db.select(
      '''
      SELECT * FROM telegram_users
      WHERE username LIKE ? COLLATE NOCASE OR CAST(user_id AS TEXT) = ?
      ORDER BY updated_at DESC
      LIMIT ?;
      ''',
      <Object?>['%$normalized%', trimmed, limit],
    );
    return rows.map(mapUser).toList(growable: false);
  }

  @override
  List<int> listBroadcastUserIds({required BroadcastSegment segment}) {
    final sql = switch (segment) {
      BroadcastSegment.allStarted =>
        '''
        SELECT user_id FROM telegram_users
        WHERE bot_blocked = 0
        ORDER BY user_id;
      ''',
      BroadcastSegment.guideNotPaid =>
        '''
        SELECT user_id FROM telegram_users
        WHERE bot_blocked = 0
          AND magnet_issued_at IS NOT NULL
          AND funnel_phase NOT IN ('paid', 'access_granted', 'cancelled', 'deposit_paid')
        ORDER BY user_id;
      ''',
    };
    return _db.select(sql).map((row) => row['user_id'] as int).toList(growable: false);
  }
}
