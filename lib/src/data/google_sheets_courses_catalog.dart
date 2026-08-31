import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';

/// Visual language matches [GoogleSheetsFunnelDashboard]: forest, sage, ivory.
abstract final class GoogleSheetsCoursesCatalog {
  static const GoogleSheetsRgb ink = GoogleSheetsRgb(0.14, 0.20, 0.17);
  static const GoogleSheetsRgb paper = GoogleSheetsRgb(0.96, 0.95, 0.93);
  static const GoogleSheetsRgb header = GoogleSheetsRgb(0.18, 0.27, 0.23);
  static const GoogleSheetsRgb headerText = GoogleSheetsRgb(0.96, 0.94, 0.89);
  static const GoogleSheetsRgb muted = GoogleSheetsRgb(0.42, 0.45, 0.42);
  static const GoogleSheetsRgb tableHead = GoogleSheetsRgb(0.29, 0.39, 0.35);
  static const GoogleSheetsRgb stripeA = GoogleSheetsRgb(0.98, 0.97, 0.95);
  static const GoogleSheetsRgb stripeB = GoogleSheetsRgb(0.92, 0.94, 0.91);
  static const GoogleSheetsRgb accent = GoogleSheetsRgb(0.89, 0.93, 0.90);
  static const GoogleSheetsRgb rule = GoogleSheetsRgb(0.48, 0.54, 0.50);

  static GoogleSheetsDashboard build({
    int headerRow = CoursesSheet.defaultHeaderRow,
    int dataRowCount = 8,
  }) {
    final columnCount = CoursesSheet.columnCount;
    final dataStart = headerRow + 1;
    final dataEnd =
        dataStart +
        (dataRowCount < CoursesSheet.extraDataRows ? CoursesSheet.extraDataRows : dataRowCount);
    final canvasEnd = dataEnd + 4;
    final styles = <GoogleSheetsRangeStyle>[
      GoogleSheetsRangeStyle(
        startRow: 0,
        endRowExclusive: canvasEnd,
        startColumn: 0,
        endColumnExclusive: columnCount,
        background: paper,
        foreground: ink,
        fontSize: 10,
        wrap: true,
        verticalAlignment: 'MIDDLE',
      ),
    ];

    if (headerRow >= 3) {
      styles.add(
        const GoogleSheetsRangeStyle(
          startRow: 0,
          endRowExclusive: 1,
          startColumn: 0,
          endColumnExclusive: CoursesSheet.columnCount - 1,
          background: header,
          foreground: headerText,
          bold: true,
          fontSize: 18,
          merge: true,
          verticalAlignment: 'MIDDLE',
        ),
      );
      styles.add(
        const GoogleSheetsRangeStyle(
          startRow: 0,
          endRowExclusive: 1,
          startColumn: CoursesSheet.columnCount - 1,
          endColumnExclusive: CoursesSheet.columnCount,
          background: header,
          foreground: headerText,
          bold: true,
          fontSize: 11,
          horizontalAlignment: 'RIGHT',
          verticalAlignment: 'MIDDLE',
        ),
      );
      styles.add(
        const GoogleSheetsRangeStyle(
          startRow: 1,
          endRowExclusive: 2,
          startColumn: 0,
          endColumnExclusive: CoursesSheet.columnCount,
          background: accent,
          foreground: muted,
          fontSize: 10,
          merge: true,
          wrap: true,
          verticalAlignment: 'MIDDLE',
        ),
      );
      if (headerRow >= 2) {
        styles.add(
          const GoogleSheetsRangeStyle(
            startRow: 2,
            endRowExclusive: 3,
            startColumn: 0,
            endColumnExclusive: CoursesSheet.columnCount,
            background: rule,
            merge: true,
          ),
        );
      }
    }

    styles.add(
      GoogleSheetsRangeStyle(
        startRow: headerRow,
        endRowExclusive: headerRow + 1,
        startColumn: 0,
        endColumnExclusive: columnCount,
        background: tableHead,
        foreground: headerText,
        bold: true,
        fontSize: 10,
        horizontalAlignment: 'CENTER',
        verticalAlignment: 'MIDDLE',
        wrap: true,
        borders: true,
        innerBorders: true,
      ),
    );

    for (var row = dataStart; row < dataEnd; row++) {
      styles.add(
        GoogleSheetsRangeStyle(
          startRow: row,
          endRowExclusive: row + 1,
          startColumn: 0,
          endColumnExclusive: columnCount,
          background: row.isOdd ? stripeB : stripeA,
          foreground: ink,
          fontSize: 10,
          verticalAlignment: 'MIDDLE',
          wrap: true,
        ),
      );
    }
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: dataStart,
        endRowExclusive: dataEnd,
        startColumn: 0,
        endColumnExclusive: columnCount,
        borders: true,
        innerBorders: true,
        verticalAlignment: 'MIDDLE',
      ),
    );

    const priceColumns = <int>[5, 6];
    for (final column in priceColumns) {
      styles.add(
        GoogleSheetsRangeStyle(
          startRow: dataStart,
          endRowExclusive: dataEnd,
          startColumn: column,
          endColumnExclusive: column + 1,
          horizontalAlignment: 'RIGHT',
          numberFormatType: 'NUMBER',
          numberFormatPattern: '#,##0',
        ),
      );
    }
    const dateColumns = <int>[7, 8];
    for (final column in dateColumns) {
      styles.add(
        GoogleSheetsRangeStyle(
          startRow: dataStart,
          endRowExclusive: dataEnd,
          startColumn: column,
          endColumnExclusive: column + 1,
          horizontalAlignment: 'CENTER',
          numberFormatType: 'DATE',
          numberFormatPattern: 'dd.mm.yyyy',
        ),
      );
    }
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: dataStart,
        endRowExclusive: dataEnd,
        startColumn: 4,
        endColumnExclusive: 5,
        horizontalAlignment: 'CENTER',
        bold: true,
      ),
    );
    final statusColumn = CoursesSheet.headers.indexOf(CoursesSheet.status);
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: dataStart,
        endRowExclusive: dataEnd,
        startColumn: statusColumn,
        endColumnExclusive: statusColumn + 1,
        foreground: muted,
        wrap: true,
      ),
    );

    return GoogleSheetsDashboard(
      sheetTitle: CoursesSheet.tabTitle,
      rows: const <List<Object?>>[],
      charts: const <GoogleSheetsChart>[],
      styles: styles,
      columnWidthsPx: const <int>[130, 140, 130, 180, 90, 110, 130, 120, 120, 140, 170, 280],
      frozenRowCount: headerRow + 1,
      hideGridlines: true,
      tabColor: header,
      rowHeightsPx: headerRow >= 3 ? const <int>[42, 52, 12, 36] : const <int>[],
      notes: <GoogleSheetsNote>[
        for (var i = 0; i < CoursesSheet.headerNotes.length; i++)
          GoogleSheetsNote(row: headerRow, column: i, text: CoursesSheet.headerNotes[i]),
      ],
      columnCount: columnCount,
      rowCount: canvasEnd,
      validations: <GoogleSheetsValidation>[
        GoogleSheetsValidation(
          startRow: dataStart,
          endRowExclusive: dataEnd,
          startColumn: 7,
          endColumnExclusive: 9,
          conditionType: 'DATE_IS_VALID',
          inputMessage: 'Выбери дату в календаре. Формат 19.08.2026.',
        ),
      ],
    );
  }
}
