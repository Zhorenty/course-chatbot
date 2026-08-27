import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
import 'package:intl/intl.dart';

abstract final class GoogleSheetsFunnelDashboard {
  static const String defaultSheetTitle = 'ВОРОНКА';
  static const List<String> obsoleteSheetTitles = <String>[
    'FUNNEL',
    'FUNNEL__next',
    'FUNNEL__prev',
  ];
  static const int columnCount = 12;

  /// Одна тёплая гамма: лес → шалфей → слоновая кость, акцент пыльная роза.
  /// Без холодного синего и терракоты — они ломали соседство с зеленью.
  static const GoogleSheetsRgb ink = GoogleSheetsRgb(0.14, 0.20, 0.17);
  static const GoogleSheetsRgb paper = GoogleSheetsRgb(0.96, 0.95, 0.93);
  static const GoogleSheetsRgb header = GoogleSheetsRgb(0.18, 0.27, 0.23);
  static const GoogleSheetsRgb headerText = GoogleSheetsRgb(0.96, 0.94, 0.89);
  static const GoogleSheetsRgb muted = GoogleSheetsRgb(0.42, 0.45, 0.42);
  static const GoogleSheetsRgb kpiA = GoogleSheetsRgb(0.89, 0.93, 0.90);
  static const GoogleSheetsRgb kpiB = GoogleSheetsRgb(0.95, 0.91, 0.85);
  static const GoogleSheetsRgb kpiC = GoogleSheetsRgb(0.93, 0.89, 0.88);
  static const GoogleSheetsRgb section = GoogleSheetsRgb(0.29, 0.39, 0.35);
  static const GoogleSheetsRgb tableHead = GoogleSheetsRgb(0.85, 0.89, 0.85);

  static final DateFormat _stamp = DateFormat('dd.MM.yyyy HH:mm');

  static GoogleSheetsDashboard build(
    FunnelAnalytics analytics, {
    String sheetTitle = defaultSheetTitle,
  }) {
    final sheet = _FunnelSheetBuilder();
    sheet.paintSheet();
    sheet.writeHeader(analytics);
    sheet.writeKpis(analytics);
    sheet.writeFunnel(analytics);
    sheet.writeDynamics(analytics);
    sheet.writeWhereNow(analytics);
    return GoogleSheetsDashboard(
      sheetTitle: sheetTitle,
      rows: sheet.rows,
      charts: sheet.charts.where((chart) => chart.hasData).toList(growable: false),
      styles: sheet.styles,
      bandedTables: sheet.bandedTables,
      columnWidthsPx: const <int>[250, 110, 120, 250, 110, 120, 200, 90, 90, 90, 90, 180],
      obsoleteSheetTitles: sheetTitle == defaultSheetTitle
          ? GoogleSheetsFunnelDashboard.obsoleteSheetTitles
          : const <String>[],
    );
  }
}

final class _FunnelSheetBuilder {
  final List<List<Object?>> rows = <List<Object?>>[];
  final List<GoogleSheetsRangeStyle> styles = <GoogleSheetsRangeStyle>[];
  final List<GoogleSheetsBandedTable> bandedTables = <GoogleSheetsBandedTable>[];
  final List<GoogleSheetsChart> charts = <GoogleSheetsChart>[];

  int get nextRow => rows.length;

  void paintSheet() {
    styles.add(
      const GoogleSheetsRangeStyle(
        startRow: 0,
        endRowExclusive: 80,
        startColumn: 0,
        endColumnExclusive: GoogleSheetsFunnelDashboard.columnCount,
        background: GoogleSheetsFunnelDashboard.paper,
        foreground: GoogleSheetsFunnelDashboard.ink,
        fontSize: 10,
        wrap: true,
      ),
    );
  }

