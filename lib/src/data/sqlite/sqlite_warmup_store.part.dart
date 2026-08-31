part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteWarmupStore on _SqliteEnrollmentStore implements WarmupRepository {
  @override
  List<WarmupStep> listWarmupSteps() {
    final rows = _db.select(
      'SELECT * FROM warmup_steps WHERE enabled = 1 ORDER BY sort_order, step_key;',
    );
    return rows
        .map(
          (row) => WarmupStep(
            stepKey: row['step_key'] as String,
            delay: Duration(seconds: row['delay_seconds'] as int),
            sortOrder: row['sort_order'] as int,
            anchor: WarmupAnchorX.parse(row['anchor'] as String?),
            enabled: (row['enabled'] as int) == 1,
          ),
        )
        .toList(growable: false);
  }

  @override
  void seedDefaultWarmupSteps() {
    for (final step in WarmupStep.defaults) {
      _db.execute(
        '''
        INSERT OR IGNORE INTO warmup_steps (step_key, delay_seconds, sort_order, enabled, anchor)
        VALUES (?, ?, ?, 1, ?);
        ''',
        <Object?>[step.stepKey, step.delay.inSeconds, step.sortOrder, step.anchor.storageValue],
      );
    }
  }

  int? _warmupLaunchId(int? launchId) => resolveEnrollmentLaunchId(launchId);

  @override
  bool hasWarmupBeenSent({required int userId, required String stepKey, int? launchId}) {
    final resolved = _warmupLaunchId(launchId);
    if (resolved == null) {
      return false;
    }
    final rows = _db.select(
      'SELECT 1 FROM warmup_sent WHERE user_id = ? AND launch_id = ? AND step_key = ? LIMIT 1;',
      <Object?>[userId, resolved, stepKey],
    );
    return rows.isNotEmpty;
  }

  @override
  void recordWarmupSent({
    required int userId,
    required String stepKey,
    required DateTime sentAt,
    int? launchId,
  }) {
    final resolved = _warmupLaunchId(launchId);
    if (resolved == null) {
      return;
    }
    _db.execute(
      '''
      INSERT OR IGNORE INTO warmup_sent (user_id, launch_id, step_key, sent_at)
      VALUES (?, ?, ?, ?);
      ''',
      <Object?>[userId, resolved, stepKey, sentAt.toUtc().toIso8601String()],
    );
  }

  @override
  List<WarmupCandidate> listWarmupCandidates({required DateTime now, int limit = 200}) {
    final rows = _db.select(
      '''
      SELECT e.user_id, e.launch_id, e.magnet_issued_at, e.started_at, e.funnel_phase,
             u.first_started_at, u.source,
             GROUP_CONCAT(w.step_key) AS sent_keys
      FROM user_enrollments e
      JOIN telegram_users u ON u.user_id = e.user_id
      LEFT JOIN warmup_sent w ON w.user_id = e.user_id AND w.launch_id = e.launch_id
      WHERE u.bot_blocked = 0
        AND e.warmup_opt_out = 0
        AND e.funnel_phase NOT IN ('checkout', 'deposit_paid', 'paid', 'access_granted', 'cancelled')
      GROUP BY e.user_id, e.launch_id
      ORDER BY e.started_at
      LIMIT ?;
      ''',
      <Object?>[limit],
    );
    return [
      for (final row in rows)
        WarmupCandidate(
          userId: row['user_id'] as int,
          launchId: row['launch_id'] as int,
          firstStartedAt: DateTime.parse(row['started_at'] as String),
          magnetIssuedAt: parseTime(row['magnet_issued_at'] as String?),
          source: row['source'] as String?,
          funnelPhase: FunnelPhaseX.parse(row['funnel_phase'] as String?),
          sentKeys: _splitSentKeys(row['sent_keys'] as String?),
        ),
    ];
  }

  Set<String> _splitSentKeys(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <String>{};
    }
    return <String>{
      for (final key in raw.split(','))
        if (key.isNotEmpty) key,
    };
  }
}
