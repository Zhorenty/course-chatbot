import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/order.dart';
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

  test('deposit does not grant access on success, full and installment do', () {
    expect(PaymentKind.deposit.grantsAccessOnSuccess, isFalse);
    expect(PaymentKind.full.grantsAccessOnSuccess, isTrue);
    expect(PaymentKind.remainder.grantsAccessOnSuccess, isTrue);
    expect(PaymentKind.installment.grantsAccessOnSuccess, isTrue);
  });
}
