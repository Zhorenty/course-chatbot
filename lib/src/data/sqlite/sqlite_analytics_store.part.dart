part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteAnalyticsStore on _SqliteCourseStore implements FunnelAnalyticsRepository {
  @override
  FunnelAnalytics funnelAnalytics({required DateTime now}) {
    final nowUtc = now.toUtc();
    final d7 = nowUtc.subtract(const Duration(days: 7)).toIso8601String();
    final d30 = nowUtc.subtract(const Duration(days: 30)).toIso8601String();
    int scalar(String sql, [List<Object?> params = const <Object?>[]]) {
      return _db.select(sql, params).first['c'] as int;
    }

    Map<String, int> grouped(String sql) {
      final map = <String, int>{};
      for (final row in _db.select(sql)) {
        map[row['k']?.toString() ?? 'unknown'] = row['c'] as int;
      }
      return map;
    }

    return FunnelAnalytics(
      generatedAt: nowUtc,
      startedUsersTotal: scalar('SELECT COUNT(*) AS c FROM telegram_users;'),
      funnelUsers: scalar(
        '''
        SELECT COUNT(*) AS c FROM telegram_users
        WHERE funnel_phase NOT IN ('cancelled');
        ''',
      ),
      guideTaken: scalar(
        'SELECT COUNT(*) AS c FROM telegram_users WHERE magnet_issued_at IS NOT NULL;',
      ),
      checkoutStarted: scalar(
        '''
        SELECT COUNT(DISTINCT user_id) AS c FROM orders;
        ''',
      ),
      paidUsers: scalar(
        '''
        SELECT COUNT(*) AS c FROM telegram_users
        WHERE funnel_phase IN ('paid', 'access_granted');
        ''',
      ),
      startedLast7Days: scalar(
        'SELECT COUNT(*) AS c FROM telegram_users WHERE first_started_at >= ?;',
        <Object?>[d7],
      ),
      startedLast30Days: scalar(
        'SELECT COUNT(*) AS c FROM telegram_users WHERE first_started_at >= ?;',
        <Object?>[d30],
      ),
      paidLast7Days: scalar(
        '''
        SELECT COUNT(*) AS c FROM orders
        WHERE status = 'paid' AND paid_at >= ?;
        ''',
        <Object?>[d7],
      ),
      paidLast30Days: scalar(
        '''
        SELECT COUNT(*) AS c FROM orders
        WHERE status = 'paid' AND paid_at >= ?;
        ''',
        <Object?>[d30],
      ),
      phaseCounts: grouped(
        'SELECT funnel_phase AS k, COUNT(*) AS c FROM telegram_users GROUP BY funnel_phase;',
      ),
      sourceCounts: grouped(
        '''
        SELECT COALESCE(source, 'unknown') AS k, COUNT(*) AS c
        FROM telegram_users GROUP BY COALESCE(source, 'unknown');
        ''',
      ),
    );
  }
}
