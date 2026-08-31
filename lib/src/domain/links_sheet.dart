import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/funnel.dart';

/// Human-editable deep-link catalog. Bot seeds and fills the URL column; ВОРОНКА must not wipe it.
abstract final class LinksSheet {
  static const String tabTitle = 'ССЫЛКИ';
  static const int columnCount = 5;
  static const int defaultHeaderRow = 3;
  static const int extraDataRows = 24;

  static const String origin = 'origin';
  static const String destination = 'destination';
  static const String payload = 'payload';
  static const String launchCode = 'launch_code';
  static const String url = 'url';

  static const String title = 'Курс · Диплинки';
  static const String titleAside = 'Правят руками';
  static const String hint =
      'Четыре стартовые метки уже есть. Новая (Stories, таргет) — строка с меткой латиницей. '
      'Куда: гайд или курс. Поток — выбери из списка запусков на COURSES; '
      'гайд и запись в MVP всегда текущий «да». Пусто = текущий. '
      'После правок нажми в боте «Обновить Google Sheets» или «Диплинки».';
  static const String invalidPayloadStatus = 'невалидная метка';

  static const List<String> headers = <String>[origin, destination, payload, launchCode, url];

  static const List<String> displayHeaders = <String>['Откуда', 'Куда', 'Метка', 'Поток', 'Ссылка'];

  static const List<String> headerNotes = <String>[
    'Откуда человек пришёл. Пример: Instagram Reels. Можно своё.',
    'Что открыть при первом Start: гайд или курс.',
    'Метка в ссылке t.me/бот?start=метка. Латиница, цифры и подчёркивание, до 64 символов.',
    'Выбери поток с листа COURSES (название запуска). Пусто — текущий набор. '
        'Гайд и оплата в MVP всё равно текущий запуск.',
    'Не заполняй. Бот сам подставит готовую t.me-ссылку.',
  ];

  static const int launchDropdownRows = 40;

  /// Data-validation formula: dropdown of COURSES launch titles.
  static String launchDropdownFormula({int coursesHeaderRow = CoursesSheet.defaultHeaderRow}) {
    final column = CoursesSheet.columnLetter(
      CoursesSheet.headers.indexOf(CoursesSheet.launchTitle),
    );
    final start = coursesHeaderRow + 2;
    final end = start + launchDropdownRows - 1;
    return "='${CoursesSheet.tabTitle}'!\$$column\$$start:\$$column\$$end";
  }

