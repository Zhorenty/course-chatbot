import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/admin_payment_status.dart';
import 'package:course_chatbot/src/domain/catalog_admin.dart';
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
    expect(texts, <String>[
      MessageTemplates.buttonAdminSearch,
      MessageTemplates.buttonAdminCatalog,
      MessageTemplates.buttonAdminLinks,
      MessageTemplates.buttonAdminSheets,
      MessageTemplates.buttonAdminBroadcast,
      MessageTemplates.buttonAdminClearFunnel,
    ]);
    expect(texts, isNot(contains(MessageTemplates.buttonAdminAddUser)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminCatalogNew)));
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

  test('admin catalog button lists launches and create-course stays off the admin menu', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);

    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    expect(sheets.sender.messages.any((m) => m.text.contains('Управление курсами')), isTrue);
    expect(sheets.sender.messages.any((m) => m.text.contains('launch-1')), isTrue);
    final list = sheets.sender.messages.lastWhere((m) => m.replyMarkup != null);
    expect(_inlineButtonTexts(list.replyMarkup), contains(MessageTemplates.buttonAdminCatalogNew));
    expect(
      _replyButtonTexts(sheets.sender.messages.first.replyMarkup),
      isNot(contains(MessageTemplates.buttonAdminCatalogNew)),
    );
    expect(_inlineCallbackData(list.replyMarkup).every((data) => data.length <= 64), isTrue);
  });

  test('admin catalog without Sheets says the table is off', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('не подключ')), isTrue);
    expect(harness.course.listLaunches(), hasLength(1));
  });

  test('admin catalog list hides launches missing from COURSES', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);
    sheets.course.upsertLaunch(
      productCode: 'course',
      productTitle: 'Курс',
      launchCode: 'old-stream',
      launchTitle: 'Старый поток',
      priceFullKopecks: 1800000,
      depositKopecks: 0,
      depositDueDays: 7,
    );

    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    expect(sheets.course.launchByCode('old-stream'), isNull);
    expect(sheets.sender.messages.any((m) => m.text.contains('old-stream')), isFalse);
    expect(sheets.sender.messages.any((m) => m.text.contains('Старый поток')), isFalse);
    expect(sheets.sender.messages.any((m) => m.text.contains('launch-1')), isTrue);
  });

  test('admin catalog screens edit the same panel message', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);
    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    final count = sheets.sender.messages.length;
    final launch = sheets.course.launchByCode('launch-1')!;
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cl',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogOpen}${launch.id}',
      ),
    );
    expect(sheets.sender.messages, hasLength(count));
    expect(sheets.sender.messages.last.text, contains('launch-1'));
  });

  test('admin catalog wizard create writes COURSES row and sqlite', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);

    await _runCatalogCreateWizard(sheets, title: 'Ноябрь', code: 'nov-26', active: true);
    final sheet = sheets.sheetsGateway!.valuesBySheetId[0]!;
    expect(sheet.first.first, CoursesSheet.title);
    expect(sheet[CoursesSheet.defaultHeaderRow].first, 'Код продукта');
    final created = _coursesRowByCode(sheet, 'nov-26');
    expect(created, isNotNull);
    expect(created![CoursesSheet.headers.indexOf(CoursesSheet.launchTitle)], 'Ноябрь');
    expect(created[CoursesSheet.headers.indexOf(CoursesSheet.priceFullRub)], 20000);
    expect(created[CoursesSheet.headers.indexOf(CoursesSheet.isActive)], 'да');
    expect(created[CoursesSheet.headers.indexOf(CoursesSheet.status)].toString(), startsWith('='));
    final seed = _coursesRowByCode(sheet, 'launch-1');
    expect(seed, isNotNull);
    expect(seed![CoursesSheet.headers.indexOf(CoursesSheet.isActive)], '');
    expect(sheets.course.launchByCode('nov-26')?.title, 'Ноябрь');
    expect(sheets.course.launchByCode('nov-26')?.isActive, isTrue);
    expect(sheets.course.activeLaunch()?.code, 'nov-26');
    expect(sheets.sheetsGateway!.deletedSheetIds, isEmpty);
    expect(
      sheets.sheetsGateway!.clearedRanges.any((range) => range.contains(LinksSheet.tabTitle)),
      isFalse,
    );
    expect(sheets.sheetsWriter!.replaceDashboardCount, 0);
  });

  test('admin catalog invalid price stays on the same step', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);

    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cn',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.cbCatalogNew,
      ),
    );
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: 'Ноябрь'));
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: 'nov-26'));
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: 'нет'));
    expect(sheets.sender.messages.last.text, contains('не цена'));
    expect(_coursesRowByCode(sheets.sheetsGateway!.valuesBySheetId[0]!, 'nov-26'), isNull);

    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '20000'));
    expect(sheets.sender.messages.last.text, contains('Предоплата'));
  });

  test('admin catalog invalid date does not write a row', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);

    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cn',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.cbCatalogNew,
      ),
    );
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: 'Ноябрь'));
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: 'nov-26'));
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '20000'));
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '0'));
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '31.02.2026'));
    expect(sheets.sender.messages.last.text, contains('Дата не разобралась'));
    expect(_coursesRowByCode(sheets.sheetsGateway!.valuesBySheetId[0]!, 'nov-26'), isNull);
  });

  test('admin catalog edit price updates COURSES and sqlite', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);
    await sheets.catalogSync!.sync();
    final launch = sheets.course.launchByCode('launch-1')!;

    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cl',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogOpen}${launch.id}',
      ),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'ce',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogEdit}${launch.id}',
      ),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cf',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.catalogFieldData(launch.id, CatalogLaunchField.price),
      ),
    );
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '21000'));
    expect(sheets.course.launchByCode('launch-1')?.priceFullKopecks, 2100000);
    final row = _coursesRowByCode(sheets.sheetsGateway!.valuesBySheetId[0]!, 'launch-1')!;
    expect(row[CoursesSheet.headers.indexOf(CoursesSheet.priceFullRub)], 21000);
    expect(sheets.sheetsGateway!.valuesBySheetId[0]!.first.first, CoursesSheet.title);
  });

  test('admin catalog activate clears the previous is_active flag', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);
    await _runCatalogCreateWizard(sheets, title: 'Ноябрь', code: 'nov-26', active: false);
    final second = sheets.course.launchByCode('nov-26')!;
    expect(second.isActive, isFalse);

    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'ca',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogActivate}${second.id}',
      ),
    );
    expect(sheets.course.activeLaunch()?.code, 'nov-26');
    expect(sheets.course.launchByCode('launch-1')?.isActive, isFalse);
    final sheet = sheets.sheetsGateway!.valuesBySheetId[0]!;
    expect(
      _coursesRowByCode(sheet, 'nov-26')![CoursesSheet.headers.indexOf(CoursesSheet.isActive)],
      'да',
    );
    expect(
      _coursesRowByCode(sheet, 'launch-1')![CoursesSheet.headers.indexOf(CoursesSheet.isActive)],
      '',
    );
  });

  test('admin catalog deletes an empty launch and refuses the last or busy one', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);
    await _runCatalogCreateWizard(sheets, title: 'Ноябрь', code: 'nov-26', active: false);
    final empty = sheets.course.launchByCode('nov-26')!;

    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cd',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogDelete}${empty.id}',
      ),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cdy',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogDeleteYes}${empty.id}',
      ),
    );
    expect(sheets.course.launchByCode('nov-26'), isNull);
    expect(_coursesRowByCode(sheets.sheetsGateway!.valuesBySheetId[0]!, 'nov-26'), isNull);
    expect(_coursesRowByCode(sheets.sheetsGateway!.valuesBySheetId[0]!, 'launch-1'), isNotNull);
    expect(sheets.sheetsGateway!.deletedDimensions, isNotEmpty);
    expect(sheets.sheetsGateway!.deletedSheetIds, isEmpty);

    final first = sheets.course.launchByCode('launch-1')!;
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cd1',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogDelete}${first.id}',
      ),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cdy1',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogDeleteYes}${first.id}',
      ),
    );
    expect(sheets.sender.messages.last.text, contains('единственный'));
    expect(sheets.course.launchByCode('launch-1'), isNotNull);

    await _runCatalogCreateWizard(sheets, title: 'Декабрь', code: 'dec-26', active: false);
    final busy = sheets.course.launchByCode('dec-26')!;
    sheets.course.ensureUser(userId: 50, now: DateTime.utc(2026, 1, 1));
    sheets.course.ensureEnrollment(userId: 50, launchId: busy.id, now: DateTime.utc(2026, 1, 1));
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cdb',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogDelete}${busy.id}',
      ),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cdyb',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogDeleteYes}${busy.id}',
      ),
    );
    expect(sheets.sender.messages.last.text, contains('ученики'));
    expect(sheets.course.launchByCode('dec-26'), isNotNull);
  });

  test('admin catalog open syncs a COURSES-only row into sqlite', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);
    sheets.sheetsGateway!.valuesBySheetId[0]!.add(
      _coursesDataRow(code: 'hand-26', title: 'Руками', deposit: '', due: ''),
    );
    expect(sheets.course.launchByCode('hand-26'), isNull);

    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    expect(sheets.course.launchByCode('hand-26')?.title, 'Руками');
    expect(sheets.sender.messages.any((m) => m.text.contains('hand-26')), isTrue);
  });

  test('admin catalog list ignores stray text', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);

    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    final before = sheets.sender.messages.length;
    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: 'случайно', messageId: 77),
    );
    expect(sheets.sender.messages, hasLength(before));
    expect(sheets.sender.messages.last.text, contains('Курсы'));
    expect(
      sheets.sender.deletedMessages.any((item) => item.chatId == 1 && item.messageId == 77),
      isTrue,
    );
  });

  test('admin catalog wizard deletes the admin replies', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);

    await sheets.handlers.handle(
      privateMessageUpdate(
        chatId: 1,
        userId: 1,
        text: MessageTemplates.buttonAdminCatalog,
        messageId: 40,
      ),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cn',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.cbCatalogNew,
      ),
    );
    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: 'Ноябрь', messageId: 41),
    );
    expect(
      sheets.sender.deletedMessages.any((item) => item.chatId == 1 && item.messageId == 41),
      isTrue,
    );
    expect(sheets.sender.messages.last.text, contains('Код запуска'));
  });

  test('admin catalog create refuses a code that already exists on COURSES', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);

    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    sheets.sheetsGateway!.valuesBySheetId[0]!.add(
      _coursesDataRow(code: 'hand-26', title: 'Руками', deposit: '', due: ''),
    );
    await _runCatalogCreateWizard(
      sheets,
      title: 'Overwrite',
      code: 'hand-26',
      active: false,
      openCatalog: false,
    );
    expect(sheets.sender.messages.last.text, contains('уже есть'));
    final row = _coursesRowByCode(sheets.sheetsGateway!.valuesBySheetId[0]!, 'hand-26')!;
    expect(row[CoursesSheet.headers.indexOf(CoursesSheet.launchTitle)], 'Руками');
    expect(sheets.course.launchByCode('hand-26'), isNull);
  });

  test('admin catalog edit empty channel clears the COURSES cell', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);
    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    final launch = sheets.course.launchByCode('launch-1')!;
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cl',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogOpen}${launch.id}',
      ),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'ce',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogEdit}${launch.id}',
      ),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cf',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.catalogFieldData(launch.id, CatalogLaunchField.channel),
      ),
    );
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '-100555'));
    expect(
      _coursesRowByCode(sheets.sheetsGateway!.valuesBySheetId[0]!, 'launch-1')![CoursesSheet.headers
          .indexOf(CoursesSheet.channelId)],
      -100555,
    );

    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'ce2',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogEdit}${launch.id}',
      ),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cf2',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.catalogFieldData(launch.id, CatalogLaunchField.channel),
      ),
    );
    await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '-'));
    final cell = _coursesRowByCode(
      sheets.sheetsGateway!.valuesBySheetId[0]!,
      'launch-1',
    )![CoursesSheet.headers.indexOf(CoursesSheet.channelId)];
    expect('$cell', anyOf('', 'null'));
  });

  test('admin catalog delete still drops sqlite when COURSES row is already gone', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);
    await _runCatalogCreateWizard(sheets, title: 'Ноябрь', code: 'nov-26', active: false);
    final empty = sheets.course.launchByCode('nov-26')!;
    sheets.sheetsGateway!.valuesBySheetId[0]!.removeWhere(
      (row) => row.length > 2 && row[2] == 'nov-26',
    );

    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cdy',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbCatalogDeleteYes}${empty.id}',
      ),
    );
    expect(sheets.course.launchByCode('nov-26'), isNull);
    expect(_coursesRowByCode(sheets.sheetsGateway!.valuesBySheetId[0]!, 'launch-1'), isNotNull);
  });

  test('admin catalog cancel returns to admin menu', () async {
    final sheets = HandlerHarness();
    await sheets.init(adminUserIds: const <int>{1}, enableSheets: true);
    addTearDown(sheets.dispose);

    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
    await sheets.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'cn',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.cbCatalogNew,
      ),
    );
    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminBroadcastCancel),
    );
    expect(sheets.sender.messages.last.text, contains('Админка'));
    expect(
      _replyButtonTexts(sheets.sender.messages.last.replyMarkup),
      contains(MessageTemplates.buttonAdminCatalog),
    );
    expect(
      _replyButtonTexts(sheets.sender.messages.last.replyMarkup),
      isNot(contains(MessageTemplates.buttonAdminCatalogNew)),
    );
  });
}

