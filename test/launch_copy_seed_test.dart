import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:course_chatbot/src/data/sqlite_course_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/launch_copy.dart';
import 'package:course_chatbot/src/messages/funnel_media.dart';
import 'package:course_chatbot/src/messages/launch_copy_defaults.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/messages/stored_copy_media.dart';
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

  test('launch keeps its promo checkout link and falls back to LeadPay', () {
    final plain = _upsert(course: course, code: 'launch-1', title: 'Запуск', activate: true);
    expect(plain.promoCheckoutUrl, isNull);
    expect(plain.resolvedPromoCheckoutUrl, LaunchPrices.defaultPromoCheckoutUrl);
    final custom = course.upsertLaunch(
      productCode: 'course',
      productTitle: 'Курс',
      launchCode: 'launch-1',
      launchTitle: 'Запуск',
      priceFullKopecks: LaunchPrices.fullKopecks,
      pricePromoKopecks: LaunchPrices.promoKopecks,
      depositKopecks: 500000,
      depositDueDays: 7,
      courseStartAt: DateTime.utc(2026, 10, 12),
      webinarAt: DateTime.utc(2026, 9, 29, 16),
      salesStartAt: DateTime.utc(2026, 9, 30),
      salesEndAt: Launch.impliedSalesEndAt(DateTime.utc(2026, 10, 12)),
      channelId: -1001,
      promoCheckoutUrl: ' https://pay.example/promo ',
    );
    expect(custom.promoCheckoutUrl, 'https://pay.example/promo');
    expect(custom.resolvedPromoCheckoutUrl, 'https://pay.example/promo');
  });

  test('init refreshes copy seeded from old defaults and keeps custom slots', () {
    final active = _upsert(course: course, code: 'launch-1', title: 'Запуск', activate: true);
    const oldPosts = <String>['assets/funnel/post_1.jpg', 'assets/funnel/post_2.jpg'];
    course.upsertLaunchCopySlot(
      launchId: active.id,
      slot: LaunchCopySlotKey.afterWebinar,
      payload: storedCopyFromHtml('после эфира', photoPaths: oldPosts),
    );
    course.upsertLaunchCopySlot(
      launchId: active.id,
      slot: LaunchCopySlotKey.salesOpen,
      payload: storedCopyFromHtml(
        'своё',
        photoPaths: const <String>['assets/funnel/post_2.jpg', 'assets/funnel/post_1.jpg'],
      ),
    );
    course.upsertLaunchCopySlot(
      launchId: active.id,
      slot: LaunchCopySlotKey.enrollPromo,
      payload: storedCopyFromHtml('Спеццена\nПосле полной оплаты придет ссылка на канал курса.'),
    );

    course.init();

    final copy = course.getLaunch(active.id)!.copy;
    final afterWebinar = copy[LaunchCopySlotKey.afterWebinar]!;
    expect(afterWebinar.html, 'после эфира');
    expect(
      afterWebinar.media.map((item) => item.localPath).toList(),
      FunnelMedia.pathsFor('webinar_next'),
    );
    expect(afterWebinar.media, hasLength(9));
    expect(copy[LaunchCopySlotKey.salesOpen]!.media, hasLength(2));
    expect(
      copy.htmlOf(LaunchCopySlotKey.enrollPromo),
      'Спеццена\nПосле оплаты с тобой свяжется администратор и пригласит тебя в группу.',
    );
  });

  test('init adds the master-class recording link to the seeded follow-up letter', () {
    final active = _upsert(course: course, code: 'launch-1', title: 'Запуск', activate: true);
    final seeded = LaunchCopyDefaults.afterWebinar.replaceFirst(
      LaunchCopyDefaults.afterWebinarRecordingLine,
      '<i>Запись мастер-класса:</i>',
    );
    course.upsertLaunchCopySlot(
      launchId: active.id,
      slot: LaunchCopySlotKey.afterWebinar,
      payload: storedCopyFromHtml(seeded),
    );
    final custom = _upsert(course: course, code: 'launch-2', title: 'Второй поток');
    course.upsertLaunchCopySlot(
      launchId: custom.id,
      slot: LaunchCopySlotKey.afterWebinar,
      payload: storedCopyFromHtml('свой текст'),
    );

    course.init();

    expect(
      course.getLaunch(active.id)!.copy.htmlOf(LaunchCopySlotKey.afterWebinar),
      LaunchCopyDefaults.afterWebinar,
    );
    expect(course.getLaunch(custom.id)!.copy.htmlOf(LaunchCopySlotKey.afterWebinar), 'свой текст');
  });

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
