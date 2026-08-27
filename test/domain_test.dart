import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

void main() {
  test('quiet hours 10-21 Moscow skip 09 and 21', () {
    const hours = QuietHours(timezoneOffsetHours: 3, fromHour: 10, toHour: 21);
    expect(hours.isQuiet(DateTime.utc(2026, 8, 26, 6)), isTrue); // 09 MSK
    expect(hours.isQuiet(DateTime.utc(2026, 8, 26, 7)), isFalse); // 10 MSK
    expect(hours.isQuiet(DateTime.utc(2026, 8, 26, 17)), isFalse); // 20 MSK
    expect(hours.isQuiet(DateTime.utc(2026, 8, 26, 18)), isTrue); // 21 MSK
  });

  test('first /start payload wins', () {
    expect(AcquisitionSource.normalize('Ig_Reels_Guide'), 'ig_reels_guide');
    expect(AcquisitionSource.opensCourseCard('direct_course'), isTrue);
    expect(AcquisitionSource.opensCourseCard('ig_reels_guide'), isFalse);
    expect(AcquisitionSource.normalize('bad payload!'), isNull);
  });

  test('sheet extras open course only when destination is курс', () {
    final catalog = AcquisitionLinkCatalog()
      ..replaceAll(<AcquisitionLink>[
        ...AcquisitionLink.starters,
        const AcquisitionLink(
          origin: 'Таргет',
          destination: AcquisitionDestination.course,
          payload: 'ads_course',
        ),
        const AcquisitionLink(
          origin: 'Stories',
          destination: AcquisitionDestination.guide,
          payload: 'ig_extra',
        ),
      ]);
    expect(catalog.opensCourseCard('ads_course'), isTrue);
    expect(catalog.opensCourseCard('ig_extra'), isFalse);
    expect(catalog.opensCourseCard('direct_course'), isTrue);
    expect(catalog.opensCourseCard('unknown_tag'), isFalse);
  });

  test('deposit does not grant access on success, full and installment do', () {
    expect(PaymentKind.deposit.grantsAccessOnSuccess, isFalse);
    expect(PaymentKind.full.grantsAccessOnSuccess, isTrue);
    expect(PaymentKind.remainder.grantsAccessOnSuccess, isTrue);
    expect(PaymentKind.installment.grantsAccessOnSuccess, isTrue);
  });

  test('callback id parser uses the prefix length', () {
    expect(MessageTemplates.idFromCallback('ap:99', MessageTemplates.cbAdminPaid), 99);
    expect(MessageTemplates.idFromCallback('cp:12', MessageTemplates.cbContinuePay), 12);
    expect(MessageTemplates.idFromCallback('g', MessageTemplates.cbAdminPaid), isNull);
  });

  test('broadcast segment codes are short and parse back', () {
    expect(BroadcastSegment.guideNotPaid.code, 'g');
    expect(BroadcastSegment.fromCode('a'), BroadcastSegment.allStarted);
    expect(BroadcastSegment.fromCode('l'), BroadcastSegment.leadNoGuide);
    expect(BroadcastSegment.fromCode('x'), BroadcastSegment.cancelled);
    expect(BroadcastSegment.fromCode('nope'), isNull);
    expect(MessageTemplates.segmentFromCallback('bs:p'), BroadcastSegment.paidAccess);
  });

  test('funnel phases do not move backwards except cancel/admin override', () {
    expect(FunnelPhase.paid.canTransitionTo(FunnelPhase.magnetIssued), isFalse);
    expect(FunnelPhase.accessGranted.canTransitionTo(FunnelPhase.checkout), isFalse);
    expect(FunnelPhase.warming.canTransitionTo(FunnelPhase.checkout), isTrue);
    expect(FunnelPhase.paid.canTransitionTo(FunnelPhase.accessGranted), isTrue);
    expect(FunnelPhase.paid.canTransitionTo(FunnelPhase.cancelled), isTrue);
    expect(FunnelPhase.cancelled.canTransitionTo(FunnelPhase.paid), isTrue);
  });

  test('parseRubStringToKopecks avoids binary float drift', () {
    expect(parseRubStringToKopecks('10000.00'), 1000000);
    expect(parseRubStringToKopecks('19.99'), 1999);
    expect(parseRubStringToKopecks('0.10'), 10);
    expect(parseRubStringToKopecks('7'), 700);
  });
}
