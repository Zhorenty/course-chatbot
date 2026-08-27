import 'package:course_chatbot/src/data/google_sheets_courses_catalog.dart';
import 'package:course_chatbot/src/data/google_sheets_funnel_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_links_catalog.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
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
    expect(texts, isNot(contains(MessageTemplates.buttonEnroll)));
    expect(texts, isNot(contains(MessageTemplates.buttonGuide)));
    expect(texts, isNot(contains(MessageTemplates.buttonMenu)));
    expect(texts, isNot(contains(MessageTemplates.buttonHelp)));
  });

  test('user reply keyboard has no admin actions', () {
    final templates = MessageTemplates();
    final texts = _replyButtonTexts(templates.userMenuKeyboard(hasAccess: false));
    expect(texts, contains(MessageTemplates.buttonEnroll));
    expect(texts, contains(MessageTemplates.buttonGuide));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminSheets)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminLinks)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminSearch)));
    expect(texts, isNot(contains(MessageTemplates.buttonAdminMenu)));
  });
}

List<String> _replyButtonTexts(Map<String, Object?> markup) {
  final rows = markup['keyboard'] as List<dynamic>? ?? const <dynamic>[];
  return <String>[
    for (final row in rows)
      for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
  ];
}
