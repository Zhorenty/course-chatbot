import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';

abstract interface class GoogleSheetsWriter {
  Future<void> replaceSheet({
    required String sheetTitle,
    required List<List<Object?>> rows,
  });

  Future<void> replaceDashboard(GoogleSheetsDashboard dashboard);

  Future<void> close();
}

abstract interface class GoogleSheetsSpreadsheetGateway {
  Future<Set<String>> listSheetTitles();

  Future<List<GoogleSheetsSheetInfo>> describeSheets();

  Future<void> addSheet(String title);

  Future<void> renameSheet({required int sheetId, required String title});

  Future<void> deleteSheet(int sheetId);

  Future<void> clearRange(String a1Range);

  Future<void> updateValues({
    required String a1Range,
    required List<List<Object?>> rows,
    String valueInputOption = 'RAW',
  });

  Future<List<List<Object?>>> getValues(String a1Range);

  Future<void> deleteDimension({
    required int sheetId,
    required String dimension,
    required int startIndex,
    required int endIndex,
  });

  Future<void> applyDashboardLook({
    required int sheetId,
    required GoogleSheetsDashboard dashboard,
  });

  Future<void> close();
}
