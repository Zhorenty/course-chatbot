import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/admin_payment_status.dart';
import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/participant_list.dart';
import 'package:course_chatbot/src/domain/sales_window.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

import 'support/launch_fixture.dart';

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
    expect(AcquisitionSource.normalize(AcquisitionSource.adminManual), 'admin');
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

  test('deposit does not grant access on success, full and remainder do', () {
    expect(PaymentKind.deposit.grantsAccessOnSuccess, isFalse);
    expect(PaymentKind.full.grantsAccessOnSuccess, isTrue);
    expect(PaymentKind.remainder.grantsAccessOnSuccess, isTrue);
  });

  test('callback id parser uses the prefix length', () {
    expect(MessageTemplates.idFromCallback('ap:99', MessageTemplates.cbAdminPaid), 99);
    expect(MessageTemplates.idFromCallback('cp:12', MessageTemplates.cbContinuePay), 12);
    expect(MessageTemplates.idFromCallback('g', MessageTemplates.cbAdminPaid), isNull);
    expect(MessageTemplates.adminStatusFromCallback('as:p:99'), (
      status: AdminPaymentStatus.paid,
      userId: 99,
    ));
    expect(MessageTemplates.adminStatusFromCallback('as:x:99'), isNull);
  });

  test('admin payment status resolves order before funnel leftovers', () {
    expect(AdminPaymentStatusX.resolve(phase: FunnelPhase.warming), AdminPaymentStatus.unpaid);
    expect(AdminPaymentStatusX.resolve(phase: FunnelPhase.accessGranted), AdminPaymentStatus.paid);
    expect(AdminPaymentStatusX.resolve(phase: FunnelPhase.depositPaid), AdminPaymentStatus.deposit);
    expect(AdminPaymentStatusX.resolve(phase: FunnelPhase.cancelled), AdminPaymentStatus.cancelled);
    expect(AdminPaymentStatus.paid.canIssueChannelInvite, isTrue);
    expect(AdminPaymentStatus.unpaid.canIssueChannelInvite, isFalse);
    expect(AdminPaymentStatus.deposit.canIssueChannelInvite, isFalse);
    expect(AdminPaymentStatus.cancelled.canIssueChannelInvite, isFalse);
    expect(AdminPaymentStatus.paid.canRemoveFromCourse(), isTrue);
    expect(AdminPaymentStatus.unpaid.canRemoveFromCourse(), isFalse);
    expect(AdminPaymentStatus.deposit.canRemoveFromCourse(), isFalse);
    expect(AdminPaymentStatus.cancelled.canRemoveFromCourse(), isFalse);
    expect(AdminPaymentStatus.unpaid.canRemoveFromCourse(inChannel: true), isTrue);
    expect(AdminPaymentStatus.cancelled.canRemoveFromCourse(inChannel: true), isTrue);
  });

  test('broadcast segment codes are short and parse back', () {
    expect(BroadcastSegment.guideNotPaid.code, 'g');
    expect(BroadcastSegment.fromCode('a'), BroadcastSegment.allStarted);
    expect(BroadcastSegment.fromCode('l'), BroadcastSegment.leadNoGuide);
    expect(BroadcastSegment.fromCode('n'), BroadcastSegment.paidNotJoined);
    expect(BroadcastSegment.fromCode('k'), BroadcastSegment.courseLeadNoCheckout);
    expect(BroadcastSegment.fromCode('nope'), isNull);
    expect(MessageTemplates.segmentFromCallback('bs:p'), BroadcastSegment.paidAccess);
    expect(
      BroadcastSegment.ordered({BroadcastSegment.paidAccess, BroadcastSegment.guideNotPaid}),
      <BroadcastSegment>[BroadcastSegment.guideNotPaid, BroadcastSegment.paidAccess],
    );
    expect(BroadcastSegment.coversAll(BroadcastSegment.values), isTrue);
    expect(BroadcastSegment.coversAll({BroadcastSegment.paidAccess}), isFalse);
  });

  test('participant list segment codes are short and parse back', () {
    expect(ParticipantListSegment.webinarRsvp.code, 'w');
    expect(ParticipantListSegment.fromCode('p'), ParticipantListSegment.paid);
    expect(ParticipantListSegment.fromCode('nope'), isNull);
    expect(MessageTemplates.peopleSegmentFromCallback('ps:w'), (
      segment: ParticipantListSegment.webinarRsvp,
      page: 0,
    ));
    expect(MessageTemplates.peopleSegmentFromCallback('ps:p:2'), (
      segment: ParticipantListSegment.paid,
      page: 2,
    ));
    expect(MessageTemplates.peopleSegmentData(ParticipantListSegment.paid, page: 2), 'ps:p:2');
    expect(
      MessageTemplates.peopleSegmentData(ParticipantListSegment.webinarRsvp).length,
      lessThanOrEqualTo(64),
    );
  });

  test('funnel phases do not move backwards except cancel/admin override', () {
    expect(FunnelPhase.paid.canTransitionTo(FunnelPhase.magnetIssued), isFalse);
    expect(FunnelPhase.accessGranted.canTransitionTo(FunnelPhase.checkout), isFalse);
    expect(FunnelPhase.warming.canTransitionTo(FunnelPhase.checkout), isTrue);
    expect(FunnelPhase.checkout.excludeSellingDrip, isTrue);
    expect(FunnelPhase.paid.canTransitionTo(FunnelPhase.accessGranted), isTrue);
    expect(FunnelPhase.paid.canTransitionTo(FunnelPhase.cancelled), isTrue);
    expect(FunnelPhase.cancelled.canTransitionTo(FunnelPhase.paid), isTrue);
  });

  test('promo price is 15000 for RSVP during three days after webinar', () {
    final launch = testLaunch(
      priceFullKopecks: 1900000,
      pricePromoKopecks: 1500000,
      webinarAt: DateTime.utc(2026, 10, 5, 16),
      salesStartAt: DateTime.utc(2026, 10, 5, 16),
    );
    final during = LaunchSales.quote(launch, rsvp: true, now: DateTime.utc(2026, 10, 6, 12));
    expect(during.phase, SalesPhase.promo);
    expect(during.checkoutOpen, isTrue);
    expect(during.payableKopecks, 1500000);
    final outsider = LaunchSales.quote(launch, rsvp: false, now: DateTime.utc(2026, 10, 6, 12));
    expect(outsider.checkoutOpen, isTrue);
    expect(outsider.payableKopecks, 1900000);
    final regular = LaunchSales.quote(launch, rsvp: true, now: DateTime.utc(2026, 10, 9, 12));
    expect(regular.phase, SalesPhase.regular);
    expect(regular.payableKopecks, 1900000);
    expect(regular.checkoutOpen, isTrue);
  });

  test('sales stay closed until the stored sales start', () {
    final launch = testLaunch(
      webinarAt: DateTime.utc(2026, 9, 1, 16),
      salesStartAt: DateTime.utc(2026, 10, 1, 16),
    );
    final quote = LaunchSales.quote(launch, rsvp: true, now: DateTime.utc(2026, 9, 8));
    expect(quote.phase, SalesPhase.preSales);
    expect(quote.checkoutOpen, isFalse);
  });

  test('checkout stays closed until sales start even after the webinar', () {
    final launch = testLaunch(
      pricePromoKopecks: 1500000,
      webinarAt: DateTime.utc(2026, 9, 1, 16),
      salesStartAt: DateTime.utc(2026, 10, 1, 16),
    );
    final afterWebinar = LaunchSales.quote(launch, rsvp: true, now: DateTime.utc(2026, 9, 2));
    expect(afterWebinar.phase, SalesPhase.preSales);
    expect(afterWebinar.checkoutOpen, isFalse);
    final atSales = LaunchSales.quote(launch, rsvp: true, now: DateTime.utc(2026, 10, 2));
    expect(atSales.phase, SalesPhase.regular);
    expect(atSales.checkoutOpen, isTrue);
  });

  test('RSVP stays open until the webinar plus grace, live starts at webinar', () {
    final launch = testLaunch(webinarAt: DateTime.utc(2026, 10, 5, 16));
    expect(LaunchSales.webinarStarted(launch, DateTime.utc(2026, 10, 5, 15)), isFalse);
    expect(LaunchSales.webinarStarted(launch, DateTime.utc(2026, 10, 5, 16)), isTrue);
    expect(LaunchSales.rsvpOpen(launch, DateTime.utc(2026, 10, 5, 19)), isTrue);
    expect(LaunchSales.rsvpOpen(launch, DateTime.utc(2026, 10, 5, 21)), isFalse);
  });

  test('implied sales start is the next Moscow day after the webinar', () {
    final webinar = DateTime.utc(2026, 10, 5, 16);
    final launch = testLaunch(
      pricePromoKopecks: 1500000,
      webinarAt: webinar,
      salesStartAt: Launch.impliedSalesStartAt(webinar),
    );
    final duringLive = LaunchSales.quote(
      launch,
      rsvp: true,
      now: DateTime.utc(2026, 10, 5, 16, 30),
    );
    expect(duringLive.phase, SalesPhase.preSales);
    expect(duringLive.checkoutOpen, isFalse);
    final nextAfternoon = LaunchSales.quote(launch, rsvp: true, now: DateTime.utc(2026, 10, 6, 12));
    expect(nextAfternoon.phase, SalesPhase.promo);
    expect(nextAfternoon.checkoutOpen, isTrue);
    expect(nextAfternoon.payableKopecks, 1500000);
  });

  test('parseRubStringToKopecks avoids binary float drift', () {
    expect(parseRubStringToKopecks('10000.00'), 1000000);
    expect(parseRubStringToKopecks('19.99'), 1999);
    expect(parseRubStringToKopecks('0.10'), 10);
    expect(parseRubStringToKopecks('7'), 700);
  });
}
