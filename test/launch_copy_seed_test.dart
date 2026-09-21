import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:course_chatbot/src/data/sqlite_course_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/launch_copy.dart';
import 'package:course_chatbot/src/messages/launch_copy_defaults.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

Launch _upsert({
  required SqliteCourseRepository course,
  required String code,
  required String title,
  bool activate = false,
  String? description,
}) {
  return course.upsertLaunch(
    productCode: 'course',
    productTitle: 'Курс',
    launchCode: code,
    launchTitle: title,
    priceFullKopecks: LaunchPrices.fullKopecks,
    pricePromoKopecks: LaunchPrices.promoKopecks,
    depositKopecks: 500000,
    depositDueDays: 7,
    courseStartAt: DateTime.utc(2026, 10, 12),
    webinarAt: DateTime.utc(2026, 9, 29, 16),
    salesStartAt: DateTime.utc(2026, 9, 30),
    salesEndAt: Launch.impliedSalesEndAt(DateTime.utc(2026, 10, 12)),
    channelId: -1001,
    description: description,
    activate: activate,
  );
}

void main() {
  late Database db;
  late SqliteCourseRepository course;

  setUp(() {
    db = sqlite3.openInMemory();
    course = SqliteCourseRepository(
      databaseHandle: SqliteDatabaseHandle.fromDatabase(db, path: ':memory:'),
    )..init();
  });

  tearDown(() => db.dispose());

  test('init seeds current coloristic copy onto the active launch only', () {
    final active = _upsert(
      course: course,
      code: 'launch-1',
      title: MessageTemplates.defaultCourseTitle,
      activate: true,
    );
    final copyKeys = LaunchCopySlotKey.values
        .where((slot) => slot.storesInCopyTable)
        .toList(growable: false);
    expect(active.copy.asMap.keys, unorderedEquals(copyKeys));
    expect(active.copy.htmlOf(LaunchCopySlotKey.startOffer), LaunchCopyDefaults.startOffer);
    expect(active.copy.htmlOf(LaunchCopySlotKey.guideTitle), LaunchCopyDefaults.guideTitle);
    expect(active.copy.htmlOf(LaunchCopySlotKey.enrollPromo), contains('{price_promo}'));
    expect(active.copy.htmlOf(LaunchCopySlotKey.courseButton), LaunchCopyDefaults.courseButton);
    expect(course.listLaunchDozhim(active.id), hasLength(4));
    expect(course.listLaunchDozhim(active.id).first.payload?.html, contains('{course_start_join}'));
    expect(MessageTemplates().courseReplyButton(active), MessageTemplates.buttonEnroll);

    course.seedActiveLaunchCopy();
    expect(course.listLaunchDozhim(active.id), hasLength(4));
    expect(course.getLaunch(active.id)!.copy.asMap, hasLength(copyKeys.length));

    final second = _upsert(course: course, code: 'launch-2', title: 'Второй поток');
    expect(second.copy.asMap, isEmpty);
    expect(course.listLaunchDozhim(second.id), isEmpty);

    course.setActiveLaunch('launch-2');
    final stillEmpty = course.activeLaunch()!;
    expect(stillEmpty.code, 'launch-2');
    expect(stillEmpty.copy.asMap, isEmpty);
    expect(course.listLaunchDozhim(stillEmpty.id), isEmpty);
  });

  test('seed keeps a custom description already on the launch', () {
    final launch = _upsert(
      course: course,
      code: 'launch-1',
      title: 'Запуск',
      activate: true,
      description: 'Кастомное описание потока.',
    );
    expect(launch.copy.htmlOf(LaunchCopySlotKey.description), 'Кастомное описание потока.');
    expect(launch.copy.htmlOf(LaunchCopySlotKey.startOffer), LaunchCopyDefaults.startOffer);
  });
}
