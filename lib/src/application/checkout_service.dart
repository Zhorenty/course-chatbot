import 'dart:async';

import 'package:course_chatbot/src/application/access_service.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:l/l.dart';

final class PaymentApplyResult {
  const PaymentApplyResult({
    required this.order,
    required this.alreadyApplied,
    this.inviteLink,
    this.grantedAccess = false,
    this.depositOnly = false,
    this.repairedInvite = false,
  });

  final CourseOrder order;
  final bool alreadyApplied;
  final String? inviteLink;
  final bool grantedAccess;
  final bool depositOnly;
  final bool repairedInvite;
}

enum CheckoutBlockReason { alreadyPaid, priceNotSet }

final class CheckoutBlockedException implements Exception {
  const CheckoutBlockedException(this.reason);

  final CheckoutBlockReason reason;

  @override
  String toString() => 'CheckoutBlockedException: $reason';
}

abstract interface class PaymentResultNotifier {
  Future<void> notifyPaymentResult(PaymentApplyResult result);
}

final class CheckoutService {
  CheckoutService({
    required CourseRepository course,
    required PaymentGateway gateway,
    required AccessService access,
    DateTime Function()? nowProvider,
    String? returnUrl,
  })  : _course = course,
        _gateway = gateway,
        _access = access,
        _nowProvider = nowProvider ?? DateTime.now,
        _returnUrl = returnUrl;

  final CourseRepository _course;
  final PaymentGateway _gateway;
  final AccessService _access;
  final DateTime Function() _nowProvider;
  final String? _returnUrl;

  CourseOrder startOrReuseOrder({
    required int userId,
    required Launch launch,
    required PaymentKind kind,
  }) {
    _assertCanStartCharge(userId: userId, kind: kind);
    final existing = _course.latestOpenOrder(userId);
    if (existing != null && existing.launchId == launch.id && _shouldReuse(existing, kind)) {
      return existing;
    }
    final now = _nowProvider();
    final dueAt = kind == PaymentKind.deposit ? launch.resolveDepositDueAt(now) : null;
    final amountDue = switch (kind) {
      PaymentKind.deposit => launch.priceFullKopecks,
      PaymentKind.remainder => existing?.amountDueKopecks ?? launch.priceFullKopecks,
      PaymentKind.full || PaymentKind.installment => launch.priceFullKopecks,
    };
    return _course.createOrder(
      userId: userId,
      launchId: launch.id,
      kind: kind,
      priceFullKopecks: launch.priceFullKopecks,
      amountDueKopecks: amountDue,
      now: now,
      dueAt: dueAt,
    );
  }

  void _assertCanStartCharge({required int userId, required PaymentKind kind}) {
    final user = _course.getUser(userId);
    if (user != null && user.funnelPhase.isPaidOrAccess && kind != PaymentKind.remainder) {
      throw const CheckoutBlockedException(CheckoutBlockReason.alreadyPaid);
    }
    final latest = _course.latestOrder(userId);
    if (latest != null && latest.status.isFullyPaid && kind != PaymentKind.remainder) {
      throw const CheckoutBlockedException(CheckoutBlockReason.alreadyPaid);
    }
  }

  /// Reuse an open checkout for the same charge type.
  /// A deposit-paid order is only reused for remainder; a new full charge
  /// starts a separate order so the remainder path stays intact.
  bool _shouldReuse(CourseOrder existing, PaymentKind kind) {
    final remainderOnDeposit =
        kind == PaymentKind.remainder && existing.status == OrderStatus.depositPaid;
    final newChargeOnOpenCheckout =
        kind != PaymentKind.remainder && existing.status != OrderStatus.depositPaid;
    return remainderOnDeposit || newChargeOnOpenCheckout;
  }

