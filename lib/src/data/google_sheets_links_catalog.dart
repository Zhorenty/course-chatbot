import 'package:course_chatbot/src/data/google_sheets_courses_catalog.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';

/// Visual language matches [GoogleSheetsCoursesCatalog]: forest, sage, ivory.
abstract final class GoogleSheetsLinksCatalog {
  static GoogleSheetsDashboard build({
    int headerRow = LinksSheet.defaultHeaderRow,
    int dataRowCount = LinksSheet.extraDataRows,
  }) {
    const columnCount = LinksSheet.columnCount;
    final dataStart = headerRow + 1;
    final dataEnd =
        dataStart +
        (dataRowCount < LinksSheet.extraDataRows ? LinksSheet.extraDataRows : dataRowCount);
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
        verticalAlignment: 'MIDDLE',
      ),
    ];

    if (headerRow >= 3) {
      styles.add(
        const GoogleSheetsRangeStyle(
          startRow: 0,
          endRowExclusive: 1,
          startColumn: 0,
          endColumnExclusive: LinksSheet.columnCount - 1,
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
          startColumn: LinksSheet.columnCount - 1,
          endColumnExclusive: LinksSheet.columnCount,
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
          endColumnExclusive: LinksSheet.columnCount,
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
            endColumnExclusive: LinksSheet.columnCount,
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
    final urlColumn = LinksSheet.headers.indexOf(LinksSheet.url);
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: dataStart,
        endRowExclusive: dataEnd,
        startColumn: urlColumn,
        endColumnExclusive: urlColumn + 1,
        foreground: GoogleSheetsCoursesCatalog.muted,
        wrap: true,
      ),
    );

    return GoogleSheetsDashboard(
      sheetTitle: LinksSheet.tabTitle,
      rows: const <List<Object?>>[],
      charts: const <GoogleSheetsChart>[],
      styles: styles,
      columnWidthsPx: const <int>[220, 90, 160, 420],
      frozenRowCount: headerRow + 1,
      hideGridlines: true,
      tabColor: GoogleSheetsCoursesCatalog.header,
      rowHeightsPx: headerRow >= 3 ? const <int>[42, 52, 12, 36] : const <int>[],
      notes: <GoogleSheetsNote>[
        for (var i = 0; i < LinksSheet.headerNotes.length; i++)
          GoogleSheetsNote(row: headerRow, column: i, text: LinksSheet.headerNotes[i]),
      ],
      columnCount: columnCount,
      rowCount: canvasEnd,
    );
  }
}
