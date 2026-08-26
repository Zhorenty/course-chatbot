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
    expect(harness.sender.messages.any((m) => m.text.contains('Запись на курс')), isTrue);

    harness.sender.messages.clear();
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 8, userId: 8, text: '/start threads_guide'),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('Гайд по колористике')), isTrue);
  });

  test('guide delivery sends PDF and immediate warmup_0', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start ig_reels_guide'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
          callbackId: '1', chatId: 42, userId: 42, data: MessageTemplates.cbGuide),
    );

    expect(harness.sender.documents, contains('file-guide'));
    expect(harness.sender.messages.any((m) => m.text.contains('Первое касание')), isTrue);
    expect(harness.course.hasWarmupBeenSent(userId: 42, stepKey: 'warmup_0'), isTrue);
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.warming);
  });

  test('opt-out stops selling drip copy but enroll remains available', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
          callbackId: '1', chatId: 42, userId: 42, data: MessageTemplates.cbGuide),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
          callbackId: '2', chatId: 42, userId: 42, data: MessageTemplates.cbOptOut),
    );

    expect(harness.course.getUser(42)?.warmupOptOut, isTrue);
    harness.sender.messages.clear();
    await harness.handlers.handle(
      privateCallbackUpdate(
          callbackId: '3', chatId: 42, userId: 42, data: MessageTemplates.cbEnroll),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('Запись на курс')), isTrue);
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
}