  Future<PaymentRecord> createCheckout({
    required CourseOrder order,
    required PaymentKind kind,
    required int amountKopecks,
  }) async {
    if (amountKopecks <= 0) {
      throw const CheckoutBlockedException(CheckoutBlockReason.priceNotSet);
    }
    _assertCanStartCharge(userId: order.userId, kind: kind);
    final reusable = _course.latestPendingPayment(order.id, kind: kind);
    if (reusable != null &&
        reusable.confirmationUrl != null &&
        reusable.confirmationUrl!.isNotEmpty) {
      return reusable;
    }
    if (reusable != null) {
      _course.updatePayment(reusable.copyWith(status: PaymentRecordStatus.canceled));
    }

    final now = _nowProvider();
    var payment = _course.insertPayment(
      orderId: order.id,
      provider: _gateway.providerId,
      kind: kind,
      amountKopecks: amountKopecks,
      now: now,
    );
    late final CheckoutSession session;
    try {
      session = await _gateway
          .createPayment(
            order: order,
            kind: kind,
            amountKopecks: amountKopecks,
            paymentDbId: payment.id,
            returnUrl: _returnUrl,
          )
          .timeout(PaymentGateway.requestTimeout);
    } on PaymentUnavailableException {
      _course.updatePayment(payment.copyWith(status: PaymentRecordStatus.canceled));
      rethrow;
    } on Object catch (error, stackTrace) {
      _course.updatePayment(payment.copyWith(status: PaymentRecordStatus.canceled));
      Error.throwWithStackTrace(
        PaymentUnavailableException('Checkout failed: $error'),
        stackTrace,
      );
    }

    final currentPayment = _course.getPayment(payment.id) ?? payment;
    if (currentPayment.status == PaymentRecordStatus.succeeded) {
      return currentPayment;
    }
    final currentOrder = _course.getOrder(order.id) ?? order;
    if (currentOrder.status.isFullyPaid || currentOrder.accessGranted) {
      return currentPayment.copyWith(
        provider: session.provider,
        providerPaymentId: session.providerPaymentId,
        confirmationUrl: session.confirmationUrl,
      );
    }

    payment = currentPayment.copyWith(
      provider: session.provider,
      providerPaymentId: session.providerPaymentId,
      confirmationUrl: session.confirmationUrl,
    );
    _course.updatePayment(payment);
    if (!currentOrder.status.isFullyPaid && currentOrder.status != OrderStatus.depositPaid) {
      _course.updateOrder(
        currentOrder.copyWith(
          status: OrderStatus.awaitingPayment,
          kind: kind,
        ),
      );
    }
    final user = _course.getUser(order.userId);
    if (user == null || !user.funnelPhase.excludeSellingDrip) {
      _course.setFunnelPhase(userId: order.userId, phase: FunnelPhase.checkout);
    }
    return payment;
  }

  int amountFor(Launch launch, CourseOrder order, PaymentKind kind) {
    switch (kind) {
      case PaymentKind.full:
      case PaymentKind.installment:
        return launch.priceFullKopecks;
      case PaymentKind.deposit:
        return launch.depositKopecks;
      case PaymentKind.remainder:
        return order.amountDueKopecks;
    }
  }

  Future<PaymentApplyResult> applyCallback(
    PaymentCallback callback, {
    required Launch launch,
  }) async {
    final result = _course.transaction(() => _applyLocked(callback, launch: launch));
    if (result.depositOnly) {
      return result;
    }
    final paid = result.grantedAccess || result.order.status.isFullyPaid;
    if (!paid) {
      return result;
    }
    final hadAccess = result.order.accessGranted;
    try {
      final link = await _access.issueInvite(
        userId: result.order.userId,
        orderId: result.order.id,
        launch: launch,
      );
      final repaired = result.alreadyApplied && !hadAccess && link != null;
      return PaymentApplyResult(
        order: _course.getOrder(result.order.id) ?? result.order,
        alreadyApplied: result.alreadyApplied && !repaired,
        inviteLink: link,
        grantedAccess: true,
        repairedInvite: repaired,
      );
    } on Object catch (error, stackTrace) {
      l.w('Paid but invite failed for order ${result.order.id}: $error', stackTrace);
      return result;
    }
  }

  Future<PaymentApplyResult> applyManualPaid({
    required CourseOrder order,
    required Launch launch,
    required PaymentKind kind,
    required int amountKopecks,
  }) {
    return applyCallback(
      PaymentCallback(
        provider: 'manual',
        providerPaymentId: 'manual-override-${order.id}-${_nowProvider().microsecondsSinceEpoch}',
        succeeded: true,
        charged: true,
        kind: kind,
        orderId: order.id,
        userId: order.userId,
        amountKopecks: amountKopecks,
      ),
      launch: launch,
    );
  }

