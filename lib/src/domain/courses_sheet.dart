import 'package:course_chatbot/src/domain/money.dart';

/// Human-editable catalog on spreadsheet `gid=0`. Bot reads; ВОРОНКА must not live here.
abstract final class CoursesSheet {
  static const String tabTitle = 'COURSES';
  static const int sheetId = 0;
  static const int columnCount = 14;
  static const int defaultHeaderRow = 3;
  static const int extraDataRows = 8;
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
  static const String status = 'status';

  static const String title = 'Курс · Каталог запусков';
  static const String titleAside = 'Правят руками';
  static const String hint =
      'Поставь «да» в одной строке — это текущий набор. Цены в рублях, даты как 19.08.2026. '
      'После правок нажми в боте «Обновить Google Sheets».';

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
    status,
  ];

  static const List<String> displayHeaders = <String>[
    'Код продукта',
    'Продукт',
    'Код запуска',
    'Название запуска',
    'Активен',
    'Цена, ₽',
    'Предоплата, ₽',
    'Доплата до',
    'Старт курса',
    'ID канала',
    'Оферта',
    'Файл гайда',
    'Ссылка на гайд',
    'статус',
  ];

  static const List<String> headerNotes = <String>[
    'Короткий код продукта. Пример: course. Можно не заполнять.',
    'Как называется продукт. Пример: Курс.',
    'Короткий код этого потока. Пример: launch-1. Без кода строка не попадёт в бота.',
    'Как называется этот поток. Это увидят в боте.',
    'Поставь «да», если это текущий набор. «Да» должна быть ровно одна строка. Если нигде нет — возьмётся первая заполненная.',
    'Полная цена курса в рублях. Пиши число: 18000 или 18 000.',
    'Сумма предоплаты в рублях. Пусто или 0 — сразу полная оплата, без предоплаты.',
    'Дата. Выбери в календаре. Формат 19.08.2026. До этого дня нужно доплатить остаток.',
    'Дата. Выбери в календаре. Формат 19.08.2026. Когда начинается обучение.',
    'Номер закрытого канала этого потока. Число вида −100…. Если не знаешь — оставь пустым, канал уже подключен.',
    'Ссылка на текст публичной оферты. Если пусто — в боте останется согласие без ссылки на документ.',
    'Не заполняй. Бот сам запомнит файл гайда. Сюда пишет только тот, кто меняет гайд в Telegram.',
    'Ссылка на гайд, если отдаём не файлом. Можно не заполнять.',
    'Готово или чего не хватает. Не пиши сюда руками. Если вся строка пустая — статус тоже пустой.',
  ];

  static const String seedProductCode = 'course';
  static const String seedProductTitle = 'Курс';
  static const String seedLaunchCode = 'launch-1';
  static const String seedLaunchTitle = 'Запуск';
  static const int seedPriceFullRub = 18000;
  static const int seedDepositRub = 5000;
  static const String seedDepositDueDate = '05.10.2026';
  static const String seedCourseStartDate = '12.10.2026';

  static List<List<Object?>> seedRows() {
    return withChrome(dataRows: <List<Object?>>[seedDataRow()]);
  }

  static List<List<Object?>> withChrome({
    List<Object?>? headerRow,
    List<List<Object?>> dataRows = const <List<Object?>>[],
  }) {
    return <List<Object?>>[
      titleRow(),
      hintRow(),
      padded(const <Object?>[]),
      toDisplayHeaders(headerRow ?? displayHeaders),
      ...dataRows,
    ];
  }

  static List<Object?> titleRow() {
    final row = padded(<Object?>[title]);
    row[columnCount - 1] = titleAside;
    return row;
  }

  static List<Object?> hintRow() => padded(<Object?>[hint]);

  static List<Object?> seedDataRow() {
    return padded(<Object?>[
      seedProductCode,
      seedProductTitle,
      seedLaunchCode,
      seedLaunchTitle,
      'да',
      seedPriceFullRub,
      seedDepositRub,
      seedDepositDueDate,
      seedCourseStartDate,
      '',
      '',
      '',
      '',
      statusFormula(row: defaultHeaderRow + 2),
    ]);
  }

  static String columnLetter(int column) {
    var n = column + 1;
    final buffer = StringBuffer();
    while (n > 0) {
      n -= 1;
      buffer.writeCharCode(65 + n % 26);
      n ~/= 26;
    }
    return buffer.toString().split('').reversed.join();
  }

  /// Locale-aware status formula for data row [row] (1-based A1).
  static String statusFormula({required int row, String formulaSep = ';'}) {
    String cell(String canonical) {
      final index = headers.indexOf(canonical);
      if (index < 0) {
        throw StateError('COURSES header "$canonical" is missing from spec.');
      }
      return '${columnLetter(index)}$row';
    }

    final statusIndex = headers.indexOf(status);
    final dataRange = '${columnLetter(0)}$row:${columnLetter(statusIndex - 1)}$row';
    const required = <String>[launchCode, priceFullRub, depositDueDate, courseStartDate];
    final allRequired = <String>[
      for (final name in required) '${cell(name)}<>""',
    ].join('$formulaSep ');
    final missing = <String>[
      'IF(${cell(launchCode)}="";"нет кода запуска";"")',
      'IF(${cell(priceFullRub)}="";"нет цены";"")',
      'IF(${cell(depositDueDate)}="";"нет даты доплаты";"")',
      'IF(${cell(courseStartDate)}="";"нет даты старта";"")',
    ].join('$formulaSep ');
    return '=IF(COUNTA($dataRange)=0;"";IF(AND($allRequired);"готово";'
        'TEXTJOIN("; "$formulaSep TRUE$formulaSep $missing)))';
  }

  static List<Object?> padded(List<Object?> cells) {
    return <Object?>[
      for (var i = 0; i < columnCount; i++) i < cells.length ? (cells[i] ?? '') : '',
    ];
  }

  static List<Object?> toDisplayHeaders(List<Object?> headerRow) {
    final mapped = <Object?>[
      for (var i = 0; i < headerRow.length; i++)
        displayNameFor(CoursesSheetParser.canonicalHeader(headerRow[i])) ?? headerRow[i],
    ];
    final hasStatus = mapped.any((cell) => CoursesSheetParser.canonicalHeader(cell) == status);
    if (!hasStatus) {
      mapped.add(displayHeaders.last);
    }
    return padded(mapped);
  }

  static String? displayNameFor(String? canonical) {
    if (canonical == null) {
      return null;
    }
    final index = headers.indexOf(canonical);
    if (index < 0 || index >= displayHeaders.length) {
      return null;
    }
    return displayHeaders[index];
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
      case 'воронка':
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
  static const Map<String, String> headerAliases = <String, String>{
    CoursesSheet.productCode: CoursesSheet.productCode,
    'код продукта': CoursesSheet.productCode,
    CoursesSheet.productTitle: CoursesSheet.productTitle,
    'продукт': CoursesSheet.productTitle,
    'название продукта': CoursesSheet.productTitle,
    CoursesSheet.launchCode: CoursesSheet.launchCode,
    'код запуска': CoursesSheet.launchCode,
    CoursesSheet.launchTitle: CoursesSheet.launchTitle,
    'название запуска': CoursesSheet.launchTitle,
    CoursesSheet.isActive: CoursesSheet.isActive,
    'активен': CoursesSheet.isActive,
    'active': CoursesSheet.isActive,
    CoursesSheet.priceFullRub: CoursesSheet.priceFullRub,
    'цена руб': CoursesSheet.priceFullRub,
    'цена': CoursesSheet.priceFullRub,
    'полная цена': CoursesSheet.priceFullRub,
    CoursesSheet.depositRub: CoursesSheet.depositRub,
    'предоплата руб': CoursesSheet.depositRub,
    'предоплата': CoursesSheet.depositRub,
    CoursesSheet.depositDueDate: CoursesSheet.depositDueDate,
    'доплата до': CoursesSheet.depositDueDate,
    'дата доплаты': CoursesSheet.depositDueDate,
    CoursesSheet.courseStartDate: CoursesSheet.courseStartDate,
    'старт курса': CoursesSheet.courseStartDate,
    CoursesSheet.channelId: CoursesSheet.channelId,
    'id канала': CoursesSheet.channelId,
    'канал': CoursesSheet.channelId,
    CoursesSheet.offerUrl: CoursesSheet.offerUrl,
    'оферта': CoursesSheet.offerUrl,
    CoursesSheet.leadMagnetFileId: CoursesSheet.leadMagnetFileId,
    'file_id гайда': CoursesSheet.leadMagnetFileId,
    'file id гайда': CoursesSheet.leadMagnetFileId,
    'файл гайда': CoursesSheet.leadMagnetFileId,
    CoursesSheet.leadMagnetUrl: CoursesSheet.leadMagnetUrl,
    'url гайда': CoursesSheet.leadMagnetUrl,
    'ссылка гайда': CoursesSheet.leadMagnetUrl,
    'ссылка на гайд': CoursesSheet.leadMagnetUrl,
    CoursesSheet.status: CoursesSheet.status,
    'статус': CoursesSheet.status,
  };

  static String? canonicalHeader(Object? cell) {
    final normalized = _normalizeHeader(cell);
    if (normalized == null) {
      return null;
    }
    return headerAliases[normalized];
  }

  static int? headerRowIndex(List<List<Object?>> rows) {
    for (var i = 0; i < rows.length; i++) {
      if (_headerIndex(rows[i]).containsKey(CoursesSheet.launchCode)) {
        return i;
      }
    }
    return null;
  }

  static int? columnIndex(List<List<Object?>> rows, String canonical) {
    final headerAt = headerRowIndex(rows);
    if (headerAt == null) {
      return null;
    }
    return _headerIndex(rows[headerAt])[canonical];
  }

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
    final headerAt = headerRowIndex(rows);
    if (headerAt == null) {
      return const CoursesSheetParseResult(
        rows: <CatalogLaunchDraft>[],
        skippedInvalidCount: 0,
        error: 'missing launch_code header',
      );
    }
    final headerIndex = _headerIndex(rows[headerAt]);

    final parsed = <CatalogLaunchDraft>[];
    var skipped = 0;
    for (var i = headerAt + 1; i < rows.length; i++) {
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
      final name = canonicalHeader(headerRow[i]);
      if (name == null) {
        continue;
      }
      map.putIfAbsent(name, () => i);
    }
    return map;
  }

  static String? _normalizeHeader(Object? cell) {
    final text = _cellString(cell);
    if (text == null) {
      return null;
    }
    return text
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll('₽', 'руб')
        .replaceAll(RegExp('[,:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
final _dottedDate = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');

DateTime? _parseIsoDate(String? raw) {
  final trimmed = raw?.trim() ?? '';
  var match = _isoDate.firstMatch(trimmed);
  if (match != null) {
    return _utcDate(match.group(1)!, match.group(2)!, match.group(3)!);
  }
  match = _dottedDate.firstMatch(trimmed);
  if (match != null) {
    return _utcDate(match.group(3)!, match.group(2)!, match.group(1)!);
  }
  return null;
}

DateTime? _utcDate(String yearRaw, String monthRaw, String dayRaw) {
  final year = int.parse(yearRaw);
  final month = int.parse(monthRaw);
  final day = int.parse(dayRaw);
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
