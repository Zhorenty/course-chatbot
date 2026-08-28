part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteWarmupStore on _SqliteCourseStore implements WarmupRepository {
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

  @override
  bool hasWarmupBeenSent({required int userId, required String stepKey}) {
    final rows = _db.select(
      'SELECT 1 FROM warmup_sent WHERE user_id = ? AND step_key = ? LIMIT 1;',
      <Object?>[userId, stepKey],
    );
    return rows.isNotEmpty;
  }

  @override
  void recordWarmupSent({required int userId, required String stepKey, required DateTime sentAt}) {
    _db.execute(
      '''
      INSERT OR IGNORE INTO warmup_sent (user_id, step_key, sent_at)
      VALUES (?, ?, ?);
      ''',
      <Object?>[userId, stepKey, sentAt.toUtc().toIso8601String()],
    );
  }

  @override
  List<WarmupCandidate> listWarmupCandidates({required DateTime now, int limit = 200}) {
    final rows = _db.select(
      '''
      SELECT u.user_id, u.magnet_issued_at, u.first_started_at, u.source, u.funnel_phase,
             GROUP_CONCAT(w.step_key) AS sent_keys
      FROM telegram_users u
      LEFT JOIN warmup_sent w ON w.user_id = u.user_id
      WHERE u.bot_blocked = 0
        AND u.warmup_opt_out = 0
        AND u.funnel_phase NOT IN ('checkout', 'deposit_paid', 'paid', 'access_granted', 'cancelled')
      GROUP BY u.user_id
      ORDER BY u.first_started_at
      LIMIT ?;
      ''',
      <Object?>[limit],
    );
    return [
      for (final row in rows)
        WarmupCandidate(
          userId: row['user_id'] as int,
          firstStartedAt: DateTime.parse(row['first_started_at'] as String),
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
