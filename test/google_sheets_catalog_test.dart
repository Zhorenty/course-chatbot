import 'package:course_chatbot/src/data/google_sheets_catalog_sync.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:course_chatbot/src/data/sqlite_course_repository.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

void main() {
  test('seed row parses to 18000/5000 rub and October 2026 dates', () {
    final parsed = CoursesSheetParser.parse(CoursesSheet.seedRows());
    expect(parsed.rows, hasLength(1));
    final draft = parsed.active!;
    expect(draft.launchCode, 'launch-1');
    expect(draft.productCode, 'course');
    expect(draft.priceFullKopecks, 1800000);
    expect(draft.depositKopecks, 500000);
    expect(draft.depositDueAt, DateTime.utc(2026, 10, 5, 20, 59, 59));
    expect(draft.courseStartAt, DateTime.utc(2026, 10, 12));
    expect(draft.isActive, isTrue);
  });

  test('parser skips empty rows and rows without launch_code', () {
    final parsed = CoursesSheetParser.parse(<List<Object?>>[
      CoursesSheet.headers,
      <Object?>[],
      CoursesSheet.seedDataRow(),
      <Object?>['course', 'Курс', '', 'Nope', '1', 1, 0],
    ]);
    expect(parsed.rows, hasLength(1));
    expect(parsed.active!.launchCode, 'launch-1');
  });

  test('multiple is_active flags pick the first row and stay valid', () {
    final second = List<Object?>.from(CoursesSheet.seedDataRow())
      ..[CoursesSheet.headers.indexOf(CoursesSheet.launchCode)] = 'launch-2'
      ..[CoursesSheet.headers.indexOf(CoursesSheet.priceFullRub)] = 20000;
    final parsed = CoursesSheetParser.parse(<List<Object?>>[
      CoursesSheet.headers,
      CoursesSheet.seedDataRow(),
      second,
    ]);
    expect(parsed.multipleActive, isTrue);
    expect(parsed.active!.launchCode, 'launch-1');
    expect(parsed.active!.priceFullKopecks, 1800000);
  });

  test('invalid price or date skips the row', () {
    final badPrice = List<Object?>.from(CoursesSheet.seedDataRow())
      ..[CoursesSheet.headers.indexOf(CoursesSheet.priceFullRub)] = 0;
    final badDate = List<Object?>.from(CoursesSheet.seedDataRow())
      ..[CoursesSheet.headers.indexOf(CoursesSheet.launchCode)] = 'launch-bad'
      ..[CoursesSheet.headers.indexOf(CoursesSheet.depositDueDate)] = 'нет';
    final parsed = CoursesSheetParser.parse(<List<Object?>>[
      CoursesSheet.headers,
      badPrice,
      badDate,
    ]);
    expect(parsed.rows, isEmpty);
    expect(parsed.skippedInvalidCount, 2);
  });

  test('Russian headers and dotted dates parse', () {
    final parsed = CoursesSheetParser.parse(<List<Object?>>[
      CoursesSheet.displayHeaders,
      <Object?>[
        'course',
        'Курс',
        'launch-1',
        'Запуск',
        'да',
        18000,
        5000,
        '05.10.2026',
        '12.10.2026',
      ],
    ]);
    expect(parsed.rows, hasLength(1));
    expect(parsed.active!.isActive, isTrue);
    expect(parsed.active!.depositDueAt, DateTime.utc(2026, 10, 5, 20, 59, 59));
    expect(parsed.active!.courseStartAt, DateTime.utc(2026, 10, 12));
  });

  test('pretty seed layout has chrome, Russian headers, status and parses', () {
    final rows = CoursesSheet.seedRows();
    expect(rows[0].first, CoursesSheet.title);
    expect(rows[1].first, contains('текущий набор'));
    expect(rows[1].first, isNot(contains('FUNNEL')));
    expect(rows[3].first, 'Код продукта');
    expect(rows[3].last, 'статус');
    expect(rows[4].last.toString(), startsWith('='));
    expect(CoursesSheetParser.headerRowIndex(rows), 3);
    final parsed = CoursesSheetParser.parse(rows);
    expect(parsed.active!.priceFullKopecks, 1800000);
  });

  test('status formula names missing fields and готов', () {
    final formula = CoursesSheet.statusFormula(row: 5);
    expect(formula, startsWith('='));
    expect(formula, contains('SUMPRODUCT(LEN('));
    expect(formula, isNot(contains('COUNTA(')));
    expect(formula, contains('готово'));
    expect(formula, contains('нет кода запуска'));
    expect(formula, contains('нет цены'));
    expect(formula, contains('нет даты доплаты'));
    expect(formula, isNot(contains('.env')));
    expect(CoursesSheet.headerNotes[7], contains('Выбери в календаре'));
    expect(CoursesSheet.headerNotes.last, contains('пустая'));
    expect(CoursesSheet.displayHeaders, isNot(contains('file_id гайда')));
    expect(CoursesSheet.headers.last, CoursesSheet.status);
    expect(CoursesSheet.displayHeaders, hasLength(CoursesSheet.columnCount));
    expect(CoursesSheet.headerNotes, hasLength(CoursesSheet.columnCount));
  });

  group('GoogleSheetsCatalogSync', () {
    late Database db;
    late SqliteCourseRepository course;
    late FakeGoogleSheetsGateway gateway;

    setUp(() {
      db = sqlite3.openInMemory();
      final handle = SqliteDatabaseHandle.fromDatabase(db, path: ':memory:');
      course = SqliteCourseRepository(databaseHandle: handle)..init();
      JobDedupeRepository(databaseHandle: handle).initSchema();
      gateway = FakeGoogleSheetsGateway();
    });

    tearDown(() => db.dispose());

    test('empty gid=0 is seeded once and upserted', () async {
      final sync = GoogleSheetsCatalogSync(gateway: gateway, catalog: course);
      final first = await sync.sync();
      expect(first.ok, isTrue);
      expect(first.seeded, isTrue);
      expect(course.activeLaunch()?.priceFullKopecks, 1800000);
      expect(gateway.applyLookCount, 2);
      expect(gateway.looksBySheetId[CoursesSheet.sheetId]?.hideGridlines, isTrue);
      expect(gateway.looksBySheetId[CoursesSheet.sheetId]?.notes, hasLength(14));
      expect(gateway.looksBySheetId[CoursesSheet.sheetId]?.columnCount, 14);
      expect(gateway.valuesBySheetId[0]!.first.first, CoursesSheet.title);
      final seeded = gateway.valuesBySheetId[0]!;
      final statusCol = CoursesSheetParser.columnIndex(seeded, CoursesSheet.status)!;
      expect(seeded[CoursesSheet.defaultHeaderRow][statusCol], 'статус');
      expect(seeded[CoursesSheet.defaultHeaderRow + 1][statusCol].toString(), startsWith('='));

      final sheet = gateway.valuesBySheetId[CoursesSheet.sheetId]!;
      final priceCol = CoursesSheetParser.columnIndex(sheet, CoursesSheet.priceFullRub)!;
      final dataRow = CoursesSheetParser.headerRowIndex(sheet)! + 1;
      sheet[dataRow][priceCol] = 21000;
      final updatesAfterSeed = gateway.updateValuesCount;
      final looksAfterSeed = gateway.applyLookCount;
      final second = await sync.sync();
      expect(second.ok, isTrue);
      expect(second.seeded, isFalse);
      expect(gateway.updateValuesCount, updatesAfterSeed + 2);
      expect(gateway.applyLookCount, looksAfterSeed + 2);
      expect(course.activeLaunch()?.priceFullKopecks, 2100000);
    });

    test('empty lead_magnet_file_id does not wipe cached sqlite file_id', () async {
      course.upsertActiveLaunch(
        productCode: 'course',
        productTitle: 'Курс',
        launchCode: 'launch-1',
        launchTitle: 'Запуск',
        priceFullKopecks: 1800000,
        depositKopecks: 500000,
        depositDueDays: 7,
        leadMagnetFileId: 'cached-file',
      );
      gateway.sheets = const [GoogleSheetsSheetInfo(title: 'COURSES', sheetId: 0)];
      gateway.valuesBySheetId[0] = CoursesSheet.seedRows();
      final sync = GoogleSheetsCatalogSync(gateway: gateway, catalog: course);
      final result = await sync.sync();
      expect(result.ok, isTrue);
      expect(course.activeLaunch()?.leadMagnetFileId, 'cached-file');
    });

    test('broken rows do not destroy an existing sqlite launch', () async {
      course.upsertActiveLaunch(
        productCode: 'course',
        productTitle: 'Курс',
        launchCode: 'launch-1',
        launchTitle: 'Запуск',
        priceFullKopecks: 1800000,
        depositKopecks: 500000,
        depositDueDays: 7,
      );
      final broken = List<Object?>.from(CoursesSheet.seedDataRow())
        ..[CoursesSheet.headers.indexOf(CoursesSheet.priceFullRub)] = 0;
      gateway.sheets = const [GoogleSheetsSheetInfo(title: 'COURSES', sheetId: 0)];
      gateway.valuesBySheetId[0] = <List<Object?>>[CoursesSheet.headers, broken];
      final sync = GoogleSheetsCatalogSync(gateway: gateway, catalog: course);
      final result = await sync.sync();
      expect(result.ok, isFalse);
      expect(course.activeLaunch()?.priceFullKopecks, 1800000);
      expect(
        gateway.valuesBySheetId[0]![1][CoursesSheet.headers.indexOf(CoursesSheet.priceFullRub)],
        0,
      );
      expect(gateway.valuesBySheetId[0]![0].first, CoursesSheet.productCode);
    });

    test('snake_case catalog is wrapped in chrome without losing the row', () async {
      gateway.sheets = const [GoogleSheetsSheetInfo(title: 'COURSES', sheetId: 0)];
      gateway.valuesBySheetId[0] = <List<Object?>>[
        List<Object?>.from(CoursesSheet.headers),
        <Object?>[
          'course',
          'Курс',
          'launch-1',
          'Запуск',
          '1',
          18000,
          5000,
          '2026-10-05',
          '2026-10-12',
        ],
      ];
      final sync = GoogleSheetsCatalogSync(gateway: gateway, catalog: course);
      final result = await sync.sync();
      expect(result.ok, isTrue);
      expect(gateway.valuesBySheetId[0]!.first.first, CoursesSheet.title);
      expect(gateway.valuesBySheetId[0]![3].first, 'Код продукта');
      expect(gateway.valuesBySheetId[0]![3].last, 'статус');
      expect(course.activeLaunch()?.code, 'launch-1');
    });

    test('renames Sheet1 and FUNNEL on gid=0 to COURSES', () async {
      gateway.sheets = const [GoogleSheetsSheetInfo(title: 'FUNNEL', sheetId: 0)];
      final sync = GoogleSheetsCatalogSync(gateway: gateway, catalog: course);
      final result = await sync.sync();
      expect(result.ok, isTrue);
      expect(gateway.sheets.any((sheet) => sheet.title == CoursesSheet.tabTitle), isTrue);
      expect(gateway.sheets.any((sheet) => sheet.title == LinksSheet.tabTitle), isTrue);
      expect(gateway.renamedSheetIds, contains(0));
      expect(gateway.valuesBySheetId[0]!.first.first, CoursesSheet.title);
    });

    test('sync keeps inactive COURSES rows in sqlite', () async {
      final second = List<Object?>.from(CoursesSheet.seedDataRow())
        ..[CoursesSheet.headers.indexOf(CoursesSheet.launchCode)] = 'launch-2'
        ..[CoursesSheet.headers.indexOf(CoursesSheet.launchTitle)] = 'Ноябрь'
        ..[CoursesSheet.headers.indexOf(CoursesSheet.isActive)] = ''
        ..[CoursesSheet.headers.indexOf(CoursesSheet.priceFullRub)] = 21000;
      gateway.sheets = const [GoogleSheetsSheetInfo(title: 'COURSES', sheetId: 0)];
      gateway.valuesBySheetId[0] = CoursesSheet.withChrome(
        dataRows: <List<Object?>>[CoursesSheet.seedDataRow(), second],
      );
      final sync = GoogleSheetsCatalogSync(gateway: gateway, catalog: course);
      final result = await sync.sync();
      expect(result.ok, isTrue);
      expect(course.activeLaunch()?.code, 'launch-1');
      expect(course.launchByCode('launch-2')?.priceFullKopecks, 2100000);
      expect(course.launchByCode('launch-1')?.priceFullKopecks, 1800000);
    });
  });

  group('ССЫЛКИ catalog', () {
    late Database db;
    late SqliteCourseRepository course;
    late FakeGoogleSheetsGateway gateway;
    late AcquisitionLinkCatalog links;

    setUp(() {
      db = sqlite3.openInMemory();
      final handle = SqliteDatabaseHandle.fromDatabase(db, path: ':memory:');
      course = SqliteCourseRepository(databaseHandle: handle)..init();
      JobDedupeRepository(databaseHandle: handle).initSchema();
      gateway = FakeGoogleSheetsGateway();
      links = AcquisitionLinkCatalog();
    });

    tearDown(() => db.dispose());

    test('seeds empty sheet with four starters and fills t.me URLs', () async {
      final sync = GoogleSheetsCatalogSync(
        gateway: gateway,
        catalog: course,
        links: links,
        botUsername: 'course_bot',
      );
      final result = await sync.sync();
      expect(result.ok, isTrue);
      final tab = gateway.sheets.firstWhere((sheet) => sheet.title == LinksSheet.tabTitle);
      final sheet = gateway.valuesBySheetId[tab.sheetId]!;
      expect(sheet.first.first, LinksSheet.title);
      final parsed = LinksSheetParser.parse(sheet);
      expect(parsed.rows.map((row) => row.payload).toList(), <String>[
        'ig_reels_guide',
        'threads_guide',
        'tg_announce',
        'direct_course',
      ]);
      final urlCol = LinksSheetParser.columnIndex(sheet, LinksSheet.url)!;
      final dataRow = LinksSheetParser.headerRowIndex(sheet)! + 1;
      expect(sheet[dataRow][urlCol], 'https://t.me/course_bot?start=ig_reels_guide');
      expect(links.entries, hasLength(4));
      expect(links.opensCourseCard('tg_announce'), isTrue);
      final headerAt = LinksSheetParser.headerRowIndex(sheet)!;
      expect(sheet.length, greaterThanOrEqualTo(headerAt + 1 + LinksSheet.extraDataRows));
    });

    test('second sync keeps a human fifth row and fills its URL', () async {
      final sync = GoogleSheetsCatalogSync(
        gateway: gateway,
        catalog: course,
        links: links,
        botUsername: 'course_bot',
      );
      await sync.sync();
      final tab = gateway.sheets.firstWhere((sheet) => sheet.title == LinksSheet.tabTitle);
      final sheet = gateway.valuesBySheetId[tab.sheetId]!;
      sheet.add(LinksSheet.padded(<Object?>['Таргет', 'курс', 'ads_course', '']));
      final result = await sync.sync();
      expect(result.ok, isTrue);
      final again = gateway.valuesBySheetId[tab.sheetId]!;
      final parsed = LinksSheetParser.parse(again);
      expect(parsed.rows.map((row) => row.payload), contains('ads_course'));
      expect(links.opensCourseCard('ads_course'), isTrue);
      expect(again.any((row) => row.contains('https://t.me/course_bot?start=ads_course')), isTrue);
    });

    test('invalid payload is skipped and marked in the URL column', () async {
      gateway.sheets = <GoogleSheetsSheetInfo>[
        const GoogleSheetsSheetInfo(title: CoursesSheet.tabTitle, sheetId: CoursesSheet.sheetId),
        const GoogleSheetsSheetInfo(title: LinksSheet.tabTitle, sheetId: 2),
      ];
      gateway.valuesBySheetId[CoursesSheet.sheetId] = CoursesSheet.seedRows();
      gateway.valuesBySheetId[2] = LinksSheet.withChrome(
        dataRows: <List<Object?>>[
          LinksSheet.seedDataRow(AcquisitionLink.starters.first),
          LinksSheet.padded(<Object?>['Сломанная', 'гайд', 'bad payload!', '']),
        ],
      );
      final sync = GoogleSheetsCatalogSync(
        gateway: gateway,
        catalog: course,
        links: links,
        botUsername: 'course_bot',
      );
      await sync.sync();
      expect(links.entries.map((row) => row.payload), isNot(contains('bad payload!')));
      final sheet = gateway.valuesBySheetId[2]!;
      expect(sheet.any((row) => row.contains(LinksSheet.invalidPayloadStatus)), isTrue);
      expect(
        sheet.length,
        greaterThanOrEqualTo(LinksSheet.defaultHeaderRow + 1 + LinksSheet.extraDataRows),
      );
    });

    test('without bot username does not invent t.me URLs', () async {
      final sync = GoogleSheetsCatalogSync(gateway: gateway, catalog: course, links: links);
      await sync.sync();
      final tab = gateway.sheets.firstWhere((sheet) => sheet.title == LinksSheet.tabTitle);
      final sheet = gateway.valuesBySheetId[tab.sheetId]!;
      expect(
        sheet.any((row) => row.any((cell) => cell.toString().contains('https://t.me/'))),
        isFalse,
      );
    });
  });
}
