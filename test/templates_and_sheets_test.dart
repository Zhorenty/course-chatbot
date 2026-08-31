import 'package:course_chatbot/src/data/google_sheets_courses_catalog.dart';
import 'package:course_chatbot/src/data/google_sheets_funnel_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_links_catalog.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/admin_payment_status.dart';
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

  test('offer consent copy names the pay button and one combined checkbox', () {
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
    expect(templates.offerConsent(launch), contains('нажми галочку'));
    expect(templates.enrollOptions(launch), contains('Ссылку в канал пришлю после полной оплаты'));
    expect(templates.enrollOptions(launch), isNot(contains('В канал пущу')));
    final keyboard = templates.offerKeyboard(accepted: false);
    final rows = keyboard['inline_keyboard'] as List<dynamic>;
    expect(rows, hasLength(2));
    expect(rows[0].toString(), contains('☐'));
    expect(rows[0].toString(), contains(MessageTemplates.buttonAcceptConsent));
    expect(rows[1].toString(), contains('Перейти к оплате'));
    expect('☑️ ${MessageTemplates.buttonAcceptConsent}'.length, lessThanOrEqualTo(64));
    expect(templates.offerKeyboard(accepted: true)['inline_keyboard'].toString(), contains('☑️'));
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
    expect(flat, contains('Конверсия по источникам'));
    expect(flat, contains('Invite выдан, не вошли'));
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
    expect(look.columnCount, 5);
    expect(look.notes, hasLength(5));
    expect(look.notes[3].text, contains('атрибуции'));
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
              'Как это устроено\n\nСейчас: оформляешь оплату.\n\nДальше — гайд, запись на курс или помощь.',
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
    expect(text, contains('→ Как это устроено'));
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

  test('user reply keyboard swaps enroll for course status after payment', () {
    final templates = MessageTemplates();
    final texts = _replyButtonTexts(templates.userMenuKeyboard(showCourseStatus: false));
    expect(texts, contains(MessageTemplates.buttonEnroll));
    expect(texts, contains(MessageTemplates.buttonGuide));
    expect(texts, contains(MessageTemplates.buttonHelp));
    expect(texts, isNot(contains(MessageTemplates.buttonCourseStatus)));
    expect(texts, isNot(contains('👤 Профиль')));
    expect(texts, isNot(contains('📋 Меню')));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminSheets)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminLinks)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminSearch)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminMenu)));

    final paid = _replyButtonTexts(templates.userMenuKeyboard(showCourseStatus: true));
    expect(paid, contains(MessageTemplates.buttonCourseStatus));
    expect(paid, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(paid, contains(MessageTemplates.buttonGuide));
    expect(paid, contains(MessageTemplates.buttonHelp));
    expect(paid, isNot(contains('👤 Профиль')));
  });

  test('course status names payment, start and channel without a permanent invite', () {
    final templates = MessageTemplates();
    final launch = Launch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Запуск',
      priceFullKopecks: 1800000,
      depositKopecks: 500000,
      depositDueDays: 7,
      depositDueAt: DateTime.utc(2026, 10, 5),
      courseStartAt: DateTime.utc(2026, 10, 12),
    );
    final deposit = CourseOrder(
      id: 3,
      userId: 42,
      launchId: 1,
      status: OrderStatus.depositPaid,
      kind: PaymentKind.deposit,
      priceFullKopecks: 1800000,
      amountPaidKopecks: 500000,
      amountDueKopecks: 1300000,
      checkoutStartedAt: DateTime.utc(2026, 8, 10),
      dueAt: DateTime.utc(2026, 10, 5),
    );
    final beforeStart = templates.courseStatus(
      launch: launch,
      order: deposit,
      now: DateTime.utc(2026, 10, 1),
    );
    expect(beforeStart, contains('предоплата'));
    expect(beforeStart, contains('5000 ₽'));
    expect(beforeStart, contains('18000 ₽'));
    expect(beforeStart, contains('13000 ₽'));
    expect(beforeStart, contains('05.10.2026'));
    expect(beforeStart, contains('ещё не начался'));
    expect(beforeStart, contains('после полной суммы'));
    expect(beforeStart, contains('доплатить остаток'));
    expect(
      _inlineButtonTexts(templates.courseStatusKeyboard(order: deposit)!),
      contains(MessageTemplates.buttonPayRemainder),
    );

    final paid = deposit.copyWith(
      status: OrderStatus.paid,
      kind: PaymentKind.full,
      amountPaidKopecks: 1800000,
      amountDueKopecks: 0,
      accessGranted: true,
    );
    final unjoined = ChannelAccess(
      id: 1,
      userId: 42,
      launchId: 1,
      orderId: 3,
      inviteLink: 'https://t.me/+keep-me',
    );
    final waiting = templates.courseStatus(
      launch: launch,
      order: paid,
      access: unjoined,
      now: DateTime.utc(2026, 10, 1),
    );
    expect(waiting, contains('закрыта'));
    expect(waiting, contains('https://t.me/+keep-me'));
    expect(waiting, contains('входа пока нет'));
    expect(
      _inlineButtonTexts(templates.courseStatusKeyboard(order: paid, access: unjoined)!),
      <String>[MessageTemplates.buttonOpenInvite],
    );

    final joined = ChannelAccess(
      id: 1,
      userId: 42,
      launchId: 1,
      orderId: 3,
      inviteLink: 'https://t.me/+keep-me',
      joinedAt: DateTime.utc(2026, 10, 12),
    );
    final started = templates.courseStatus(
      launch: launch,
      order: paid,
      access: joined,
      now: DateTime.utc(2026, 10, 13),
    );
    expect(started, contains('идёт с 12.10.2026'));
    expect(started, contains('уже внутри'));
    expect(started, isNot(contains('https://t.me/+')));
    expect(templates.courseStatusKeyboard(order: paid, access: joined), isNull);
  });

  test('funnel inline keyboards do not repeat the reply menu', () {
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
    final enroll = _inlineButtonTexts(templates.enrollKeyboard(launch));
    expect(enroll, isNot(contains(MessageTemplates.buttonGuide)));
    expect(enroll, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(enroll, isNot(contains(MessageTemplates.buttonHelp)));
    expect(enroll, contains(MessageTemplates.buttonPayFull));
    expect(_inlineButtonTexts(templates.warmupKeyboard()), <String>[MessageTemplates.buttonOptOut]);
    expect(_inlineButtonTexts(templates.unjoinedInviteKeyboard('https://t.me/+x')), <String>[
      MessageTemplates.buttonOpenInvite,
    ]);
    expect(_inlineCallbackData(templates.unjoinedInviteKeyboard('https://t.me/+x')), isEmpty);
    expect(templates.inviteMessage('https://t.me/+x'), contains('напиши сюда'));
    expect(templates.inviteMessage('https://t.me/+x'), isNot(contains('запроси новую')));
    expect(templates.unjoinedInviteReminder('https://t.me/+x'), contains('https://t.me/+x'));
    expect(templates.unjoinedInviteReminder('https://t.me/+x'), isNot(contains('запроси новую')));
    expect(templates.help(), isNot(contains('Новая ссылка')));
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1)),
      contains(MessageTemplates.buttonAdminChangeStatus),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1)),
      contains(MessageTemplates.buttonAdminReinvite),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1)),
      isNot(contains(MessageTemplates.buttonAdminStatusPaid)),
    );
    final paidPicker = _inlineButtonTexts(
      templates.adminStatusKeyboard(1, AdminPaymentStatus.paid),
    );
    expect(paidPicker, contains(MessageTemplates.buttonAdminStatusUnpaid));
    expect(paidPicker, contains(MessageTemplates.buttonAdminStatusDeposit));
    expect(paidPicker, isNot(contains(MessageTemplates.buttonAdminStatusPaid)));
    expect(
      _inlineCallbackData(templates.adminStatusKeyboard(1, AdminPaymentStatus.paid)),
      contains(MessageTemplates.adminStatusSetData(AdminPaymentStatus.deposit, 1)),
    );
  });
}

List<String> _replyButtonTexts(Map<String, Object?> markup) {
  final rows = markup['keyboard'] as List<dynamic>? ?? const <dynamic>[];
  return <String>[
    for (final row in rows)
      for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
  ];
}

List<String> _inlineButtonTexts(Map<String, Object?> markup) {
  final rows = markup['inline_keyboard'] as List<dynamic>? ?? const <dynamic>[];
  return <String>[
    for (final row in rows)
      for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
  ];
}

List<String> _inlineCallbackData(Map<String, Object?> markup) {
  final rows = markup['inline_keyboard'] as List<dynamic>? ?? const <dynamic>[];
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
