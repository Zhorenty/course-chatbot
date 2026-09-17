import 'package:course_chatbot/src/data/google_sheets_courses_catalog.dart';
import 'package:course_chatbot/src/data/google_sheets_funnel_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_links_catalog.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/admin_payment_status.dart';
import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/catalog_admin.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
import 'package:course_chatbot/src/domain/launch_dozhim.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/sales_window.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/messages/funnel_media.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/messages/rich_html.dart';
import 'package:course_chatbot/src/telegram/input_rich_message.dart';
import 'package:test/test.dart';

import 'support/launch_fixture.dart';

void main() {
  test('classic HTML converts to rich headings paragraphs lists and tables', () {
    expect(richHtmlFromClassic('<h2>Already</h2><p>rich</p>'), '<h2>Already</h2><p>rich</p>');
    expect(
      richHtmlFromClassic('<b>Эфир</b>\n\nГайд уже у тебя.'),
      '<h2>Эфир</h2><p>Гайд уже у тебя.</p>',
    );
    expect(richHtmlFromClassic('• один\n• два'), '<ul><li>один</li><li>два</li></ul>');
    expect(
      richHtmlFromClassic('код: <code>a</code>\nцена: 1000 ₽'),
      '<table><tr><td>код</td><td><code>a</code></td></tr><tr><td>цена</td><td>1000 ₽</td></tr></table>',
    );
    expect(richHtmlFromClassic('Ссылка на оплату готова.'), '<p>Ссылка на оплату готова.</p>');
    expect(
      richHtmlFromClassic('Первый абзац\n\nВторой абзац'),
      '<p>Первый абзац<br><br>Второй абзац</p>',
    );
  });

  test('telegram blank lines become visible rich breaks not adjacent paragraphs', () {
    expect(
      richParagraphsFromTelegramHtml(
        'Скоро стартует мой курс по интерьерной колористике\n\n'
        'Я сообщу тебе, когда откроются продажи.',
      ),
      '<p>Скоро стартует мой курс по интерьерной колористике<br><br>'
      'Я сообщу тебе, когда откроются продажи.</p>',
    );
    expect(
      richParagraphsFromTelegramHtml(
        'Привет 🤍\n\n<b>Для начала подарок</b>\n<u>Особенно жду тебя</u>',
      ),
      '<p>Привет 🤍<br><br><b>Для начала подарок</b><br><u>Особенно жду тебя</u></p>',
    );
  });

  test('guide ready rich embeds the PDF and strips it for classic HTML', () {
    final templates = MessageTemplates();
    final rich = templates.guideReadyRich();
    expect(rich, contains('<tg-document src="tg://document?id=guide"></tg-document>'));
    expect(classicHtmlFromRich(rich), isNot(contains('tg-document')));
    expect(classicHtmlFromRich(rich), contains('Гайд «Язык цвета»'));
  });

  test('rich message media serializes file_id and local attach://', () {
    final byId = InputRichMessage(
      html: '<tg-document src="tg://document?id=guide"></tg-document>',
      media: <InputRichMessageMedia>[
        InputRichMessageMedia.document(id: 'guide', document: InputRichDocument.fileId('file-1')),
      ],
    );
    expect(byId.toJson()['media'], <Object?>[
      <String, Object?>{
        'id': 'guide',
        'media': <String, Object?>{'type': 'document', 'media': 'file-1'},
      },
    ]);
    final local = InputRichMessage(
      html: '<tg-document src="tg://document?id=guide"></tg-document>',
      media: <InputRichMessageMedia>[
        InputRichMessageMedia.document(
          id: 'guide',
          document: InputRichDocument.file(localPath: '/tmp/a.pdf', filename: 'a.pdf'),
        ),
      ],
    );
    final media = (local.toJson()['media'] as List<dynamic>).first as Map<String, Object?>;
    expect((media['media'] as Map<String, Object?>)['media'], 'attach://rich_guide');
  });

  test('bundled Drive photos map onto sheet steps', () {
    expect(FunnelMedia.pathsFor('start'), hasLength(1));
    expect(FunnelMedia.pathsFor('warmup_0'), hasLength(1));
    expect(FunnelMedia.pathsFor('webinar_24h'), FunnelMedia.pathsFor('warmup_0'));
    expect(FunnelMedia.pathsFor('webinar_next'), hasLength(2));
    expect(FunnelMedia.pathsFor('sales_open'), FunnelMedia.pathsFor('webinar_next'));
    expect(FunnelMedia.pathsFor('paid'), hasLength(1));
    expect(FunnelMedia.pathsFor('dozhim_d1'), hasLength(9));
    expect(FunnelMedia.pathsFor('dozhim_d2'), hasLength(1));
    expect(FunnelMedia.pathsFor('dozhim_d3'), hasLength(5));
    expect(FunnelMedia.pathsFor('dozhim_d4'), hasLength(1));
    expect(FunnelMedia.pathsFor('enroll_d1'), isEmpty);
    expect(FunnelMedia.pathsFor('start', root: '/tmp/missing-funnel-media'), isEmpty);
    expect(richPhotoBlock(const <String>['p0']), '<img src="tg://photo?id=p0"/>');
    expect(
      richPhotoBlock(const <String>['p0', 'p1']),
      '<tg-slideshow><img src="tg://photo?id=p0"/><img src="tg://photo?id=p1"/></tg-slideshow>',
    );
    final photo = InputRichMessageMedia.photo(
      id: 'p0',
      document: InputRichDocument.file(localPath: 'assets/funnel/welcome.jpg'),
    );
    expect(photo.toJson()['media'], <String, Object?>{
      'type': 'photo',
      'media': 'attach://rich_p0',
    });
  });

  test('retired enroll nudges have no copy', () {
    final templates = MessageTemplates();
    expect(templates.warmupStep('enroll_d1'), isEmpty);
    expect(templates.warmupStep('enroll_d3'), isEmpty);
    expect(templates.warmupStep('last_wagon'), isEmpty);
  });

  test('admin funnel logic stays under Telegram message limit', () {
    final text = MessageTemplates().adminFunnelLogic();
    expect(text.length, lessThan(4096));
    expect(text, contains('Как устроена воронка'));
    expect(text, contains('Аккаунты админов'));
  });

  test('customer copy uses the interior color voice and new CTAs', () {
    final templates = MessageTemplates();
    expect(MessageTemplates.buttonGuide, 'Получить гайд');
    expect(MessageTemplates.buttonEnroll, MessageTemplates.buttonCourseStatus);
    expect(MessageTemplates.buttonEnroll, contains('Цвет в интерьере'));
    expect(templates.startGuideOffer(), contains('Привет'));
    expect(templates.startGuideOffer(), isNot(contains('<b>Привет')));
    expect(
      templates.startGuideOffer(),
      contains('<b>Для начала у меня для тебя подарок — гайд «Язык цвета».</b>'),
    );
    expect(templates.startGuideOfferRich(), contains('<br><br>А это мой бот-помощник'));
    expect(templates.startGuideOffer(), contains('Анастасия Дубовскова'));
    expect(templates.startGuideOffer(), isNot(contains('без имени, почты')));
    expect(templates.warmupStep('warmup_0'), contains('мастер-класс'));
    expect(templates.warmupStep('last_wagon'), isEmpty);
    expect(templates.optOutConfirmed(), contains('отписались'));
    expect(templates.help(), isNot(contains('Гайд не пришёл')));
    expect(templates.paymentSucceeded(), contains('Успешная оплата'));
  });

  test('selling drip uses interior voice not wardrobe stubs', () {
    final templates = MessageTemplates();
    final launch = testLaunch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Цвет в интерьере. Основы и практика',
      priceFullKopecks: 1900000,
      depositKopecks: 500000,
      depositDueDays: 7,
      courseStartAt: DateTime.utc(2026, 10, 12),
    );
    const keys = <String>[
      'enroll_d1',
      'enroll_d3',
      'sales_open',
      'sales_regular',
      'dozhim_d1',
      'dozhim_d2',
      'dozhim_d3',
      'dozhim_d4',
      'warmup_d1',
      'warmup_d3',
      'warmup_d7',
      'warmup_start_d1',
    ];
    for (final key in keys) {
      final text = templates.warmupStep(key, launch: launch);
      expect(text, isNot(contains('гардероб')), reason: key);
      expect(text, isNot(contains('коже')), reason: key);
      expect(text, isNot(contains('Сюда встанет')), reason: key);
      expect(text, isNot(contains('Можно оплатить')), reason: key);
      expect(text, isNot(contains('Продажи открылись')), reason: key);
    }
    expect(templates.warmupStep('sales_regular', launch: launch), contains('19 000 руб.'));
    expect(templates.warmupStep('webinar_next', launch: launch), contains('21 000 руб.'));
    expect(
      templates.warmupStep('webinar_next', launch: launch),
      contains('<b>специальные условия</b>'),
    );
    expect(
      templates.warmupStep('webinar_next', launch: launch),
      contains('<i>Запись мастер-класса:</i>'),
    );
    expect(templates.warmupStep('warmup_0', launch: launch), contains('<u>Особенно жду тебя'));
    expect(
      templates.warmupStep('warmup_0', launch: launch),
      contains('<b>«Как начать работать с цветом смелее и не бояться ошибиться»</b>'),
    );
    expect(templates.warmupStep('dozhim_d1', launch: launch), contains('12 октября'));
    expect(templates.warmupStep('dozhim_d1', launch: launch), contains('Иттена'));
    expect(templates.warmupStep('dozhim_d2', launch: launch), contains('Чувство цвета'));
    expect(
      templates.warmupStep('dozhim_d2', launch: launch),
      contains('Большая авторская программа'),
    );
    expect(templates.warmupStep('dozhim_d2', launch: launch), isNot(contains('очередной курс')));
    expect(templates.warmupStep('dozhim_d4', launch: launch), contains('Pinterest'));
    expect(templates.warmupStep('warmup_d1'), isEmpty);
    for (final key in keys) {
      expect(templates.warmupStep(key, launch: launch).length, lessThan(4096), reason: key);
    }
    expect(templates.warmupStep('webinar_next', launch: launch).length, lessThan(4096));
    expect(
      _inlineButtonTexts(templates.warmupKeyboard('sales_open', launch: launch, rsvp: false)!),
      contains(MessageTemplates.buttonEnrollInline),
    );
    expect(
      _inlineButtonTexts(templates.warmupKeyboard('dozhim_d1', launch: launch, rsvp: false)!),
      contains(MessageTemplates.buttonEnrollInline),
    );
    expect(templates.warmupKeyboard('enroll_d1', launch: launch, rsvp: false), isNull);
    expect(
      _inlineButtonTexts(templates.warmupKeyboard('dozhim:12', launch: launch, rsvp: false)!),
      contains(MessageTemplates.buttonEnrollInline),
    );
    expect(templates.warmupStep('last_wagon', launch: launch), isEmpty);
  });

  test('enroll copy still points to the channel after full payment', () {
    final templates = MessageTemplates();
    final launch = testLaunch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Запуск',
      priceFullKopecks: 1900000,
      pricePromoKopecks: 1500000,
      depositKopecks: 500000,
      depositDueDays: 7,
      webinarAt: DateTime.utc(2020, 1, 1),
    );
    final quote = LaunchSales.quote(launch, rsvp: false, now: DateTime.utc(2026, 9, 8));
    expect(
      templates.enrollOptions(launch, quote: quote),
      contains('Ссылка в канал курса придет в этот чат после полной оплаты'),
    );
    expect(templates.enrollOptions(launch, quote: quote), contains('16 уроков + эфир'));
    expect(templates.enrollOptions(launch, quote: quote), contains('<s>23 000 ₽</s>'));
    expect(templates.enrollOptions(launch, quote: quote), isNot(contains('В канал пущу')));
    expect(templates.warmupStep('sales_open', launch: launch), contains('открывает свои двери'));
    expect(templates.warmupStep('sales_open', launch: launch), contains('16 уроков'));
    expect(
      templates.warmupStep('sales_open', launch: launch),
      isNot(contains('Продажи открылись')),
    );
  });

  test('empty launch fields keep CTAs honest and do not hide RSVP', () {
    final templates = MessageTemplates();
    final launch = testLaunch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Цвет в интерьере',
      priceFullKopecks: 1900000,
      pricePromoKopecks: 1500000,
      depositKopecks: 500000,
      depositDueDays: 7,
      courseStartAt: DateTime.utc(2026, 10, 12),
      webinarAt: DateTime.utc(2026, 10, 5, 16),
    );
    final quote = LaunchSales.quote(launch, rsvp: false, now: DateTime.utc(2026, 9, 15, 12));
    final card = templates.enrollOptions(launch, quote: quote);
    expect(card, contains('Нажимай на кнопку внизу'));
    expect(card, contains('Мастер-класс пройдет'));
    expect(
      _inlineButtonTexts(templates.enrollKeyboard(launch, quote: quote, rsvpOpen: true)),
      contains(MessageTemplates.buttonRsvpEnroll),
    );

    final afterRsvp = LaunchSales.quote(launch, rsvp: true, now: DateTime.utc(2026, 9, 15, 12));
    final listed = templates.enrollOptions(launch, quote: afterRsvp);
    expect(listed, contains('уже в списке'));
    expect(listed, isNot(contains('Нажимай на кнопку внизу')));
    expect(
      _inlineButtonTexts(
        templates.enrollKeyboard(launch, quote: afterRsvp, rsvpOpen: true, webinarStarted: true),
      ),
      isEmpty,
    );

    final live = testLaunch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Цвет в интерьере',
      priceFullKopecks: 1900000,
      pricePromoKopecks: 1500000,
      depositKopecks: 500000,
      depositDueDays: 7,
      courseStartAt: DateTime.utc(2026, 10, 12),
      webinarAt: DateTime.utc(2026, 10, 5, 16),
      webinarUrl: 'https://example.com/live',
      salesStartAt: DateTime.utc(2026, 10, 20, 16),
    );
    expect(
      _inlineButtonTexts(
        templates.enrollKeyboard(
          live,
          quote: LaunchSales.quote(live, rsvp: true, now: DateTime.utc(2026, 10, 5, 16)),
          webinarStarted: true,
        ),
      ),
      contains(MessageTemplates.buttonJoinWebinar),
    );

    final promoOpen = testLaunch(
      id: 3,
      productId: 1,
      code: 'launch-3',
      title: 'Цвет в интерьере',
      priceFullKopecks: 1900000,
      pricePromoKopecks: 1500000,
      depositKopecks: 500000,
      depositDueDays: 7,
      webinarAt: DateTime.utc(2026, 10, 5, 16),
      salesStartAt: DateTime.utc(2026, 10, 5, 16),
    );
    final promoQuote = LaunchSales.quote(
      promoOpen,
      rsvp: false,
      now: DateTime.utc(2026, 10, 5, 17),
    );
    expect(promoQuote.checkoutOpen, isTrue);
    expect(
      templates.enrollOptions(promoOpen, quote: promoQuote, rsvpOpen: true),
      contains('специальную цену'),
    );
    expect(
      _inlineButtonTexts(templates.enrollKeyboard(promoOpen, quote: promoQuote, rsvpOpen: true)),
      contains(MessageTemplates.buttonRsvpEnroll),
    );
    expect(
      _inlineButtonTexts(
        templates.enrollKeyboard(promoOpen, quote: promoQuote, rsvpOpen: true),
      ).any((text) => text.startsWith(MessageTemplates.buttonPayFull)),
      isTrue,
    );
    final closed = testLaunch(
      id: 4,
      productId: 1,
      code: 'launch-4',
      title: 'Цвет в интерьере',
      priceFullKopecks: 1900000,
      depositKopecks: 500000,
      depositDueDays: 7,
      webinarAt: DateTime.utc(2026, 10, 5, 16),
      salesStartAt: DateTime.utc(2026, 10, 5, 16),
      salesEndAt: DateTime.utc(2026, 10, 10),
    );
    expect(
      _inlineButtonTexts(
        templates.enrollKeyboard(
          closed,
          quote: LaunchSales.quote(closed, rsvp: false, now: DateTime.utc(2026, 10, 20)),
          rsvpOpen: false,
          continueOrderId: 9,
        ),
      ),
      contains(MessageTemplates.buttonContinuePay),
    );

    expect(templates.warmupStep('warmup_0', launch: launch), isNot(contains('ХХ:ХХ')));
    expect(templates.warmupStep('warmup_0', launch: launch), contains('прикрепим позже'));
    expect(templates.warmupStep('webinar_live', launch: launch), contains('прикрепим позже'));
    expect(templates.webinarRsvpConfirmed(launch, showLink: false), contains('прикрепим позже'));
  });

  test('course card keeps general copy and prints launch facts as parameters', () {
    final templates = MessageTemplates();
    final launch = testLaunch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Цвет в интерьере. Основы и практика',
      priceFullKopecks: 1900000,
      pricePromoKopecks: 1500000,
      depositKopecks: 500000,
      depositDueDays: 7,
      courseStartAt: DateTime.utc(2026, 10, 12),
      webinarAt: DateTime.utc(2026, 10, 5, 16),
    );
    final quote = LaunchSales.quote(launch, rsvp: true, now: DateTime.utc(2026, 9, 15, 12));
    final card = templates.enrollOptions(launch, quote: quote);
    expect(card, contains('Скоро стартует мой курс по интерьерной колористике'));
    expect(card, contains('Старт потока 12 октября'));
    expect(card, contains('<u>Я сообщу тебе, когда откроются продажи по самой выгодной цене.</u>'));
    expect(card, contains('<b>бесплатный Мастер-класс'));
    expect(card, contains('📅 Мастер-класс пройдет 5 октября в 19:00 мск'));
    expect(card, contains('уже в списке'));
    expect(card, isNot(contains('Ссылку прикрепим позже')));
    expect(templates.startCourseCard(launch: launch), contains('Старт потока 12 октября'));

    final custom = testLaunch(
      id: 2,
      productId: 1,
      code: 'launch-2',
      title: 'Цвет в интерьере. Основы и практика',
      priceFullKopecks: 1900000,
      depositKopecks: 0,
      depositDueDays: 7,
      courseStartAt: DateTime.utc(2026, 10, 12),
      webinarUrl: 'https://example.com/live',
      description: 'Мой поток про цвет в квартирах.',
    );
    final customCard = templates.startCourseCard(launch: custom);
    expect(customCard, contains('Мой поток про цвет в квартирах.'));
    expect(customCard, isNot(contains('Скоро стартует мой курс')));
    expect(customCard, contains('📅 Мастер-класс пройдет 29 сентября в 19:00 мск'));

    final marked = testLaunch(
      id: 3,
      productId: 1,
      code: 'launch-3',
      title: 'Цвет в интерьере. Основы и практика',
      priceFullKopecks: 1900000,
      depositKopecks: 0,
      depositDueDays: 7,
      description: '<b>Цвет</b>\nи практика\n\nвторой абзац',
    );
    final markedCard = templates.startCourseCard(launch: marked);
    expect(markedCard, contains('<b>Цвет</b>'));
    expect(markedCard, isNot(contains('&lt;b&gt;')));
    expect(
      templates.startCourseCardRich(launch: marked),
      contains('<b>Цвет</b><br>и практика<br><br>второй абзац<br><br>'),
    );
    expect(
      templates.startCourseCardRich(launch: launch),
      contains(
        '<p>Курс "Цвет в интерьере" 🎨<br><br>'
        'Скоро стартует мой курс по интерьерной колористике<br>'
        'Старт потока 12 октября. '
        '<u>Я сообщу тебе, когда откроются продажи по самой выгодной цене.</u><br><br>',
      ),
    );

    final laidOut = testLaunch(
      id: 4,
      productId: 1,
      code: 'launch-4',
      title: 'Цвет в интерьере. Основы и практика',
      priceFullKopecks: 1900000,
      depositKopecks: 0,
      depositDueDays: 7,
      description: 'Первый абзац\n\n\tвторой  с отступом',
    );
    expect(
      templates.startCourseCard(launch: laidOut),
      contains('\n&nbsp;&nbsp;&nbsp;&nbsp;второй'),
    );
    expect(templates.startCourseCard(launch: laidOut), contains('второй &nbsp;с отступом'));
    final laidOutRich = templates.startCourseCardRich(launch: laidOut);
    expect(
      laidOutRich,
      contains('Первый абзац<br><br>&nbsp;&nbsp;&nbsp;&nbsp;второй &nbsp;с отступом<br><br>'),
    );
    final laidOutQuote = LaunchSales.quote(laidOut, rsvp: false, now: DateTime.utc(2026, 9, 15));
    expect(laidOutQuote.phase, SalesPhase.preSales);
    expect(
      templates.enrollOptionsRich(laidOut, quote: laidOutQuote),
      contains('Первый абзац<br><br>&nbsp;&nbsp;&nbsp;&nbsp;второй &nbsp;с отступом'),
    );
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
    expect(flat, contains('Отметились на эфир'));
    expect(flat, contains('Нажали «Записаться»'));
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
    expect(look.columnWidthsPx, hasLength(17));
    expect(look.columnCount, 17);
    expect(look.notes, hasLength(17));
    expect(look.notes[8].text, contains('Выбери в календаре'));
    expect(look.notes[14].text, contains('шаблон'));
    expect(look.notes.last.text, contains('пустая'));
    expect(look.validations, isNotEmpty);
    expect(look.validations.first.clear, isTrue);
    expect(look.validations.first.endColumnExclusive, 17);
    final depositCol = CoursesSheet.headers.indexOf(CoursesSheet.depositRub);
    expect(
      look.validations.where((rule) => !rule.clear).every((rule) => rule.startColumn != depositCol),
      isTrue,
    );
    expect(
      look.validations.where((rule) => !rule.clear).map((rule) => rule.startColumn),
      containsAll(<int>[
        CoursesSheet.headers.indexOf(CoursesSheet.isActive),
        CoursesSheet.headers.indexOf(CoursesSheet.courseStartDate),
        CoursesSheet.headers.indexOf(CoursesSheet.salesEndDate),
      ]),
    );
    expect(
      look.validations.where((rule) => !rule.clear).map((rule) => rule.startColumn),
      isNot(contains(CoursesSheet.headers.indexOf(CoursesSheet.productCode))),
    );
    expect(
      look.validations.where((rule) => !rule.clear).map((rule) => rule.startColumn),
      isNot(contains(CoursesSheet.headers.indexOf(CoursesSheet.productTitle))),
    );
    expect(
      look.validations.any(
        (rule) =>
            !rule.clear &&
            rule.conditionType == 'BOOLEAN' &&
            rule.startColumn == CoursesSheet.headers.indexOf(CoursesSheet.isActive) &&
            rule.conditionValues.first == CoursesSheet.activeYes,
      ),
      isTrue,
    );
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
    expect(look.notes[3].text, contains('каталога'));
    expect(look.notes.last.text, contains('t.me'));
    expect(look.validations, hasLength(2));
    expect(look.validations.first.conditionType, 'ONE_OF_LIST');
    expect(look.validations.first.conditionValues, <String>['гайд', 'курс']);
    expect(look.validations.last.conditionType, 'ONE_OF_RANGE');
    expect(look.validations.last.conditionValues.single, LinksSheet.launchDropdownFormula());
    expect(look.validations.last.conditionValues.single, contains(CoursesSheet.tabTitle));
    expect(look.validations.last.conditionValues.single, contains('\$D\$'));
    final named = GoogleSheetsLinksCatalog.build(
      coursesSheetTitle: 'КУРСЫ',
      launchTitles: const <String>['Первый запуск'],
    );
    expect(named.validations.last.conditionType, 'ONE_OF_LIST');
    expect(named.validations.last.conditionValues, <String>['Первый запуск']);
    expect(LinksSheet.launchDropdownFormula(coursesSheetTitle: 'КУРСЫ'), contains("'КУРСЫ'"));
    expect(LinksSheet.extraDataRows, greaterThanOrEqualTo(24));
    expect(look.rowCount, greaterThanOrEqualTo(LinksSheet.defaultHeaderRow + 1 + 24));
  });

  test('admin search prompt lists id and username', () {
    final text = MessageTemplates().adminAskSearch();
    expect(text, contains('<b>Поиск человека</b>'));
    expect(text, contains('Пришли id'));
    expect(text, contains('id'));
    expect(text, contains('или @username'));
  });

  test('admin add prompt asks for numeric id or a forwarded message', () {
    final text = MessageTemplates().adminAskAddUser();
    expect(text, contains('<b>Добавить на курс</b>'));
    expect(text, contains('id'));
    expect(text, contains('переслать'));
    expect(text, contains('Человеку сразу не пишу'));
  });

  test('admin sheets refresh result is a structured card', () {
    final launch = testLaunch(
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

  test('admin progress copy is a short wait hint', () {
    final templates = MessageTemplates();
    expect(templates.adminSheetsRefreshing(), contains('Обновляю таблицу'));
    expect(templates.adminDeepLinksRefreshing(), contains(LinksSheet.tabTitle));
  });

  test('admin deep-link copy without username does not invent t.me URLs', () {
    final text = MessageTemplates().adminDeepLinks(AcquisitionLink.starters);
    expect(text, contains('неизвестен'));
    expect(text, isNot(contains('https://t.me/')));
    expect(text, contains('ig_reels_guide'));
  });

  test('admin reply keyboard is admin-only and includes sheets refresh', () {
    final templates = MessageTemplates();
    final keyboard = templates.adminMenuKeyboard();
    final texts = _replyButtonTexts(keyboard);
    expect(texts, <String>[
      MessageTemplates.buttonAdminSearch,
      MessageTemplates.buttonAdminSheetsHub,
      MessageTemplates.buttonAdminFunnelLogic,
      MessageTemplates.buttonAdminBroadcast,
      MessageTemplates.buttonAdminClearFunnel,
    ]);
    expect(texts, isNot(contains(MessageTemplates.buttonAdminAddUser)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminCatalogNew)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminCatalog)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminLinks)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminSheets)));
    final rows = keyboard['keyboard'] as List<dynamic>;
    expect(rows, hasLength(3));
    expect(
      <List<String>>[
        for (final row in rows)
          <String>[for (final cell in row as List<dynamic>) (cell as Map)['text'] as String],
      ],
      <List<String>>[
        <String>[MessageTemplates.buttonAdminSearch, MessageTemplates.buttonAdminSheetsHub],
        <String>[MessageTemplates.buttonAdminFunnelLogic, MessageTemplates.buttonAdminBroadcast],
        <String>[MessageTemplates.buttonAdminClearFunnel],
      ],
    );
    expect(texts, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(texts, isNot(contains(MessageTemplates.buttonGuide)));
    expect(texts, isNot(contains(MessageTemplates.buttonHelp)));
  });

  test('admin catalog inline callbacks stay short', () {
    final launch = testLaunch(
      id: 12,
      productId: 1,
      code: 'launch-1',
      title: 'Запуск',
      priceFullKopecks: 1800000,
      depositKopecks: 0,
      depositDueDays: 7,
      isActive: true,
    );
    final templates = MessageTemplates();
    final data = <String>[
      ..._inlineCallbackData(templates.adminCatalogListKeyboard(<Launch>[launch])),
      ..._inlineCallbackData(templates.adminCatalogCardKeyboard(launch)),
      ..._inlineCallbackData(templates.adminCatalogFieldsKeyboard(launch.id)),
      ..._inlineCallbackData(templates.adminCatalogKeepCodeKeyboard()),
      ..._inlineCallbackData(templates.adminCatalogKeepSuggestedKeyboard()),
      ..._inlineCallbackData(templates.adminCatalogBackToCardKeyboard(12)),
      ..._inlineCallbackData(templates.adminCatalogSkipChannelKeyboard()),
      ..._inlineCallbackData(templates.adminCatalogSkipOptionalKeyboard()),
    ];
    expect(data, isNotEmpty);
    expect(data.every((item) => item.length <= 64), isTrue);
    expect(data, contains(MessageTemplates.cbCatalogNew));
    expect(data, contains('${MessageTemplates.cbCatalogOpen}12'));
    expect(data, contains(MessageTemplates.catalogFieldData(12, CatalogLaunchField.price)));
    expect(data, contains(MessageTemplates.catalogFieldData(12, CatalogLaunchField.salesStart)));
    expect(data, contains(MessageTemplates.catalogFieldData(12, CatalogLaunchField.guide)));
    expect(data, contains(MessageTemplates.cbCatalogKeepCode));
    expect(data, contains(MessageTemplates.cbCatalogSkipOptional));
    expect(templates.adminCatalogCard(launch), contains('гайд: нет'));
    expect(templates.adminCatalogCard(launch), contains('описание: шаблон'));
    expect(templates.adminCatalogCard(launch), contains('дожим: нет'));
    expect(data, contains(MessageTemplates.catalogFieldData(12, CatalogLaunchField.description)));
    expect(templates.adminCatalogCard(launch, dozhimCount: 2), contains('дожим: 2 дня'));
    expect(data, contains('${MessageTemplates.cbCatalogDozhim}12'));
    expect(
      _inlineCallbackData(
        templates.adminCatalogDozhimListKeyboard(12, const <LaunchDozhimMessage>[]),
      ),
      contains('${MessageTemplates.cbCatalogDozhimAdd}12'),
    );
    expect(templates.adminCatalogDozhimAsk(dayIndex: 1, replace: false), contains('альбом'));
    expect(templates.adminCatalogDozhimAsk(dayIndex: 1, replace: false), contains('можно удалить'));
    expect(
      templates.adminCatalogDozhimList(launch, const <LaunchDozhimMessage>[]),
      contains('можно удалить'),
    );
    expect(templates.broadcastContentKindLabel(BroadcastContentKind.album), 'альбом');
    expect(templates.broadcastContentKindLabel(BroadcastContentKind.location), 'геолокация');
    expect(
      templates.adminCatalogGuideButton(launch),
      MessageTemplates.buttonAdminCatalogAttachGuide,
    );
    final withGuide = testLaunch(
      id: 12,
      productId: 1,
      code: 'launch-1',
      title: 'Запуск',
      priceFullKopecks: 1800000,
      depositKopecks: 0,
      depositDueDays: 7,
      isActive: true,
      leadMagnetFileId: 'file-1',
    );
    expect(templates.adminCatalogCard(withGuide), contains('гайд: есть'));
    expect(
      templates.adminCatalogGuideButton(withGuide),
      MessageTemplates.buttonAdminCatalogReplaceGuide,
    );
    expect(templates.adminCatalogAskField(CatalogLaunchField.guide), contains('PDF'));
  });

  test('admin catalog channel prompt requires a Telegram id', () {
    final templates = MessageTemplates();
    expect(templates.adminCatalogAskChannel(), contains('Обязательно'));
    expect(
      templates.adminCatalogAskChannel(),
      isNot(contains(MessageTemplates.buttonAdminCatalogSkipChannel)),
    );
    expect(templates.adminCatalogAskChannel(), isNot(contains('Пусто')));
    expect(templates.adminCatalogAskField(CatalogLaunchField.channel), isNot(contains('Пусто')));
    expect(templates.adminCatalogAskField(CatalogLaunchField.channel), contains('Обязательно'));
    expect(
      templates.adminCatalogFieldError(CatalogFieldError.badChannel),
      isNot(contains(MessageTemplates.buttonAdminCatalogSkipChannel)),
    );
  });

  test('admin catalog create wizard starts with product fields', () {
    final templates = MessageTemplates();
    expect(templates.adminCatalogAskProductCode('course'), contains('Шаг 1 из 15'));
    expect(templates.adminCatalogAskProductCode('course'), contains('Код продукта'));
    expect(templates.adminCatalogAskProductTitle('Курс'), contains('Шаг 2 из 15'));
    expect(templates.adminCatalogAskActive(), contains('Шаг 15 из 15'));
    final preview = templates.adminCatalogPreview(
      testDraft(
        productCode: 'color',
        productTitle: 'Колористика',
        launchCode: 'nov-26',
        launchTitle: 'Ноябрь',
        isActive: false,
        priceFullKopecks: 2000000,
        depositKopecks: 0,
      ),
    );
    expect(preview, contains('код продукта'));
    expect(preview, contains('color'));
    expect(preview, contains('Колористика'));
  });

  test('admin sheets hub keyboard nests catalog, links and refresh', () {
    final templates = MessageTemplates();
    final rows = templates.adminSheetsHubKeyboard()['keyboard'] as List<dynamic>;
    expect(
      <List<String>>[
        for (final row in rows)
          <String>[for (final cell in row as List<dynamic>) (cell as Map)['text'] as String],
      ],
      <List<String>>[
        <String>[MessageTemplates.buttonAdminCatalog, MessageTemplates.buttonAdminLinks],
        <String>[MessageTemplates.buttonAdminSheets],
        <String>[MessageTemplates.buttonAdminBack],
      ],
    );
  });

  test('admin links inline callbacks stay short and card escapes origin', () {
    const link = AcquisitionLink(
      origin: 'Reels <b>',
      destination: AcquisitionDestination.guide,
      payload: 'ig_reels_guide',
    );
    final launch = testLaunch(
      id: 12,
      productId: 1,
      code: 'launch-1',
      title: 'Запуск',
      priceFullKopecks: 1800000,
      depositKopecks: 0,
      depositDueDays: 7,
      isActive: true,
    );
    final templates = MessageTemplates(botUsername: 'bot&x');
    final data = <String>[
      ..._inlineCallbackData(
        templates.adminLinksListKeyboard(const <AcquisitionLink>[link], canWrite: true),
      ),
      ..._inlineCallbackData(templates.adminLinksCardKeyboard(0, canWrite: true)),
      ..._inlineCallbackData(templates.adminLinksFieldsKeyboard(0)),
      ..._inlineCallbackData(templates.adminLinksDestinationKeyboard()),
      ..._inlineCallbackData(templates.adminLinksLaunchKeyboard(<Launch>[launch])),
    ];
    expect(data, isNotEmpty);
    expect(data.every((item) => item.length <= 64), isTrue);
    expect(data, contains(MessageTemplates.cbLinksNew));
    expect(data, contains('${MessageTemplates.cbLinksOpen}0'));
    expect(data, contains(MessageTemplates.linksFieldData(0, CatalogLinkField.origin)));
    expect(data, contains(MessageTemplates.cbLinksSkipLaunch));
    expect(data, contains('${MessageTemplates.cbLinksPickLaunch}12'));
    expect(templates.adminLinksCard(link), contains('Reels &lt;b&gt;'));
    expect(templates.adminLinksCard(link), contains('https://t.me/bot&amp;x?start=ig_reels_guide'));
    expect(templates.adminLinksCard(link), isNot(contains('Reels <b>')));
  });

  test('admin clear-funnel copy asks to confirm', () {
    final templates = MessageTemplates();
    expect(templates.adminAskClearFunnel(), contains('Сотру людей'));
    expect(templates.adminFunnelCleared(people: 3), contains('3'));
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

  test('broadcast segment keyboard can mark several selected sections', () {
    final templates = MessageTemplates();
    final counts = <BroadcastSegment, int>{
      for (final segment in BroadcastSegment.values) segment: 0,
    };
    final empty = templates.broadcastSegmentKeyboard(counts);
    final emptyTexts = <String>[
      for (final row in empty['inline_keyboard'] as List<dynamic>)
        for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
    ];
    expect(emptyTexts, contains(MessageTemplates.buttonAdminBroadcastSelectAll));
    expect(emptyTexts, isNot(contains(MessageTemplates.buttonAdminBroadcastContinue)));
    expect(emptyTexts.join(), isNot(contains('✓')));

    final selected = templates.broadcastSegmentKeyboard(
      counts,
      selected: <BroadcastSegment>{BroadcastSegment.guideNotPaid, BroadcastSegment.depositPaid},
    );
    final selectedTexts = <String>[
      for (final row in selected['inline_keyboard'] as List<dynamic>)
        for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
    ];
    expect(
      selectedTexts,
      contains('✓ ${templates.broadcastSegmentButton(BroadcastSegment.guideNotPaid, 0)}'),
    );
    expect(selectedTexts, contains(MessageTemplates.buttonAdminBroadcastContinue));
    expect(selectedTexts, contains(MessageTemplates.buttonAdminBroadcastSelectAll));
    expect(templates.adminBroadcastPickSegment(counts), contains('Можно несколько сегментов'));

    final all = templates.broadcastSegmentKeyboard(
      counts,
      selected: BroadcastSegment.values.toSet(),
    );
    final allTexts = <String>[
      for (final row in all['inline_keyboard'] as List<dynamic>)
        for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
    ];
    expect(allTexts, contains(MessageTemplates.buttonAdminBroadcastClearAll));
    expect(allTexts, isNot(contains(MessageTemplates.buttonAdminBroadcastSelectAll)));
    expect(templates.broadcastSegmentsLabel(BroadcastSegment.values), 'все сегменты');
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

  test('admin funnel event copy names the person and does not leak the invite', () {
    final templates = MessageTemplates();
    final user = UserProfile(
      userId: 42,
      username: 'masha',
      firstName: 'Маша',
      source: 'ig_reels_guide',
      funnelPhase: FunnelPhase.warming,
      firstStartedAt: DateTime.utc(2026, 9, 1),
      lastSeenAt: DateTime.utc(2026, 9, 1),
    );
    final launch = testLaunch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Запуск',
      priceFullKopecks: 1900000,
      depositKopecks: 500000,
      depositDueDays: 7,
      webinarAt: DateTime.utc(2026, 10, 5, 16),
    );
    final order = CourseOrder(
      id: 9,
      userId: 42,
      launchId: 1,
      status: OrderStatus.paid,
      kind: PaymentKind.full,
      priceFullKopecks: 1500000,
      amountPaidKopecks: 1500000,
      amountDueKopecks: 0,
      checkoutStartedAt: DateTime.utc(2026, 10, 6),
    );

    expect(templates.adminGuideIssued(user: user, launch: launch), contains('Получил гайд'));
    expect(templates.adminGuideIssued(user: user, launch: launch), contains('@masha'));
    expect(templates.adminGuideIssued(user: user, launch: launch), contains('Instagram Reels'));
    expect(templates.adminWebinarRsvp(user: user, launch: launch), contains('Записался на эфир'));
    expect(templates.adminWebinarRsvp(user: user, launch: launch), contains('05.10.2026'));
    final paid = templates.adminPaidWithInvite(user: user, order: order, launch: launch);
    expect(paid, contains('Оплатил — ссылка в канал выдана'));
    expect(paid, contains('15000 ₽'));
    expect(paid, contains('полная оплата'));
    expect(paid, isNot(contains('t.me/+')));
    expect(
      templates.adminPaidWithInviteRich(user: user, order: order, launch: launch),
      contains('Оплатил'),
    );
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
    expect(text, contains('← Курс'));
    expect(text, contains('Цвет в интерьере'));
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
    expect(texts, isNot(contains('👤 Профиль')));
    expect(texts, isNot(contains('📋 Меню')));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminSheets)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminLinks)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminSearch)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminMenu)));
    expect(
      templates.userMenuKeyboard(showCourseStatus: false).containsKey('input_field_placeholder'),
      isFalse,
    );
    expect(templates.adminMenuKeyboard().containsKey('input_field_placeholder'), isFalse);
    expect(templates.help(), contains('перешлю человеку на связи'));

    final paid = _replyButtonTexts(templates.userMenuKeyboard(showCourseStatus: true));
    expect(paid, contains(MessageTemplates.buttonCourseStatus));
    expect(paid, contains(MessageTemplates.buttonGuide));
    expect(paid, contains(MessageTemplates.buttonHelp));
    expect(paid, isNot(contains('👤 Профиль')));
  });

  test('paid and deposit copy match the sheet', () {
    final templates = MessageTemplates();
    final launch = testLaunch(
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
    expect(templates.depositSucceeded(deposit, launch: launch), contains('Предоплата прошла'));
    expect(
      _inlineButtonTexts(templates.courseStatusKeyboard(order: deposit)!),
      contains(MessageTemplates.buttonPayRemainder),
    );
    expect(templates.paymentSucceeded(launch: launch), contains('Успешная оплата'));
    expect(_inlineButtonTexts(templates.unjoinedInviteKeyboard('https://t.me/+keep-me')), <String>[
      MessageTemplates.buttonOpenInvite,
    ]);
  });

  test('funnel inline keyboards do not repeat the reply menu', () {
    final templates = MessageTemplates();
    final launch = testLaunch(
      id: 1,
      productId: 1,
      code: 'launch-1',
      title: 'Запуск',
      priceFullKopecks: 1800000,
      depositKopecks: 500000,
      depositDueDays: 7,
      webinarAt: DateTime.utc(2020, 1, 1),
    );
    final quote = LaunchSales.quote(launch, rsvp: false, now: DateTime.utc(2026, 9, 8));
    final enroll = _inlineButtonTexts(templates.enrollKeyboard(launch, quote: quote));
    expect(enroll, isNot(contains(MessageTemplates.buttonGuide)));
    expect(enroll, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(enroll, isNot(contains(MessageTemplates.buttonHelp)));
    expect(enroll.any((text) => text.startsWith(MessageTemplates.buttonPayFull)), isTrue);
    expect(_inlineButtonTexts(templates.helpKeyboard()), <String>[MessageTemplates.buttonOptOut]);
    expect(templates.help(), contains('перешлю человеку на связи'));
    expect(_inlineButtonTexts(templates.unjoinedInviteKeyboard('https://t.me/+x')), <String>[
      MessageTemplates.buttonOpenInvite,
    ]);
    expect(_inlineCallbackData(templates.unjoinedInviteKeyboard('https://t.me/+x')), isEmpty);
    expect(templates.inviteMessage(), contains('напиши сюда'));
    expect(templates.inviteMessage(), contains('кнопку ниже'));
    expect(templates.inviteMessage(), isNot(contains('https://t.me/')));
    expect(templates.inviteMessage(), isNot(contains('запроси новую')));
    expect(templates.accessRevoked(), contains('Доступ к потоку снят'));
    expect(templates.accessRevoked(), contains('напиши сюда'));
    expect(templates.paymentResetToUnpaid(), contains('Статус оплаты сброшен'));
    expect(templates.adminCancelled(clientNotified: true), contains('Человеку написал'));
    expect(
      templates.adminCancelled(clientNotified: true, clientReached: false),
      contains('не дошло'),
    );
    expect(templates.unjoinedInviteReminder(), contains('кнопку ниже'));
    expect(templates.unjoinedInviteReminder(), isNot(contains('https://t.me/')));
    expect(templates.unjoinedInviteReminder(), isNot(contains('запроси новую')));
    expect(templates.help(), isNot(contains('Новая ссылка')));
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.unpaid)),
      contains(MessageTemplates.buttonAdminChangeStatus),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.paid)),
      contains(MessageTemplates.buttonAdminReinvite),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.paid)),
      contains(MessageTemplates.buttonAdminCancel),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.unpaid)),
      isNot(contains(MessageTemplates.buttonAdminReinvite)),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.unpaid)),
      isNot(contains(MessageTemplates.buttonAdminCancel)),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.deposit)),
      isNot(contains(MessageTemplates.buttonAdminReinvite)),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.deposit)),
      isNot(contains(MessageTemplates.buttonAdminCancel)),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.cancelled)),
      isNot(contains(MessageTemplates.buttonAdminReinvite)),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.cancelled)),
      isNot(contains(MessageTemplates.buttonAdminCancel)),
    );
    expect(
      _inlineButtonTexts(
        templates.adminCardKeyboard(1, status: AdminPaymentStatus.unpaid, inChannel: true),
      ),
      contains(MessageTemplates.buttonAdminCancel),
    );
    expect(
      _inlineButtonTexts(templates.adminCardKeyboard(1, status: AdminPaymentStatus.unpaid)),
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
