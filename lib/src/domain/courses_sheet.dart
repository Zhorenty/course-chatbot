import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/domain/moscow_time.dart';

/// Human-editable catalog on spreadsheet `gid=0`. Admin writes rows from the bot
/// or by hand; ВОРОНКА must not live here.
abstract final class CoursesSheet {
  static const String tabTitle = 'COURSES';
  static const int sheetId = 0;
  static const int columnCount = 15;
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
  static const String pricePromoRub = 'price_promo_rub';
  static const String depositRub = 'deposit_rub';
  static const String depositDueDate = 'deposit_due_date';
  static const String courseStartDate = 'course_start_date';
  static const String webinarAt = 'webinar_at';
  static const String webinarUrl = 'webinar_url';
  static const String salesStartAt = 'sales_start_at';
  static const String salesEndDate = 'sales_end_date';
  static const String channelId = 'channel_id';
  static const String offerUrl = 'offer_url';
  static const String leadMagnetFileId = 'lead_magnet_file_id';
  static const String leadMagnetUrl = 'lead_magnet_url';
  static const String status = 'status';

  static const String title = 'Курс · Каталог запусков';
  static const String titleAside = 'Админ в боте или руками';
  static const String activeYes = 'ДА';
  static const String activeNo = 'НЕТ';

  static const String hint =
      'Флажок «Активен» — ровно в одной строке, это текущий набор. Обычная цена 19000, спеццена эфира 15000. '
      'Старт продаж — когда открывается касса и продающий прогрев. Пусто — как дата эфира. '
      'Эфир — дата и время, как 05.10.2026 19:00 (Москва). Спеццена держится 3 дня с эфира. '
      'Доплата после предоплаты — за неделю до старта курса. '
      'Править можно в боте («Google Sheets» → «Управление курсами») или здесь. '
      'После правок в таблице нажми в боте «Google Sheets» → «Обновить Sheets».';

  static const List<String> headers = <String>[
    productCode,
    productTitle,
    launchCode,
    launchTitle,
    isActive,
    priceFullRub,
    pricePromoRub,
    depositRub,
    courseStartDate,
    webinarAt,
    webinarUrl,
    salesStartAt,
    salesEndDate,
    channelId,
    status,
  ];

  static const List<String> displayHeaders = <String>[
    'Код продукта',
    'Продукт',
    'Код запуска',
    'Название запуска',
    'Активен',
    'Цена, ₽',
    'Спеццена, ₽',
    'Предоплата, ₽',
    'Старт курса',
    'Эфир',
    'Ссылка на эфир',
    'Старт продаж',
    'Конец продаж',
    'ID канала',
    'статус',
  ];

  static const List<String> headerNotes = <String>[
    'Короткий код продукта. Пример: course.',
    'Как называется продукт. Пример: Курс.',
    'Короткий код этого потока. Пример: launch-1. Без кода строка не попадёт в бота.',
    'Как называется этот поток. Это увидят в боте.',
    'Флажок: ДА — текущий набор. ДА должна быть ровно одна строка. Если нигде нет — возьмётся первая заполненная.',
    'Обычная цена в рублях. Пиши число: 19000 или 19 000. Для тех, кто не отмечался на эфир.',
    'Спеццена эфира в рублях. 15000. Для тех, кто нажал «Буду на эфире». Действует 3 дня с даты эфира. '
        'Пусто — подставим 15000.',
    'Сумма предоплаты в рублях. Пусто или 0 — сразу полная оплата, без предоплаты. '
        'Срок доплаты бот ставит сам: за неделю до старта курса.',
    'Дата. Выбери в календаре. Формат 19.08.2026. Когда начинается обучение.',
    'Дата и время эфира по Москве. Формат 05.10.2026 19:00. Без времени возьмём 19:00.',
    'Ссылка на эфир. Бот пришлёт её отметившимся в день эфира. Можно дописать позже.',
    'Когда открывается касса и продающий прогрев. Дата и время по Москве, как 05.10.2026 19:00. '
        'Пусто — как дата эфира. Без эфира и без этой даты продажи закрыты.',
    'Последний день продаж, как 11.10.2026. Пусто — продажи не закрываем по календарю.',
    'Номер закрытого канала этого потока. Число вида −100…. Если не знаешь — оставь пустым, канал уже подключен.',
    'Готово или чего не хватает. Не пиши сюда руками. Если вся строка пустая — статус тоже пустой.',
  ];