  static List<List<Object?>> seedRows({String? botUsername}) {
    final starters = <List<Object?>>[
      for (final link in AcquisitionLink.starters) seedDataRow(link, botUsername: botUsername),
    ];
    return withChrome(
      dataRows: <List<Object?>>[
        ...starters,
        for (var i = starters.length; i < extraDataRows; i++) padded(const <Object?>[]),
      ],
    );
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

  static List<Object?> seedDataRow(AcquisitionLink link, {String? botUsername}) {
    return padded(<Object?>[
      link.origin,
      link.destinationLabel,
      link.payload,
      link.launchCode ?? '',
      AcquisitionLink.telegramStartUrl(link.payload, botUsername) ?? '',
    ]);
  }

  static String columnLetter(int column) => CoursesSheet.columnLetter(column);

  static List<Object?> padded(List<Object?> cells) {
    return <Object?>[
      for (var i = 0; i < columnCount; i++) i < cells.length ? (cells[i] ?? '') : '',
    ];
  }

  static List<Object?> toDisplayHeaders(List<Object?> headerRow) {
    final mapped = <Object?>[
      for (var i = 0; i < headerRow.length; i++)
        displayNameFor(LinksSheetParser.canonicalHeader(headerRow[i])) ?? headerRow[i],
    ];
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
}

final class LinksSheetParseResult {
  const LinksSheetParseResult({required this.rows, required this.skippedInvalidCount, this.error});

  final List<AcquisitionLink> rows;
  final int skippedInvalidCount;
  final String? error;

  bool get isEmpty => rows.isEmpty;
}

abstract final class LinksSheetParser {
  static const Map<String, String> headerAliases = <String, String>{
    LinksSheet.origin: LinksSheet.origin,
    'откуда': LinksSheet.origin,
    'источник': LinksSheet.origin,
    LinksSheet.destination: LinksSheet.destination,
    'куда': LinksSheet.destination,
    'сценарий': LinksSheet.destination,
    LinksSheet.payload: LinksSheet.payload,
    'метка': LinksSheet.payload,
    'start': LinksSheet.payload,
    LinksSheet.launchCode: LinksSheet.launchCode,
    'код запуска': LinksSheet.launchCode,
    'запуск': LinksSheet.launchCode,
    'поток': LinksSheet.launchCode,
    'название запуска': LinksSheet.launchCode,
    LinksSheet.url: LinksSheet.url,
    'ссылка': LinksSheet.url,
    'диплинк': LinksSheet.url,
    'deep link': LinksSheet.url,
    'deeplink': LinksSheet.url,
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
      if (_headerIndex(rows[i]).containsKey(LinksSheet.payload)) {
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

  static LinksSheetParseResult parse(List<List<Object?>> rows) {
    if (rows.isEmpty) {
      return const LinksSheetParseResult(
        rows: <AcquisitionLink>[],
        skippedInvalidCount: 0,
        error: 'empty sheet',
      );
    }
    final headerAt = headerRowIndex(rows);
    if (headerAt == null) {
      return const LinksSheetParseResult(
        rows: <AcquisitionLink>[],
        skippedInvalidCount: 0,
        error: 'missing payload header',
      );
    }
    final headerIndex = _headerIndex(rows[headerAt]);
    final parsed = <AcquisitionLink>[];
    var skipped = 0;
    for (var i = headerAt + 1; i < rows.length; i++) {
      final raw = rows[i];
      if (_isEmptyRow(raw)) {
        continue;
      }
      final payloadRaw = _cell(raw, headerIndex, LinksSheet.payload);
      if (payloadRaw == null || payloadRaw.isEmpty) {
        continue;
      }
      final normalized = AcquisitionSource.normalize(payloadRaw);
      if (normalized == null) {
        skipped += 1;
        continue;
      }
      parsed.add(
        AcquisitionLink(
          origin: _cell(raw, headerIndex, LinksSheet.origin) ?? normalized,
          destination: parseDestination(_cell(raw, headerIndex, LinksSheet.destination)),
          payload: normalized,
          launchCode: _cell(raw, headerIndex, LinksSheet.launchCode),
          url: _cell(raw, headerIndex, LinksSheet.url),
        ),
      );
    }
    return LinksSheetParseResult(
      rows: AcquisitionLinkCatalog.dedupe(parsed),
      skippedInvalidCount: skipped,
    );
  }

  static List<Object?> urlColumnCells(List<List<Object?>> rows, {String? botUsername}) {
    final headerAt = headerRowIndex(rows);
    if (headerAt == null) {
      return const <Object?>[];
    }
    final headerIndex = _headerIndex(rows[headerAt]);
    final values = <Object?>[];
    for (var i = headerAt + 1; i < rows.length; i++) {
      final raw = rows[i];
      if (_isEmptyRow(raw)) {
        values.add('');
        continue;
      }
      final payloadRaw = _cell(raw, headerIndex, LinksSheet.payload);
      if (payloadRaw == null || payloadRaw.isEmpty) {
        values.add('');
        continue;
      }
      final normalized = AcquisitionSource.normalize(payloadRaw);
      if (normalized == null) {
        values.add(LinksSheet.invalidPayloadStatus);
        continue;
      }
      final url = AcquisitionLink.telegramStartUrl(normalized, botUsername);
      if (url == null) {
        values.add(_cell(raw, headerIndex, LinksSheet.url) ?? '');
        continue;
      }
      values.add(url);
    }
    return values;
  }

  static AcquisitionDestination parseDestination(String? raw) {
    final normalized = (raw ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'\s+'), ' ');
    switch (normalized) {
      case 'курс':
      case 'course':
      case 'карточка':
      case 'карточка курса':
        return AcquisitionDestination.course;
      default:
        return AcquisitionDestination.guide;
    }
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
        .replaceAll(RegExp('[,:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
}
