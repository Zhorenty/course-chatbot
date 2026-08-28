import 'package:course_chatbot/src/domain/storage_enum.dart';

enum OrderStatus { checkoutStarted, awaitingPayment, depositPaid, paid, cancelled }

extension OrderStatusX on OrderStatus {
  String get storageValue => switch (this) {
    OrderStatus.checkoutStarted => 'checkout_started',
    OrderStatus.awaitingPayment => 'awaiting_payment',
    OrderStatus.depositPaid => 'deposit_paid',
    OrderStatus.paid => 'paid',
    OrderStatus.cancelled => 'cancelled',
  };

  bool get isOpen =>
      this == OrderStatus.checkoutStarted ||
      this == OrderStatus.awaitingPayment ||
      this == OrderStatus.depositPaid;

  bool get isFullyPaid => this == OrderStatus.paid;

  static OrderStatus parse(String? raw, {OrderStatus fallback = OrderStatus.checkoutStarted}) {
    return parseStoredEnum(
      raw,
      values: OrderStatus.values,
      storage: (value) => value.storageValue,
      fallback: fallback,
    );
  }
}

/// Waves for deposit remainder reminders. Each wave fires once.
enum RemainderWave { beforeDue, onDueDay, overdue }

enum PaymentKind { full, deposit, remainder, installment }

extension PaymentKindX on PaymentKind {
  String get storageValue => switch (this) {
    PaymentKind.full => 'full',
    PaymentKind.deposit => 'deposit',
    PaymentKind.remainder => 'remainder',
    PaymentKind.installment => 'installment',
  };

  /// Full payment or an actual installment charge grants channel access.
  bool get grantsAccessOnSuccess =>
      this == PaymentKind.full || this == PaymentKind.remainder || this == PaymentKind.installment;

  static PaymentKind parse(String? raw, {PaymentKind fallback = PaymentKind.full}) {
    return parseStoredEnum(
      raw,
      values: PaymentKind.values,
      storage: (value) => value.storageValue,
      fallback: fallback,
    );
  }
}

final class CourseOrder {
  const CourseOrder({
    required this.id,
    required this.userId,
    required this.launchId,
    required this.status,
    required this.kind,
    required this.priceFullKopecks,
    required this.amountPaidKopecks,
    required this.amountDueKopecks,
    required this.checkoutStartedAt,
    this.dueAt,
    this.paidAt,
    this.cancelledAt,
    this.accessGranted = false,
  });

  final int id;
  final int userId;
  final int launchId;
  final OrderStatus status;
  final PaymentKind kind;
  final int priceFullKopecks;
  final int amountPaidKopecks;
  final int amountDueKopecks;
  final DateTime checkoutStartedAt;
  final DateTime? dueAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final bool accessGranted;

  bool get hasRemainder => amountDueKopecks > 0 && status == OrderStatus.depositPaid;

  CourseOrder copyWith({
    OrderStatus? status,
    PaymentKind? kind,
    int? amountPaidKopecks,
    int? amountDueKopecks,
    DateTime? dueAt,
    DateTime? paidAt,
    DateTime? cancelledAt,
    bool? accessGranted,
  }) {
    return CourseOrder(
      id: id,
      userId: userId,
      launchId: launchId,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      priceFullKopecks: priceFullKopecks,
      amountPaidKopecks: amountPaidKopecks ?? this.amountPaidKopecks,
      amountDueKopecks: amountDueKopecks ?? this.amountDueKopecks,
      checkoutStartedAt: checkoutStartedAt,
      dueAt: dueAt ?? this.dueAt,
      paidAt: paidAt ?? this.paidAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      accessGranted: accessGranted ?? this.accessGranted,
    );
  }
}
