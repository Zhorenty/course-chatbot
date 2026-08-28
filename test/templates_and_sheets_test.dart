import 'package:course_chatbot/src/data/google_sheets_courses_catalog.dart';
import 'package:course_chatbot/src/data/google_sheets_funnel_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_links_catalog.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

void main() {
  test('in-development copy is a stub, not a funnel step', () {
    expect(MessageTemplates().botInDevelopment(), contains('в разработке'));
  });

  test('enroll CTA stays in templates until access is granted', () {
    final templates = MessageTemplates();
    expect(templates.warmupStep('warmup_0'), contains('записаться'));
    expect(MessageTemplates.buttonEnroll, contains('Записаться'));
  });

  test('offer consent copy names the pay button and both checkboxes', () {
    final templates = MessageTemplates();
    const launch = Launch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Запуск',
      priceFullKopecks: 1800000,
      depositKopecks: 500000,
      depositDueDays: 7,
    );
    expect(templates.offerConsent(launch), contains('Перейти к оплате'));
    expect(templates.offerConsent(launch), contains('Публичной оферты'));
    final keyboard = templates.offerKeyboard(acceptedOffer: true, acceptedPersonalData: false);
    final rows = keyboard['inline_keyboard'] as List<dynamic>;
    expect(rows[0].toString(), contains('☑️'));
    expect(rows[0].toString(), contains(MessageTemplates.buttonAcceptOffer));
    expect(rows[1].toString(), contains('☐'));
    expect(rows[1].toString(), contains(MessageTemplates.buttonAcceptPersonalData));
    expect(rows[2].toString(), contains('Перейти к оплате'));
    expect('☑️ ${MessageTemplates.buttonAcceptOffer}'.length, lessThanOrEqualTo(64));
    expect('☑️ ${MessageTemplates.buttonAcceptPersonalData}'.length, lessThanOrEqualTo(64));
  });

  test('ВОРОНКА dashboard has course steps not club quiz', () {
    final dashboard = GoogleSheetsFunnelDashboard.build(
      FunnelAnalytics(
        generatedAt: DateTime.utc(2026, 8, 26, 12),
        startedUsersTotal: 10,
        funnelUsers: 9,
        guideTaken: 8,
        checkoutStarted: 3,
        paidUsers: 1,
        startedLast7Days: 4,
        startedLast30Days: 10,
        paidLast7Days: 1,
        paidLast30Days: 1,
        phaseCounts: const <String, int>{'warming': 5, 'paid': 1},
        sourceCounts: const <String, int>{'ig_reels_guide': 6, 'direct_course': 4},
      ),
    );
    final flat = dashboard.rows.map((row) => row.join(' ')).join('\n');
    expect(flat, contains('Взяли гайд'));
    expect(flat, contains('Instagram Reels'));
    expect(flat, isNot(contains('квиз')));
    expect(dashboard.charts, isNotEmpty);
    expect(dashboard.sheetTitle, 'ВОРОНКА');
    expect(dashboard.obsoleteSheetTitles, contains('FUNNEL'));
  });

  test('COURSES catalog look matches ВОРОНКА palette and has no charts', () {
    final look = GoogleSheetsCoursesCatalog.build();
    expect(look.sheetTitle, 'COURSES');
    expect(look.charts, isEmpty);
    expect(look.hideGridlines, isTrue);
    expect(look.frozenRowCount, 4);
    expect(look.tabColor, GoogleSheetsCoursesCatalog.header);
    expect(look.columnWidthsPx, hasLength(14));
    expect(look.columnCount, 14);
    expect(look.notes, hasLength(14));
    expect(look.notes[7].text, contains('Выбери в календаре'));
    expect(look.notes.last.text, contains('пустая'));
    expect(look.validations, isNotEmpty);
    expect(look.styles, isNotEmpty);
  });

  test('ССЫЛКИ catalog look matches COURSES palette and has no charts', () {
    final look = GoogleSheetsLinksCatalog.build();
    expect(look.sheetTitle, LinksSheet.tabTitle);
    expect(look.charts, isEmpty);
    expect(look.hideGridlines, isTrue);
    expect(look.frozenRowCount, 4);
    expect(look.columnCount, 4);
    expect(look.notes, hasLength(4));
    expect(look.notes.last.text, contains('t.me'));
    expect(LinksSheet.extraDataRows, greaterThanOrEqualTo(24));
    expect(look.rowCount, greaterThanOrEqualTo(LinksSheet.defaultHeaderRow + 1 + 24));
  });

  test('admin search prompt lists id and username', () {
    final text = MessageTemplates().adminAskSearch();
    expect(text, contains('<b>Поиск человека</b>'));
    expect(text, contains('Пришли сообщением'));
    expect(text, contains('id'));
    expect(text, contains('или @username'));
  });

  test('admin add prompt asks for numeric id or a forwarded message', () {
    final text = MessageTemplates().adminAskAddUser();
    expect(text, contains('<b>Добавить на курс</b>'));
    expect(text, contains('id'));
    expect(text, contains('переслать'));
  });

  test('admin sheets refresh result is a structured card', () {
    final launch = Launch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Октябрь <b>',
      priceFullKopecks: 1800000,
      depositKopecks: 500000,
      depositDueDays: 7,
      courseStartAt: DateTime.utc(2026, 10, 12),
    );
    final text = MessageTemplates().adminSheetsRefreshResult(
      catalogAttempted: true,
      catalogOk: true,
      funnelAttempted: true,
      funnelOk: true,
      launch: launch,
    );
    expect(text, contains('<b>Таблица</b>'));
    expect(text, contains('Набор в боте'));
    expect(text, contains('поток: Октябрь &lt;b&gt;'));
    expect(text, contains('цена: 18000 ₽'));
    expect(text, contains('старт: 12.10.2026'));
    expect(text, contains('лист ВОРОНКА: цифры перезаписаны'));
    expect(text, isNot(contains('Октябрь <b>')));
  });

  test('admin deep-link copy escapes origin and URL', () {
    final templates = MessageTemplates(botUsername: 'bot&x');
    final text = templates.adminDeepLinks(const <AcquisitionLink>[
      AcquisitionLink(
        origin: 'Reels <b>',
        destination: AcquisitionDestination.guide,
        payload: 'ig_reels_guide',
      ),
    ]);
    expect(text, contains('Reels &lt;b&gt;'));
    expect(text, contains('https://t.me/bot&amp;x?start=ig_reels_guide'));
    expect(text, isNot(contains('Reels <b>')));
  });

  test('admin deep-link copy without username does not invent t.me URLs', () {
    final text = MessageTemplates().adminDeepLinks(AcquisitionLink.starters);
    expect(text, contains('неизвестен'));
    expect(text, isNot(contains('https://t.me/')));
    expect(text, contains('ig_reels_guide'));
  });

  test('admin reply keyboard is admin-only and includes sheets refresh', () {
    final templates = MessageTemplates();
    final texts = _replyButtonTexts(templates.adminMenuKeyboard());
    expect(texts, contains(MessageTemplates.buttonAdminSearch));
    expect(texts, contains(MessageTemplates.buttonAdminBroadcast));
    expect(texts, contains(MessageTemplates.buttonAdminLinks));
    expect(texts, contains(MessageTemplates.buttonAdminSheets));
    expect(texts.last, MessageTemplates.buttonAdminBroadcast);
    expect(texts, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(texts, isNot(contains(MessageTemplates.buttonGuide)));
    expect(texts, isNot(contains(MessageTemplates.buttonProfile)));
    expect(texts, isNot(contains(MessageTemplates.buttonHelp)));
  });

  test('broadcast confirm keyboard is not locked to one segment', () {
    final templates = MessageTemplates();
    final rows = templates.broadcastConfirmKeyboard()['inline_keyboard'] as List<dynamic>;
    final texts = <String>[
      for (final row in rows)
        for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
    ];
    final data = <String>[
      for (final row in rows)
        for (final cell in row as List<dynamic>) (cell as Map)['callback_data'] as String,
    ];
    expect(texts, contains(MessageTemplates.buttonAdminBroadcastSend));
    expect(texts, contains(MessageTemplates.buttonAdminBroadcastOtherSegment));
    expect(data, contains(MessageTemplates.cbBroadcastSend));
    expect(data, isNot(contains('bg')));
    expect(texts.join(), isNot(contains('получили гайд и не купили')));
  });

  test('admin card is a declarative snapshot, not a pupil address', () {
    final templates = MessageTemplates();
    final startedAt = DateTime.utc(2026, 8, 1);
    final user = UserProfile(
      userId: 50,
      username: 'anna',
      firstName: 'Анна <b>',
      source: 'ig_reels_guide',
      funnelPhase: FunnelPhase.depositPaid,
      warmupOptOut: true,
      botBlocked: true,
      firstStartedAt: startedAt,
      lastSeenAt: startedAt,
    );
    final order = CourseOrder(
      id: 3,
      userId: 50,
      launchId: 1,
      status: OrderStatus.depositPaid,
      kind: PaymentKind.deposit,
      priceFullKopecks: 1800000,
      amountPaidKopecks: 500000,
      amountDueKopecks: 1300000,
      checkoutStartedAt: DateTime.utc(2026, 8, 10),
      dueAt: DateTime.utc(2026, 10, 12),
    );
    final access = ChannelAccess(
      id: 1,
      userId: 50,
      launchId: 1,
      orderId: 3,
      inviteLink: 'https://t.me/+secret',
      joinedAt: DateTime.utc(2026, 8, 15, 12, 40),
    );
    final text = templates.adminCard(
      user: user,
      order: order,
      access: access,
      dialog: <ConversationLogEntry>[
        ConversationLogEntry(
          id: 1,
          occurredAt: DateTime.utc(2026, 8, 15),
          direction: ConversationDirection.inbound,
          peerUserId: 50,
          chatId: 50,
          contentType: ConversationContentType.photo,
        ),
      ],
    );

    expect(text, contains('<b>Карточка</b> Анна &lt;b&gt; · @anna'));
    expect(text, contains('id <code>50</code>'));
    expect(text, contains('источник: Instagram Reels · <code>ig_reels_guide</code>'));
    expect(text, contains('<b>Внесена предоплата</b>'));
    expect(text, contains('заказ #3 · предоплата · внесена предоплата'));
    expect(text, contains('оплачено 5000 ₽ из 18000 ₽'));
    expect(text, contains('остаток 13000 ₽ · до 12.10.2026'));
    expect(text, contains('<b>Канал</b>'));
    expect(text, contains('вошёл 15.08.2026 15:40'));
    expect(text, contains('<b>Связь</b>'));
    expect(text, contains('прогрев не шлём («Не писать»)'));
    expect(text, contains('заблокировал бота'));
    expect(text, contains('← фото'));
    expect(text, isNot(contains('сейчас:')));
    expect(text, isNot(contains('Сейчас:')));
    expect(text, isNot(contains('оформляешь')));
    expect(text, isNot(contains('гайд уже у тебя')));
    expect(text, isNot(contains('смотришь')));
    expect(text, isNot(contains('checkout_started')));
    expect(text, isNot(contains('deposit_paid')));
    expect(text, isNot(contains('2026-08-15T')));
    expect(text, isNot(contains('не писать: да')));
    expect(text, isNot(contains('Анна <b>')));
    expect(text, isNot(contains('https://t.me/+secret')));
    expect(text, isNot(contains('photo')));

    final checkoutUser = UserProfile(
      userId: 50,
      username: 'anna',
      firstName: 'Анна',
      funnelPhase: FunnelPhase.checkout,
      firstStartedAt: startedAt,
      lastSeenAt: startedAt,
    );
    expect(templates.adminCard(user: checkoutUser), contains('<b>Оформляет оплату</b>'));
    expect(templates.adminCard(user: checkoutUser), isNot(contains('сейчас:')));
    expect(templates.adminCard(user: checkoutUser), isNot(contains('оформляешь')));
    expect(templates.adminIncomingUserMessage(user: checkoutUser), contains('оформляет оплату'));
    expect(templates.adminIncomingUserMessage(user: checkoutUser), isNot(contains('сейчас:')));
    expect(templates.adminIncomingUserMessage(user: checkoutUser), isNot(contains('оформляешь')));
  });

  test('admin card dialog keeps one line per message and hides file ids', () {
    final startedAt = DateTime.utc(2026, 8, 1);
    final text = MessageTemplates().adminCard(
      user: UserProfile(
        userId: 50,
        firstName: 'Анна',
        funnelPhase: FunnelPhase.checkout,
        firstStartedAt: startedAt,
        lastSeenAt: startedAt,
      ),
      dialog: <ConversationLogEntry>[
        ConversationLogEntry(
          id: 1,
          occurredAt: DateTime.utc(2026, 8, 15, 10),
          direction: ConversationDirection.outbound,
          peerUserId: 50,
          chatId: 50,
          contentType: ConversationContentType.document,
          textPreview:
              'document BQACAgIAAxkDAAMKao_ubwVvf_X-8R4HIo_gof56x8AAArOhAAJHuoBIHMwPOJ6ookw9BA',
        ),
        ConversationLogEntry(
          id: 2,
          occurredAt: DateTime.utc(2026, 8, 15, 11),
          direction: ConversationDirection.outbound,
          peerUserId: 50,
          chatId: 50,
          contentType: ConversationContentType.text,
          textPreview:
              'Профиль\n\nСейчас: оформляешь оплату.\n\nДальше — гайд, запись на курс или помощь.',
        ),
        ConversationLogEntry(
          id: 3,
          occurredAt: DateTime.utc(2026, 8, 15, 12),
          direction: ConversationDirection.inbound,
          peerUserId: 50,
          chatId: 50,
          contentType: ConversationContentType.text,
          textPreview: MessageTemplates.buttonEnroll,
        ),
      ],
    );

    expect(text, contains('<b>Диалог</b>'));
    expect(text, contains('→ файл'));
    expect(text, contains('→ Профиль'));
    expect(text, contains('← ${MessageTemplates.buttonEnroll}'));
    expect(text, isNot(contains('BQACAgIA')));
    expect(text, isNot(contains('оформляешь')));
    expect(text, isNot(contains('Сейчас:')));
    expect(text, isNot(contains('сейчас:')));
    expect(text, isNot(contains('Дальше — гайд')));
  });

  test('admin card without order shows empty payment and default flags', () {
    final text = MessageTemplates().adminCard(
      user: UserProfile(
        userId: 7,
        funnelPhase: FunnelPhase.lead,
        firstStartedAt: DateTime.utc(2026, 8, 1),
        lastSeenAt: DateTime.utc(2026, 8, 1),
      ),
    );
    expect(text, contains('<b>Карточка</b>'));
    expect(text, contains('источник: без метки'));
    expect(text, contains('<b>Пришёл, без гайда</b>'));
    expect(text, contains('заказа нет'));
    expect(text, contains('<b>Канал</b>'));
    expect(text, contains('нет доступа'));
    expect(text, contains('прогрев идёт'));
    expect(text, contains('бот на связи'));
    expect(text, isNot(contains('сейчас:')));
    expect(text, isNot(contains('остаток')));
  });

  test('user reply keyboard has profile, not menu, and no admin actions', () {
    final templates = MessageTemplates();
    final texts = _replyButtonTexts(templates.userMenuKeyboard(hasAccess: false));
    expect(texts, contains(MessageTemplates.buttonEnroll));
    expect(texts, contains(MessageTemplates.buttonGuide));
    expect(texts, contains(MessageTemplates.buttonProfile));
    expect(texts, contains(MessageTemplates.buttonHelp));
    expect(texts, isNot(contains('📋 Меню')));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminSheets)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminLinks)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminSearch)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminMenu)));

    final withAccess = _replyButtonTexts(templates.userMenuKeyboard(hasAccess: true));
    expect(withAccess, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(withAccess, contains(MessageTemplates.buttonGuide));
    expect(withAccess, contains(MessageTemplates.buttonProfile));
    expect(withAccess, contains(MessageTemplates.buttonHelp));
  });

  test('user profile is a pupil snapshot: stream, status, guide, payment, next step', () {
    final templates = MessageTemplates();
    final startedAt = DateTime.utc(2026, 8, 1);
    final launch = Launch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Запуск',
      priceFullKopecks: 1800000,
      depositKopecks: 500000,
      depositDueDays: 7,
      courseStartAt: DateTime.utc(2026, 10, 12),
    );

    final magnet = templates.profile(
      user: UserProfile(
        userId: 50,
        firstName: 'Анна <b>',
        source: 'ig_reels_guide',
        funnelPhase: FunnelPhase.magnetIssued,
        magnetIssuedAt: startedAt,
        firstStartedAt: startedAt,
        lastSeenAt: startedAt,
      ),
      launch: launch,
    );
    expect(magnet, contains('<b>Профиль</b> Анна &lt;b&gt;'));
    expect(magnet, contains('<b>Курс</b>'));
    expect(magnet, contains('Запуск'));
    expect(magnet, contains('старт 12.10.2026'));
    expect(magnet, contains('пока не записан'));
    expect(magnet, contains('гайд выдан'));
    expect(magnet, contains('<b>Гайд</b>'));
    expect(magnet, contains('выдан'));
    expect(magnet, contains('оплаты ещё не было'));
    expect(magnet, isNot(contains('18000')));
    expect(magnet, isNot(contains('Анна <b>')));
    expect(magnet, isNot(contains('ig_reels_guide')));
    expect(magnet, isNot(contains('id 50')));
    expect(magnet, isNot(contains('<code>50</code>')));
    expect(magnet, isNot(contains('<b>Канал</b>')));

    final checkout = templates.profile(
      user: UserProfile(
        userId: 50,
        firstName: 'Анна',
        funnelPhase: FunnelPhase.checkout,
        magnetIssuedAt: startedAt,
        firstStartedAt: startedAt,
        lastSeenAt: startedAt,
      ),
      launch: launch,
      order: CourseOrder(
        id: 9,
        userId: 50,
        launchId: 1,
        status: OrderStatus.checkoutStarted,
        kind: PaymentKind.full,
        priceFullKopecks: 1800000,
        amountPaidKopecks: 0,
        amountDueKopecks: 1800000,
        checkoutStartedAt: DateTime.utc(2026, 8, 10),
      ),
    );
    expect(checkout, contains('оформление оплаты'));
    expect(checkout, contains('полная'));
    expect(checkout, contains('оплачено 0 ₽ из 18000 ₽'));
    expect(checkout, contains('в канал пущу после полной оплаты'));
    expect(checkout, isNot(contains('пока не записан')));
    expect(checkout, isNot(contains('awaiting_payment')));
    expect(checkout, isNot(contains('заказ #9')));

    final deposit = templates.profile(
      user: UserProfile(
        userId: 50,
        firstName: 'Анна',
        funnelPhase: FunnelPhase.depositPaid,
        magnetIssuedAt: startedAt,
        firstStartedAt: startedAt,
        lastSeenAt: startedAt,
      ),
      launch: launch,
      order: CourseOrder(
        id: 3,
        userId: 50,
        launchId: 1,
        status: OrderStatus.depositPaid,
        kind: PaymentKind.deposit,
        priceFullKopecks: 1800000,
        amountPaidKopecks: 500000,
        amountDueKopecks: 1300000,
        checkoutStartedAt: DateTime.utc(2026, 8, 10),
        dueAt: DateTime.utc(2026, 10, 5),
      ),
    );
    expect(deposit, contains('есть предоплата'));
    expect(deposit, contains('предоплата'));
    expect(deposit, contains('оплачено 5000 ₽ из 18000 ₽'));
    expect(deposit, contains('остаток 13000 ₽ — до 05.10.2026'));
    expect(deposit, contains('в канал пущу после полной оплаты'));
    expect(deposit, contains(MessageTemplates.buttonEnroll));
    expect(deposit, isNot(contains('https://t.me/')));

    final invited = templates.profile(
      user: UserProfile(
        userId: 50,
        firstName: 'Анна',
        funnelPhase: FunnelPhase.accessGranted,
        magnetIssuedAt: startedAt,
        firstStartedAt: startedAt,
        lastSeenAt: startedAt,
      ),
      launch: launch,
      order: CourseOrder(
        id: 4,
        userId: 50,
        launchId: 1,
        status: OrderStatus.paid,
        kind: PaymentKind.full,
        priceFullKopecks: 1800000,
        amountPaidKopecks: 1800000,
        amountDueKopecks: 0,
        checkoutStartedAt: DateTime.utc(2026, 8, 10),
        accessGranted: true,
      ),
      access: const ChannelAccess(
        id: 1,
        userId: 50,
        launchId: 1,
        orderId: 4,
        inviteLink: 'https://t.me/+secret',
      ),
    );
    expect(invited, contains('доступ в канал есть'));
    expect(invited, contains('ссылка в канал выдана'));
    expect(invited, contains(MessageTemplates.buttonNewInvite));
    expect(invited, isNot(contains('https://t.me/+secret')));
    expect(invited, isNot(contains('-1001')));

    final joined = templates.profile(
      user: UserProfile(
        userId: 50,
        firstName: 'Анна',
        funnelPhase: FunnelPhase.accessGranted,
        magnetIssuedAt: startedAt,
        firstStartedAt: startedAt,
        lastSeenAt: startedAt,
      ),
      launch: launch,
      order: CourseOrder(
        id: 4,
        userId: 50,
        launchId: 1,
        status: OrderStatus.paid,
        kind: PaymentKind.full,
        priceFullKopecks: 1800000,
        amountPaidKopecks: 1800000,
        amountDueKopecks: 0,
        checkoutStartedAt: DateTime.utc(2026, 8, 10),
        accessGranted: true,
      ),
      access: ChannelAccess(
        id: 1,
        userId: 50,
        launchId: 1,
        orderId: 4,
        inviteLink: 'https://t.me/+secret',
        joinedAt: DateTime.utc(2026, 8, 15, 12, 40),
      ),
    );
    expect(joined, contains('ты в канале этого потока'));
    expect(joined, isNot(contains('https://t.me/+secret')));

    final cancelled = templates.profile(
      user: UserProfile(
        userId: 50,
        firstName: 'Анна',
        funnelPhase: FunnelPhase.cancelled,
        warmupOptOut: true,
        firstStartedAt: startedAt,
        lastSeenAt: startedAt,
      ),
      launch: launch,
      order: CourseOrder(
        id: 5,
        userId: 50,
        launchId: 1,
        status: OrderStatus.cancelled,
        kind: PaymentKind.full,
        priceFullKopecks: 1800000,
        amountPaidKopecks: 0,
        amountDueKopecks: 1800000,
        checkoutStartedAt: DateTime.utc(2026, 8, 10),
      ),
      access: ChannelAccess(
        id: 2,
        userId: 50,
        launchId: 1,
        orderId: 5,
        inviteLink: 'https://t.me/+old',
        revokedAt: DateTime.utc(2026, 8, 20),
      ),
    );
    expect(cancelled, contains('оплата отменена'));
    expect(cancelled, contains('ссылки в канал нет'));
    expect(cancelled, contains('прогрев выключен'));
    expect(cancelled, contains(MessageTemplates.buttonHelp));
    expect(cancelled, isNot(contains('https://t.me/+old')));
    expect(cancelled, isNot(contains('revokedAt')));
    expect(cancelled, isNot(contains('<b>Связь</b>')));
  });
}

List<String> _replyButtonTexts(Map<String, Object?> markup) {
  final rows = markup['keyboard'] as List<dynamic>? ?? const <dynamic>[];
  return <String>[
    for (final row in rows)
      for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
  ];
}
