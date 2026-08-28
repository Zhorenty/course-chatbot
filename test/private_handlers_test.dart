import 'dart:io';

import 'package:course_chatbot/src/bot/handlers/private/interaction_whitelist.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
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
    final courseOffer = harness.sender.messages.firstWhere((m) => m.text.contains('Поток с'));
    expect(_inlineButtonTexts(courseOffer.replyMarkup), isEmpty);
    final courseMenu = _replyButtonTexts(harness.sender.messages.last.replyMarkup);
    expect(courseMenu, contains(MessageTemplates.buttonEnroll));
    expect(courseMenu, contains(MessageTemplates.buttonGuide));

    harness.sender.messages.clear();
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 8, userId: 8, text: '/start threads_guide'),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isTrue);
  });

  test('later bare /start keeps the course card when source was a course payload', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 7, userId: 7, text: '/start tg_announce'),
    );
    harness.sender.messages.clear();
    await harness.handlers.handle(privateMessageUpdate(chatId: 7, userId: 7, text: '/start'));
    expect(harness.sender.messages.any((m) => m.text.contains('Поток с')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isFalse);
  });

  test('extra sheet payload with курс opens the course card', () async {
    final sheetsHarness = HandlerHarness();
    await sheetsHarness.init(enableSheets: true, botUsername: 'course_bot');
    addTearDown(sheetsHarness.dispose);
    await sheetsHarness.catalogSync!.sync();
    final tab = sheetsHarness.sheetsGateway!.sheets.firstWhere(
      (sheet) => sheet.title == LinksSheet.tabTitle,
    );
    sheetsHarness.sheetsGateway!.valuesBySheetId[tab.sheetId]!.add(
      LinksSheet.padded(const <Object?>['Таргет', 'курс', 'ads_course', '']),
    );
    await sheetsHarness.catalogSync!.sync();

    await sheetsHarness.handlers.handle(
      privateMessageUpdate(chatId: 21, userId: 21, text: '/start ads_course'),
    );
    expect(sheetsHarness.sender.messages.any((m) => m.text.contains('Поток с')), isTrue);

    sheetsHarness.sender.messages.clear();
    sheetsHarness.sheetsGateway!.valuesBySheetId[tab.sheetId]!.add(
      LinksSheet.padded(const <Object?>['Stories', 'гайд', 'ig_extra', '']),
    );
    await sheetsHarness.catalogSync!.sync();
    await sheetsHarness.handlers.handle(
      privateMessageUpdate(chatId: 22, userId: 22, text: '/start ig_extra'),
    );
    expect(sheetsHarness.sender.messages.any((m) => m.text.contains('без имени, почты')), isTrue);
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

  test('repeat /start after the guide restores guide, enroll and help', () async {
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
    harness.sender.messages.clear();
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    final texts = _replyButtonTexts(harness.sender.messages.single.replyMarkup);
    expect(texts, contains(MessageTemplates.buttonGuide));
    expect(texts, contains(MessageTemplates.buttonEnroll));
    expect(texts, contains(MessageTemplates.buttonHelp));
    expect(harness.sender.messages.single.text, contains('можно запросить снова'));
  });

  test('help callback opens help and does not escalate', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    harness.sender.messages.clear();
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'help',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbHelp,
      ),
    );
    expect(harness.sender.messages.single.text, contains('напиши сюда'));
    expect(harness.sender.forwards, isEmpty);
    final texts = _replyButtonTexts(harness.sender.messages.single.replyMarkup);
    expect(texts, contains(MessageTemplates.buttonGuide));
    expect(texts, contains(MessageTemplates.buttonHelp));
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
    final texts = _replyButtonTexts(
      harness.sender.messages.lastWhere((m) => m.replyMarkup != null).replyMarkup,
    );
    expect(texts, contains(MessageTemplates.buttonCourseStatus));
    expect(texts, isNot(contains(MessageTemplates.buttonEnroll)));
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
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.lead);
  });

  test('/start after invite without join resends the existing link', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    harness.course.setFunnelPhase(userId: 42, phase: FunnelPhase.accessGranted);
    final launch = harness.course.activeLaunch()!;
    harness.course.upsertAccess(
      userId: 42,
      launchId: launch.id,
      orderId: 1,
      inviteLink: 'https://t.me/+keep-me',
      inviteCreatedAt: DateTime.utc(2026, 10, 1),
    );
    harness.sender.messages.clear();
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    expect(harness.sender.messages.any((m) => m.text.contains('https://t.me/+keep-me')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('уже в канале')), isFalse);
    expect(harness.channel.created, isEmpty);
    expect(harness.channel.revoked, isEmpty);
    final reminder = harness.sender.messages.firstWhere(
      (m) => m.text.contains('https://t.me/+keep-me'),
    );
    expect(_inlineButtonTexts(reminder.replyMarkup), <String>[MessageTemplates.buttonOpenInvite]);
    expect(_inlineCallbackData(reminder.replyMarkup), isEmpty);
    final pin = _replyButtonTexts(harness.sender.messages.last.replyMarkup);
    expect(pin, contains(MessageTemplates.buttonCourseStatus));
    expect(pin, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(pin, contains(MessageTemplates.buttonGuide));
    expect(pin, contains(MessageTemplates.buttonHelp));
  });

  test('course status button shows paid amount, start date and remainder CTA', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.deposit,
    );
    harness.course.updateOrder(
      order.copyWith(
        status: OrderStatus.depositPaid,
        amountPaidKopecks: launch.depositKopecks,
        amountDueKopecks: launch.priceFullKopecks - launch.depositKopecks,
        dueAt: launch.depositDueAt,
      ),
    );
    harness.course.setFunnelPhase(userId: 42, phase: FunnelPhase.depositPaid);
    harness.sender.messages.clear();

    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: MessageTemplates.buttonCourseStatus),
    );
    final status = harness.sender.messages.single;
    expect(status.text, contains('предоплата'));
    expect(status.text, contains('5000 ₽'));
    expect(status.text, contains('13000 ₽'));
    expect(status.text, contains('05.10.2026'));
    expect(status.text, contains('12.10.2026'));
    expect(status.text, contains('ещё не начался'));
    expect(_inlineButtonTexts(status.replyMarkup), contains(MessageTemplates.buttonPayRemainder));

    harness.sender.messages.clear();
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    final pin = _replyButtonTexts(harness.sender.messages.last.replyMarkup);
    expect(pin, contains(MessageTemplates.buttonCourseStatus));
    expect(pin, isNot(contains(MessageTemplates.buttonEnroll)));
  });

  test('full payment swaps enroll for course status in the reply menu', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );
    final result = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.full,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
        amountKopecks: launch.priceFullKopecks,
      ),
      launch: launch,
    );
    harness.sender.messages.clear();
    await harness.handlers.notifyPaymentResult(result);

    expect(harness.sender.messages.any((m) => m.text.contains('Оплата прошла')), isTrue);
    final menu = harness.sender.messages.firstWhere(
      (m) => _replyButtonTexts(m.replyMarkup).contains(MessageTemplates.buttonCourseStatus),
    );
    expect(_replyButtonTexts(menu.replyMarkup), isNot(contains(MessageTemplates.buttonEnroll)));

    harness.sender.messages.clear();
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: MessageTemplates.buttonEnroll),
    );
    expect(harness.sender.messages.single.text, contains('Твой поток'));
    expect(harness.sender.messages.single.text, contains('закрыта'));
    expect(harness.sender.messages.single.text, isNot(contains('Запись на поток')));
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

  test('repeat /start after guide does not re-offer the first screen', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: '1',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGuide,
      ),
    );
    harness.sender.messages.clear();
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    expect(harness.sender.messages.any((m) => m.text.contains('Ты уже здесь')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('без имени, почты')), isFalse);
  });

  test('free-text help message is forwarded to admins', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    harness.sender.messages.clear();

    final handled = await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: 'касса зависла <b>test</b>'),
    );

    expect(handled, isTrue);
    final toAdmin = harness.sender.messages.where((m) => m.chatId == 1);
    expect(toAdmin, isNotEmpty);
    expect(toAdmin.first.text, contains('касса зависла'));
    expect(toAdmin.first.text, contains('&lt;b&gt;test&lt;/b&gt;'));
    expect(toAdmin.first.text, isNot(contains('<b>test</b>')));
    expect(toAdmin.first.text, contains('<code>42</code>'));
    expect(toAdmin.first.disableNotification, isFalse);
    expect(toAdmin.first.replyMarkup.toString(), contains('${MessageTemplates.cbAdminCard}42'));
    expect(harness.sender.forwards, hasLength(1));
    expect(harness.sender.forwards.single.chatId, 1);
    expect(harness.sender.forwards.single.fromChatId, 42);
    expect(harness.sender.forwards.single.messageId, 10);
    expect(
      harness.sender.messages.any((m) => m.chatId == 42 && m.text.contains('Передал админу')),
      isTrue,
    );
    expect(harness.sender.messages.any((m) => m.chatId == 42 && m.text.contains('Меню')), isFalse);
  });

  test('photo without caption is still forwarded to admin', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    harness.sender.messages.clear();

    await harness.handlers.handle(privatePhotoUpdate(chatId: 42, userId: 42));

    expect(harness.sender.messages.any((m) => m.chatId == 1 && m.text.contains('фото')), isTrue);
    expect(harness.sender.forwards.single.messageId, 11);
    expect(
      harness.sender.messages.any((m) => m.chatId == 42 && m.text.contains('Передал админу')),
      isTrue,
    );
  });

  test('ADMIN_CHAT_ID gets a copy in addition to admin user ids', () async {
    final extra = HandlerHarness();
    addTearDown(extra.dispose);
    await extra.init(adminUserIds: const <int>{1}, adminChatId: -100500);

    await extra.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    extra.sender.messages.clear();
    await extra.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: 'ссылка не открылась'),
    );

    expect(extra.sender.messages.where((m) => m.chatId == 1), isNotEmpty);
    expect(extra.sender.messages.where((m) => m.chatId == -100500), isNotEmpty);
    expect(extra.sender.forwards.map((f) => f.chatId), containsAll(<int>[1, -100500]));
  });

  test('help button does not escalate to admin', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    harness.sender.messages.clear();

    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: MessageTemplates.buttonHelp),
    );
    expect(harness.sender.messages.any((m) => m.text.contains('напиши сюда')), isTrue);
    expect(harness.sender.forwards, isEmpty);
    expect(harness.sender.messages.any((m) => m.chatId == 1), isFalse);
  });

  test('retired profile and menu entries do not escalate to admin', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    for (final command in <String>['👤 Профиль', '📋 Меню', '/profile', '/menu']) {
      harness.sender.messages.clear();
      await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: command));
      expect(harness.sender.messages.single.text, contains('Как это устроено'));
      expect(harness.sender.forwards, isEmpty);
      expect(harness.sender.messages.any((m) => m.chatId == 1), isFalse);
    }
  });

  test('/start offers the guide and pins the reply menu without inline duplicates', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start ig_reels_guide'),
    );
    expect(harness.sender.messages, hasLength(2));
    final offer = harness.sender.messages.first;
    expect(offer.text, contains('Гайд'));
    expect(offer.text, contains(MessageTemplates.buttonGuide));
    expect(offer.text, isNot(contains('<b>Профиль</b>')));
    expect(offer.text, isNot(contains('<b>Меню</b>')));
    expect(_inlineButtonTexts(offer.replyMarkup), isEmpty);
    final texts = _replyButtonTexts(harness.sender.messages.last.replyMarkup);
    expect(texts, contains(MessageTemplates.buttonEnroll));
    expect(texts, contains(MessageTemplates.buttonGuide));
    expect(texts, contains(MessageTemplates.buttonHelp));
    expect(texts, isNot(contains('👤 Профиль')));
    expect(texts, isNot(contains('📋 Меню')));
  });

  test('admin card button from incoming notice opens the person card', () async {
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 42, userId: 42, text: '/start', username: 'lead'),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'c',
        chatId: 1,
        userId: 1,
        data: '${MessageTemplates.cbAdminCard}42',
      ),
    );
    expect(
      harness.sender.messages.any((m) => m.chatId == 1 && m.text.contains('Карточка')),
      isTrue,
    );
  });

  test('client new-invite callback does not mint a channel link', () async {
    await harness.handlers.handle(privateMessageUpdate(chatId: 42, userId: 42, text: '/start'));
    harness.course.setFunnelPhase(userId: 42, phase: FunnelPhase.accessGranted);
    final launch = harness.course.activeLaunch()!;
    harness.course.upsertAccess(
      userId: 42,
      launchId: launch.id,
      orderId: 1,
      inviteLink: 'https://t.me/+keep-me',
      inviteCreatedAt: DateTime.utc(2026, 10, 1),
    );
    harness.sender.messages.clear();
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'ni',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbNewInvite,
      ),
    );
    expect(harness.channel.created, isEmpty);
    expect(harness.channel.revoked, isEmpty);
    expect(harness.sender.messages.any((m) => m.text.contains('админ')), isTrue);
    expect(harness.sender.messages.any((m) => m.text.contains('https://t.me/+')), isFalse);
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
