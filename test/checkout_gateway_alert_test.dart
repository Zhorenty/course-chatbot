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
      harness.course.ensureUser(
        userId: 42,
        username: 'masha',
        firstName: 'Маша',
        now: DateTime.utc(2026, 1, 1),
      );
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
      expect(alertPort.alerts.single.username, 'masha');
      expect(alertPort.alerts.single.firstName, 'Маша');
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

  test('a second person hitting the same outage still alerts admins', () async {
    harness = HandlerHarness();
    final alertPort = FakePaymentGatewayAlertPort();
    await harness.init(adminUserIds: <int>{1}, alertPort: alertPort);
    final launch = harness.course.activeLaunch()!;
    harness.gateway.createError = const PaymentUnavailableException('leadpay down');

    for (final userId in <int>[42, 43]) {
      harness.course.ensureUser(userId: userId, now: DateTime.utc(2026, 1, 1));
      final order = harness.checkout.startOrReuseOrder(
        userId: userId,
        launch: launch,
        kind: PaymentKind.full,
      );
      await expectLater(
        harness.checkout.createCheckout(
          order: order,
          kind: PaymentKind.full,
          amountKopecks: launch.priceFullKopecks,
        ),
        throwsA(isA<PaymentUnavailableException>()),
      );
    }

    expect(alertPort.alerts.map((alert) => alert.userId), <int>[42, 43]);
  });

  test('empty confirmation URL is treated as a kassa error and alerts admins', () async {
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
    harness.gateway.url = '';

    await expectLater(
      harness.checkout.createCheckout(
        order: order,
        kind: PaymentKind.full,
        amountKopecks: launch.priceFullKopecks,
      ),
      throwsA(isA<PaymentUnavailableException>()),
    );
    expect(alertPort.alerts, hasLength(1));
    expect(alertPort.alerts.single.reason, contains('empty confirmation URL'));
  });

  test('PaymentAlertNotifier names the person who hit the kassa error', () async {
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
      username: 'masha',
      firstName: 'Маша',
    );

    expect(harness.sender.messages, hasLength(2));
    final chatIds = harness.sender.messages.map((message) => message.chatId).toSet();
    expect(chatIds, <int>{1, 999});
    for (final message in harness.sender.messages) {
      expect(message.text, contains('Ошибка онлайн-оплаты'));
      expect(message.text, contains('leadpay'));
      expect(message.text, contains('42'));
      expect(message.text, contains('@masha'));
      expect(message.text, contains('Маша'));
      expect(message.text, contains('полная оплата'));
      expect(message.parseMode, 'HTML');
      expect(message.replyMarkup.toString(), contains('${MessageTemplates.cbAdminCard}42'));
    }
  });

  test('pay button outage writes the person to the admin chat', () async {
    harness = HandlerHarness();
    final notifier = PaymentAlertNotifier(
      sender: harness.sender,
      templates: MessageTemplates(),
      notificationChatIds: <int>{1},
    );
    await harness.init(adminUserIds: <int>{1}, alertPort: notifier);
    harness.gateway.createError = const PaymentUnavailableException('leadpay down');

    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start', username: 'masha'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbEnroll,
        username: 'masha',
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '2',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbPayFull,
        username: 'masha',
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '3',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbToggleOffer,
        username: 'masha',
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '4',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGoToPay,
        username: 'masha',
      ),
    );

    expect(
      harness.sender.messages.any(
        (message) => message.chatId == 42 && message.text.contains('неполадки'),
      ),
      isTrue,
    );
    final admin = harness.sender.messages.where((message) => message.chatId == 1);
    expect(admin, isNotEmpty);
    expect(admin.first.text, contains('@masha'));
    expect(admin.first.text, contains('42'));
    expect(admin.first.text, contains('Test'));
    expect(admin.first.replyMarkup.toString(), contains('${MessageTemplates.cbAdminCard}42'));
  });
}
