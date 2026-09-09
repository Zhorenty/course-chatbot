import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/enrollment.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/jobs/abandoned_payment_job.dart';
import 'package:course_chatbot/src/jobs/remainder_reminder_job.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  const quietHours = QuietHours(timezoneOffsetHours: 3, fromHour: 10, toHour: 21);
  final templates = MessageTemplates();

  test('A: guide → RSVP → promo full pay → one-time channel invite', () async {
    final clock = _Clock(DateTime.utc(2026, 10, 4, 12));
    final harness = await _clientHarness(clock);
    addTearDown(harness.dispose);
    final client = _Client(harness);

    await client.tap('/start ig_reels_guide');
    expect(harness.course.getUser(42)?.source, 'ig_reels_guide');
    expect(_phase(harness, 42), FunnelPhase.lead);
    expect(harness.sender.messages.any((m) => m.text.contains('Гайд')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isTrue);
    expect(_inlineButtonTexts(harness.sender.messages.first.replyMarkup), isEmpty);
    expect(
      _replyButtonTexts(harness.sender.messages.last.replyMarkup),
      containsAll(<String>[
        MessageTemplates.buttonGuide,
        MessageTemplates.buttonEnroll,
        MessageTemplates.buttonHelp,
      ]),
    );

    await client.tap(MessageTemplates.buttonGuide);
    expect(harness.sender.documents, contains('file-guide'));
    expect(harness.sender.messages.any((m) => m.text.contains('Эфир')), isTrue);
    expect(
      harness.sender.messages
          .where((m) => m.text.contains('Эфир'))
          .every((m) => !_inlineButtonTexts(m.replyMarkup).contains(MessageTemplates.buttonOptOut)),
      isTrue,
    );
    expect(
      _inlineButtonTexts(
        harness.sender.messages.firstWhere((m) => m.text.contains('Эфир')).replyMarkup,
      ),
      contains(MessageTemplates.buttonRsvp),
    );
    expect(harness.course.hasWarmupBeenSent(userId: 42, stepKey: 'warmup_0'), isTrue);
    expect(_phase(harness, 42), FunnelPhase.warming);

    await client.press(MessageTemplates.cbRsvp);
    expect(_enrollment(harness, 42)?.webinarRsvp, isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('Ты в списке')), isTrue);
    expect(
      harness.sender.messages.any((m) => m.text.contains('https://example.com/live')),
      isFalse,
    );

    harness.sender.messages.clear();
    await client.tap(MessageTemplates.buttonEnroll);
    final preSales = harness.sender.messages.last;
    expect(preSales.text, contains('Касса откроется'));
    expect(_payButtonTexts(preSales.replyMarkup), isEmpty);
    expect(_enrollment(harness, 42)?.enrollIntentAt, isNotNull);
    expect(_phase(harness, 42), FunnelPhase.warming);

    clock.value = DateTime.utc(2026, 10, 6, 12);
    harness.sender.messages.clear();
    await client.tap(MessageTemplates.buttonEnroll);
    final promo = harness.sender.messages.last;
    expect(promo.text, contains('15000 ₽'));
    expect(promo.text, contains('спеццена'));
    expect(
      _inlineButtonTexts(promo.replyMarkup),
      containsAll(<String>[
        templates.payFullButtonLabel(LaunchPrices.promoKopecks),
        templates.payDepositButtonLabel(500000),
      ]),
    );
    expect(_inlineButtonTexts(promo.replyMarkup), isNot(contains('Рассрочка')));

    await client.payWithConsent(MessageTemplates.cbPayFull);
    expect(harness.gateway.creates, 1);
    expect(harness.sender.messages.any((m) => m.text.contains('Ссылка на оплату')), isTrue);
    expect(_phase(harness, 42), FunnelPhase.checkout);
    final launch = harness.course.activeLaunch()!;
    final order = harness.course.latestOrder(42, launchId: launch.id)!;
    expect(order.status, OrderStatus.awaitingPayment);
    expect(order.priceFullKopecks, LaunchPrices.promoKopecks);
    final pending = harness.course.latestPendingPayment(order.id)!;

    final paid = await client.settle(
      kind: PaymentKind.full,
      amountKopecks: LaunchPrices.promoKopecks,
    );
    expect(paid.grantedAccess, isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('Оплата прошла')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('https://t.me/+invite')), isTrue);
    expect(harness.channel.created, hasLength(1));
    expect(_phase(harness, 42), FunnelPhase.accessGranted);
    final paidMenu = _replyButtonTexts(
      harness.sender.messages
          .lastWhere((m) => _replyButtonTexts(m.replyMarkup).isNotEmpty)
          .replyMarkup,
    );
    expect(paidMenu, contains(MessageTemplates.buttonCourseStatus));
    expect(paidMenu, contains(MessageTemplates.buttonGuide));
    expect(paidMenu, contains(MessageTemplates.buttonHelp));
    expect(paidMenu, isNot(contains(MessageTemplates.buttonEnroll)));

    final repeat = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: pending.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.full,
        orderId: order.id,
        paymentDbId: pending.id,
        userId: 42,
        amountKopecks: LaunchPrices.promoKopecks,
      ),
      launch: launch,
    );
    expect(repeat.alreadyApplied, isTrue);
    expect(harness.channel.created, hasLength(1));
    expect(harness.channel.revoked, isEmpty);

    await harness.handlers.handle(<String, dynamic>{
      'update_id': 9,
      'chat_member': <String, dynamic>{
        'chat': <String, dynamic>{'id': launch.channelId, 'type': 'channel'},
        'new_chat_member': <String, dynamic>{
          'status': 'member',
          'user': <String, dynamic>{'id': 42},
        },
      },
    });
    expect(harness.course.accessFor(userId: 42, launchId: launch.id)?.joinedAt, isNotNull);

    harness.sender.messages.clear();
    await client.tap('/start');
    expect(harness.course.getUser(42)?.source, 'ig_reels_guide');
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isFalse);
    expect(harness.sender.messages.any((m) => m.text.contains('ты уже внутри')), isTrue);
    expect(harness.channel.created, hasLength(1));
    expect(harness.channel.revoked, isEmpty);

    harness.sender.messages.clear();
    await client.tap('/start direct_course');
    expect(harness.course.getUser(42)?.source, 'ig_reels_guide');
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isFalse);
    expect(harness.channel.created, hasLength(1));

    harness.sender.messages.clear();
    await client.press(MessageTemplates.cbNewInvite);
    expect(harness.channel.created, hasLength(1));
    expect(harness.channel.revoked, isEmpty);
    expect(harness.sender.messages.any((m) => m.text.contains('админ')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('https://t.me/+')), isFalse);

    harness.sender.messages.clear();
    await client.tap(MessageTemplates.buttonCourseStatus);
    final status = harness.sender.messages.single;
    expect(status.text, contains('закрыта'));
    expect(status.text, contains('15000 ₽'));
    expect(status.text, contains('12.10.2026'));
    expect(status.text, contains('ты уже внутри'));
  });

  test('B: deposit does not open the channel until remainder is paid', () async {
    final clock = _Clock(DateTime.utc(2026, 10, 4, 12));
    final harness = await _clientHarness(clock);
    addTearDown(harness.dispose);
    final client = _Client(harness);
    await _reachPromoCheckout(client, clock);

    await client.payWithConsent(MessageTemplates.cbPayDeposit);
    expect(harness.gateway.creates, 1);
    final launch = harness.course.activeLaunch()!;
    final order = harness.course.latestOrder(42, launchId: launch.id)!;
    final afterDeposit = await client.settle(
      kind: PaymentKind.deposit,
      amountKopecks: launch.depositKopecks,
    );
    expect(afterDeposit.depositOnly, isTrue);
    expect(afterDeposit.grantedAccess, isFalse);
    expect(harness.channel.created, isEmpty);
    expect(_phase(harness, 42), FunnelPhase.depositPaid);
    expect(harness.sender.messages.any((m) => m.text.contains('Предоплата дошла')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('10000 ₽')), isTrue);
    expect(
      _replyButtonTexts(
        harness.sender.messages
            .lastWhere((m) => _replyButtonTexts(m.replyMarkup).isNotEmpty)
            .replyMarkup,
      ),
      contains(MessageTemplates.buttonCourseStatus),
    );

    harness.sender.messages.clear();
    await client.tap(MessageTemplates.buttonCourseStatus);
    final status = harness.sender.messages.single;
    expect(status.text, contains('предоплата'));
    expect(status.text, contains('5000 ₽'));
    expect(status.text, contains('10000 ₽'));
    expect(status.text, contains('ещё не начался'));
    expect(_inlineButtonTexts(status.replyMarkup), contains(MessageTemplates.buttonPayRemainder));

    await client.tap(MessageTemplates.buttonHelp);
    await client.press(MessageTemplates.cbOptOut);
    expect(harness.course.getUser(42)?.warmupOptOut, isTrue);
    expect(_enrollment(harness, 42)?.warmupOptOut, isTrue);

    final due = harness.course.getOrder(order.id)!;
    harness.course.updateOrder(due.copyWith(dueAt: DateTime.utc(2026, 10, 1)));
    harness.sender.messages.clear();
    await RemainderReminderJob(
      course: harness.course,
      dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      nowProvider: () => DateTime.utc(2026, 10, 8, 12),
    ).run();
    expect(harness.sender.messages.any((m) => m.text.contains('Доплата')), isTrue);

    harness.sender.messages.clear();
    await client.press('${MessageTemplates.cbPayRemainder}${order.id}');
    await client.completeOffer();
    expect(harness.gateway.creates, 2);
    final afterFull = await client.settle(
      kind: PaymentKind.remainder,
      amountKopecks: afterDeposit.order.amountDueKopecks,
    );
    expect(afterFull.grantedAccess, isTrue);
    expect(harness.channel.created, isNotEmpty);
    expect(_phase(harness, 42), FunnelPhase.accessGranted);
  });

  test('D: abandoned checkout reminds once, then continue pay reuses the URL', () async {
    final clock = _Clock(DateTime.utc(2026, 10, 4, 12));
    final harness = await _clientHarness(clock);
    addTearDown(harness.dispose);
    final client = _Client(harness);
    await _reachPromoCheckout(client, clock);
    await client.payWithConsent(MessageTemplates.cbPayFull);
    expect(harness.gateway.creates, 1);
    final launch = harness.course.activeLaunch()!;
    final order = harness.course.latestOrder(42, launchId: launch.id)!;
    final pending = harness.course.latestPendingPayment(order.id)!;
    expect(pending.confirmationUrl, 'https://pay.example/checkout');

    harness.db.execute('UPDATE orders SET checkout_started_at = ? WHERE id = ?;', <Object?>[
      '2026-10-06T00:00:00.000Z',
      order.id,
    ]);
    final dedupe = JobDedupeRepository(databaseHandle: harness.handle)..initSchema();
    harness.sender.messages.clear();
    await AbandonedPaymentJob(
      course: harness.course,
      dedupe: dedupe,
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      firstDelay: const Duration(hours: 1),
      secondDelay: const Duration(hours: 24),
      nowProvider: () => DateTime.utc(2026, 10, 6, 6),
    ).run();
    expect(harness.sender.messages, isEmpty);

    final dayJob = AbandonedPaymentJob(
      course: harness.course,
      dedupe: dedupe,
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      firstDelay: const Duration(hours: 1),
      secondDelay: const Duration(hours: 24),
      nowProvider: () => DateTime.utc(2026, 10, 6, 12),
    );
    await dayJob.run();
    expect(
      harness.sender.messages.where((m) => m.text.contains('Оформление началось')),
      hasLength(1),
    );
    await dayJob.run();
    expect(
      harness.sender.messages.where((m) => m.text.contains('Оформление началось')),
      hasLength(1),
    );

    harness.sender.messages.clear();
    await client.press('${MessageTemplates.cbContinuePay}${order.id}');
    expect(harness.gateway.creates, 1);
    expect(harness.sender.messages.any((m) => m.text.contains('Ссылка на оплату')), isTrue);
    expect(
      harness.sender.messages.any(
        (m) => '${m.replyMarkup}'.contains('https://pay.example/checkout'),
      ),
      isTrue,
    );

    await client.settle(kind: PaymentKind.full, amountKopecks: LaunchPrices.promoKopecks);
    harness.sender.messages.clear();
    await dayJob.run();
    expect(harness.sender.messages.any((m) => m.text.contains('Оформление началось')), isFalse);
  });

  test('E: course deep link opens the card and keeps checkout closed before the webinar', () async {
    final clock = _Clock(DateTime.utc(2026, 10, 4, 12));
    final harness = await _clientHarness(clock);
    addTearDown(harness.dispose);
    final client = _Client(harness, userId: 7);

    await client.tap('/start tg_announce');
    expect(harness.course.getUser(7)?.source, 'tg_announce');
    expect(harness.sender.messages.any((m) => m.text.contains('Запуск')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isFalse);
    expect(_inlineButtonTexts(harness.sender.messages.first.replyMarkup), isEmpty);

    harness.sender.messages.clear();
    await client.tap('/start');
    expect(harness.sender.messages.any((m) => m.text.contains('Запуск')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isFalse);

    harness.sender.messages.clear();
    await client.tap(MessageTemplates.buttonEnroll);
    expect(harness.sender.messages.last.text, contains('Касса откроется'));
    expect(_payButtonTexts(harness.sender.messages.last.replyMarkup), isEmpty);
    expect(_phase(harness, 7), FunnelPhase.lead);

    harness.sender.messages.clear();
    await client.tap(MessageTemplates.buttonGuide);
    expect(harness.sender.documents, contains('file-guide'));
    expect(harness.sender.messages.any((m) => m.text.contains('Эфир')), isTrue);
    expect(_phase(harness, 7), FunnelPhase.warming);

    harness.sender.messages.clear();
    await client.tap('/start');
    expect(harness.course.getUser(7)?.source, 'tg_announce');
    expect(
      harness.sender.messages.any((m) => m.text.contains('Продолжаем с того же места')),
      isTrue,
    );
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isFalse);
  });
}

