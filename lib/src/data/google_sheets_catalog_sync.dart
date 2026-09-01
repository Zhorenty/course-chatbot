import 'dart:async';

import 'package:course_chatbot/src/data/catalog_repository.dart';
import 'package:course_chatbot/src/data/google_sheets_courses_catalog.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_ids.dart';
import 'package:course_chatbot/src/data/google_sheets_links_catalog.dart';
import 'package:course_chatbot/src/data/google_sheets_writer.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
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
    AcquisitionLinkCatalog? links,
    this.botUsername,
    this.timezoneOffsetHours = CoursesSheet.defaultTimezoneOffsetHours,
    this.fallbackChannelId,
    this.fallbackOfferUrl,
    this.fallbackLeadMagnetFileId,
    this.fallbackLeadMagnetUrl,
    this.requestTimeout = const Duration(seconds: 25),
  }) : _gateway = gateway,
       _catalog = catalog,
       _links = links ?? AcquisitionLinkCatalog();

  final GoogleSheetsSpreadsheetGateway _gateway;
  final CatalogRepository _catalog;
  final AcquisitionLinkCatalog _links;
  final String? botUsername;
  final int timezoneOffsetHours;
  final int? fallbackChannelId;
  final String? fallbackOfferUrl;
  final String? fallbackLeadMagnetFileId;
  final String? fallbackLeadMagnetUrl;
  final Duration requestTimeout;
  Set<String> _sheetLaunchCodes = <String>{};

  Set<String> get sheetLaunchCodes => Set<String>.unmodifiable(_sheetLaunchCodes);

  Future<CatalogSyncResult> sync() {
    return retry(_syncOnce, shouldRetry: _shouldRetry);
  }

  Future<void> syncLinks() {
    return retry(_syncLinksOnce, shouldRetry: _shouldRetry);
  }

  Future<void> upsertCourseRow({
    required CatalogLaunchDraft draft,
    String? previousLaunchCode,
    bool insertOnly = false,
  }) {
    return retry(
      () => _upsertCourseRowOnce(
        draft: draft,
        previousLaunchCode: previousLaunchCode,
        insertOnly: insertOnly,
      ),
      shouldRetry: _shouldRetry,
    );
  }

  Future<void> deleteCourseRow({required String launchCode}) {
    return retry(() => _deleteCourseRowOnce(launchCode), shouldRetry: _shouldRetry);
  }

  Future<void> upsertLinkRow({
    required AcquisitionLink link,
    String? previousPayload,
    bool insertOnly = false,
  }) {
    return retry(
      () =>
          _upsertLinkRowOnce(link: link, previousPayload: previousPayload, insertOnly: insertOnly),
      shouldRetry: _shouldRetry,
    );
  }

  Future<void> deleteLinkRow({required String payload}) {
    return retry(() => _deleteLinkRowOnce(payload), shouldRetry: _shouldRetry);
  }

  Future<void> _upsertCourseRowOnce({
    required CatalogLaunchDraft draft,
    String? previousLaunchCode,
    bool insertOnly = false,
  }) async {
    final layout = await _coursesLayout();
    final headerAt = layout.headerAt;
    final headerIndex = layout.headerIndex;
    final rows = layout.rows;
    final lookup = (previousLaunchCode ?? draft.launchCode).trim();
    final existingAt = _rowIndexForLaunchCode(
      rows,
      headerAt: headerAt,
      headerIndex: headerIndex,
      code: lookup,
    );
    final newCodeAt = _rowIndexForLaunchCode(
      rows,
      headerAt: headerAt,
      headerIndex: headerIndex,
      code: draft.launchCode,
    );
    if (insertOnly && (existingAt != null || newCodeAt != null)) {
      throw StateError('launch code "${draft.launchCode}" already exists');
    }
    if (existingAt == null && newCodeAt != null) {
      throw StateError('launch code "${draft.launchCode}" already exists');
    }
    if (existingAt != null && newCodeAt != null && newCodeAt != existingAt) {
      throw StateError('launch code "${draft.launchCode}" already exists');
    }

    final targetAt =
        existingAt ?? _firstVacantDataRow(rows, headerAt: headerAt, headerIndex: headerIndex);

    final preserved = existingAt == null
        ? draft
        : _overlayDraft(draft, rows[existingAt], headerIndex);
    final cells = CoursesSheet.rowFromDraft(preserved, rowNumber: targetAt + 1);
    await _gateway
        .updateValues(
          a1Range: '${layout.quoted}!A${targetAt + 1}',
          rows: <List<Object?>>[cells],
          valueInputOption: 'USER_ENTERED',
        )
        .timeout(requestTimeout);

    if (preserved.isActive) {
      await _writeActiveFlags(
        quoted: layout.quoted,
        rows: rows,
        headerAt: headerAt,
        headerIndex: headerIndex,
        activeRow: targetAt,
        activeCode: preserved.launchCode,
      );
    }
  }

  Future<void> _upsertLinkRowOnce({
    required AcquisitionLink link,
    String? previousPayload,
    bool insertOnly = false,
  }) async {
    final layout = await _linksLayout();
    final lookup = (previousPayload ?? link.payload).trim();
    final existingAt = _rowIndexForPayload(
      layout.rows,
      headerAt: layout.headerAt,
      headerIndex: layout.headerIndex,
      payload: lookup,
    );
    final newPayloadAt = _rowIndexForPayload(
      layout.rows,
      headerAt: layout.headerAt,
      headerIndex: layout.headerIndex,
      payload: link.payload,
    );
    if (insertOnly && (existingAt != null || newPayloadAt != null)) {
      throw StateError('link payload "${link.payload}" already exists');
    }
    if (existingAt == null && newPayloadAt != null) {
      throw StateError('link payload "${link.payload}" already exists');
    }
    if (existingAt != null && newPayloadAt != null && newPayloadAt != existingAt) {
      throw StateError('link payload "${link.payload}" already exists');
    }

    final targetAt =
        existingAt ??
        _firstVacantLinkRow(
          layout.rows,
          headerAt: layout.headerAt,
          headerIndex: layout.headerIndex,
        );
    final launchLabel = _launchSheetLabel(link.launchCode);
    final cells = LinksSheet.rowFromLink(link, botUsername: botUsername, launchLabel: launchLabel);
    await _gateway
        .updateValues(
          a1Range: '${layout.quoted}!A${targetAt + 1}',
          rows: <List<Object?>>[cells],
          valueInputOption: 'USER_ENTERED',
        )
        .timeout(requestTimeout);
  }

  Future<void> _deleteLinkRowOnce(String payload) async {
    final layout = await _linksLayout();
    final index = _rowIndexForPayload(
      layout.rows,
      headerAt: layout.headerAt,
      headerIndex: layout.headerIndex,
      payload: payload,
    );
    if (index == null) {
      return;
    }
    if (index <= layout.headerAt) {
      throw StateError('Refusing to delete ССЫЛКИ header or chrome.');
    }
    await _gateway
        .deleteDimension(
          sheetId: layout.sheetId,
          dimension: 'ROWS',
          startIndex: index,
          endIndex: index + 1,
        )
        .timeout(requestTimeout);
  }

  Future<void> _deleteCourseRowOnce(String launchCode) async {
    final layout = await _coursesLayout();
    final index = _rowIndexForLaunchCode(
      layout.rows,
      headerAt: layout.headerAt,
      headerIndex: layout.headerIndex,
      code: launchCode,
    );
    if (index == null) {
      return;
    }
    if (index <= layout.headerAt) {
      throw StateError('Refusing to delete COURSES header or chrome.');
    }
    await _gateway
        .deleteDimension(
          sheetId: CoursesSheet.sheetId,
          dimension: 'ROWS',
          startIndex: index,
          endIndex: index + 1,
        )
        .timeout(requestTimeout);
  }

  Future<
    ({
      String title,
      String quoted,
      int headerAt,
      Map<String, int> headerIndex,
      List<List<Object?>> rows,
    })
  >
  _coursesLayout() async {
    final sheets = await _gateway.describeSheets().timeout(requestTimeout);
    final catalogSheet = _sheetById(sheets, CoursesSheet.sheetId);
    if (catalogSheet == null) {
      throw StateError('COURSES catalog sheet gid=0 is missing.');
    }
    final quoted = quoteA1SheetTitle(catalogSheet.title);
    final rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);
    final headerAt = CoursesSheetParser.headerRowIndex(rows);
    if (headerAt == null) {
      throw StateError('COURSES is missing the launch_code header.');
    }
    return (
      title: catalogSheet.title,
      quoted: quoted,
      headerAt: headerAt,
      headerIndex: CoursesSheetParser.headerIndexMap(rows[headerAt]),
      rows: rows,
    );
  }

  int? _rowIndexForLaunchCode(
    List<List<Object?>> rows, {
    required int headerAt,
    required Map<String, int> headerIndex,
    required String code,
  }) {
    final wanted = code.trim();
    if (wanted.isEmpty) {
      return null;
    }
    for (var i = headerAt + 1; i < rows.length; i++) {
      final cell = CoursesSheetParser.cellOf(rows[i], headerIndex, CoursesSheet.launchCode);
      if (cell == wanted) {
        return i;
      }
    }
    return null;
  }

  int _firstVacantDataRow(
    List<List<Object?>> rows, {
    required int headerAt,
    required Map<String, int> headerIndex,
  }) {
    for (var i = headerAt + 1; i < rows.length; i++) {
      if (CoursesSheetParser.isVacantDataRow(rows[i], headerIndex)) {
        return i;
      }
    }
    return rows.length;
  }

  int? _rowIndexForPayload(
    List<List<Object?>> rows, {
    required int headerAt,
    required Map<String, int> headerIndex,
    required String payload,
  }) {
    final wanted = AcquisitionSource.normalize(payload);
    if (wanted == null) {
      return null;
    }
    for (var i = headerAt + 1; i < rows.length; i++) {
      final cell = LinksSheetParser.cellOf(rows[i], headerIndex, LinksSheet.payload);
      if (AcquisitionSource.normalize(cell) == wanted) {
        return i;
      }
    }
    return null;
  }

  int _firstVacantLinkRow(
    List<List<Object?>> rows, {
    required int headerAt,
    required Map<String, int> headerIndex,
  }) {
    for (var i = headerAt + 1; i < rows.length; i++) {
      if (LinksSheetParser.isVacantDataRow(rows[i], headerIndex)) {
        return i;
      }
    }
    return rows.length;
  }

  String _launchSheetLabel(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return '';
    }
    final launch = _catalog.launchByCode(value) ?? _catalog.launchByTitle(value);
    return launch?.title ?? value;
  }

  Future<
    ({
      int sheetId,
      String title,
      String quoted,
      int headerAt,
      Map<String, int> headerIndex,
      List<List<Object?>> rows,
    })
  >
  _linksLayout() async {
    final sheets = await _gateway.describeSheets().timeout(requestTimeout);
    var tab = _sheetByTitle(sheets, LinksSheet.tabTitle);
    if (tab == null) {
      await _gateway.addSheet(LinksSheet.tabTitle).timeout(requestTimeout);
      final refreshed = await _gateway.describeSheets().timeout(requestTimeout);
      tab = _sheetByTitle(refreshed, LinksSheet.tabTitle);
    }
    if (tab == null) {
      throw StateError('Failed to open ${LinksSheet.tabTitle} sheet.');
    }
    final quoted = quoteA1SheetTitle(tab.title);
    final rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);
    final headerAt = LinksSheetParser.headerRowIndex(rows);
    if (headerAt == null) {
      throw StateError('${LinksSheet.tabTitle} is missing the payload header.');
    }
    return (
      sheetId: tab.sheetId,
      title: tab.title,
      quoted: quoted,
      headerAt: headerAt,
      headerIndex: LinksSheetParser.headerIndexMap(rows[headerAt]),
      rows: rows,
    );
  }

  CatalogLaunchDraft _overlayDraft(
    CatalogLaunchDraft draft,
    List<Object?> existing,
    Map<String, int> headerIndex,
  ) {
    String? cell(String column) => CoursesSheetParser.cellOf(existing, headerIndex, column);
    return draft.copyWith(
      productCode: _blankToNull(cell(CoursesSheet.productCode)) ?? draft.productCode,
      productTitle: _blankToNull(cell(CoursesSheet.productTitle)) ?? draft.productTitle,
      offerUrl: draft.offerUrl ?? cell(CoursesSheet.offerUrl),
      leadMagnetFileId: draft.leadMagnetFileId ?? cell(CoursesSheet.leadMagnetFileId),
      leadMagnetUrl: draft.leadMagnetUrl ?? cell(CoursesSheet.leadMagnetUrl),
    );
  }

  Future<void> _writeActiveFlags({
    required String quoted,
    required List<List<Object?>> rows,
    required int headerAt,
    required Map<String, int> headerIndex,
    required int activeRow,
    required String activeCode,
  }) async {
    final col = headerIndex[CoursesSheet.isActive];
    if (col == null) {
      return;
    }
    final letter = CoursesSheet.columnLetter(col);
    final last = rows.length > activeRow + 1 ? rows.length : activeRow + 1;
    final flags = <List<Object?>>[];
    for (var i = headerAt + 1; i < last; i++) {
      final code = i < rows.length
          ? CoursesSheetParser.cellOf(rows[i], headerIndex, CoursesSheet.launchCode)
          : null;
      final isTarget = i == activeRow || code == activeCode;
      flags.add(<Object?>[isTarget ? 'да' : '']);
    }
    if (flags.isEmpty) {
      return;
    }
    await _gateway
        .updateValues(
          a1Range: '$quoted!$letter${headerAt + 2}',
          rows: flags,
          valueInputOption: 'USER_ENTERED',
        )
        .timeout(requestTimeout);
  }

  Future<CatalogSyncResult> _syncOnce() async {
    final outcomes = await Future.wait<Object?>(<Future<Object?>>[
      _syncCoursesOnce(),
      () async {
        try {
          await _syncLinksOnce();
        } on Object catch (error, stackTrace) {
          l.w('ССЫЛКИ catalog sync failed: $error', stackTrace);
        }
      }(),
    ]);
    return outcomes.first! as CatalogSyncResult;
  }

  Future<CatalogSyncResult> _syncCoursesOnce() async {
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
    } else if (CoursesSheetParser.needsLayoutRewrite(rows, hasValidRows: parsed.rows.isNotEmpty)) {
      await _gateway
          .updateValues(
            a1Range: '$quoted!A1',
            rows: CoursesSheetParser.projectToSpec(rows),
            valueInputOption: 'USER_ENTERED',
          )
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

    final appliedActive = draft.withFallbacks(
      channelId: fallbackChannelId,
      offerUrl: _blankToNull(fallbackOfferUrl),
      leadMagnetFileId: _blankToNull(fallbackLeadMagnetFileId),
      leadMagnetUrl: _blankToNull(fallbackLeadMagnetUrl),
    );
    Launch? launch;
    for (final row in parsed.rows) {
      final applied = row.launchCode == appliedActive.launchCode ? appliedActive : row;
      launch = _catalog.upsertLaunch(
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
    }
    final sheetCodes = <String>{for (final row in parsed.rows) row.launchCode};
    _sheetLaunchCodes = sheetCodes;
    for (final existing in _catalog.listLaunches()) {
      if (!sheetCodes.contains(existing.code)) {
        _catalog.tryDeleteLaunch(existing.id);
      }
    }
    _catalog.setActiveLaunch(appliedActive.launchCode);
    launch = _catalog.activeLaunch() ?? launch;
    if (launch == null) {
      final existing = _catalog.activeLaunch();
      return CatalogSyncResult(
        ok: false,
        launch: existing,
        seeded: seeded,
        error: 'active launch missing after sync',
      );
    }
    try {
      await _gateway
          .applyDashboardLook(
            sheetId: CoursesSheet.sheetId,
            dashboard: GoogleSheetsCoursesCatalog.build(
              headerRow: headerAt,
              dataRowCount: dataRowCount,
            ),
          )
          .timeout(requestTimeout);
    } on Object catch (error, stackTrace) {
      l.w('COURSES catalog look failed: $error', stackTrace);
    }
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

  Future<void> _syncLinksOnce() async {
    var sheets = await _gateway.describeSheets().timeout(requestTimeout);
    var tab = _sheetByTitle(sheets, LinksSheet.tabTitle);
    if (tab == null) {
      await _gateway.addSheet(LinksSheet.tabTitle).timeout(requestTimeout);
      sheets = await _gateway.describeSheets().timeout(requestTimeout);
      tab = _sheetByTitle(sheets, LinksSheet.tabTitle);
    }
    if (tab == null) {
      throw StateError('Failed to create ${LinksSheet.tabTitle} sheet.');
    }

    final quoted = quoteA1SheetTitle(tab.title);
    var rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);
    var parsed = LinksSheetParser.parse(rows);
    var seeded = false;
    if (_needsLinksSeed(parsed)) {
      await _gateway
          .updateValues(
            a1Range: '$quoted!A1',
            rows: LinksSheet.seedRows(botUsername: botUsername),
            valueInputOption: 'USER_ENTERED',
          )
          .timeout(requestTimeout);
      seeded = true;
      rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);
      parsed = LinksSheetParser.parse(rows);
    } else if (parsed.rows.isNotEmpty && LinksSheetParser.headerRowIndex(rows) == 0) {
      final wrapped = LinksSheet.withChrome(headerRow: rows[0], dataRows: rows.sublist(1));
      await _gateway
          .updateValues(a1Range: '$quoted!A1', rows: wrapped, valueInputOption: 'USER_ENTERED')
          .timeout(requestTimeout);
      rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);
      parsed = LinksSheetParser.parse(rows);
    }

    await _ensureEmptyLinkRows(title: tab.title, rows: rows);
    rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);

    await _writeUrlColumn(
      title: tab.title,
      headerAt: LinksSheetParser.headerRowIndex(rows),
      rows: rows,
    );
    rows = await _gateway.getValues('$quoted!A1:Z').timeout(requestTimeout);
    parsed = LinksSheetParser.parse(rows);

    final headerAt = LinksSheetParser.headerRowIndex(rows) ?? LinksSheet.defaultHeaderRow;
    final filled = parsed.rows.length;
    final dataRowCount = filled + 3 < LinksSheet.extraDataRows
        ? LinksSheet.extraDataRows
        : filled + 3;
    final coursesSource = await _coursesDropdownSource();
    try {
      await _gateway
          .applyDashboardLook(
            sheetId: tab.sheetId,
            dashboard: GoogleSheetsLinksCatalog.build(
              headerRow: headerAt,
              dataRowCount: dataRowCount,
              coursesSheetTitle: coursesSource.title,
              coursesHeaderRow: coursesSource.headerRow,
              launchTitles: coursesSource.launchTitles,
            ),
          )
          .timeout(requestTimeout);
    } on Object catch (error, stackTrace) {
      l.w('ССЫЛКИ catalog look failed: $error', stackTrace);
    }

    _links.replaceAll(parsed.rows);
    l.i(
      'ССЫЛКИ catalog synced. links=${_links.entries.length} seeded=$seeded '
      'skipped=${parsed.skippedInvalidCount}',
    );
  }

  Future<void> _ensureEmptyLinkRows({
    required String title,
    required List<List<Object?>> rows,
  }) async {
    final headerAt = LinksSheetParser.headerRowIndex(rows);
    if (headerAt == null) {
      return;
    }
    final dataStart = headerAt + 1;
    final currentData = rows.length <= dataStart ? 0 : rows.length - dataStart;
    if (currentData >= LinksSheet.extraDataRows) {
      return;
    }
    final missing = LinksSheet.extraDataRows - currentData;
    final quoted = quoteA1SheetTitle(title);
    final startRow = dataStart + currentData + 1;
    await _gateway
        .updateValues(
          a1Range: '$quoted!A$startRow',
          rows: <List<Object?>>[
            for (var i = 0; i < missing; i++) LinksSheet.padded(const <Object?>[]),
          ],
          valueInputOption: 'USER_ENTERED',
        )
        .timeout(requestTimeout);
  }

  Future<void> _writeUrlColumn({
    required String title,
    required int? headerAt,
    required List<List<Object?>> rows,
  }) async {
    if (headerAt == null) {
      return;
    }
    final cells = LinksSheetParser.urlColumnCells(rows, botUsername: botUsername);
    if (cells.isEmpty) {
      return;
    }
    final quoted = quoteA1SheetTitle(title);
    final urlIndex = LinksSheetParser.columnIndex(rows, LinksSheet.url);
    if (urlIndex == null) {
      return;
    }
    final letter = LinksSheet.columnLetter(urlIndex);
    await _gateway
        .updateValues(
          a1Range: '$quoted!$letter${headerAt + 2}',
          rows: <List<Object?>>[
            for (final cell in cells) <Object?>[cell],
          ],
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

  bool _needsLinksSeed(LinksSheetParseResult parsed) {
    if (!parsed.isEmpty) {
      return false;
    }
    return parsed.skippedInvalidCount == 0;
  }

  Future<({String title, int headerRow, List<String> launchTitles})>
  _coursesDropdownSource() async {
    final sheets = await _gateway.describeSheets().timeout(requestTimeout);
    final catalog = _sheetById(sheets, CoursesSheet.sheetId);
    if (catalog == null) {
      return (
        title: CoursesSheet.tabTitle,
        headerRow: CoursesSheet.defaultHeaderRow,
        launchTitles: const <String>[],
      );
    }
    final rows = await _gateway
        .getValues('${quoteA1SheetTitle(catalog.title)}!A1:Z')
        .timeout(requestTimeout);
    final parsed = CoursesSheetParser.parse(rows, timezoneOffsetHours: timezoneOffsetHours);
    final seen = <String>{};
    final titles = <String>[];
    for (final row in parsed.rows) {
      final title = row.launchTitle.trim();
      if (title.isEmpty || !seen.add(title)) {
        continue;
      }
      titles.add(title);
    }
    return (
      title: catalog.title,
      headerRow: CoursesSheetParser.headerRowIndex(rows) ?? CoursesSheet.defaultHeaderRow,
      launchTitles: titles,
    );
  }

  GoogleSheetsSheetInfo? _sheetById(List<GoogleSheetsSheetInfo> sheets, int sheetId) {
    for (final sheet in sheets) {
      if (sheet.sheetId == sheetId) {
        return sheet;
      }
    }
    return null;
  }

  GoogleSheetsSheetInfo? _sheetByTitle(List<GoogleSheetsSheetInfo> sheets, String title) {
    for (final sheet in sheets) {
      if (sheet.title == title) {
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
