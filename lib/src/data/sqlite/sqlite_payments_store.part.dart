part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqlitePaymentsStore on _SqliteCourseStore {
  PaymentRecord insertPayment({
    required int orderId,
    required String provider,
    required PaymentKind kind,
    required int amountKopecks,
    required DateTime now,
    String? providerPaymentId,
    String? confirmationUrl,
    PaymentRecordStatus status = PaymentRecordStatus.pending,
  }) {
    _db.execute(
      '''
      INSERT INTO payments (
        order_id, provider, provider_payment_id, kind, amount_kopecks,
        status, confirmation_url, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      <Object?>[
        orderId,
        provider,
        providerPaymentId,
        kind.storageValue,
        amountKopecks,
        status.storageValue,
        confirmationUrl,
        now.toUtc().toIso8601String(),
      ],
    );
    final id = _db.select('SELECT last_insert_rowid() AS id;').first['id'] as int;
    return getPayment(id)!;
  }

  PaymentRecord? getPayment(int paymentId) {
    final rows = _db.select('SELECT * FROM payments WHERE id = ?;', <Object?>[paymentId]);
    if (rows.isEmpty) {
      return null;
    }
    return mapPayment(rows.first);
  }

  PaymentRecord? findPaymentByProviderId({
    required String provider,
    required String providerPaymentId,
  }) {
    final rows = _db.select(
      '''
      SELECT * FROM payments
      WHERE provider = ? AND provider_payment_id = ?
      ORDER BY id DESC LIMIT 1;
      ''',
      <Object?>[provider, providerPaymentId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return mapPayment(rows.first);
  }

  PaymentRecord? latestPendingPayment(int orderId) {
    final rows = _db.select(
      '''
      SELECT * FROM payments
      WHERE order_id = ? AND status = 'pending'
      ORDER BY id DESC LIMIT 1;
      ''',
      <Object?>[orderId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return mapPayment(rows.first);
  }

  void updatePayment(PaymentRecord payment) {
    _db.execute(
      '''
      UPDATE payments SET
        provider_payment_id = ?, status = ?, confirmation_url = ?, succeeded_at = ?
      WHERE id = ?;
      ''',
      <Object?>[
        payment.providerPaymentId,
        payment.status.storageValue,
        payment.confirmationUrl,
        payment.succeededAt?.toUtc().toIso8601String(),
        payment.id,
      ],
    );
  }
}
