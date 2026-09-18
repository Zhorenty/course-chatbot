import 'package:course_chatbot/src/data/google_sheets_courses_catalog.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/domain/copy_sheet.dart';

/// Visual language matches [GoogleSheetsCoursesCatalog]: forest, sage, ivory.
abstract final class GoogleSheetsCopyCatalog {
  static GoogleSheetsDashboard build({
    int headerRow = CopySheet.defaultHeaderRow,
    int dataRowCount = 8,
  }) {
    const columnCount = CopySheet.columnCount;
    final dataStart = headerRow + 1;
    final dataEnd =
        dataStart +
        (dataRowCount < CopySheet.extraDataRows ? CopySheet.extraDataRows : dataRowCount);
    final canvasEnd = dataEnd + 4;
    final styles = <GoogleSheetsRangeStyle>[
      GoogleSheetsRangeStyle(
        startRow: 0,
        endRowExclusive: canvasEnd,
        startColumn: 0,
        endColumnExclusive: columnCount,
        background: GoogleSheetsCoursesCatalog.paper,
        foreground: GoogleSheetsCoursesCatalog.ink,
        fontSize: 10,
        wrap: true,
        verticalAlignment: 'TOP',
      ),
    ];

    if (headerRow >= 3) {
      styles.add(
        const GoogleSheetsRangeStyle(
          startRow: 0,
          endRowExclusive: 1,
          startColumn: 0,
          endColumnExclusive: CopySheet.columnCount - 1,
          background: GoogleSheetsCoursesCatalog.header,
          foreground: GoogleSheetsCoursesCatalog.headerText,
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
          startColumn: CopySheet.columnCount - 1,
          endColumnExclusive: CopySheet.columnCount,
          background: GoogleSheetsCoursesCatalog.header,
          foreground: GoogleSheetsCoursesCatalog.headerText,
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
          endColumnExclusive: CopySheet.columnCount,
          background: GoogleSheetsCoursesCatalog.accent,
          foreground: GoogleSheetsCoursesCatalog.muted,
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
            endColumnExclusive: CopySheet.columnCount,
            background: GoogleSheetsCoursesCatalog.rule,
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
        background: GoogleSheetsCoursesCatalog.tableHead,
        foreground: GoogleSheetsCoursesCatalog.headerText,
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
          background: row.isOdd
              ? GoogleSheetsCoursesCatalog.stripeB
              : GoogleSheetsCoursesCatalog.stripeA,
          foreground: GoogleSheetsCoursesCatalog.ink,
          fontSize: 10,
          verticalAlignment: 'TOP',
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
        verticalAlignment: 'TOP',
      ),
    );
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: dataStart,
        endRowExclusive: dataEnd,
        startColumn: CopySheet.headers.indexOf(CopySheet.body),
        endColumnExclusive: CopySheet.headers.indexOf(CopySheet.body) + 1,
        wrap: true,
        verticalAlignment: 'TOP',
      ),
    );
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: dataStart,
        endRowExclusive: dataEnd,
        startColumn: CopySheet.headers.indexOf(CopySheet.media),
        endColumnExclusive: CopySheet.headers.indexOf(CopySheet.leadsTo) + 1,
        foreground: GoogleSheetsCoursesCatalog.muted,
        wrap: true,
        verticalAlignment: 'TOP',
      ),
    );

    return GoogleSheetsDashboard(
      sheetTitle: CopySheet.tabTitle,
      rows: const <List<Object?>>[],
      charts: const <GoogleSheetsChart>[],
      styles: styles,
      columnWidthsPx: const <int>[280, 560, 260, 220, 240],
      frozenRowCount: headerRow + 1,
      hideGridlines: true,
      tabColor: GoogleSheetsCoursesCatalog.header,
      rowHeightsPx: <int>[
        if (headerRow >= 3) 42,
        if (headerRow >= 3) 64,
        if (headerRow >= 3) 12,
        36,
        for (var i = 0; i < dataEnd - dataStart; i++) 120,
      ],
      notes: <GoogleSheetsNote>[
        for (var i = 0; i < CopySheet.headerNotes.length; i++)
          GoogleSheetsNote(row: headerRow, column: i, text: CopySheet.headerNotes[i]),
      ],
      columnCount: columnCount,
      rowCount: canvasEnd,
    );
  }
}
