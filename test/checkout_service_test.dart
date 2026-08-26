import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
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
    await harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
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

  test('repeated succeeded callback does not create a second invite', () async {
    await harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
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
    await harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
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
    await harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
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
}
