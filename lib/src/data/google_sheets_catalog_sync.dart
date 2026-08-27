import 'dart:async';

import 'package:course_chatbot/src/data/catalog_repository.dart';
import 'package:course_chatbot/src/data/google_sheets_courses_catalog.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_ids.dart';
import 'package:course_chatbot/src/data/google_sheets_writer.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/telegram/retry.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:l/l.dart';

final class CatalogSyncResult {
  const CatalogSyncResult({
    required this.ok,
    this.launch,
    this.seeded = false,
    this.multipleActive = false,
    this.usedFirstRowAsActive = false,
    this.error,
  });

  final bool ok;
  final Launch? launch;
  final bool seeded;
  final bool multipleActive;
  final bool usedFirstRowAsActive;
  final String? error;
}

final class GoogleSheetsCatalogSync {
  GoogleSheetsCatalogSync({
    required GoogleSheetsSpreadsheetGateway gateway,
    required CatalogRepository catalog,
    this.timezoneOffsetHours = CoursesSheet.defaultTimezoneOffsetHours,
    this.fallbackChannelId,
    this.fallbackOfferUrl,
    this.fallbackLeadMagnetFileId,
    this.fallbackLeadMagnetUrl,
    this.requestTimeout = const Duration(seconds: 25),
  }) : _gateway = gateway,
       _catalog = catalog;

  final GoogleSheetsSpreadsheetGateway _gateway;
  final CatalogRepository _catalog;
  final int timezoneOffsetHours;
  final int? fallbackChannelId;
  final String? fallbackOfferUrl;
  final String? fallbackLeadMagnetFileId;
  final String? fallbackLeadMagnetUrl;
  final Duration requestTimeout;

  Future<CatalogSyncResult> sync() {
    return retry(_syncOnce, shouldRetry: _shouldRetry);
  }

