import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  late HandlerHarness harness;

  setUp(() async {
    harness = HandlerHarness();
    await harness.init(adminUserIds: const <int>{1});
  });

  tearDown(() => harness.dispose());

  test('admin can search a card and mark paid with invite', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 99, userId: 99, text: '/start ig_reels_guide', username: 'lead'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'g',
        chatId: 99,
        userId: 99,
        data: MessageTemplates.cbGuide,
      ),
    );

    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminSearch),
    );
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: '@lead'),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('Карточка')), isTrue);

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'p',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbAdminPaid}99',
      ),
    );
    expect(harness.course.getUser(99)?.funnelPhase.hasAccess, isTrue);
    expect(harness.channel.created, isNotEmpty);
  });

  test('broadcast targets guide-not-paid segment', () async {
    harness.course.ensureUser(userId: 10, now: DateTime.utc(2026, 1, 1));
    harness.course.setFunnelPhase(
      userId: 10,
      phase: FunnelPhase.warming,
      magnetIssuedAt: DateTime.utc(2026, 1, 1),
    );
    harness.course.ensureUser(userId: 11, now: DateTime.utc(2026, 1, 1));
    harness.course.setFunnelPhase(userId: 11, phase: FunnelPhase.accessGranted);

    final ids = harness.course.listBroadcastUserIds(segment: BroadcastSegment.guideNotPaid);
    expect(ids, contains(10));
    expect(ids, isNot(contains(11)));
  });
}