  static const String seedProductCode = 'course';
  static const String seedProductTitle = 'Курс';
  static const String seedLaunchCode = 'launch-1';
  static const String seedLaunchTitle = 'Запуск';
  static const int seedPriceFullRub = 19000;
  static const int seedPricePromoRub = 15000;
  static const int seedDepositRub = 5000;
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
      activeYes,
      seedPriceFullRub,
      seedPricePromoRub,
      seedDepositRub,
      seedCourseStartDate,
      '',
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
    final allRequired = <String>[
      '${cell(launchCode)}<>""',
      '${cell(priceFullRub)}<>""',
      '${cell(courseStartDate)}<>""',
    ].join('$formulaSep ');
    final missing = <String>[
      'IF(${cell(launchCode)}="";"нет кода запуска";"")',
      'IF(${cell(priceFullRub)}="";"нет цены";"")',
      'IF(${cell(courseStartDate)}="";"нет даты старта";"")',
    ].join('$formulaSep ');
    return '=IF(SUMPRODUCT(LEN($dataRange))=0;"";IF(AND($allRequired);"готово";'
        'TEXTJOIN("; "$formulaSep TRUE$formulaSep $missing)))';
  }

  static List<Object?> padded(List<Object?> cells) {
    return <Object?>[
      for (var i = 0; i < columnCount; i++) i < cells.length ? (cells[i] ?? '') : '',
    ];
  }

  static String formatDottedDate(
    DateTime date, {
    int timezoneOffsetHours = defaultTimezoneOffsetHours,
  }) {
    final local = date.toUtc().add(Duration(hours: timezoneOffsetHours));
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    return '$dd.$mm.${local.year}';
  }

  static String formatDottedDateTime(
    DateTime date, {
    int timezoneOffsetHours = defaultTimezoneOffsetHours,
  }) {
    final local = date.toUtc().add(Duration(hours: timezoneOffsetHours));
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${local.year} $hh:$min';
  }

  static Object priceCell(int kopecks) {
    if (kopecks <= 0) {
      return '';
    }
    if (kopecks % 100 == 0) {
      return kopecks ~/ 100;
    }
    return (kopecks / 100).toStringAsFixed(2);
  }

  static Object activeCell(bool isActive) => isActive ? activeYes : activeNo;

  static String resolvedProductCode(String? raw) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? seedProductCode : value;
  }

  static String resolvedProductTitle(String? raw) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? seedProductTitle : value;
  }

  static List<Object?> rowFromDraft(
    CatalogLaunchDraft draft, {
    required int rowNumber,
    Map<String, int>? headerIndex,
    List<Object?>? existing,
  }) {
    final spec = padded(<Object?>[
      resolvedProductCode(draft.productCode),
      resolvedProductTitle(draft.productTitle),
      draft.launchCode,
      draft.launchTitle,
      activeCell(draft.isActive),
      priceCell(draft.priceFullKopecks),
      draft.pricePromoKopecks > 0 ? priceCell(draft.pricePromoKopecks) : '',
      draft.depositKopecks > 0 ? priceCell(draft.depositKopecks) : '',
      draft.courseStartAt == null ? '' : formatDottedDate(draft.courseStartAt!),
      draft.webinarAt == null ? '' : formatDottedDateTime(draft.webinarAt!),
      draft.webinarUrl ?? '',
      draft.salesStartAt == null ? '' : formatDottedDateTime(draft.salesStartAt!),
      draft.salesEndAt == null ? '' : formatDottedDate(draft.salesEndAt!),
      draft.channelId ?? '',
      statusFormula(row: rowNumber),
    ]);
    if (headerIndex == null || headerIndex.isEmpty) {
      return spec;
    }
    var width = existing?.length ?? 0;
    for (final index in headerIndex.values) {
      if (index + 1 > width) {
        width = index + 1;
      }
    }
    if (width < columnCount) {
      width = columnCount;
    }
    final cells = <Object?>[
      for (var i = 0; i < width; i++) i < (existing?.length ?? 0) ? existing![i] : '',
    ];
    for (var i = 0; i < headers.length; i++) {
      final dest = headerIndex[headers[i]];
      if (dest == null) {
        continue;
      }
      while (cells.length <= dest) {
        cells.add('');
      }
      cells[dest] = spec[i];
    }
    return cells;
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
    this.pricePromoKopecks = 0,
    this.depositDueAt,
    this.courseStartAt,
    this.webinarAt,
    this.webinarUrl,
    this.salesStartAt,
    this.salesEndAt,
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
  final int pricePromoKopecks;
  final int depositKopecks;
  final int depositDueDays;
  final DateTime? depositDueAt;
  final DateTime? courseStartAt;
  final DateTime? webinarAt;
  final String? webinarUrl;
  final DateTime? salesStartAt;
  final DateTime? salesEndAt;
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
      pricePromoKopecks: pricePromoKopecks,
      depositKopecks: depositKopecks,
      depositDueDays: depositDueDays,
      depositDueAt: depositDueAt,
      courseStartAt: courseStartAt,
      webinarAt: webinarAt,
      webinarUrl: webinarUrl,
      salesStartAt: salesStartAt,
      salesEndAt: salesEndAt,
      channelId: this.channelId ?? channelId,
      offerUrl: this.offerUrl ?? offerUrl,
      leadMagnetFileId: this.leadMagnetFileId ?? leadMagnetFileId,
      leadMagnetUrl: this.leadMagnetUrl ?? leadMagnetUrl,
    );
  }

  CatalogLaunchDraft copyWith({
    String? productCode,
    String? productTitle,
    String? launchCode,
    String? launchTitle,
    bool? isActive,
    int? priceFullKopecks,
    int? pricePromoKopecks,
    int? depositKopecks,
    int? depositDueDays,
    Object? depositDueAt = _catalogDraftUnset,
    Object? courseStartAt = _catalogDraftUnset,
    Object? webinarAt = _catalogDraftUnset,
    Object? webinarUrl = _catalogDraftUnset,
    Object? salesStartAt = _catalogDraftUnset,
    Object? salesEndAt = _catalogDraftUnset,
    Object? channelId = _catalogDraftUnset,
    Object? offerUrl = _catalogDraftUnset,
    Object? leadMagnetFileId = _catalogDraftUnset,
    Object? leadMagnetUrl = _catalogDraftUnset,
  }) {
    return CatalogLaunchDraft(
      productCode: productCode ?? this.productCode,
      productTitle: productTitle ?? this.productTitle,
      launchCode: launchCode ?? this.launchCode,
      launchTitle: launchTitle ?? this.launchTitle,
      isActive: isActive ?? this.isActive,
      priceFullKopecks: priceFullKopecks ?? this.priceFullKopecks,
      pricePromoKopecks: pricePromoKopecks ?? this.pricePromoKopecks,
      depositKopecks: depositKopecks ?? this.depositKopecks,
      depositDueDays: depositDueDays ?? this.depositDueDays,
      depositDueAt: identical(depositDueAt, _catalogDraftUnset)
          ? this.depositDueAt
          : depositDueAt as DateTime?,
      courseStartAt: identical(courseStartAt, _catalogDraftUnset)
          ? this.courseStartAt
          : courseStartAt as DateTime?,
      webinarAt: identical(webinarAt, _catalogDraftUnset) ? this.webinarAt : webinarAt as DateTime?,
      webinarUrl: identical(webinarUrl, _catalogDraftUnset)
          ? this.webinarUrl
          : webinarUrl as String?,
      salesStartAt: identical(salesStartAt, _catalogDraftUnset)
          ? this.salesStartAt
          : salesStartAt as DateTime?,
      salesEndAt: identical(salesEndAt, _catalogDraftUnset)
          ? this.salesEndAt
          : salesEndAt as DateTime?,
      channelId: identical(channelId, _catalogDraftUnset) ? this.channelId : channelId as int?,
      offerUrl: identical(offerUrl, _catalogDraftUnset) ? this.offerUrl : offerUrl as String?,
      leadMagnetFileId: identical(leadMagnetFileId, _catalogDraftUnset)
          ? this.leadMagnetFileId
          : leadMagnetFileId as String?,
      leadMagnetUrl: identical(leadMagnetUrl, _catalogDraftUnset)
          ? this.leadMagnetUrl
          : leadMagnetUrl as String?,
    );
  }
}

