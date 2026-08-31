import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/admin_payment_status.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:course_chatbot/src/domain/order.dart';
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
        data: '${MessageTemplates.cbAdminStatusMenu}99',
      ),
    );
    final picker = harness.sender.messages.last;
    expect(picker.text, contains('не оплачено'));
    expect(
      _inlineButtonTexts(picker.replyMarkup),
      contains(MessageTemplates.buttonAdminStatusPaid),
    );
    expect(
      _inlineButtonTexts(picker.replyMarkup),
      isNot(contains(MessageTemplates.buttonAdminStatusUnpaid)),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'py',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.adminStatusSetData(AdminPaymentStatus.paid, 99),
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
    expect(texts, contains(MessageTemplates.buttonAdminAddUser));
    expect(texts, contains(MessageTemplates.buttonAdminBroadcast));
    expect(texts, contains(MessageTemplates.buttonAdminLinks));
    expect(texts, contains(MessageTemplates.buttonAdminSheets));
    expect(texts, contains(MessageTemplates.buttonAdminClearFunnel));
    expect(texts, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(texts, isNot(contains(MessageTemplates.buttonGuide)));
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
    expect(sheetsHarness.sender.deletedMessages, hasLength(1));
    expect(sheetsHarness.sender.messages.any((m) => m.text.contains('Обновляю таблицу')), isFalse);
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
    expect(harness.sender.deletedMessages, isEmpty);
  });

  test('admin can clear funnel people and keep the launch', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 99, userId: 99, text: '/start ig_reels_guide', username: 'lead'),
    );
    expect(harness.course.getUser(99), isNotNull);
    final launchCode = harness.course.activeLaunch()?.code;

    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminClearFunnel),
    );
    expect(harness.sender.messages.last.text, contains('Сотру людей'));
    expect(harness.course.getUser(99), isNotNull);

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cf',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.cbAdminClearFunnelConfirm,
      ),
    );
    expect(harness.sender.messages.last.text, contains('Воронка очищена'));
    expect(harness.course.getUser(99), isNull);
    expect(harness.course.activeLaunch()?.code, launchCode);
  });

  test('admin abort keeps funnel people', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 99, userId: 99, text: '/start ig_reels_guide'),
    );
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminClearFunnel),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cfn',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.cbAdminClearFunnelAbort,
      ),
    );
    expect(harness.course.getUser(99), isNotNull);
    expect(harness.sender.messages.last.text, contains('Админка'));
  });

  test('non-admin cannot clear funnel via callback', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 99, userId: 99, text: '/start ig_reels_guide'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cf',
        chatId: 99,
        userId: 99,
        data: MessageTemplates.cbAdminClearFunnelConfirm,
      ),
    );
    expect(harness.course.getUser(99), isNotNull);
  });

  test('admin Диплинки without Sheets still returns four starter links', () async {
    final named = HandlerHarness();
    await named.init(adminUserIds: const <int>{1}, botUsername: 'course_bot');
    addTearDown(named.dispose);

    await named.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminLinks),
    );
    expect(named.sender.deletedMessages, isEmpty);
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

    final catalog = sheetsHarness.sheetsGateway!.valuesBySheetId[0]!;
    final priceCol = CoursesSheetParser.columnIndex(catalog, CoursesSheet.priceFullRub)!;
    final dataRow = CoursesSheetParser.headerRowIndex(catalog)! + 1;
    catalog[dataRow][priceCol] = 21000;

    await sheetsHarness.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '/links'));
    expect(sheetsHarness.sender.deletedMessages, hasLength(1));
    expect(sheetsHarness.sender.messages.any((m) => m.text.contains('Собираю диплинки')), isFalse);
    final text = sheetsHarness.sender.messages.last.text;
    expect(text, contains('?start=ig_reels_guide'));
    expect(sheetsHarness.course.activeLaunch()?.priceFullKopecks, 1800000);
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

  test('admin can add a person by Telegram id and later /start keeps admin source', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminAddUser),
    );
    await harness.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '50'));

    final created = harness.course.getUser(50);
    expect(created, isNotNull);
    expect(created!.source, AcquisitionSource.adminManual);
    expect(created.funnelPhase, FunnelPhase.lead);
    expect(harness.sender.messages.any((m) => m.text.contains('Карточка')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('id <code>50</code>')), isTrue);

    await harness.handlers.handle(
      privateMessageUpdate(chatId: 50, userId: 50, text: '/start ig_reels_guide', username: 'anna'),
    );
    expect(harness.course.getUser(50)?.source, AcquisitionSource.adminManual);
  });

  test('admin add of an existing person opens the card and does not overwrite source', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 99, userId: 99, text: '/start ig_reels_guide', username: 'lead'),
    );
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminAddUser),
    );
    await harness.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '99'));

    expect(harness.course.getUser(99)?.source, 'ig_reels_guide');
    expect(harness.sender.messages.last.text, contains('Карточка'));
  });

  test('search miss on a numeric id offers to create a card', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminSearch),
    );
    await harness.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '50'));

    final notFound = harness.sender.messages.last;
    expect(notFound.text, contains('Никого не нашёл'));
    expect(notFound.text, contains('создай карточку'));
    expect(notFound.replyMarkup.toString(), contains('${MessageTemplates.cbAdminCreate}50'));
    expect(harness.course.getUser(50), isNull);

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'create',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbAdminCreate}50',
      ),
    );
    expect(harness.course.getUser(50)?.source, AcquisitionSource.adminManual);
    expect(harness.sender.messages.last.text, contains('Карточка'));
  });

  test('admin add from a forwarded message creates the card with username', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminAddUser),
    );
    await harness.handlers.handle(
      privateMessageUpdate(
        chatId: 1,
        userId: 1,
        text: 'переслала',
        forwardFrom: <String, dynamic>{'id': 50, 'username': 'anna', 'first_name': 'Анна'},
      ),
    );
    final created = harness.course.getUser(50);
    expect(created?.username, 'anna');
    expect(created?.firstName, 'Анна');
    expect(created?.source, AcquisitionSource.adminManual);
  });

  test('admin can remove a person from the course without an order', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminAddUser),
    );
    await harness.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '50'));
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'rm',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbAdminCancel}50',
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'rmy',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbAdminCancelConfirm}50',
      ),
    );
    expect(harness.course.getUser(50)?.funnelPhase, FunnelPhase.cancelled);
    expect(harness.channel.banned, contains(50));
    expect(harness.sender.messages.any((m) => m.text.contains('Убрал с курса')), isTrue);
  });

  test('admin remove after paid revokes invite and kicks from the channel', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 99, userId: 99, text: '/start ig_reels_guide', username: 'lead'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'p',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.adminStatusSetData(AdminPaymentStatus.paid, 99),
      ),
    );
    expect(harness.course.getUser(99)?.funnelPhase.hasAccess, isTrue);
    expect(harness.channel.created, isNotEmpty);

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'rm',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbAdminCancel}99',
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'rmy',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbAdminCancelConfirm}99',
      ),
    );
    expect(harness.course.getUser(99)?.funnelPhase, FunnelPhase.cancelled);
    expect(harness.course.latestOrder(99)?.status, OrderStatus.cancelled);
    expect(harness.channel.revoked, isNotEmpty);
    expect(harness.channel.banned, contains(99));
  });

  test('admin reinvite from the card mints a new link and sends it to the person', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 99, userId: 99, text: '/start ig_reels_guide', username: 'lead'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'p',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.adminStatusSetData(AdminPaymentStatus.paid, 99),
      ),
    );
    expect(harness.channel.created, hasLength(1));
    final first = harness.channel.created.single;
    harness.sender.messages.clear();

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'ai',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbAdminInvite}99',
      ),
    );

    expect(harness.channel.created, hasLength(2));
    expect(harness.channel.revoked, contains(first));
    final next = harness.channel.created.last;
    expect(harness.sender.messages.any((m) => m.chatId == 99 && m.text.contains(next)), isTrue);
    expect(
      harness.sender.messages.any((m) => m.chatId == 1 && m.text.contains('отправил')),
      isTrue,
    );
    final toUser = harness.sender.messages.where((m) => m.chatId == 99);
    expect(
      toUser.any(
        (m) => _inlineButtonTexts(m.replyMarkup).contains(MessageTemplates.buttonOpenInvite),
      ),
      isTrue,
    );
    expect(
      toUser.any((m) => _inlineCallbackData(m.replyMarkup).contains(MessageTemplates.cbNewInvite)),
      isFalse,
    );
  });

  test('paid card offers change status and can switch to deposit', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 99, userId: 99, text: '/start ig_reels_guide', username: 'lead'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'p',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.adminStatusSetData(AdminPaymentStatus.paid, 99),
      ),
    );
    expect(harness.course.getUser(99)?.funnelPhase.hasAccess, isTrue);
    expect(harness.channel.created, isNotEmpty);

    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminSearch),
    );
    await harness.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '99'));
    final card = harness.sender.messages.last;
    expect(
      _inlineButtonTexts(card.replyMarkup),
      contains(MessageTemplates.buttonAdminChangeStatus),
    );
    expect(
      _inlineButtonTexts(card.replyMarkup),
      isNot(contains(MessageTemplates.buttonAdminStatusPaid)),
    );

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'st',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbAdminStatusMenu}99',
      ),
    );
    final picker = harness.sender.messages.last;
    expect(picker.text, contains('оплачено полностью'));
    final options = _inlineButtonTexts(picker.replyMarkup);
    expect(options, contains(MessageTemplates.buttonAdminStatusUnpaid));
    expect(options, contains(MessageTemplates.buttonAdminStatusDeposit));
    expect(options, contains(MessageTemplates.buttonAdminCancel));
    expect(options, isNot(contains(MessageTemplates.buttonAdminStatusPaid)));

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'dep',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.adminStatusSetData(AdminPaymentStatus.deposit, 99),
      ),
    );
    expect(harness.course.getUser(99)?.funnelPhase, FunnelPhase.depositPaid);
    expect(harness.course.latestOrder(99)?.status, OrderStatus.depositPaid);
    expect(harness.channel.revoked, isNotEmpty);
    expect(harness.course.latestOrder(99)?.accessGranted, isFalse);
  });

  test('admin can reset a paid person to unpaid', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 99, userId: 99, text: '/start ig_reels_guide', username: 'lead'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'p',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.adminStatusSetData(AdminPaymentStatus.paid, 99),
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'un',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.adminStatusSetData(AdminPaymentStatus.unpaid, 99),
      ),
    );
    expect(harness.course.getUser(99)?.funnelPhase, FunnelPhase.checkout);
    expect(harness.course.latestOrder(99)?.status, OrderStatus.awaitingPayment);
    expect(harness.course.latestOrder(99)?.amountPaidKopecks, 0);
    expect(harness.channel.revoked, isNotEmpty);
  });
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

List<String> _inlineCallbackData(Map<String, Object?>? markup) {
  final rows = markup?['inline_keyboard'] as List<dynamic>? ?? const <dynamic>[];
  final data = <String>[];
  for (final row in rows) {
    for (final cell in row as List<dynamic>) {
      final callback = (cell as Map)['callback_data'];
      if (callback is String) {
        data.add(callback);
      }
    }
  }
  return data;
}
