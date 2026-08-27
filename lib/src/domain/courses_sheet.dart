import 'package:course_chatbot/src/domain/money.dart';

/// Human-editable catalog on spreadsheet `gid=0`. Bot reads; FUNNEL must not live here.
abstract final class CoursesSheet {
  static const String tabTitle = 'COURSES';
  static const int sheetId = 0;
  static const int defaultDepositDueDays = 7;
  static const int defaultTimezoneOffsetHours = 3;

  static const String productCode = 'product_code';
  static const String productTitle = 'product_title';
  static const String launchCode = 'launch_code';
  static const String launchTitle = 'launch_title';
  static const String isActive = 'is_active';
  static const String priceFullRub = 'price_full_rub';
  static const String depositRub = 'deposit_rub';
  static const String depositDueDate = 'deposit_due_date';
  static const String courseStartDate = 'course_start_date';
  static const String channelId = 'channel_id';
  static const String offerUrl = 'offer_url';
  static const String leadMagnetFileId = 'lead_magnet_file_id';
  static const String leadMagnetUrl = 'lead_magnet_url';

  static const List<String> headers = <String>[
    productCode,
    productTitle,
    launchCode,
    launchTitle,
    isActive,
    priceFullRub,
    depositRub,
    depositDueDate,
    courseStartDate,
    channelId,
    offerUrl,
    leadMagnetFileId,
    leadMagnetUrl,
  ];

  static const String seedProductCode = 'course';
  static const String seedProductTitle = 'Курс';
  static const String seedLaunchCode = 'launch-1';
  static const String seedLaunchTitle = 'Запуск';
  static const int seedPriceFullRub = 18000;
  static const int seedDepositRub = 5000;
  static const String seedDepositDueDate = '2026-10-05';
  static const String seedCourseStartDate = '2026-10-12';

  static List<List<Object?>> seedRows() {
    return <List<Object?>>[List<Object?>.from(headers), seedDataRow()];
  }

  static List<Object?> seedDataRow() {
    return <Object?>[
      seedProductCode,
      seedProductTitle,
      seedLaunchCode,
      seedLaunchTitle,
      '1',
      seedPriceFullRub,
      seedDepositRub,
      seedDepositDueDate,
      seedCourseStartDate,
      '',
      '',
      '',
      '',
    ];
  }

  static bool isPlaceholderTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    switch (trimmed.toLowerCase()) {
      case 'sheet1':
      case 'лист1':
      case 'tabellenblatt1':
      case 'funnel':
        return true;
      default:
        return false;
    }
  }
}

final class CatalogLaunchDraft {
  const CatalogLaunchDraft({
    required this.productCode,
    required this.productTitle,
    required this.launchCode,
    required this.launchTitle,
    required this.isActive,
    required this.priceFullKopecks,
    required this.depositKopecks,
    required this.depositDueDays,
    this.depositDueAt,
    this.courseStartAt,
    this.channelId,
    this.offerUrl,
    this.leadMagnetFileId,
    this.leadMagnetUrl,
  });

  final String productCode;
  final String productTitle;
  final String launchCode;
  final String launchTitle;
  final bool isActive;
  final int priceFullKopecks;
  final int depositKopecks;
  final int depositDueDays;
  final DateTime? depositDueAt;
  final DateTime? courseStartAt;
  final int? channelId;
  final String? offerUrl;
  final String? leadMagnetFileId;
  final String? leadMagnetUrl;

  CatalogLaunchDraft withFallbacks({
    int? channelId,
    String? offerUrl,
    String? leadMagnetFileId,
    String? leadMagnetUrl,
  }) {
    return CatalogLaunchDraft(
      productCode: productCode,
      productTitle: productTitle,
      launchCode: launchCode,
      launchTitle: launchTitle,
      isActive: isActive,
      priceFullKopecks: priceFullKopecks,
      depositKopecks: depositKopecks,
      depositDueDays: depositDueDays,
      depositDueAt: depositDueAt,
      courseStartAt: courseStartAt,
      channelId: this.channelId ?? channelId,
      offerUrl: this.offerUrl ?? offerUrl,
      leadMagnetFileId: this.leadMagnetFileId ?? leadMagnetFileId,
      leadMagnetUrl: this.leadMagnetUrl ?? leadMagnetUrl,
    );
  }
}

final class CoursesSheetParseResult {
  const CoursesSheetParseResult({
    required this.rows,
    required this.skippedInvalidCount,
    this.error,
  });

  final List<CatalogLaunchDraft> rows;
  final int skippedInvalidCount;
  final String? error;

  bool get isEmpty => rows.isEmpty;

  CatalogLaunchDraft? get active {
    for (final row in rows) {
      if (row.isActive) {
        return row;
      }
    }
    return rows.isEmpty ? null : rows.first;
  }

  int get activeFlagCount => rows.where((row) => row.isActive).length;

  bool get multipleActive => activeFlagCount > 1;

  bool get noActiveFlag => rows.isNotEmpty && activeFlagCount == 0;
}

