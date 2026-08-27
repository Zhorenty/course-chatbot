import 'dart:io';

import 'package:course_chatbot/src/bot/handlers/private/interaction_whitelist.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/messages/html_escaper.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  test('escapeHtml encodes markup', () {
    expect(escapeHtml('<b>a&b</b>'), '&lt;b&gt;a&amp;b&lt;/b&gt;');
  });

  late HandlerHarness harness;

  setUp(() async {
    harness = HandlerHarness();
    await harness.init();
  });

  tearDown(() => harness.dispose());

  test('/start without payload offers the guide and keeps source empty', () async {
    final handled = await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start'),
    );

    expect(handled, isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('Гайд')), isTrue);
    expect(harness.course.getUser(42)?.source, isNull);
  });

  test('first deep link payload is stored and later /start does not overwrite it', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start ig_reels_guide'),
    );
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start direct_course'),
    );

    expect(harness.course.getUser(42)?.source, 'ig_reels_guide');
  });

  test('guide payload vs course payload open different first screens', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 7, userId: 7, text: '/start tg_announce'),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('Поток с')), isTrue);

    harness.sender.messages.clear();
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 8, userId: 8, text: '/start threads_guide'),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isTrue);
  });

  test('guide delivery sends PDF and immediate warmup_0', () async {
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

    expect(harness.sender.documents, contains('file-guide'));
    expect(harness.sender.messages.any((m) => m.text.contains('алфавит')), isTrue);
    expect(harness.course.hasWarmupBeenSent(userId: 42, stepKey: 'warmup_0'), isTrue);
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.warming);
  });

  test('opt-out stops selling drip copy but enroll remains available', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGuide,
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '2',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbOptOut,
      ),
    );

    expect(harness.course.getUser(42)?.warmupOptOut, isTrue);
    harness.sender.messages.clear();
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '3',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbEnroll,
      ),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('Запись на поток')), isTrue);
  });

  test('group messages are ignored', () async {
    final handled = await harness.handlers.handle(<String, dynamic>{
      'message': <String, dynamic>{
        'chat': <String, dynamic>{'id': -100, 'type': 'supergroup'},
        'text': '/start',
      },
    });
    expect(handled, isFalse);
    expect(harness.sender.messages, isEmpty);
  });

  test('guide delivery does not downgrade a paid user', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    harness.course.setFunnelPhase(userId: 42, phase: FunnelPhase.paid);
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGuide,
      ),
    );
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.paid);
    expect(harness.course.getUser(42)?.magnetIssuedAt, isNotNull);
  });

  test('bundled PDF is uploaded when Telegram file_id is empty', () async {
    final extra = HandlerHarness();
    addTearDown(extra.dispose);
    final pdf = File('${Directory.systemTemp.path}/course-guide-test.pdf')
      ..writeAsBytesSync(const <int>[37, 80, 68, 70]);
    addTearDown(() {
      if (pdf.existsSync()) {
        pdf.deleteSync();
      }
    });
    await extra.init(leadMagnetFileId: null, leadMagnetPath: pdf.path);

    await extra.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    await extra.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGuide,
      ),
    );

    expect(extra.sender.documents, contains(pdf.path));
    expect(extra.course.activeLaunch()?.leadMagnetFileId, 'cached-guide');
  });

  test('enroll shows full price, deposit and 5 October due date', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbEnroll,
      ),
    );

    final enroll = harness.sender.messages.last.text;
    expect(enroll, contains('18000 ₽'));
    expect(enroll, contains('5000 ₽'));
    expect(enroll, contains('05.10.2026'));
    expect(enroll, contains('12.10.2026'));
    expect(enroll, isNot(contains('t.me/+')));
  });

  test('checkout is blocked until both offer checkboxes are accepted', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbEnroll,
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '2',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbPayFull,
      ),
    );

    expect(harness.sender.messages.last.text, contains('Публичной оферты'));
    expect(harness.gateway.creates, 0);

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '3',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGoToPay,
      ),
    );
    expect(harness.gateway.creates, 0);
    expect(
      harness.sender.callbackAnswers.any(
        (answer) => answer.showAlert && (answer.text?.contains('галочки') ?? false),
      ),
      isTrue,
    );

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '4',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbToggleOffer,
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '5',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbTogglePersonalData,
      ),
    );
    expect(harness.sender.markupEdits, isNotEmpty);

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '6',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGoToPay,
      ),
    );
    expect(harness.gateway.creates, 1);
    expect(harness.sender.messages.any((m) => m.text.contains('Ссылка на оплату')), isTrue);
  });

  test('production whitelist admits only listed usernames', () {
    const gate = InteractionWhitelist.production;
    expect(gate.allows('zhorenty'), isTrue);
    expect(gate.allows('@Dvor_Support'), isTrue);
    expect(gate.allows('stranger'), isFalse);
    expect(gate.allows(null), isFalse);
  });

  test('non-whitelisted users get the in-development reply and are not stored', () async {
    final gated = HandlerHarness();
    addTearDown(gated.dispose);
    await gated.init(interactionWhitelist: InteractionWhitelist.production);

    final handled = await gated.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start', username: 'stranger'),
    );

    expect(handled, isTrue);
    expect(gated.sender.messages, hasLength(1));
    expect(gated.sender.messages.single.text, contains('в разработке'));
    expect(gated.course.getUser(42), isNull);

    gated.sender.messages.clear();
    await gated.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGuide,
        username: 'random_user',
      ),
    );
    expect(gated.sender.documents, isEmpty);
    expect(gated.sender.messages.single.text, contains('в разработке'));
    expect(gated.course.getUser(42), isNull);
  });

  test('whitelisted username can start the funnel', () async {
    final gated = HandlerHarness();
    addTearDown(gated.dispose);
    await gated.init(interactionWhitelist: InteractionWhitelist.production);

    await gated.handlers.handle(
      privateMessageUpdate(chatId: 7, userId: 7, text: '/start', username: 'zhorenty'),
    );
    expect(gated.sender.messages.any((m) => m.text.contains('Гайд')), isTrue);
    expect(gated.course.getUser(7), isNotNull);

    gated.sender.messages.clear();
    await gated.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 8,
        userId: 8,
        data: MessageTemplates.cbGuide,
        username: 'dvor_support',
      ),
    );
    expect(gated.sender.documents, isNotEmpty);
    expect(gated.course.getUser(8), isNotNull);
  });
}