const Object _catalogDraftUnset = Object();

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
    CoursesSheet.pricePromoRub: CoursesSheet.pricePromoRub,
    'спеццена руб': CoursesSheet.pricePromoRub,
    'спеццена': CoursesSheet.pricePromoRub,
    'цена эфира': CoursesSheet.pricePromoRub,
    CoursesSheet.depositRub: CoursesSheet.depositRub,
    'предоплата руб': CoursesSheet.depositRub,
    'предоплата': CoursesSheet.depositRub,
    CoursesSheet.depositDueDate: CoursesSheet.depositDueDate,
    'доплата до': CoursesSheet.depositDueDate,
    'дата доплаты': CoursesSheet.depositDueDate,
    CoursesSheet.courseStartDate: CoursesSheet.courseStartDate,
    'старт курса': CoursesSheet.courseStartDate,
    CoursesSheet.webinarAt: CoursesSheet.webinarAt,
    'эфир': CoursesSheet.webinarAt,
    'дата эфира': CoursesSheet.webinarAt,
    CoursesSheet.webinarUrl: CoursesSheet.webinarUrl,
    'ссылка на эфир': CoursesSheet.webinarUrl,
    'ссылка эфира': CoursesSheet.webinarUrl,
    CoursesSheet.salesStartAt: CoursesSheet.salesStartAt,
    'старт продаж': CoursesSheet.salesStartAt,
    'начало продаж': CoursesSheet.salesStartAt,
    CoursesSheet.salesEndDate: CoursesSheet.salesEndDate,
    'конец продаж': CoursesSheet.salesEndDate,
    'последний день продаж': CoursesSheet.salesEndDate,
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

  static Map<String, int> headerIndexMap(List<Object?> headerRow) => _headerIndex(headerRow);

  static String? cellOf(List<Object?> raw, Map<String, int> headerIndex, String column) {
    return _cell(raw, headerIndex, column);
  }

  static bool isVacantDataRow(List<Object?> raw, Map<String, int> headerIndex) {
    // A row is free if it has no launch_code. Status formulas, unchecked
    // «Активен» flags and NUMBER-formatted zeros must not push the next
    // course below the table.
    final code = _cell(raw, headerIndex, CoursesSheet.launchCode);
    return code == null || code.isEmpty;
  }

  static final RegExp launchCodePattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static bool isValidLaunchCode(String raw) => launchCodePattern.hasMatch(raw.trim());

  static DateTime? parseDate(String? raw) => _parseIsoDate(raw);

  static DateTime? parseDateTime(
    String? raw, {
    int timezoneOffsetHours = CoursesSheet.defaultTimezoneOffsetHours,
  }) {
    return _parseDateTime(raw, timezoneOffsetHours: timezoneOffsetHours);
  }

  static DateTime? parseDateEndOfDay(
    String? raw, {
    int timezoneOffsetHours = CoursesSheet.defaultTimezoneOffsetHours,
  }) {
    return _parseIsoDateEndOfDay(raw, timezoneOffsetHours: timezoneOffsetHours);
  }

  static int? parsePriceKopecks(String? raw) {
    if (raw == null) {
      return null;
    }
    final compact = raw.trim().replaceAll('\u00a0', '').replaceAll(' ', '');
    if (compact.isEmpty) {
      return null;
    }
    return parseRubStringToKopecks(compact);
  }

  /// Telegram cannot send an empty DM. Admins type ASCII `-`, copy `—` / `−`
  /// from the prompt, or tap «Без своего канала». All of those mean “no channel”.
  static bool isOmittedChannelId(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return true;
    }
    for (final rune in text.runes) {
      if (!_channelOmitRunes.contains(rune)) {
        return false;
      }
    }
    return true;
  }

  static int? parseChannelId(String? raw) {
    final text = raw?.trim() ?? '';
    if (isOmittedChannelId(text)) {
      return null;
    }
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune == 0x00A0 || rune == 0x0020) {
        continue;
      }
      if (_channelOmitRunes.contains(rune)) {
        buffer.writeCharCode(0x002D);
        continue;
      }
      buffer.writeCharCode(rune);
    }
    return int.tryParse(buffer.toString());
  }

  static String suggestLaunchCode(String title, {Set<String> existing = const <String>{}}) {
    final buffer = StringBuffer();
    for (final rune in title.trim().toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final mapped = _slugTranslit[char];
      if (mapped != null) {
        buffer.write(mapped);
        continue;
      }
      if (RegExp(r'[a-z0-9]').hasMatch(char)) {
        buffer.write(char);
        continue;
      }
      if (char == '_' || char == '-') {
        buffer.write(char);
        continue;
      }
      buffer.write('-');
    }
    var slug = buffer
        .toString()
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) {
      slug = 'launch';
    }
    if (slug.length > 32) {
      slug = slug.substring(0, 32).replaceAll(RegExp(r'-+$'), '');
    }
    if (slug.isEmpty) {
      slug = 'launch';
    }
    final taken = existing.map((code) => code.toLowerCase()).toSet();
    if (!taken.contains(slug.toLowerCase())) {
      return slug;
    }
    for (var i = 2; i < 100; i++) {
      final candidate = '$slug-$i';
      if (!taken.contains(candidate.toLowerCase())) {
        return candidate;
      }
    }
    return '$slug-new';
  }

  static bool headerMatchesSpec(List<Object?> headerRow) {
    for (var i = 0; i < CoursesSheet.headers.length; i++) {
      if (i >= headerRow.length) {
        return false;
      }
      if (canonicalHeader(headerRow[i]) != CoursesSheet.headers[i]) {
        return false;
      }
    }
    for (var i = CoursesSheet.headers.length; i < headerRow.length; i++) {
      if (canonicalHeader(headerRow[i]) != null) {
        return false;
      }
    }
    return true;
  }

  static bool needsLayoutRewrite(List<List<Object?>> rows, {required bool hasValidRows}) {
    final headerAt = headerRowIndex(rows);
    if (headerAt == null) {
      return false;
    }
    if (!headerMatchesSpec(rows[headerAt])) {
      return true;
    }
    return hasValidRows && headerAt != CoursesSheet.defaultHeaderRow;
  }

  /// Maps an older COURSES layout (extra columns, header at row 0) onto the
  /// current spec. Dropped fields stay readable via [headerAliases] until rewrite.
  static List<List<Object?>> projectToSpec(List<List<Object?>> rows) {
    final headerAt = headerRowIndex(rows);
    if (headerAt == null) {
      return CoursesSheet.seedRows();
    }
    final headerIndex = _headerIndex(rows[headerAt]);
    final dataRows = <List<Object?>>[];
    for (var i = headerAt + 1; i < rows.length; i++) {
      final raw = rows[i];
      if (_isEmptyRow(raw)) {
        continue;
      }
      final cells = <Object?>[
        for (final name in CoursesSheet.headers)
          name == CoursesSheet.status ? '' : (_cell(raw, headerIndex, name) ?? ''),
      ];
      dataRows.add(CoursesSheet.padded(cells));
    }
    return CoursesSheet.withChrome(dataRows: dataRows);
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
    final startRaw = _cell(raw, headerIndex, CoursesSheet.courseStartDate);
    DateTime? courseStartAt;
    if (startRaw != null && startRaw.isNotEmpty) {
      courseStartAt = _parseIsoDate(startRaw);
      if (courseStartAt == null) {
        return null;
      }
    }
    final webinarRaw = _cell(raw, headerIndex, CoursesSheet.webinarAt);
    DateTime? webinarAt;
    if (webinarRaw != null && webinarRaw.isNotEmpty) {
      webinarAt = _parseDateTime(webinarRaw, timezoneOffsetHours: timezoneOffsetHours);
      if (webinarAt == null) {
        return null;
      }
    }
    final salesStartRaw = _cell(raw, headerIndex, CoursesSheet.salesStartAt);
    DateTime? salesStartAt;
    if (salesStartRaw != null && salesStartRaw.isNotEmpty) {
      salesStartAt = _parseDateTime(salesStartRaw, timezoneOffsetHours: timezoneOffsetHours);
      if (salesStartAt == null) {
        return null;
      }
    }
    final salesEndRaw = _cell(raw, headerIndex, CoursesSheet.salesEndDate);
    DateTime? salesEndAt;
    if (salesEndRaw != null && salesEndRaw.isNotEmpty) {
      salesEndAt = _parseIsoDateEndOfDay(salesEndRaw, timezoneOffsetHours: timezoneOffsetHours);
      if (salesEndAt == null) {
        return null;
      }
    }
    final promoKopecks = _priceKopecks(raw, headerIndex, CoursesSheet.pricePromoRub) ?? 1500000;
    final depositKopecks = _priceKopecks(raw, headerIndex, CoursesSheet.depositRub) ?? 0;
    if (depositKopecks < 0) {
      return null;
    }
    final depositDueAt = depositKopecks > 0
        ? MoscowTime.daysBeforeCourseStart(courseStartAt, days: CoursesSheet.defaultDepositDueDays)
        : null;
    final channelRaw = _cell(raw, headerIndex, CoursesSheet.channelId);
    int? channelId;
    if (channelRaw != null && channelRaw.isNotEmpty && !isOmittedChannelId(channelRaw)) {
      channelId = parseChannelId(channelRaw);
      if (channelId == null) {
        return null;
      }
    }
    return CatalogLaunchDraft(
      productCode: CoursesSheet.resolvedProductCode(
        _cell(raw, headerIndex, CoursesSheet.productCode),
      ),
      productTitle: CoursesSheet.resolvedProductTitle(
        _cell(raw, headerIndex, CoursesSheet.productTitle),
      ),
      launchCode: launchCode,
      launchTitle: _cell(raw, headerIndex, CoursesSheet.launchTitle) ?? launchCode,
      isActive: _isTruthy(_cell(raw, headerIndex, CoursesSheet.isActive)),
      priceFullKopecks: priceKopecks,
      pricePromoKopecks: promoKopecks,
      depositKopecks: depositKopecks,
      depositDueDays: CoursesSheet.defaultDepositDueDays,
      depositDueAt: depositDueAt,
      courseStartAt: courseStartAt,
      webinarAt: webinarAt,
      webinarUrl: _cell(raw, headerIndex, CoursesSheet.webinarUrl),
      salesStartAt: salesStartAt,
      salesEndAt: salesEndAt,
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
final _isoDateTime = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?$',
);
final _dottedDateTime = RegExp(
  r'^(\d{1,2})\.(\d{1,2})\.(\d{4})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?$',
);

/// ASCII hyphen, unicode dashes, and minus sign — what admins type or copy
/// when Telegram will not send an empty message.
const Set<int> _channelOmitRunes = <int>{
  0x002D, // hyphen-minus
  0x2010, // hyphen
  0x2011, // non-breaking hyphen
  0x2012, // figure dash
  0x2013, // en dash
  0x2014, // em dash
  0x2015, // horizontal bar
  0x2212, // minus sign
};

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
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

DateTime? _parseDateTime(String? raw, {required int timezoneOffsetHours}) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  var match = _dottedDateTime.firstMatch(trimmed);
  if (match != null) {
    return _moscowDateTime(
      match.group(3)!,
      match.group(2)!,
      match.group(1)!,
      match.group(4)!,
      match.group(5)!,
      match.group(6) ?? '0',
      timezoneOffsetHours: timezoneOffsetHours,
    );
  }
  match = _isoDateTime.firstMatch(trimmed);
  if (match != null) {
    return _moscowDateTime(
      match.group(1)!,
      match.group(2)!,
      match.group(3)!,
      match.group(4)!,
      match.group(5)!,
      match.group(6) ?? '0',
      timezoneOffsetHours: timezoneOffsetHours,
    );
  }
  final dateOnly = _parseIsoDate(trimmed);
  if (dateOnly == null) {
    return null;
  }
  return DateTime.utc(
    dateOnly.year,
    dateOnly.month,
    dateOnly.day,
    19,
    0,
  ).subtract(Duration(hours: timezoneOffsetHours));
}