Future<HandlerHarness> _clientHarness(_Clock clock) async {
  final harness = HandlerHarness();
  await harness.init(
    priceFullKopecks: LaunchPrices.fullKopecks,
    pricePromoKopecks: LaunchPrices.promoKopecks,
    depositKopecks: 500000,
    webinarAt: DateTime.utc(2026, 10, 5, 16),
    webinarUrl: 'https://example.com/live',
    courseStartAt: DateTime.utc(2026, 10, 12),
    nowProvider: clock.now,
  );
  return harness;
}

Future<void> _reachPromoCheckout(_Client client, _Clock clock) async {
  await client.tap('/start ig_reels_guide');
  await client.tap(MessageTemplates.buttonGuide);
  await client.press(MessageTemplates.cbRsvp);
  clock.value = DateTime.utc(2026, 10, 6, 12);
  await client.tap(MessageTemplates.buttonEnroll);
}

FunnelPhase? _phase(HandlerHarness harness, int userId) {
  final user = harness.course.getUser(userId);
  if (user == null) {
    return null;
  }
  return harness.funnel.phaseOf(user);
}

UserEnrollment? _enrollment(HandlerHarness harness, int userId) {
  final launch = harness.course.activeLaunch();
  if (launch == null) {
    return null;
  }
  return harness.course.getEnrollment(userId: userId, launchId: launch.id);
}

