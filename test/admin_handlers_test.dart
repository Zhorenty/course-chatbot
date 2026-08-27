import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
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
    await harness.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '@lead'));
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

  test('harness without Sheets still uses upsertActiveLaunch', () {
    expect(harness.catalogSync, isNull);
    expect(harness.course.activeLaunch()?.code, 'launch-1');
    expect(harness.course.activeLaunch()?.priceFullKopecks, 1800000);
  });

  test('admin /start shows only admin reply buttons', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '/start'));
    final withKeyboard = harness.sender.messages.lastWhere((m) => m.replyMarkup != null);
    expect(withKeyboard.text, contains('Админка'));
    expect(withKeyboard.text, isNot(contains('Гайд по колористике')));
    final texts = _replyButtonTexts(withKeyboard.replyMarkup);
    expect(texts, contains(MessageTemplates.buttonAdminSearch));
    expect(texts, contains(MessageTemplates.buttonAdminBroadcast));
    expect(texts, contains(MessageTemplates.buttonAdminLinks));
    expect(texts, contains(MessageTemplates.buttonAdminSheets));
    expect(texts, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(texts, isNot(contains(MessageTemplates.buttonGuide)));
    expect(texts, isNot(contains(MessageTemplates.buttonMenu)));
  });

  test('admin sheets button pulls COURSES and writes ВОРОНКА', () async {
    final sheetsHarness = HandlerHarness();
    await sheetsHarness.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheetsHarness.dispose);

    final sheet = sheetsHarness.sheetsGateway!.valuesBySheetId[0]!;
    final priceCol = CoursesSheetParser.columnIndex(sheet, CoursesSheet.priceFullRub)!;
    final dataRow = CoursesSheetParser.headerRowIndex(sheet)! + 1;
    sheet[dataRow][priceCol] = 21000;

    await sheetsHarness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminSheets),
    );
    expect(sheetsHarness.sheetsWriter!.replaceDashboardCount, 1);
    expect(sheetsHarness.course.activeLaunch()?.priceFullKopecks, 2100000);
    expect(
      sheetsHarness.sender.messages.any(
        (m) =>
            m.text.contains('Набор в боте') &&
            m.text.contains('Воронка') &&
            m.text.contains('21000'),
      ),
      isTrue,
    );
  });

  test('admin sheets button says disabled when Sheets is off', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminSheets),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('не подключ')), isTrue);
  });

  test('admin Диплинки without Sheets still returns four starter links', () async {
    final named = HandlerHarness();
    await named.init(adminUserIds: const <int>{1}, botUsername: 'course_bot');
    addTearDown(named.dispose);

    await named.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminLinks),
    );
    final text = named.sender.messages.last.text;
    expect(text, contains('https://t.me/course_bot?start=ig_reels_guide'));
    expect(text, contains('https://t.me/course_bot?start=threads_guide'));
    expect(text, contains('https://t.me/course_bot?start=tg_announce'));
    expect(text, contains('https://t.me/course_bot?start=direct_course'));
    expect(text, contains(LinksSheet.tabTitle));
  });

  test('admin /links with Sheets seeds ССЫЛКИ then lists the same URLs', () async {
    final sheetsHarness = HandlerHarness();
    await sheetsHarness.init(
      adminUserIds: const <int>{1},
      enableSheets: true,
      botUsername: 'course_bot',
    );
    addTearDown(sheetsHarness.dispose);

    await sheetsHarness.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '/links'));
    final text = sheetsHarness.sender.messages.last.text;
    expect(text, contains('?start=ig_reels_guide'));
    final tab = sheetsHarness.sheetsGateway!.sheets.firstWhere(
      (sheet) => sheet.title == LinksSheet.tabTitle,
    );
    final sheet = sheetsHarness.sheetsGateway!.valuesBySheetId[tab.sheetId]!;
    expect(sheet.any((row) => row.contains('https://t.me/course_bot?start=direct_course')), isTrue);
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
    harness.course.ensureUser(userId: 12, now: DateTime.utc(2026, 1, 1));
    harness.course.setFunnelPhase(userId: 12, phase: FunnelPhase.depositPaid);

    final ids = harness.course.listBroadcastUserIds(segment: BroadcastSegment.guideNotPaid);
    expect(ids, contains(10));
    expect(ids, isNot(contains(11)));
    expect(ids, isNot(contains(12)));
  });
}

List<String> _replyButtonTexts(Map<String, Object?>? markup) {
  final rows = markup?['keyboard'] as List<dynamic>? ?? const <dynamic>[];
  return <String>[
    for (final row in rows)
      for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
  ];
}
