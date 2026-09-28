part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteUsersStore on _SqliteEnrollmentStore implements UserRepository {
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
    } else {
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
    }
    final launch = activeLaunch();
    if (launch != null) {
      ensureEnrollment(userId: userId, launchId: launch.id, now: now);
      _syncProfileToEnrollment(userId: userId, launchId: launch.id);
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
  void setFunnelPhase({
    required int userId,
    required FunnelPhase phase,
    DateTime? magnetIssuedAt,
    int? launchId,
    bool force = false,
  }) {
    final resolved = resolveEnrollmentLaunchId(launchId);
    if (resolved != null) {
      writeEnrollmentPhase(
        userId: userId,
        launchId: resolved,
        phase: phase,
        magnetIssuedAt: magnetIssuedAt,
        force: force,
      );
    }
    if (resolved != null && !isActiveLaunchId(resolved)) {
      return;
    }
    _writeUserFunnelPhase(
      userId: userId,
      phase: phase,
      magnetIssuedAt: magnetIssuedAt,
      force: force,
    );
  }

  void _syncProfileToEnrollment({required int userId, required int launchId}) {
    final user = getUser(userId);
    if (user == null) {
      return;
    }
    final enrollment = getEnrollment(userId: userId, launchId: launchId);
    final phase = enrollment?.funnelPhase ?? FunnelPhase.lead;
    final magnet = enrollment?.magnetIssuedAt;
    final optOut = enrollment?.warmupOptOut ?? false;
    if (user.funnelPhase == phase &&
        user.warmupOptOut == optOut &&
        _sameInstant(user.magnetIssuedAt, magnet)) {
      return;
    }
    _db.execute(
      '''
      UPDATE telegram_users
      SET funnel_phase = ?, magnet_issued_at = ?, warmup_opt_out = ?, updated_at = ?
      WHERE user_id = ?;
      ''',
      <Object?>[
        phase.storageValue,
        magnet?.toUtc().toIso8601String(),
        optOut ? 1 : 0,
        _nowProvider().toUtc().toIso8601String(),
        userId,
      ],
    );
  }

  bool _sameInstant(DateTime? left, DateTime? right) {
    if (left == null || right == null) {
      return left == right;
    }
    return left.toUtc().isAtSameMomentAs(right.toUtc());
  }

  void _writeUserFunnelPhase({
    required int userId,
    required FunnelPhase phase,
    DateTime? magnetIssuedAt,
    bool force = false,
  }) {
    final existing = getUser(userId);
    final current = existing?.funnelPhase;
    final allowed = force || current == null || current.canTransitionTo(phase);
    final nextPhase = allowed ? phase : current;
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
    if (!allowed) {
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
  void setWarmupOptOut({required int userId, required bool optOut, int? launchId}) {
    final resolved = resolveEnrollmentLaunchId(launchId);
    if (resolved != null) {
      setEnrollmentWarmupOptOut(userId: userId, launchId: resolved, optOut: optOut);
    }
    if (resolved != null && !isActiveLaunchId(resolved)) {
      return;
    }
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
  void resetUserFunnel(int userId) {
    _handle.transaction(() {
      final orderRows = _db.select('SELECT id FROM orders WHERE user_id = ?;', <Object?>[userId]);
      for (final row in orderRows) {
        final orderId = row['id'] as int;
        _db.execute('DELETE FROM job_dedupe_log WHERE dedupe_key LIKE ?;', <Object?>[
          'abandon:$orderId:%',
        ]);
        _db.execute('DELETE FROM job_dedupe_log WHERE dedupe_key LIKE ?;', <Object?>[
          'remainder:$orderId:%',
        ]);
      }
      _db.execute(
        'DELETE FROM payments WHERE order_id IN (SELECT id FROM orders WHERE user_id = ?);',
        <Object?>[userId],
      );
      _db.execute('DELETE FROM orders WHERE user_id = ?;', <Object?>[userId]);
      _db.execute('DELETE FROM channel_access WHERE user_id = ?;', <Object?>[userId]);
      _db.execute('DELETE FROM warmup_sent WHERE user_id = ?;', <Object?>[userId]);
      _db.execute('DELETE FROM user_enrollments WHERE user_id = ?;', <Object?>[userId]);
      _db.execute('DELETE FROM acquisition_events WHERE user_id = ?;', <Object?>[userId]);
      for (final launch in listLaunches()) {
        _db.execute('DELETE FROM job_dedupe_log WHERE dedupe_key LIKE ?;', <Object?>[
          'warmup:${launch.id}:$userId:%',
        ]);
      }
      _db.execute('DELETE FROM job_dedupe_log WHERE dedupe_key LIKE ?;', <Object?>[
        'unjoined:$userId:%',
      ]);
      _db.execute(
        '''
        UPDATE telegram_users
        SET source = NULL,
            funnel_phase = 'lead',
            warmup_opt_out = 0,
            magnet_issued_at = NULL,
            updated_at = ?
        WHERE user_id = ?;
        ''',
        <Object?>[_nowProvider().toUtc().toIso8601String(), userId],
      );
    });
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
  List<int> listBroadcastUserIds({
    required BroadcastSegment segment,
    bool excludeOptOut = false,
    int? launchId,
  }) {
    final resolved = resolveEnrollmentLaunchId(launchId);
    if (resolved == null) {
      return const <int>[];
    }
    final params = <Object?>[resolved];
    final where = _broadcastWhere(segment, excludeOptOut: excludeOptOut, params: params);
    final rows = _db.select('''
      SELECT u.user_id
      FROM telegram_users u
      JOIN user_enrollments e ON e.user_id = u.user_id AND e.launch_id = ?
      WHERE $where
      ORDER BY u.user_id;
      ''', params);
    return rows.map((row) => row['user_id'] as int).toList(growable: false);
  }

  @override
  int countBroadcastUsers({
    required BroadcastSegment segment,
    bool excludeOptOut = false,
    int? launchId,
  }) {
    final resolved = resolveEnrollmentLaunchId(launchId);
    if (resolved == null) {
      return 0;
    }
    final params = <Object?>[resolved];
    final where = _broadcastWhere(segment, excludeOptOut: excludeOptOut, params: params);
    final rows = _db.select('''
      SELECT COUNT(*) AS c
      FROM telegram_users u
      JOIN user_enrollments e ON e.user_id = u.user_id AND e.launch_id = ?
      WHERE $where;
      ''', params);
    return rows.first['c'] as int;
  }

  String _broadcastWhere(
    BroadcastSegment segment, {
    required bool excludeOptOut,
    required List<Object?> params,
  }) {
    final filter = _participantsWhere(
      segment.participantSegment,
      excludeUserIds: const <int>{},
      params: params,
    );
    final optOut = excludeOptOut ? ' AND e.warmup_opt_out = 0' : '';
    return '($filter) AND u.bot_blocked = 0$optOut';
  }

  @override
  List<UserProfile> listParticipants({
    required ParticipantListSegment segment,
    int? launchId,
    int limit = 8,
    int offset = 0,
    Set<int> excludeUserIds = const <int>{},
  }) {
    final resolved = resolveEnrollmentLaunchId(launchId);
    if (resolved == null) {
      return const <UserProfile>[];
    }
    final params = <Object?>[resolved];
    final where = _participantsWhere(segment, excludeUserIds: excludeUserIds, params: params);
    params
      ..add(limit)
      ..add(offset);
    final rows = _db.select('''
      SELECT
        u.user_id,
        u.username,
        u.first_name,
        u.source,
        e.funnel_phase,
        e.warmup_opt_out,
        u.bot_blocked,
        e.magnet_issued_at,
        u.first_started_at,
        u.last_seen_at
      FROM telegram_users u
      JOIN user_enrollments e ON e.user_id = u.user_id AND e.launch_id = ?
      WHERE $where
      ORDER BY ${_participantsOrder(segment)}
      LIMIT ? OFFSET ?;
      ''', params);
    return rows.map(mapUser).toList(growable: false);
  }

  @override
  int countParticipants({
    required ParticipantListSegment segment,
    int? launchId,
    Set<int> excludeUserIds = const <int>{},
  }) {
    final resolved = resolveEnrollmentLaunchId(launchId);
    if (resolved == null) {
      return 0;
    }
    final params = <Object?>[resolved];
    final where = _participantsWhere(segment, excludeUserIds: excludeUserIds, params: params);
    final rows = _db.select('''
      SELECT COUNT(*) AS c
      FROM telegram_users u
      JOIN user_enrollments e ON e.user_id = u.user_id AND e.launch_id = ?
      WHERE $where;
      ''', params);
    return rows.first['c'] as int;
  }

  String _participantsWhere(
    ParticipantListSegment segment, {
    required Set<int> excludeUserIds,
    required List<Object?> params,
  }) {
    final filter = switch (segment) {
      ParticipantListSegment.webinarRsvp => 'e.webinar_rsvp = 1',
      ParticipantListSegment.paid => "e.funnel_phase IN ('paid', 'access_granted')",
      ParticipantListSegment.deposit => "e.funnel_phase = 'deposit_paid'",
      ParticipantListSegment.checkout => "e.funnel_phase = 'checkout'",
      ParticipantListSegment.enrollIntent => 'e.enroll_intent_at IS NOT NULL',
      ParticipantListSegment.magnet => 'e.magnet_issued_at IS NOT NULL',
      ParticipantListSegment.started => '1=1',
      ParticipantListSegment.cancelled => "e.funnel_phase = 'cancelled'",
    };
    if (excludeUserIds.isEmpty) {
      return filter;
    }
    final placeholders = List<String>.filled(excludeUserIds.length, '?').join(', ');
    params.addAll(excludeUserIds);
    return '$filter AND u.user_id NOT IN ($placeholders)';
  }

  String _participantsOrder(ParticipantListSegment segment) {
    return switch (segment) {
      ParticipantListSegment.webinarRsvp =>
        'COALESCE(e.webinar_rsvp_at, e.updated_at) DESC, u.user_id DESC',
      ParticipantListSegment.enrollIntent =>
        'COALESCE(e.enroll_intent_at, e.updated_at) DESC, u.user_id DESC',
      ParticipantListSegment.paid ||
      ParticipantListSegment.deposit ||
      ParticipantListSegment.checkout ||
      ParticipantListSegment.magnet ||
      ParticipantListSegment.started ||
      ParticipantListSegment.cancelled => 'e.updated_at DESC, u.user_id DESC',
    };
  }
}
