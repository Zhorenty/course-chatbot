part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteOrdersStore on _SqliteCourseStore {
  CourseOrder createOrder({
    required int userId,
    required int launchId,
    required PaymentKind kind,
    required int priceFullKopecks,
    required int amountDueKopecks,
    required DateTime now,
    DateTime? dueAt,
  }) {
    _db.execute(
      '''
      INSERT INTO orders (
        user_id, launch_id, status, kind, price_full_kopecks, amount_paid_kopecks,
        amount_due_kopecks, due_at, checkout_started_at, access_granted
      ) VALUES (?, ?, ?, ?, ?, 0, ?, ?, ?, 0);
      ''',
      <Object?>[
        userId,
        launchId,
        OrderStatus.checkoutStarted.storageValue,
        kind.storageValue,
        priceFullKopecks,
        amountDueKopecks,
        dueAt?.toUtc().toIso8601String(),
        now.toUtc().toIso8601String(),
      ],
    );
    final id = _db.select('SELECT last_insert_rowid() AS id;').first['id'] as int;
    return getOrder(id)!;
  }

  CourseOrder? getOrder(int orderId) {
    final rows = _db.select('SELECT * FROM orders WHERE id = ?;', <Object?>[orderId]);
    if (rows.isEmpty) {
      return null;
    }
    return mapOrder(rows.first);
  }

  CourseOrder? latestOpenOrder(int userId) {
    final rows = _db.select(
      '''
      SELECT * FROM orders
      WHERE user_id = ? AND status IN ('checkout_started', 'awaiting_payment', 'deposit_paid')
      ORDER BY id DESC LIMIT 1;
      ''',
      <Object?>[userId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return mapOrder(rows.first);
  }

  CourseOrder? latestOrder(int userId) {
    final rows = _db.select(
      'SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC LIMIT 1;',
      <Object?>[userId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return mapOrder(rows.first);
  }

  List<CourseOrder> listOrdersForUser(int userId, {int limit = 10}) {
    final rows = _db.select(
      'SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC LIMIT ?;',
      <Object?>[userId, limit],
    );
    return rows.map(mapOrder).toList(growable: false);
  }

  void updateOrder(CourseOrder order) {
    _db.execute(
      '''
      UPDATE orders SET
        status = ?, kind = ?, amount_paid_kopecks = ?, amount_due_kopecks = ?,
        due_at = ?, paid_at = ?, cancelled_at = ?, access_granted = ?
      WHERE id = ?;
      ''',
      <Object?>[
        order.status.storageValue,
        order.kind.storageValue,
        order.amountPaidKopecks,
        order.amountDueKopecks,
        order.dueAt?.toUtc().toIso8601String(),
        order.paidAt?.toUtc().toIso8601String(),
        order.cancelledAt?.toUtc().toIso8601String(),
        order.accessGranted ? 1 : 0,
        order.id,
      ],
    );
  }

  List<CourseOrder> listAbandonedCheckout({
    required DateTime now,
    required Duration minAge,
    int limit = 100,
  }) {
    final threshold = now.toUtc().subtract(minAge).toIso8601String();
    final rows = _db.select(
      '''
      SELECT o.*
      FROM orders o
      JOIN telegram_users u ON u.user_id = o.user_id
      WHERE o.status = 'awaiting_payment'
        AND o.checkout_started_at <= ?
        AND u.bot_blocked = 0
      ORDER BY o.id
      LIMIT ?;
      ''',
      <Object?>[threshold, limit],
    );
    return rows.map(mapOrder).toList(growable: false);
  }

  List<CourseOrder> listRemainderDue({
    required DateTime now,
    int limit = 100,
  }) {
    final nowIso = now.toUtc().toIso8601String();
    final rows = _db.select(
      '''
      SELECT o.*
      FROM orders o
      JOIN telegram_users u ON u.user_id = o.user_id
      WHERE o.status = 'deposit_paid'
        AND o.due_at IS NOT NULL
        AND o.due_at <= ?
        AND u.bot_blocked = 0
      ORDER BY o.due_at
      LIMIT ?;
      ''',
      <Object?>[nowIso, limit],
    );
    return rows.map(mapOrder).toList(growable: false);
  }
}