  PaymentApplyResult _applyLocked(
    PaymentCallback callback, {
    required Launch launch,
  }) {
    if (callback.providerPaymentId.isNotEmpty) {
      final existing = _course.findPaymentByProviderId(
        provider: callback.provider,
        providerPaymentId: callback.providerPaymentId,
      );
      if (existing != null && existing.status == PaymentRecordStatus.succeeded) {
        final order = _course.getOrder(existing.orderId)!;
        return PaymentApplyResult(
          order: order,
          alreadyApplied: true,
          grantedAccess: order.accessGranted || order.status.isFullyPaid,
        );
      }
    }
    if (!callback.succeeded || !callback.charged) {
      final orderId = callback.orderId;
      if (orderId != null) {
        final order = _course.getOrder(orderId);
        if (order != null) {
          return PaymentApplyResult(order: order, alreadyApplied: false);
        }
      }
      throw StateError('Payment callback has no matching order.');
    }

    var payment = callback.paymentDbId != null
        ? _course.getPayment(callback.paymentDbId!)
        : _course.findPaymentByProviderId(
            provider: callback.provider,
            providerPaymentId: callback.providerPaymentId,
          );
    var order = payment != null
        ? _course.getOrder(payment.orderId)
        : (callback.orderId != null ? _course.getOrder(callback.orderId!) : null);
    order ??= callback.userId != null ? _course.latestOpenOrder(callback.userId!) : null;
    if (order == null) {
      throw StateError('Payment callback has no matching order.');
    }
    if (callback.userId != null && callback.userId != order.userId) {
      throw StateError('Payment callback user does not match the order.');
    }
    final kind = callback.kind ?? payment?.kind ?? order.kind;
    final amount = callback.amountKopecks ?? payment?.amountKopecks ?? order.amountDueKopecks;
    final now = _nowProvider();
    payment ??= _course.insertPayment(
      orderId: order.id,
      provider: callback.provider,
      kind: kind,
      amountKopecks: amount,
      now: now,
      providerPaymentId: callback.providerPaymentId,
    );
    _course.updatePayment(
      payment.copyWith(
        providerPaymentId: callback.providerPaymentId,
        status: PaymentRecordStatus.succeeded,
        succeededAt: now,
      ),
    );

    if (order.status.isFullyPaid || order.accessGranted) {
      return PaymentApplyResult(
        order: order,
        alreadyApplied: true,
        grantedAccess: order.accessGranted || order.status.isFullyPaid,
      );
    }

    final paidTotal = order.amountPaidKopecks + amount;
    final due = (order.priceFullKopecks - paidTotal).clamp(0, order.priceFullKopecks);
    final grantsAccess = kind.grantsAccessOnSuccess || due <= 0;
    final nextStatus = grantsAccess
        ? OrderStatus.paid
        : (kind == PaymentKind.deposit ? OrderStatus.depositPaid : OrderStatus.awaitingPayment);
    final updated = order.copyWith(
      status: nextStatus,
      kind: kind,
      amountPaidKopecks: paidTotal,
      amountDueKopecks: due,
      dueAt: kind == PaymentKind.deposit
          ? (order.dueAt ?? launch.resolveDepositDueAt(now))
          : order.dueAt,
      paidAt: grantsAccess ? now : order.paidAt,
    );
    _course.updateOrder(updated);
    if (grantsAccess) {
      _course.setFunnelPhase(userId: order.userId, phase: FunnelPhase.paid);
    } else if (nextStatus == OrderStatus.depositPaid) {
      _course.setFunnelPhase(userId: order.userId, phase: FunnelPhase.depositPaid);
    }
    return PaymentApplyResult(
      order: updated,
      alreadyApplied: false,
      grantedAccess: grantsAccess,
      depositOnly: nextStatus == OrderStatus.depositPaid,
    );
  }

  Future<void> cancel({
    required CourseOrder order,
    required Launch launch,
  }) async {
    final now = _nowProvider();
    _course.updateOrder(
      order.copyWith(
        status: OrderStatus.cancelled,
        cancelledAt: now,
        accessGranted: false,
      ),
    );
    _course.setFunnelPhase(userId: order.userId, phase: FunnelPhase.cancelled);
    await _access.revoke(userId: order.userId, launch: launch);
  }
}