List<String> _replyButtonTexts(Map<String, Object?>? markup) {
  final rows = markup?['keyboard'] as List<dynamic>? ?? const <dynamic>[];
  return <String>[
    for (final row in rows)
      for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
  ];
}

List<String> _inlineButtonTexts(Map<String, Object?>? markup) {
  final rows = markup?['inline_keyboard'] as List<dynamic>? ?? const <dynamic>[];
  return <String>[
    for (final row in rows)
      for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
  ];
}

List<String> _payButtonTexts(Map<String, Object?>? markup) {
  return _inlineButtonTexts(markup)
      .where(
        (text) =>
            text.startsWith(MessageTemplates.buttonPayFull) ||
            text.startsWith(MessageTemplates.buttonPayDeposit),
      )
      .toList();
}

final class _Clock {
  _Clock(this.value);

  DateTime value;

  DateTime now() => value;
}

final class _Client {
  _Client(this.harness, {this.userId = 42});

  final HandlerHarness harness;
  final int userId;
  int _callbacks = 0;

  Future<void> tap(String text) {
    return harness.handlers.handle(
      privateMessageUpdate(chatId: userId, userId: userId, text: text),
    );
  }

  Future<void> press(String data) {
    _callbacks += 1;
    return harness.handlers.handle(
      privateCallbackUpdate(callbackId: '$_callbacks', chatId: userId, userId: userId, data: data),
    );
  }

