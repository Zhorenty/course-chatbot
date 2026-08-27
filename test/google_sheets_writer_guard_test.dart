import 'package:course_chatbot/src/data/google_sheets_api_writer.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_funnel_dashboard.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
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

  test('FUNNEL export does not delete, rename, or clear gid=0', () async {
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
    expect(gateway.sheets.any((sheet) => sheet.title == 'FUNNEL'), isTrue);
    expect(gateway.valuesBySheetId[CoursesSheet.sheetId]!.first.first, 'product_code');
  });

  test('replaceDashboard refuses when FUNNEL is gid=0', () async {
    final gateway = FakeGoogleSheetsGateway(
      sheets: const <GoogleSheetsSheetInfo>[
        GoogleSheetsSheetInfo(title: 'FUNNEL', sheetId: CoursesSheet.sheetId),
      ],
    );
    final writer = GoogleSheetsApiWriter(gateway: gateway);
    await expectLater(writer.replaceDashboard(dashboard()), throwsStateError);
    expect(gateway.deletedSheetIds, isEmpty);
    expect(gateway.renamedSheetIds, isEmpty);
    expect(gateway.clearedRanges, isEmpty);
    expect(gateway.sheets.single.title, 'FUNNEL');
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
    expect(gateway.valuesBySheetId[CoursesSheet.sheetId]!.first.first, 'product_code');
  });
}
