import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/domain/admin_payment_status.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late HandlerHarness harness;

  setUp(() async {
    harness = HandlerHarness();
    await harness.init();
  });

  tearDown(() => harness.dispose());

  test('full payment grants a one-time invite', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );
    final result = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.full,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
        amountKopecks: launch.priceFullKopecks,
      ),
      launch: launch,
    );

    expect(result.grantedAccess, isTrue);
    expect(result.inviteLink, isNotNull);
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.accessGranted);
    expect(harness.channel.created, isNotEmpty);
  });

  test('admin can switch a fully paid order to deposit', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );
    await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.full,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
        amountKopecks: launch.priceFullKopecks,
      ),
      launch: launch,
    );

    final switched = await harness.checkout.applyAdminPaymentStatus(
      userId: 42,
      launch: launch,
      target: AdminPaymentStatus.deposit,
    );
    expect(switched?.depositOnly, isTrue);
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.depositPaid);
    expect(harness.course.getOrder(order.id)?.status, OrderStatus.depositPaid);
    expect(harness.course.getOrder(order.id)?.accessGranted, isFalse);
    expect(harness.channel.revoked, isNotEmpty);
  });

  test('repeated succeeded callback does not create a second invite', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );
    final callback = PaymentCallback(
      provider: 'fake',
      providerPaymentId: payment.providerPaymentId!,
      succeeded: true,
      charged: true,
      kind: PaymentKind.full,
      orderId: order.id,
      paymentDbId: payment.id,
      userId: 42,
      amountKopecks: launch.priceFullKopecks,
    );
    await harness.checkout.applyCallback(callback, launch: launch);
    final second = await harness.checkout.applyCallback(callback, launch: launch);

    expect(second.alreadyApplied, isTrue);
    expect(harness.channel.created, hasLength(1));
  });

  test('deposit does not grant invite until remainder is paid', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.deposit,
    );
    final deposit = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.deposit,
      amountKopecks: launch.depositKopecks,
    );
    final afterDeposit = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: deposit.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.deposit,
        orderId: order.id,
        paymentDbId: deposit.id,
        userId: 42,
        amountKopecks: launch.depositKopecks,
      ),
      launch: launch,
    );

    expect(afterDeposit.depositOnly, isTrue);
    expect(afterDeposit.grantedAccess, isFalse);
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.depositPaid);
    expect(harness.channel.created, isEmpty);

    final remainder = await harness.checkout.createCheckout(
      order: afterDeposit.order,
      kind: PaymentKind.remainder,
      amountKopecks: afterDeposit.order.amountDueKopecks,
    );
    final afterFull = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: remainder.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.remainder,
        orderId: order.id,
        paymentDbId: remainder.id,
        userId: 42,
        amountKopecks: afterDeposit.order.amountDueKopecks,
      ),
      launch: launch,
    );

    expect(afterFull.grantedAccess, isTrue);
    expect(harness.channel.created, isNotEmpty);
  });

  test('installment application without charge does not grant access', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.installment,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.installment,
      amountKopecks: launch.priceFullKopecks,
    );
    final approved = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: false,
        kind: PaymentKind.installment,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
      ),
      launch: launch,
    );

    expect(approved.grantedAccess, isFalse);
    expect(harness.channel.created, isEmpty);
  });

  test('cancel revokes invite and marks the order cancelled', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );
    final paid = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.full,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
        amountKopecks: launch.priceFullKopecks,
      ),
      launch: launch,
    );
    expect(paid.inviteLink, isNotNull);

    await harness.checkout.cancel(order: paid.order, launch: launch);
    expect(harness.course.getOrder(order.id)?.status, OrderStatus.cancelled);
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.cancelled);
    expect(harness.channel.revoked, isNotEmpty);
  });

  test('cancelEnrollment without an order still marks cancelled and revokes access', () async {
    harness.course.ensureUser(userId: 7, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    await harness.checkout.cancelEnrollment(userId: 7, launch: launch);
    expect(harness.course.getUser(7)?.funnelPhase, FunnelPhase.cancelled);
    expect(harness.course.latestOrder(7), isNull);
    expect(harness.channel.banned, contains(7));
  });

  test('gateway failure cancels the pending payment instead of leaving it open', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    harness.gateway.createError = const PaymentUnavailableException('down');

    await expectLater(
      harness.checkout.createCheckout(
        order: order,
        kind: PaymentKind.full,
        amountKopecks: launch.priceFullKopecks,
      ),
      throwsA(isA<PaymentUnavailableException>()),
    );
    expect(harness.course.latestPendingPayment(order.id), isNull);
  });

  test('webhook during createPayment does not revert paid status', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    harness.gateway.onCreated = (session, paymentDbId) async {
      await harness.checkout.applyCallback(
        PaymentCallback(
          provider: 'fake',
          providerPaymentId: session.providerPaymentId,
          succeeded: true,
          charged: true,
          kind: PaymentKind.full,
          orderId: order.id,
          paymentDbId: paymentDbId,
          userId: 42,
          amountKopecks: launch.priceFullKopecks,
        ),
        launch: launch,
      );
    };

    final created = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );

    expect(harness.course.getOrder(order.id)?.status, OrderStatus.paid);
    expect(harness.course.getPayment(created.id)?.status, PaymentRecordStatus.succeeded);
    expect(
      harness.course.getUser(42)?.funnelPhase,
      anyOf(FunnelPhase.paid, FunnelPhase.accessGranted),
    );
  });

  test('second checkout after paid is refused', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );
    await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.full,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
        amountKopecks: launch.priceFullKopecks,
      ),
      launch: launch,
    );

    expect(
      () => harness.checkout.startOrReuseOrder(userId: 42, launch: launch, kind: PaymentKind.full),
      throwsA(
        isA<CheckoutBlockedException>().having(
          (error) => error.reason,
          'reason',
          CheckoutBlockReason.alreadyPaid,
        ),
      ),
    );
  });

  test('repeated checkout reuses the pending payment URL', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    final first = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );
    final second = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );

    expect(second.id, first.id);
    expect(harness.gateway.creates, 1);
  });

  test('failed invite is repaired on a repeated succeeded callback', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );
    harness.channel.createError = StateError('telegram down');
    final first = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.full,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
        amountKopecks: launch.priceFullKopecks,
      ),
      launch: launch,
    );
    expect(first.inviteLink, isNull);
    expect(harness.course.getOrder(order.id)?.accessGranted, isFalse);

    harness.channel.createError = null;
    final second = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.full,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
        amountKopecks: launch.priceFullKopecks,
      ),
      launch: launch,
    );
    expect(second.inviteLink, isNotNull);
    expect(second.repairedInvite, isTrue);
    expect(harness.channel.created, isNotEmpty);
  });

  test('deposit remainder is due 5 October 2026 Moscow', () {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 8, 27));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.deposit,
    );

    expect(order.dueAt, DateTime.utc(2026, 10, 5, 20, 59, 59));
    expect(launch.courseStartAt, DateTime.utc(2026, 10, 12));
  });

  test('zero amount checkout is refused', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    await expectLater(
      harness.checkout.createCheckout(order: order, kind: PaymentKind.full, amountKopecks: 0),
      throwsA(
        isA<CheckoutBlockedException>().having(
          (error) => error.reason,
          'reason',
          CheckoutBlockReason.priceNotSet,
        ),
      ),
    );
  });
}