  Future<void> payWithConsent(String payCallback) async {
    await press(payCallback);
    await completeOffer();
  }

  Future<void> completeOffer() async {
    final createsBefore = harness.gateway.creates;
    expect(harness.sender.messages.last.text, contains('Публичной оферты'));
    await press(MessageTemplates.cbGoToPay);
    expect(harness.gateway.creates, createsBefore);
    expect(
      harness.sender.callbackAnswers.any(
        (answer) => answer.showAlert && (answer.text?.contains('галочку') ?? false),
      ),
      isTrue,
    );
    await press(MessageTemplates.cbToggleOffer);
    expect(harness.sender.markupEdits, isNotEmpty);
    expect(harness.sender.markupEdits.last.replyMarkup.toString(), contains('☑️'));
    await press(MessageTemplates.cbGoToPay);
    expect(harness.gateway.creates, createsBefore + 1);
    expect(harness.sender.messages.any((m) => m.text.contains('Ссылка на оплату')), isTrue);
  }

  Future<PaymentApplyResult> settle({
    required PaymentKind kind,
    required int amountKopecks,
    bool succeeded = true,
    bool charged = true,
    String? providerPaymentId,
  }) async {
    final launch = harness.course.activeLaunch()!;
    final order = harness.course.latestOrder(userId, launchId: launch.id)!;
    final payment = harness.course.latestPendingPayment(order.id);
    final result = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: providerPaymentId ?? payment!.providerPaymentId!,
        succeeded: succeeded,
        charged: charged,
        kind: kind,
        orderId: order.id,
        paymentDbId: payment?.id,
        userId: userId,
        amountKopecks: amountKopecks,
      ),
      launch: launch,
    );
    await harness.handlers.notifyPaymentResult(result);
    return result;
  }
}
