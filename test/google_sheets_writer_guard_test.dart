import 'package:course_chatbot/src/data/google_sheets_api_writer.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_funnel_dashboard.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  GoogleSheetsDashboard dashboard() {
    return GoogleSheetsFunnelDashboard.build(
      FunnelAnalytics(
        generatedAt: DateTime.utc(2026, 8, 26, 12),
        startedUsersTotal: 1,
        funnelUsers: 1,
        guideTaken: 1,
        checkoutStarted: 0,
        paidUsers: 0,
        startedLast7Days: 1,
        startedLast30Days: 1,
        paidLast7Days: 0,
        paidLast30Days: 0,
        phaseCounts: const <String, int>{'lead': 1},
        sourceCounts: const <String, int>{'direct_course': 1},
      ),
    );
  }

  test('ВОРОНКА export does not delete, rename, or clear gid=0', () async {
    final gateway = FakeGoogleSheetsGateway(
      sheets: const <GoogleSheetsSheetInfo>[
        GoogleSheetsSheetInfo(title: CoursesSheet.tabTitle, sheetId: CoursesSheet.sheetId),
      ],
      valuesBySheetId: <int, List<List<Object?>>>{CoursesSheet.sheetId: CoursesSheet.seedRows()},
    );
    final writer = GoogleSheetsApiWriter(gateway: gateway);
    await writer.replaceDashboard(dashboard());
    expect(gateway.deletedSheetIds, isNot(contains(CoursesSheet.sheetId)));
    expect(gateway.renamedSheetIds, isNot(contains(CoursesSheet.sheetId)));
    expect(gateway.clearedRanges.any((range) => range.contains(CoursesSheet.tabTitle)), isFalse);
    expect(gateway.sheets.any((sheet) => sheet.sheetId == CoursesSheet.sheetId), isTrue);
    expect(
      gateway.sheets.firstWhere((sheet) => sheet.sheetId == CoursesSheet.sheetId).title,
      CoursesSheet.tabTitle,
    );
    expect(gateway.sheets.any((sheet) => sheet.title == 'ВОРОНКА'), isTrue);
    expect(gateway.sheets.any((sheet) => sheet.title == 'FUNNEL'), isFalse);
    expect(gateway.valuesBySheetId[CoursesSheet.sheetId]!.first.first, CoursesSheet.title);
  });

  test('replaceDashboard refuses when ВОРОНКА is gid=0', () async {
    final gateway = FakeGoogleSheetsGateway(
      sheets: const <GoogleSheetsSheetInfo>[
        GoogleSheetsSheetInfo(title: 'ВОРОНКА', sheetId: CoursesSheet.sheetId),
      ],
    );
    final writer = GoogleSheetsApiWriter(gateway: gateway);
    await expectLater(writer.replaceDashboard(dashboard()), throwsStateError);
    expect(gateway.deletedSheetIds, isEmpty);
    expect(gateway.renamedSheetIds, isEmpty);
    expect(gateway.clearedRanges, isEmpty);
    expect(gateway.sheets.single.title, 'ВОРОНКА');
  });

  test('ВОРОНКА export deletes an obsolete FUNNEL tab', () async {
    final gateway = FakeGoogleSheetsGateway(
      sheets: const <GoogleSheetsSheetInfo>[
        GoogleSheetsSheetInfo(title: CoursesSheet.tabTitle, sheetId: CoursesSheet.sheetId),
        GoogleSheetsSheetInfo(title: 'FUNNEL', sheetId: 7),
      ],
      valuesBySheetId: <int, List<List<Object?>>>{CoursesSheet.sheetId: CoursesSheet.seedRows()},
    );
    final writer = GoogleSheetsApiWriter(gateway: gateway);
    await writer.replaceDashboard(dashboard());
    expect(gateway.deletedSheetIds, contains(7));
    expect(gateway.sheets.any((sheet) => sheet.title == 'FUNNEL'), isFalse);
    expect(gateway.sheets.any((sheet) => sheet.title == 'ВОРОНКА'), isTrue);
  });

  test('ВОРОНКА export does not delete or clear ССЫЛКИ', () async {
    final linksRows = LinksSheet.seedRows(botUsername: 'course_bot');
    final gateway = FakeGoogleSheetsGateway(
      sheets: const <GoogleSheetsSheetInfo>[
        GoogleSheetsSheetInfo(title: CoursesSheet.tabTitle, sheetId: CoursesSheet.sheetId),
        GoogleSheetsSheetInfo(title: LinksSheet.tabTitle, sheetId: 4),
      ],
      valuesBySheetId: <int, List<List<Object?>>>{
        CoursesSheet.sheetId: CoursesSheet.seedRows(),
        4: linksRows,
      },
    );
    final writer = GoogleSheetsApiWriter(gateway: gateway);
    await writer.replaceDashboard(dashboard());
    expect(gateway.deletedSheetIds, isNot(contains(4)));
    expect(gateway.sheets.any((sheet) => sheet.title == LinksSheet.tabTitle), isTrue);
    expect(gateway.valuesBySheetId[4]!.first.first, LinksSheet.title);
    expect(
      gateway.valuesBySheetId[4]!.any(
        (row) => row.contains('https://t.me/course_bot?start=ig_reels_guide'),
      ),
      isTrue,
    );
  });

  test('ВОРОНКА export does not delete or clear ССЫЛКИ', () async {
    final linksRows = LinksSheet.seedRows(botUsername: 'course_bot');
    final gateway = FakeGoogleSheetsGateway(
      sheets: const <GoogleSheetsSheetInfo>[
        GoogleSheetsSheetInfo(title: CoursesSheet.tabTitle, sheetId: CoursesSheet.sheetId),
        GoogleSheetsSheetInfo(title: LinksSheet.tabTitle, sheetId: 4),
      ],
      valuesBySheetId: <int, List<List<Object?>>>{
        CoursesSheet.sheetId: CoursesSheet.seedRows(),
        4: linksRows,
      },
    );
    final writer = GoogleSheetsApiWriter(gateway: gateway);
    await writer.replaceDashboard(dashboard());
    expect(gateway.deletedSheetIds, isNot(contains(4)));
    expect(gateway.sheets.any((sheet) => sheet.title == LinksSheet.tabTitle), isTrue);
    expect(gateway.valuesBySheetId[4]!.first.first, LinksSheet.title);
    expect(
      gateway.valuesBySheetId[4]!.any(
        (row) => row.contains('https://t.me/course_bot?start=ig_reels_guide'),
      ),
      isTrue,
    );
  });

  test('replaceSheet refuses to wipe gid=0 catalog', () async {
    final gateway = FakeGoogleSheetsGateway(
      sheets: const <GoogleSheetsSheetInfo>[
        GoogleSheetsSheetInfo(title: CoursesSheet.tabTitle, sheetId: CoursesSheet.sheetId),
      ],
      valuesBySheetId: <int, List<List<Object?>>>{CoursesSheet.sheetId: CoursesSheet.seedRows()},
    );
    final writer = GoogleSheetsApiWriter(gateway: gateway);
    await expectLater(
      writer.replaceSheet(sheetTitle: CoursesSheet.tabTitle, rows: const <List<Object?>>[]),
      throwsStateError,
    );
    expect(gateway.clearedRanges, isEmpty);
    expect(gateway.valuesBySheetId[CoursesSheet.sheetId]!.first.first, CoursesSheet.title);
  });

  test('replaceSheet refuses to wipe ССЫЛКИ', () async {
    final gateway = FakeGoogleSheetsGateway(
      sheets: const <GoogleSheetsSheetInfo>[
        GoogleSheetsSheetInfo(title: CoursesSheet.tabTitle, sheetId: CoursesSheet.sheetId),
        GoogleSheetsSheetInfo(title: LinksSheet.tabTitle, sheetId: 4),
      ],
      valuesBySheetId: <int, List<List<Object?>>>{
        CoursesSheet.sheetId: CoursesSheet.seedRows(),
        4: LinksSheet.seedRows(),
      },
    );
    final writer = GoogleSheetsApiWriter(gateway: gateway);
    await expectLater(
      writer.replaceSheet(sheetTitle: LinksSheet.tabTitle, rows: const <List<Object?>>[]),
      throwsStateError,
    );
    expect(gateway.clearedRanges, isEmpty);
    expect(gateway.valuesBySheetId[4]!.first.first, LinksSheet.title);
  });
}
