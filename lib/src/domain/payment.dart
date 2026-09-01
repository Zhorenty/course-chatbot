import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/storage_enum.dart';

enum PaymentRecordStatus { pending, succeeded, canceled }

extension PaymentRecordStatusX on PaymentRecordStatus {
  String get storageValue => switch (this) {
    PaymentRecordStatus.pending => 'pending',
    PaymentRecordStatus.succeeded => 'succeeded',
    PaymentRecordStatus.canceled => 'canceled',
  };

  static PaymentRecordStatus parse(
    String? raw, {
    PaymentRecordStatus fallback = PaymentRecordStatus.pending,
  }) {
    return parseStoredEnum(
      raw,
      values: PaymentRecordStatus.values,
      storage: (value) => value.storageValue,
      fallback: fallback,
    );
  }
}

final class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.provider,
    required this.kind,
    required this.amountKopecks,
    required this.status,
    required this.createdAt,
    this.providerPaymentId,
    this.confirmationUrl,
    this.succeededAt,
  });

  final int id;
  final int orderId;
  final String provider;
  final PaymentKind kind;
  final int amountKopecks;
  final PaymentRecordStatus status;
  final DateTime createdAt;
  final String? providerPaymentId;
  final String? confirmationUrl;
  final DateTime? succeededAt;

  PaymentRecord copyWith({
    String? provider,
    String? providerPaymentId,
    PaymentRecordStatus? status,
    String? confirmationUrl,
    DateTime? succeededAt,
  }) {
    return PaymentRecord(
      id: id,
      orderId: orderId,
      provider: provider ?? this.provider,
      providerPaymentId: providerPaymentId ?? this.providerPaymentId,
      kind: kind,
      amountKopecks: amountKopecks,
      status: status ?? this.status,
      createdAt: createdAt,
      confirmationUrl: confirmationUrl ?? this.confirmationUrl,
      succeededAt: succeededAt ?? this.succeededAt,
    );
  }
}

final class CheckoutSession {
  const CheckoutSession({
    required this.provider,
    required this.providerPaymentId,
    this.confirmationUrl,
    this.settled,
  });

  final String provider;
  final String providerPaymentId;
  final String? confirmationUrl;

  /// Set when create already returned a terminal status (e.g. Idempotence-Key
  /// replay of a payment that already succeeded).
  final PaymentCallback? settled;
}

final class PaymentCallback {
  const PaymentCallback({
    required this.provider,
    required this.providerPaymentId,
    required this.succeeded,
    this.kind,
    this.orderId,
    this.paymentDbId,
    this.userId,
    this.amountKopecks,
    this.charged = true,
  });

  final String provider;
  final String providerPaymentId;
  final bool succeeded;
  final PaymentKind? kind;
  final int? orderId;
  final int? paymentDbId;
  final int? userId;
  final int? amountKopecks;

  /// False when the kassa only approved an installment application.
  final bool charged;
}
