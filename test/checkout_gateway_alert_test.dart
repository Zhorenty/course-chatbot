import 'package:course_chatbot/src/application/payment_alert_notifier.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  late HandlerHarness harness;

  tearDown(() => harness.dispose());

  test(
    'gateway outage still surfaces PaymentUnavailableException and notifies admins once',
    () async {
      harness = HandlerHarness();
      final alertPort = FakePaymentGatewayAlertPort();
      await harness.init(adminUserIds: <int>{1}, alertPort: alertPort);
      harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
      final launch = harness.course.activeLaunch()!;
      final order = harness.checkout.startOrReuseOrder(
        userId: 42,
        launch: launch,
        kind: PaymentKind.full,
      );
      harness.gateway.createError = const PaymentUnavailableException('leadpay down');

      // Same signal the handler shows the user (payManualFallback) still fires.
      await expectLater(
        harness.checkout.createCheckout(
          order: order,
          kind: PaymentKind.full,
          amountKopecks: launch.priceFullKopecks,
        ),
        throwsA(isA<PaymentUnavailableException>()),
      );

      expect(alertPort.alerts, hasLength(1));
      expect(alertPort.alerts.single.userId, 42);
      expect(alertPort.alerts.single.launchId, launch.id);
      expect(alertPort.alerts.single.provider, 'fake');
      expect(alertPort.alerts.single.reason, contains('leadpay down'));
    },
  );

  test(
    'isAvailable() == false is treated the same as a thrown PaymentUnavailableException',
    () async {
      harness = HandlerHarness();
      final alertPort = FakePaymentGatewayAlertPort();
      await harness.init(adminUserIds: <int>{1}, alertPort: alertPort);
      harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
      final launch = harness.course.activeLaunch()!;
      final order = harness.checkout.startOrReuseOrder(
        userId: 42,
        launch: launch,
        kind: PaymentKind.full,
      );
      harness.gateway.available = false;

      await expectLater(
        harness.checkout.createCheckout(
          order: order,
          kind: PaymentKind.full,
          amountKopecks: launch.priceFullKopecks,
        ),
        throwsA(isA<PaymentUnavailableException>()),
      );
      expect(
        harness.gateway.creates,
        0,
        reason: 'createPayment must not run when isAvailable() is false',
      );
      expect(alertPort.alerts, hasLength(1));
    },
  );

  test('repeated retries within the cooldown window notify admins only once', () async {
    harness = HandlerHarness();
    final alertPort = FakePaymentGatewayAlertPort();
    var now = DateTime.utc(2026, 1, 1);
    await harness.init(
      adminUserIds: <int>{1},
      alertPort: alertPort,
      gatewayAlertCooldown: const Duration(minutes: 15),
      nowProvider: () => now,
    );
    harness.course.ensureUser(userId: 42, now: now);
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    harness.gateway.createError = const PaymentUnavailableException('flapping');

    for (var i = 0; i < 3; i++) {
      await expectLater(
        harness.checkout.createCheckout(
          order: order,
          kind: PaymentKind.full,
          amountKopecks: launch.priceFullKopecks,
        ),
        throwsA(isA<PaymentUnavailableException>()),
      );
      now = now.add(const Duration(minutes: 1));
    }

    expect(alertPort.alerts, hasLength(1));

    // Once the cooldown has elapsed, a fresh outage is worth a new alert.
    now = now.add(const Duration(minutes: 20));
    await expectLater(
      harness.checkout.createCheckout(
        order: order,
        kind: PaymentKind.full,
        amountKopecks: launch.priceFullKopecks,
      ),
      throwsA(isA<PaymentUnavailableException>()),
    );
    expect(alertPort.alerts, hasLength(2));
  });

  test('PaymentAlertNotifier pushes every admin chat with a short HTML alert', () async {
    harness = HandlerHarness();
    await harness.init(adminUserIds: <int>{1});
    final templates = MessageTemplates();
    final notifier = PaymentAlertNotifier(
      sender: harness.sender,
      templates: templates,
      notificationChatIds: <int>{1, 999},
    );
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;

    await notifier.notifyGatewayUnavailable(
      userId: 42,
      launchId: launch.id,
      kind: PaymentKind.full,
      provider: 'leadpay',
      reason: 'token missing',
    );

    expect(harness.sender.messages, hasLength(2));
    final chatIds = harness.sender.messages.map((message) => message.chatId).toSet();
    expect(chatIds, <int>{1, 999});
    for (final message in harness.sender.messages) {
      expect(message.text, contains('leadpay'));
      expect(message.text, contains('42'));
      expect(message.parseMode, 'HTML');
    }
  });
}
