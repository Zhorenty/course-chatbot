import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  test('first guide delivery notifies admins, a repeat request does not', () async {
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
    expect(alerts.guideIssued, hasLength(1));
    expect(alerts.guideIssued.single.userId, 42);
    expect(alerts.guideIssued.single.username, 'masha');

    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: MessageTemplates.buttonGuide),
    );
    expect(alerts.guideIssued, hasLength(1));
  });

  test('missing guide alerts the missing-file path, not guide issued', () async {
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
    expect(alerts.guideIssued, isEmpty);
    expect(alerts.guideMissing, <int>[42]);
  });

  test('first webinar RSVP notifies admins, a second tap does not', () async {
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
    expect(alerts.webinarRsvp, isEmpty);

    await harness.handlers.handle(
      privateCallbackUpdate(callbackId: '2', chatId: 42, userId: 42, data: MessageTemplates.cbRsvp),
    );
    expect(alerts.webinarRsvp, hasLength(1));
    expect(alerts.webinarRsvp.single.userId, 42);

    await harness.handlers.handle(
      privateCallbackUpdate(callbackId: '3', chatId: 42, userId: 42, data: MessageTemplates.cbRsvp),
    );
    expect(alerts.webinarRsvp, hasLength(1));
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
