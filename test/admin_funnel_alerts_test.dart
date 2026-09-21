import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  test('guide delivery does not ping admins per person', () async {
    final harness = HandlerHarness();
    final alerts = FakePaymentGatewayAlertPort();
    await harness.init(adminUserIds: const <int>{1}, alertPort: alerts);
    addTearDown(harness.dispose);

    await harness.handlers.handle(
      privateMessageUpdate(
        chatId: 42,
        userId: 42,
        text: '/start ig_reels_guide',
        username: 'masha',
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGuide,
      ),
    );
    expect(alerts.funnelDayDigests, isEmpty);
    expect(harness.course.getUser(42)?.magnetIssuedAt, isNotNull);
  });

  test('missing guide alerts the missing-file path, not a digest', () async {
    final harness = HandlerHarness();
    final alerts = FakePaymentGatewayAlertPort();
    await harness.init(adminUserIds: const <int>{1}, alertPort: alerts, leadMagnetFileId: '');
    addTearDown(harness.dispose);

    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGuide,
      ),
    );
    expect(alerts.funnelDayDigests, isEmpty);
    expect(alerts.guideMissing, <int>[42]);
  });

  test('webinar RSVP does not ping admins per person', () async {
    final harness = HandlerHarness();
    final alerts = FakePaymentGatewayAlertPort();
    await harness.init(
      adminUserIds: const <int>{1},
      alertPort: alerts,
      webinarAt: DateTime.utc(2026, 10, 5, 16),
      nowProvider: () => DateTime.utc(2026, 9, 8, 12),
    );
    addTearDown(harness.dispose);

    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start ig_reels_guide'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGuide,
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(callbackId: '2', chatId: 42, userId: 42, data: MessageTemplates.cbRsvp),
    );
    expect(alerts.funnelDayDigests, isEmpty);
    expect(
      harness.course
          .getEnrollment(userId: 42, launchId: harness.course.activeLaunch()!.id)
          ?.webinarRsvp,
      isTrue,
    );
  });

  test('full payment with invite notifies admins once; deposit does not', () async {
    final harness = HandlerHarness();
    final alerts = FakePaymentGatewayAlertPort();
    await harness.init(adminUserIds: const <int>{1}, alertPort: alerts);
    addTearDown(harness.dispose);
    harness.course.ensureUser(
      userId: 42,
      username: 'masha',
      firstName: 'Маша',
      now: DateTime.utc(2026, 1, 1),
    );
    final launch = harness.course.activeLaunch()!;

    final depositOrder = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.deposit,
    );
    final depositPayment = (await harness.checkout.createCheckout(
      order: depositOrder,
      kind: PaymentKind.deposit,
      amountKopecks: launch.depositKopecks,
    )).payment;
    final deposit = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: depositPayment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.deposit,
        orderId: depositOrder.id,
        paymentDbId: depositPayment.id,
        userId: 42,
        amountKopecks: launch.depositKopecks,
      ),
      launch: launch,
    );
    await harness.handlers.notifyPaymentResult(deposit);
    expect(deposit.depositOnly, isTrue);
    expect(alerts.paidWithInvite, isEmpty);

    final remainderPayment = (await harness.checkout.createCheckout(
      order: deposit.order,
      kind: PaymentKind.remainder,
      amountKopecks: deposit.order.amountDueKopecks,
    )).payment;
    final remainder = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: remainderPayment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.remainder,
        orderId: depositOrder.id,
        paymentDbId: remainderPayment.id,
        userId: 42,
        amountKopecks: deposit.order.amountDueKopecks,
      ),
      launch: launch,
    );
    await harness.handlers.notifyPaymentResult(remainder);
    expect(remainder.grantedAccess, isTrue);
    expect(remainder.inviteLink, isNotNull);
    expect(alerts.paidWithInvite, hasLength(1));
    expect(alerts.paidWithInvite.single.id, remainder.order.id);

    final repeat = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: remainderPayment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.remainder,
        orderId: depositOrder.id,
        paymentDbId: remainderPayment.id,
        userId: 42,
        amountKopecks: deposit.order.amountDueKopecks,
      ),
      launch: launch,
    );
    await harness.handlers.notifyPaymentResult(repeat);
    expect(repeat.alreadyApplied, isTrue);
    expect(alerts.paidWithInvite, hasLength(1));
  });
}