abstract final class CoursesSheetParser {
  static CoursesSheetParseResult parse(
    List<List<Object?>> rows, {
    int timezoneOffsetHours = CoursesSheet.defaultTimezoneOffsetHours,
  }) {
    if (rows.isEmpty) {
      return const CoursesSheetParseResult(
        rows: <CatalogLaunchDraft>[],
        skippedInvalidCount: 0,
        error: 'empty sheet',
      );
    }
    final headerIndex = _headerIndex(rows.first);
    if (!headerIndex.containsKey(CoursesSheet.launchCode)) {
      return const CoursesSheetParseResult(
        rows: <CatalogLaunchDraft>[],
        skippedInvalidCount: 0,
        error: 'missing launch_code header',
      );
    }

    final parsed = <CatalogLaunchDraft>[];
    var skipped = 0;
    for (var i = 1; i < rows.length; i++) {
      final raw = rows[i];
      if (_isEmptyRow(raw)) {
        continue;
      }
      final launchCode = _cell(raw, headerIndex, CoursesSheet.launchCode);
      if (launchCode == null || launchCode.isEmpty) {
        continue;
      }
      final draft = _parseRow(raw, headerIndex, timezoneOffsetHours: timezoneOffsetHours);
      if (draft == null) {
        skipped += 1;
        continue;
      }
      parsed.add(draft);
    }
    return CoursesSheetParseResult(rows: parsed, skippedInvalidCount: skipped);
  }

  static Map<String, int> _headerIndex(List<Object?> headerRow) {
    final map = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final name = _cellString(headerRow[i])?.toLowerCase();
      if (name == null || name.isEmpty) {
        continue;
      }
      map[name] = i;
    }
    return map;
  }

  static CatalogLaunchDraft? _parseRow(
    List<Object?> raw,
    Map<String, int> headerIndex, {
    required int timezoneOffsetHours,
  }) {
    final launchCode = _cell(raw, headerIndex, CoursesSheet.launchCode);
    if (launchCode == null || launchCode.isEmpty) {
      return null;
    }
    final priceKopecks = _priceKopecks(raw, headerIndex, CoursesSheet.priceFullRub);
    if (priceKopecks == null || priceKopecks <= 0) {
      return null;
    }
    final depositDueRaw = _cell(raw, headerIndex, CoursesSheet.depositDueDate);
    final startRaw = _cell(raw, headerIndex, CoursesSheet.courseStartDate);
    DateTime? depositDueAt;
    DateTime? courseStartAt;
    if (depositDueRaw != null && depositDueRaw.isNotEmpty) {
      depositDueAt = _parseIsoDateEndOfDay(depositDueRaw, timezoneOffsetHours: timezoneOffsetHours);
      if (depositDueAt == null) {
        return null;
      }
    }
    if (startRaw != null && startRaw.isNotEmpty) {
      courseStartAt = _parseIsoDate(startRaw);
      if (courseStartAt == null) {
        return null;
      }
    }
    final depositKopecks = _priceKopecks(raw, headerIndex, CoursesSheet.depositRub) ?? 0;
    if (depositKopecks < 0) {
      return null;
    }
    final channelRaw = _cell(raw, headerIndex, CoursesSheet.channelId);
    int? channelId;
    if (channelRaw != null && channelRaw.isNotEmpty) {
      channelId = int.tryParse(channelRaw);
      if (channelId == null) {
        return null;
      }
    }
    return CatalogLaunchDraft(
      productCode:
          _cell(raw, headerIndex, CoursesSheet.productCode) ?? CoursesSheet.seedProductCode,
      productTitle:
          _cell(raw, headerIndex, CoursesSheet.productTitle) ?? CoursesSheet.seedProductTitle,
      launchCode: launchCode,
      launchTitle: _cell(raw, headerIndex, CoursesSheet.launchTitle) ?? launchCode,
      isActive: _isTruthy(_cell(raw, headerIndex, CoursesSheet.isActive)),
      priceFullKopecks: priceKopecks,
      depositKopecks: depositKopecks,
      depositDueDays: CoursesSheet.defaultDepositDueDays,
      depositDueAt: depositDueAt,
      courseStartAt: courseStartAt,
      channelId: channelId,
      offerUrl: _cell(raw, headerIndex, CoursesSheet.offerUrl),
      leadMagnetFileId: _cell(raw, headerIndex, CoursesSheet.leadMagnetFileId),
      leadMagnetUrl: _cell(raw, headerIndex, CoursesSheet.leadMagnetUrl),
    );
  }

  static int? _priceKopecks(List<Object?> raw, Map<String, int> headerIndex, String column) {
    final value = _cell(raw, headerIndex, column);
    if (value == null || value.isEmpty) {
      return null;
    }
    final compact = value.replaceAll('\u00a0', '').replaceAll(' ', '');
    return parseRubStringToKopecks(compact);
  }

  static String? _cell(List<Object?> raw, Map<String, int> headerIndex, String column) {
    final index = headerIndex[column];
    if (index == null || index >= raw.length) {
      return null;
    }
    return _cellString(raw[index]);
  }

  static String? _cellString(Object? cell) {
    if (cell == null) {
      return null;
    }
    final text = cell.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  static bool _isEmptyRow(List<Object?> raw) {
    for (final cell in raw) {
      if (_cellString(cell) != null) {
        return false;
      }
    }
    return true;
  }

  static bool _isTruthy(String? raw) {
    if (raw == null) {
      return false;
    }
    switch (raw.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'y':
      case 'on':
      case 'да':
      case 'да.':
        return true;
      default:
        return false;
    }
  }
}

final _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

DateTime? _parseIsoDate(String? raw) {
  final match = _isoDate.firstMatch(raw?.trim() ?? '');
  if (match == null) {
    return null;
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  return DateTime.utc(year, month, day);
}

DateTime? _parseIsoDateEndOfDay(String? raw, {required int timezoneOffsetHours}) {
  final date = _parseIsoDate(raw);
  if (date == null) {
    return null;
  }
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    23,
    59,
    59,
  ).subtract(Duration(hours: timezoneOffsetHours));
}