  Future<CatalogSyncResult> _syncOnce() async {
    final sheets = await _gateway.describeSheets().timeout(requestTimeout);
    final catalogSheet = _sheetById(sheets, CoursesSheet.sheetId);
    if (catalogSheet == null) {
      final message = 'COURSES catalog sheet gid=0 is missing.';
      l.w(message);
      return CatalogSyncResult(ok: false, launch: _catalog.activeLaunch(), error: message);
    }

    var title = catalogSheet.title;
    if (CoursesSheet.isPlaceholderTitle(title) && title != CoursesSheet.tabTitle) {
      await _gateway
          .renameSheet(sheetId: CoursesSheet.sheetId, title: CoursesSheet.tabTitle)
          .timeout(requestTimeout);
      title = CoursesSheet.tabTitle;
    }

    final quoted = quoteA1SheetTitle(title);
    var rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);
    var parsed = CoursesSheetParser.parse(rows, timezoneOffsetHours: timezoneOffsetHours);
    var seeded = false;
    if (_needsSeed(parsed)) {
      await _gateway
          .updateValues(
            a1Range: '$quoted!A1',
            rows: CoursesSheet.seedRows(),
            valueInputOption: 'USER_ENTERED',
          )
          .timeout(requestTimeout);
      seeded = true;
      rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);
      parsed = CoursesSheetParser.parse(rows, timezoneOffsetHours: timezoneOffsetHours);
    } else if (parsed.rows.isNotEmpty && CoursesSheetParser.headerRowIndex(rows) == 0) {
      final headerAt = 0;
      final wrapped = CoursesSheet.withChrome(
        headerRow: rows[headerAt],
        dataRows: rows.sublist(headerAt + 1),
      );
      await _gateway
          .updateValues(a1Range: '$quoted!A1', rows: wrapped, valueInputOption: 'USER_ENTERED')
          .timeout(requestTimeout);
      rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);
      parsed = CoursesSheetParser.parse(rows, timezoneOffsetHours: timezoneOffsetHours);
    }

    final headerAt = CoursesSheetParser.headerRowIndex(rows) ?? CoursesSheet.defaultHeaderRow;
    final dataRowCount = parsed.rows.isEmpty ? CoursesSheet.extraDataRows : parsed.rows.length + 3;
    await _writeStatusColumn(
      title: title,
      headerAt: headerAt,
      dataRowCount: dataRowCount < CoursesSheet.extraDataRows
          ? CoursesSheet.extraDataRows
          : dataRowCount,
    );
    await _gateway
        .applyDashboardLook(
          sheetId: CoursesSheet.sheetId,
          dashboard: GoogleSheetsCoursesCatalog.build(
            headerRow: headerAt,
            dataRowCount: dataRowCount,
          ),
        )
        .timeout(requestTimeout);

    final draft = parsed.active;
    if (draft == null) {
      final existing = _catalog.activeLaunch();
      final message =
          parsed.error ??
          'COURSES has no valid launch rows (skipped=${parsed.skippedInvalidCount}).';
      l.w(message);
      return CatalogSyncResult(ok: false, launch: existing, seeded: seeded, error: message);
    }

    if (parsed.multipleActive) {
      l.w(
        'COURSES has ${parsed.activeFlagCount} active rows; '
        'using first (${draft.launchCode}).',
      );
    } else if (parsed.noActiveFlag) {
      l.w('COURSES has no is_active flag; using first row (${draft.launchCode}).');
    }

    final applied = draft.withFallbacks(
      channelId: fallbackChannelId,
      offerUrl: _blankToNull(fallbackOfferUrl),
      leadMagnetFileId: _blankToNull(fallbackLeadMagnetFileId),
      leadMagnetUrl: _blankToNull(fallbackLeadMagnetUrl),
    );
    final launch = _catalog.upsertActiveLaunch(
      productCode: applied.productCode,
      productTitle: applied.productTitle,
      launchCode: applied.launchCode,
      launchTitle: applied.launchTitle,
      priceFullKopecks: applied.priceFullKopecks,
      depositKopecks: applied.depositKopecks,
      depositDueDays: applied.depositDueDays,
      depositDueAt: applied.depositDueAt,
      courseStartAt: applied.courseStartAt,
      channelId: applied.channelId,
      offerUrl: applied.offerUrl,
      leadMagnetFileId: applied.leadMagnetFileId,
      leadMagnetUrl: applied.leadMagnetUrl,
    );
    l.i(
      'COURSES catalog synced. launch=${launch.code} '
      'price=${launch.priceFullKopecks} seeded=$seeded',
    );
    return CatalogSyncResult(
      ok: true,
      launch: launch,
      seeded: seeded,
      multipleActive: parsed.multipleActive,
      usedFirstRowAsActive: parsed.noActiveFlag,
    );
  }

  Future<void> _writeStatusColumn({
    required String title,
    required int headerAt,
    required int dataRowCount,
  }) async {
    final quoted = quoteA1SheetTitle(title);
    final statusIndex = CoursesSheet.headers.indexOf(CoursesSheet.status);
    final letter = CoursesSheet.columnLetter(statusIndex);
    final rows = <List<Object?>>[
      <Object?>[CoursesSheet.displayHeaders[statusIndex]],
      for (var i = 0; i < dataRowCount; i++)
        <Object?>[CoursesSheet.statusFormula(row: headerAt + 2 + i)],
    ];
    await _gateway
        .updateValues(
          a1Range: '$quoted!$letter${headerAt + 1}',
          rows: rows,
          valueInputOption: 'USER_ENTERED',
        )
        .timeout(requestTimeout);
  }

  bool _needsSeed(CoursesSheetParseResult parsed) {
    if (!parsed.isEmpty) {
      return false;
    }
    // Header + launch_code rows that failed validation: do not overwrite human edits.
    return parsed.skippedInvalidCount == 0;
  }

  GoogleSheetsSheetInfo? _sheetById(List<GoogleSheetsSheetInfo> sheets, int sheetId) {
    for (final sheet in sheets) {
      if (sheet.sheetId == sheetId) {
        return sheet;
      }
    }
    return null;
  }

  String? _blankToNull(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool _shouldRetry(Object error) {
    if (error is StateError) {
      return false;
    }
    if (error is TimeoutException) {
      return true;
    }
    if (error is DetailedApiRequestError) {
      final status = error.status;
      return status == null || status == 429 || status >= 500;
    }
    return true;
  }
}
