part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteAnalyticsStore on _SqliteEnrollmentStore implements FunnelAnalyticsRepository {
  @override
  FunnelAnalytics funnelAnalytics({required DateTime now, int? launchId}) {
    final nowUtc = now.toUtc();
    final d7 = nowUtc.subtract(const Duration(days: 7)).toIso8601String();
    final d30 = nowUtc.subtract(const Duration(days: 30)).toIso8601String();
    final launchParams = launchId == null ? const <Object?>[] : <Object?>[launchId];
    final enrollLaunch = launchId == null ? '' : ' AND e.launch_id = ?';
    final orderLaunch = launchId == null ? '' : ' AND o.launch_id = ?';
    final accessLaunch = launchId == null ? '' : ' AND a.launch_id = ?';

    int scalar(String sql, [List<Object?> params = const <Object?>[]]) {
      return _db.select(sql, params).first['c'] as int;
    }

    Map<String, int> grouped(String sql, [List<Object?> params = const <Object?>[]]) {
      final map = <String, int>{};
      for (final row in _db.select(sql, params)) {
        map[row['k']?.toString() ?? 'unknown'] = row['c'] as int;
      }
      return map;
    }

    return FunnelAnalytics(
      generatedAt: nowUtc,
      startedUsersTotal: scalar(
        'SELECT COUNT(*) AS c FROM user_enrollments e WHERE 1=1$enrollLaunch;',
        launchParams,
      ),
      funnelUsers: scalar('''
        SELECT COUNT(*) AS c FROM user_enrollments e
        WHERE e.funnel_phase NOT IN ('cancelled', 'paid', 'access_granted')$enrollLaunch;
        ''', launchParams),
      guideTaken: scalar(
        'SELECT COUNT(*) AS c FROM user_enrollments e WHERE e.magnet_issued_at IS NOT NULL$enrollLaunch;',
        launchParams,
      ),
      checkoutStarted: scalar('''
        SELECT COUNT(DISTINCT o.user_id) AS c FROM orders o WHERE 1=1$orderLaunch;
        ''', launchParams),
      paidUsers: scalar('''
        SELECT COUNT(*) AS c FROM user_enrollments e
        WHERE e.funnel_phase IN ('paid', 'access_granted')$enrollLaunch;
        ''', launchParams),
      startedLast7Days: scalar(
        'SELECT COUNT(*) AS c FROM user_enrollments e WHERE e.started_at >= ?$enrollLaunch;',
        <Object?>[d7, ...launchParams],
      ),
      startedLast30Days: scalar(
        'SELECT COUNT(*) AS c FROM user_enrollments e WHERE e.started_at >= ?$enrollLaunch;',
        <Object?>[d30, ...launchParams],
      ),
      paidLast7Days: scalar(
        '''
        SELECT COUNT(*) AS c FROM orders o
        WHERE o.status = 'paid' AND o.paid_at >= ?$orderLaunch;
        ''',
        <Object?>[d7, ...launchParams],
      ),
      paidLast30Days: scalar(
        '''
        SELECT COUNT(*) AS c FROM orders o
        WHERE o.status = 'paid' AND o.paid_at >= ?$orderLaunch;
        ''',
        <Object?>[d30, ...launchParams],
      ),
      phaseCounts: grouped('''
        SELECT e.funnel_phase AS k, COUNT(*) AS c
        FROM user_enrollments e
        WHERE 1=1$enrollLaunch
        GROUP BY e.funnel_phase;
        ''', launchParams),
      sourceCounts: grouped('''
        SELECT COALESCE(u.source, 'unknown') AS k, COUNT(*) AS c
        FROM user_enrollments e
        JOIN telegram_users u ON u.user_id = e.user_id
        WHERE 1=1$enrollLaunch
        GROUP BY COALESCE(u.source, 'unknown');
        ''', launchParams),
      sourceFunnels: _sourceFunnels(launchId: launchId),
      inviteIssuedNotJoined: scalar('''
        SELECT COUNT(*) AS c FROM channel_access a
        JOIN telegram_users u ON u.user_id = a.user_id
        WHERE a.invite_link IS NOT NULL AND a.invite_link != ''
          AND a.joined_at IS NULL AND a.revoked_at IS NULL
          AND u.bot_blocked = 0$accessLaunch;
        ''', launchParams),
      warmupOptOutCount: scalar(
        'SELECT COUNT(*) AS c FROM user_enrollments e WHERE e.warmup_opt_out = 1$enrollLaunch;',
        launchParams,
      ),
      botBlockedCount: scalar('''
        SELECT COUNT(*) AS c FROM telegram_users u
        WHERE u.bot_blocked = 1
          AND EXISTS (
            SELECT 1 FROM user_enrollments e
            WHERE e.user_id = u.user_id$enrollLaunch
          );
        ''', launchParams),
    );
  }

  List<SourceFunnelSlice> _sourceFunnels({int? launchId}) {
    final enrollLaunch = launchId == null ? '' : ' AND e.launch_id = ?';
    final orderLaunch = launchId == null ? '' : ' AND o.launch_id = ?';
    final params = launchId == null ? const <Object?>[] : <Object?>[launchId, launchId];
    final rows = _db.select('''
      SELECT COALESCE(u.source, 'unknown') AS k,
             COUNT(*) AS started,
             SUM(CASE WHEN e.magnet_issued_at IS NOT NULL THEN 1 ELSE 0 END) AS guide_taken,
             SUM(CASE WHEN EXISTS (
               SELECT 1 FROM orders o WHERE o.user_id = e.user_id$orderLaunch
             ) THEN 1 ELSE 0 END) AS checkout_started,
             SUM(CASE WHEN e.funnel_phase IN ('paid', 'access_granted') THEN 1 ELSE 0 END) AS paid
      FROM user_enrollments e
      JOIN telegram_users u ON u.user_id = e.user_id
      WHERE 1=1$enrollLaunch
      GROUP BY COALESCE(u.source, 'unknown')
      ORDER BY started DESC;
      ''', params);
    return [
      for (final row in rows)
        SourceFunnelSlice(
          source: row['k']?.toString() ?? 'unknown',
          started: row['started'] as int,
          guideTaken: row['guide_taken'] as int,
          checkoutStarted: row['checkout_started'] as int,
          paid: row['paid'] as int,
        ),
    ];
  }
}