Future<void> _runCatalogCreateWizard(
  HandlerHarness sheets, {
  required String title,
  required String code,
  required bool active,
  bool openCatalog = true,
}) async {
  if (openCatalog) {
    await sheets.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminCatalog),
    );
  }
  await sheets.handlers.handle(
    privateCallbackUpdate(
      callbackId: 'cn-$code',
      chatId: 1,
      userId: 1,
      data: MessageTemplates.cbCatalogNew,
    ),
  );
  await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: title));
  await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: code));
  await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '20000'));
  await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '0'));
  await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '01.11.2026'));
  await sheets.handlers.handle(privateMessageUpdate(chatId: 1, userId: 1, text: '-'));
  await sheets.handlers.handle(
    privateCallbackUpdate(
      callbackId: 'cay-$code',
      chatId: 1,
      userId: 1,
      data: active ? MessageTemplates.cbCatalogActiveYes : MessageTemplates.cbCatalogActiveNo,
    ),
  );
  await sheets.handlers.handle(
    privateCallbackUpdate(
      callbackId: 'ccy-$code',
      chatId: 1,
      userId: 1,
      data: MessageTemplates.cbCatalogCreateYes,
    ),
  );
}

List<Object?> _coursesDataRow({
  required String code,
  required String title,
  String isActive = '',
  Object? deposit = 0,
  Object? due = '',
}) {
  return List<Object?>.from(CoursesSheet.seedDataRow())
    ..[CoursesSheet.headers.indexOf(CoursesSheet.launchCode)] = code
    ..[CoursesSheet.headers.indexOf(CoursesSheet.launchTitle)] = title
    ..[CoursesSheet.headers.indexOf(CoursesSheet.isActive)] = isActive
    ..[CoursesSheet.headers.indexOf(CoursesSheet.depositRub)] = deposit
    ..[CoursesSheet.headers.indexOf(CoursesSheet.depositDueDate)] = due;
}

List<Object?>? _coursesRowByCode(List<List<Object?>> sheet, String code) {
  final headerAt = CoursesSheetParser.headerRowIndex(sheet);
  final codeCol = CoursesSheetParser.columnIndex(sheet, CoursesSheet.launchCode);
  if (headerAt == null || codeCol == null) {
    return null;
  }
  for (var i = headerAt + 1; i < sheet.length; i++) {
    final row = sheet[i];
    if (row.length <= codeCol) {
      continue;
    }
    if (row[codeCol]?.toString() == code) {
      return row;
    }
  }
  return null;
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
