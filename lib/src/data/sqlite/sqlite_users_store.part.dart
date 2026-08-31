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
  }) {
    final resolved = resolveEnrollmentLaunchId(launchId);
    if (resolved != null) {
      writeEnrollmentPhase(
        userId: userId,
        launchId: resolved,
        phase: phase,
        magnetIssuedAt: magnetIssuedAt,
      );
    }
    if (resolved != null && !isActiveLaunchId(resolved)) {
      return;
    }
    _writeUserFunnelPhase(userId: userId, phase: phase, magnetIssuedAt: magnetIssuedAt);
  }

  void _writeUserFunnelPhase({
    required int userId,
    required FunnelPhase phase,
    DateTime? magnetIssuedAt,
  }) {
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
    Set<String> courseEntrySources = AcquisitionSource.coursePayloads,
    int? launchId,
  }) {
    final params = <Object?>[];
    final sql = _broadcastSelect(
      segment,
      excludeOptOut: excludeOptOut,
      courseEntrySources: courseEntrySources,
      launchId: resolveEnrollmentLaunchId(launchId),
      params: params,
    );
    return _db.select(sql, params).map((row) => row['user_id'] as int).toList(growable: false);
  }

  @override
  int countBroadcastUsers({
    required BroadcastSegment segment,
    bool excludeOptOut = false,
    Set<String> courseEntrySources = AcquisitionSource.coursePayloads,
    int? launchId,
  }) {
    final params = <Object?>[];
    final sql = _broadcastSelect(
      segment,
      excludeOptOut: excludeOptOut,
      courseEntrySources: courseEntrySources,
      launchId: resolveEnrollmentLaunchId(launchId),
      params: params,
      count: true,
    );
    final rows = _db.select(sql, params);
    return rows.first['c'] as int;
  }

  String _broadcastSelect(
    BroadcastSegment segment, {
    required bool excludeOptOut,
    required Set<String> courseEntrySources,
    required int? launchId,
    required List<Object?> params,
    bool count = false,
  }) {
    final scoped = launchId != null;
    if (scoped) {
      params.add(launchId);
    }
    final from = scoped
        ? 'telegram_users u JOIN user_enrollments e ON e.user_id = u.user_id AND e.launch_id = ?'
        : 'telegram_users';
    final cols = scoped
        ? (
            user: 'u.user_id',
            blocked: 'u.bot_blocked',
            source: 'u.source',
            phase: 'e.funnel_phase',
            magnet: 'e.magnet_issued_at',
            opt: 'e.warmup_opt_out',
            accessLaunch: 'e.launch_id',
          )
        : (
            user: 'user_id',
            blocked: 'bot_blocked',
            source: 'source',
            phase: 'funnel_phase',
            magnet: 'magnet_issued_at',
            opt: 'warmup_opt_out',
            accessLaunch: null,
          );
    final where = _broadcastWhere(
      segment,
      excludeOptOut: excludeOptOut,
      courseEntrySources: courseEntrySources,
      params: params,
      cols: cols,
    );
    if (count) {
      return 'SELECT COUNT(*) AS c FROM $from WHERE $where;';
    }
    return 'SELECT ${cols.user} AS user_id FROM $from WHERE $where ORDER BY ${cols.user};';
  }

  String _broadcastWhere(
    BroadcastSegment segment, {
    required bool excludeOptOut,
    required Set<String> courseEntrySources,
    required List<Object?> params,
    required ({
      String user,
      String blocked,
      String source,
      String phase,
      String magnet,
      String opt,
      String? accessLaunch,
    })
    cols,
  }) {
    final optOut = excludeOptOut ? ' AND ${cols.opt} = 0' : '';
    return switch (segment) {
      BroadcastSegment.allStarted =>
        "${cols.blocked} = 0 AND ${cols.phase} NOT IN ('paid', 'access_granted', 'cancelled')$optOut",
      BroadcastSegment.leadNoGuide =>
        "${cols.blocked} = 0 AND ${cols.phase} = 'lead' AND ${cols.magnet} IS NULL$optOut"
            '${_sourceNotIn(cols.source, courseEntrySources, params)}',
      BroadcastSegment.guideNotPaid =>
        '${cols.blocked} = 0 AND ${cols.magnet} IS NOT NULL '
            "AND ${cols.phase} NOT IN ('paid', 'access_granted', 'cancelled', 'deposit_paid', 'checkout')$optOut",
      BroadcastSegment.courseLeadNoCheckout => _courseLeadWhere(
        cols: cols,
        courseEntrySources: courseEntrySources,
        params: params,
        excludeOptOut: excludeOptOut,
      ),
      BroadcastSegment.checkoutOpen => "${cols.blocked} = 0 AND ${cols.phase} = 'checkout'$optOut",
      BroadcastSegment.depositPaid =>
        "${cols.blocked} = 0 AND ${cols.phase} = 'deposit_paid'$optOut",
      BroadcastSegment.paidAccess =>
        "${cols.blocked} = 0 AND ${cols.phase} IN ('paid', 'access_granted')$optOut",
      BroadcastSegment.paidNotJoined =>
        "${cols.blocked} = 0 AND ${cols.phase} IN ('paid', 'access_granted')$optOut "
            'AND EXISTS ('
            '  SELECT 1 FROM channel_access a '
            '  WHERE a.user_id = ${cols.user} '
            '    AND a.invite_link IS NOT NULL AND a.invite_link != \'\' '
            '    AND a.joined_at IS NULL AND a.revoked_at IS NULL'
            '${cols.accessLaunch == null ? '' : ' AND a.launch_id = ${cols.accessLaunch}'}'
            ')',
      BroadcastSegment.cancelled => "${cols.blocked} = 0 AND ${cols.phase} = 'cancelled'$optOut",
    };
  }

  String _courseLeadWhere({
    required ({
      String user,
      String blocked,
      String source,
      String phase,
      String magnet,
      String opt,
      String? accessLaunch,
    })
    cols,
    required Set<String> courseEntrySources,
    required List<Object?> params,
    required bool excludeOptOut,
  }) {
    final optOut = excludeOptOut ? ' AND ${cols.opt} = 0' : '';
    if (courseEntrySources.isEmpty) {
      return '0';
    }
    final placeholders = List<String>.filled(courseEntrySources.length, '?').join(', ');
    params.addAll(courseEntrySources);
    return "${cols.blocked} = 0 AND ${cols.phase} = 'lead' AND ${cols.magnet} IS NULL "
        'AND ${cols.source} IN ($placeholders)$optOut';
  }

  String _sourceNotIn(String sourceCol, Set<String> sources, List<Object?> params) {
    if (sources.isEmpty) {
      return '';
    }
    final placeholders = List<String>.filled(sources.length, '?').join(', ');
    params.addAll(sources);
    return ' AND ($sourceCol IS NULL OR $sourceCol NOT IN ($placeholders))';
  }
}
