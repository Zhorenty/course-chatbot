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
            enabled: (row['enabled'] as int) == 1,
          ),
        )
        .toList(growable: false);
  }

  @override
  void seedDefaultWarmupSteps() {
    final existing = _db.select('SELECT COUNT(*) AS c FROM warmup_steps;');
    if ((existing.first['c'] as int) > 0) {
      return;
    }
    const steps = <(String, int, int)>[
      ('warmup_0', 0, 0),
      ('warmup_d1', 86400, 1),
      ('warmup_d3', 259200, 2),
    ];
    for (final step in steps) {
      _db.execute(
        '''
        INSERT INTO warmup_steps (step_key, delay_seconds, sort_order, enabled)
        VALUES (?, ?, ?, 1);
        ''',
        <Object?>[step.$1, step.$2, step.$3],
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
  List<WarmupCandidate> listWarmupCandidates({required DateTime now, int limit = 100}) {
    final nowIso = now.toUtc().toIso8601String();
    final rows = _db.select(
      '''
      SELECT u.user_id, u.magnet_issued_at, u.first_started_at,
             GROUP_CONCAT(w.step_key) AS sent_keys
      FROM telegram_users u
      LEFT JOIN warmup_sent w ON w.user_id = u.user_id
      WHERE u.bot_blocked = 0
        AND u.warmup_opt_out = 0
        AND u.funnel_phase IN ('magnet_issued', 'warming')
        AND EXISTS (
          SELECT 1 FROM warmup_steps s
          WHERE s.enabled = 1
            AND NOT EXISTS (
              SELECT 1 FROM warmup_sent sent
              WHERE sent.user_id = u.user_id AND sent.step_key = s.step_key
            )
            AND (
              strftime('%s', ?)
              - strftime('%s', COALESCE(u.magnet_issued_at, u.first_started_at))
            ) >= s.delay_seconds
        )
      GROUP BY u.user_id
      ORDER BY u.first_started_at
      LIMIT ?;
      ''',
      <Object?>[nowIso, limit],
    );
    return [
      for (final row in rows)
        WarmupCandidate(
          userId: row['user_id'] as int,
          anchorAt: DateTime.parse(
            (row['magnet_issued_at'] as String?) ?? (row['first_started_at'] as String),
          ),
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
