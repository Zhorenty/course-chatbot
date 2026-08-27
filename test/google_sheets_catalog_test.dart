import 'package:course_chatbot/src/data/google_sheets_catalog_sync.dart';
import 'package:course_chatbot/src/data/google_sheets_dashboard.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:course_chatbot/src/data/sqlite_course_repository.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
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
      ..[CoursesSheet.headers.indexOf(CoursesSheet.depositDueDate)] = '05.10.2026';
    final parsed = CoursesSheetParser.parse(<List<Object?>>[
      CoursesSheet.headers,
      badPrice,
      badDate,
    ]);
    expect(parsed.rows, isEmpty);
    expect(parsed.skippedInvalidCount, 2);
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

      gateway.valuesBySheetId[CoursesSheet.sheetId]![1][CoursesSheet.headers.indexOf(
            CoursesSheet.priceFullRub,
          )] =
          21000;
      final updatesAfterSeed = gateway.updateValuesCount;
      final second = await sync.sync();
      expect(second.ok, isTrue);
      expect(second.seeded, isFalse);
      expect(gateway.updateValuesCount, updatesAfterSeed);
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
      expect(gateway.updateValuesCount, 0);
      expect(course.activeLaunch()?.priceFullKopecks, 1800000);
    });

    test('renames Sheet1 and FUNNEL on gid=0 to COURSES', () async {
      gateway.sheets = const [GoogleSheetsSheetInfo(title: 'FUNNEL', sheetId: 0)];
      final sync = GoogleSheetsCatalogSync(gateway: gateway, catalog: course);
      final result = await sync.sync();
      expect(result.ok, isTrue);
      expect(gateway.sheets.single.title, 'COURSES');
      expect(gateway.renamedSheetIds, contains(0));
    });
  });
}