DateTime? _moscowDateTime(
  String yearRaw,
  String monthRaw,
  String dayRaw,
  String hourRaw,
  String minuteRaw,
  String secondRaw, {
  required int timezoneOffsetHours,
}) {
  final year = int.parse(yearRaw);
  final month = int.parse(monthRaw);
  final day = int.parse(dayRaw);
  final hour = int.parse(hourRaw);
  final minute = int.parse(minuteRaw);
  final second = int.parse(secondRaw);
  if (month < 1 || month > 12 || day < 1 || day > 31 || hour > 23 || minute > 59 || second > 59) {
    return null;
  }
  return DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
    second,
  ).subtract(Duration(hours: timezoneOffsetHours));
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

const Map<String, String> _slugTranslit = <String, String>{
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'е': 'e',
  'ё': 'e',
  'ж': 'zh',
  'з': 'z',
  'и': 'i',
  'й': 'j',
  'к': 'k',
  'л': 'l',
  'м': 'm',
  'н': 'n',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'у': 'u',
  'ф': 'f',
  'х': 'h',
  'ц': 'c',
  'ч': 'ch',
  'ш': 'sh',
  'щ': 'sch',
  'ъ': '',
  'ы': 'y',
  'ь': '',
  'э': 'e',
  'ю': 'yu',
  'я': 'ya',
};