  void writeHeader(FunnelAnalytics analytics) {
    final stamp = GoogleSheetsFunnelDashboard._stamp.format(analytics.generatedAt.toLocal());
    _add(<Object?>['Курс · Воронка', '', '', '', '', '', '', '', '', '', '', 'Срез $stamp']);
    styles.add(
      const GoogleSheetsRangeStyle(
        startRow: 0,
        endRowExclusive: 1,
        startColumn: 0,
        endColumnExclusive: 11,
        background: GoogleSheetsFunnelDashboard.header,
        foreground: GoogleSheetsFunnelDashboard.headerText,
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
        startColumn: 11,
        endColumnExclusive: GoogleSheetsFunnelDashboard.columnCount,
        background: GoogleSheetsFunnelDashboard.header,
        foreground: GoogleSheetsFunnelDashboard.headerText,
        bold: true,
        fontSize: 11,
        horizontalAlignment: 'RIGHT',
        verticalAlignment: 'MIDDLE',
      ),
    );
    _add(const <Object?>[
      'Гайд → прогрев → оплата. Лист обновляет бот — руками не править. Карточка человека в админке бота.',
    ]);
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: 1,
        endRowExclusive: 2,
        startColumn: 0,
        endColumnExclusive: GoogleSheetsFunnelDashboard.columnCount,
        foreground: GoogleSheetsFunnelDashboard.muted,
        fontSize: 10,
        merge: true,
      ),
    );
    _blank();
  }

  void writeKpis(FunnelAnalytics analytics) {
    final labelRow = nextRow;
    _add(const <Object?>[
      'Start всего',
      '',
      'В воронке',
      '',
      'Взяли гайд',
      '',
      'Начали оплату',
      '',
      'Купили / списание',
      '',
      'Конверсия в оплату',
      '',
    ]);
    final valueRow = nextRow;
    final conversion = analytics.paidConversion;
    _add(<Object?>[
      analytics.startedUsersTotal,
      '',
      analytics.funnelUsers,
      '',
      analytics.guideTaken,
      '',
      analytics.checkoutStarted,
      '',
      analytics.paidUsers,
      '',
      conversion ?? '—',
      '',
    ]);
    final hintRow = nextRow;
    _add(<Object?>[
      'новых Start 7д: ${analytics.startedLast7Days}',
      '',
      'Start 30д: ${analytics.startedLast30Days}',
      '',
      '',
      '',
      '',
      '',
      'оплаты 7д: ${analytics.paidLast7Days}',
      '',
      'оплаты 30д: ${analytics.paidLast30Days}',
      '',
    ]);
    const cards = <(int, GoogleSheetsRgb)>[
      (0, GoogleSheetsFunnelDashboard.kpiA),
      (2, GoogleSheetsFunnelDashboard.kpiB),
      (4, GoogleSheetsFunnelDashboard.kpiC),
      (6, GoogleSheetsFunnelDashboard.kpiA),
      (8, GoogleSheetsFunnelDashboard.kpiB),
      (10, GoogleSheetsFunnelDashboard.kpiC),
    ];
    for (final card in cards) {
      styles.add(
        GoogleSheetsRangeStyle(
          startRow: labelRow,
          endRowExclusive: labelRow + 1,
          startColumn: card.$1,
          endColumnExclusive: card.$1 + 2,
          background: card.$2,
          foreground: GoogleSheetsFunnelDashboard.muted,
          bold: true,
          fontSize: 9,
          merge: true,
          horizontalAlignment: 'CENTER',
          verticalAlignment: 'MIDDLE',
          wrap: true,
        ),
      );
      styles.add(
        GoogleSheetsRangeStyle(
          startRow: valueRow,
          endRowExclusive: valueRow + 1,
          startColumn: card.$1,
          endColumnExclusive: card.$1 + 2,
          background: card.$2,
          foreground: GoogleSheetsFunnelDashboard.ink,
          bold: true,
          fontSize: 18,
          merge: true,
          horizontalAlignment: 'CENTER',
          verticalAlignment: 'MIDDLE',
          numberFormatType: card.$1 == 10 && conversion is num ? 'PERCENT' : null,
          numberFormatPattern: card.$1 == 10 ? '0.0%' : null,
        ),
      );
      styles.add(
        GoogleSheetsRangeStyle(
          startRow: hintRow,
          endRowExclusive: hintRow + 1,
          startColumn: card.$1,
          endColumnExclusive: card.$1 + 2,
          background: card.$2,
          foreground: GoogleSheetsFunnelDashboard.muted,
          fontSize: 9,
          merge: true,
          horizontalAlignment: 'CENTER',
          verticalAlignment: 'MIDDLE',
          wrap: true,
        ),
      );
      styles.add(
        GoogleSheetsRangeStyle(
          startRow: labelRow,
          endRowExclusive: hintRow + 1,
          startColumn: card.$1,
          endColumnExclusive: card.$1 + 2,
          borders: true,
        ),
      );
    }
    _blank();
  }

  void writeFunnel(FunnelAnalytics analytics) {
    _section('Путь по шагам');
    _add(const <Object?>['Шаг', 'Люди', 'От старта', 'От предыдущего']);
    final headerRow = nextRow - 1;
    final started = analytics.startedUsersTotal;
    final steps = <(String, int)>[
      ('1. Start', analytics.startedUsersTotal),
      ('2. Взяли гайд', analytics.guideTaken),
      ('3. В прогреве / воронке', analytics.funnelUsers),
      ('4. Начали оплату', analytics.checkoutStarted),
      ('5. Купили / списание', analytics.paidUsers),
    ];
    final firstData = nextRow;
    var previous = started;
    for (final step in steps) {
      _add(<Object?>[
        step.$1,
        step.$2,
        _ratioOrDash(started <= 0 ? null : step.$2 / started),
        _ratioOrDash(previous <= 0 ? null : step.$2 / previous),
      ]);
      previous = step.$2;
    }
    _table(headerRow, nextRow, 0, 4);
    _percentColumns(firstData, nextRow, const <int>[2, 3]);
    charts.add(
      GoogleSheetsChart(
        title: 'Путь по шагам',
        kind: GoogleSheetsChartKind.bar,
        headerRow: headerRow,
        endRowExclusive: nextRow,
        labelColumn: 0,
        valueColumn: 1,
        anchorRow: headerRow,
        anchorColumn: 5,
        widthPixels: 560,
        heightPixels: 280,
        legendPosition: 'NO_LEGEND',
      ),
    );
    _blank();
  }

  void writeDynamics(FunnelAnalytics analytics) {
    _section('Динамика 7 и 30 дней');
    _add(const <Object?>['Период', 'Start', 'Оплаты']);
    final headerRow = nextRow - 1;
    _add(<Object?>['7 дней', analytics.startedLast7Days, analytics.paidLast7Days]);
    _add(<Object?>['30 дней', analytics.startedLast30Days, analytics.paidLast30Days]);
    _table(headerRow, nextRow, 0, 3);
    charts.add(
      GoogleSheetsChart(
        title: 'Start 7 / 30 дней',
        kind: GoogleSheetsChartKind.column,
        headerRow: headerRow,
        endRowExclusive: nextRow,
        labelColumn: 0,
        valueColumn: 1,
        anchorRow: headerRow,
        anchorColumn: 4,
        widthPixels: 420,
        heightPixels: 220,
      ),
    );
    charts.add(
      GoogleSheetsChart(
        title: 'Оплаты 7 / 30 дней',
        kind: GoogleSheetsChartKind.column,
        headerRow: headerRow,
        endRowExclusive: nextRow,
        labelColumn: 0,
        valueColumn: 2,
        anchorRow: headerRow,
        anchorColumn: 8,
        widthPixels: 360,
        heightPixels: 220,
        legendPosition: 'NO_LEGEND',
      ),
    );
    _blank();
  }

  void writeWhereNow(FunnelAnalytics analytics) {
    _section('Где люди сейчас  ·  Откуда пришли');
    final headerRow = nextRow;
    _add(const <Object?>['Сейчас на шаге', 'Люди', '', 'Источник', 'Люди']);
    final phases = _ordered(analytics.phaseCounts, const <String>[
      'lead',
      'magnet_issued',
      'warming',
      'checkout',
      'deposit_paid',
      'paid',
      'access_granted',
      'cancelled',
    ], _phaseLabel);
    final sources = _ordered(analytics.sourceCounts, const <String>[
      'ig_reels_guide',
      'threads_guide',
      'tg_announce',
      'direct_course',
      'ig_stories_guide',
      'email_guide',
      'unknown',
    ], _sourceLabel);
    final firstData = nextRow;
    final height = phases.length > sources.length ? phases.length : sources.length;
    for (var index = 0; index < height; index++) {
      final phase = index < phases.length ? phases[index] : null;
      final source = index < sources.length ? sources[index] : null;
      _add(<Object?>[phase?.$1 ?? '', phase?.$2 ?? '', '', source?.$1 ?? '', source?.$2 ?? '']);
    }
    _table(headerRow, firstData + phases.length, 0, 2);
    _table(headerRow, firstData + sources.length, 3, 5);
    if (phases.any((item) => item.$2 > 0)) {
      charts.add(
        GoogleSheetsChart(
          title: 'Где сейчас',
          kind: GoogleSheetsChartKind.bar,
          headerRow: headerRow,
          endRowExclusive: firstData + phases.length,
          labelColumn: 0,
          valueColumn: 1,
          anchorRow: firstData + height,
          anchorColumn: 0,
          widthPixels: 520,
          heightPixels: 280,
          legendPosition: 'NO_LEGEND',
        ),
      );
    }
    if (sources.any((item) => item.$2 > 0)) {
      charts.add(
        GoogleSheetsChart(
          title: 'Откуда пришли',
          kind: GoogleSheetsChartKind.pie,
          headerRow: headerRow,
          endRowExclusive: firstData + sources.length,
          labelColumn: 3,
          valueColumn: 4,
          anchorRow: firstData + height,
          anchorColumn: 6,
          widthPixels: 420,
          heightPixels: 280,
          pieHole: 0.45,
        ),
      );
    }
  }

  void _section(String title) {
    final row = nextRow;
    _add(<Object?>[title]);
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: row,
        endRowExclusive: row + 1,
        startColumn: 0,
        endColumnExclusive: GoogleSheetsFunnelDashboard.columnCount,
        background: GoogleSheetsFunnelDashboard.section,
        foreground: GoogleSheetsFunnelDashboard.headerText,
        bold: true,
        fontSize: 12,
        merge: true,
        verticalAlignment: 'MIDDLE',
      ),
    );
  }

  void _table(int headerRow, int endRowExclusive, int startColumn, int endColumnExclusive) {
    if (endRowExclusive <= headerRow) {
      return;
    }
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: headerRow,
        endRowExclusive: headerRow + 1,
        startColumn: startColumn,
        endColumnExclusive: endColumnExclusive,
        background: GoogleSheetsFunnelDashboard.tableHead,
        foreground: GoogleSheetsFunnelDashboard.ink,
        bold: true,
        fontSize: 10,
        verticalAlignment: 'MIDDLE',
      ),
    );
    styles.add(
      GoogleSheetsRangeStyle(
        startRow: headerRow,
        endRowExclusive: endRowExclusive,
        startColumn: startColumn,
        endColumnExclusive: endColumnExclusive,
        borders: true,
        innerBorders: true,
      ),
    );
    bandedTables.add(
      GoogleSheetsBandedTable(
        startRow: headerRow,
        endRowExclusive: endRowExclusive,
        startColumn: startColumn,
        endColumnExclusive: endColumnExclusive,
      ),
    );
  }

  void _percentColumns(int startRow, int endRowExclusive, List<int> columns) {
    for (final column in columns) {
      styles.add(
        GoogleSheetsRangeStyle(
          startRow: startRow,
          endRowExclusive: endRowExclusive,
          startColumn: column,
          endColumnExclusive: column + 1,
          numberFormatType: 'PERCENT',
          numberFormatPattern: '0.0%',
        ),
      );
    }
  }

  void _blank() => _add(const <Object?>[]);

  void _add(List<Object?> cells) {
    final row = List<Object?>.filled(GoogleSheetsFunnelDashboard.columnCount, '');
    final limit = cells.length < GoogleSheetsFunnelDashboard.columnCount
        ? cells.length
        : GoogleSheetsFunnelDashboard.columnCount;
    for (var index = 0; index < limit; index++) {
      row[index] = cells[index];
    }
    rows.add(row);
  }

  Object _ratioOrDash(double? value) => value ?? '—';

  List<(String, int)> _ordered(
    Map<String, int> counts,
    List<String> order,
    String Function(String) labelOf,
  ) {
    final seen = <String>{};
    final items = <(String, int)>[];
    for (final key in order) {
      final value = counts[key];
      if (value == null) {
        continue;
      }
      seen.add(key);
      items.add((labelOf(key), value));
    }
    final remaining = counts.entries.where((entry) => !seen.contains(entry.key)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in remaining) {
      items.add((labelOf(entry.key), entry.value));
    }
    return items;
  }

  String _phaseLabel(String raw) {
    final phase = FunnelPhaseX.parse(raw);
    return switch (phase) {
      FunnelPhase.lead => 'пришли',
      FunnelPhase.magnetIssued => 'взяли гайд',
      FunnelPhase.warming => 'в прогреве',
      FunnelPhase.checkout => 'оформление',
      FunnelPhase.depositPaid => 'предоплата',
      FunnelPhase.paid => 'оплачено',
      FunnelPhase.accessGranted => 'доступ выдан',
      FunnelPhase.cancelled => 'отменено',
    };
  }

  String _sourceLabel(String raw) => switch (raw) {
    'ig_reels_guide' => 'Instagram Reels',
    'threads_guide' => 'Threads',
    'tg_announce' => 'Telegram, анонс',
    'direct_course' => 'прямая ссылка',
    'ig_stories_guide' => 'Stories',
    'email_guide' => 'рассылка',
    'unknown' => 'без метки',
    _ => raw,
  };
}
