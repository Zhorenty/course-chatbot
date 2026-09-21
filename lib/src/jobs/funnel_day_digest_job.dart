import 'package:course_chatbot/src/application/payment_alert_notifier.dart';
import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/moscow_time.dart';
import 'package:l/l.dart';

/// One admin summary of yesterday's guide deliveries and webinar RSVPs.
final class FunnelDayDigestJob {
  FunnelDayDigestJob({
    required CourseRepository course,
    required JobDedupeRepository dedupe,
    required AdminAlertPort alerts,
    required QuietHours quietHours,
    DateTime Function()? nowProvider,
  }) : _course = course,
       _dedupe = dedupe,
       _alerts = alerts,
       _quietHours = quietHours,
       _nowProvider = nowProvider ?? DateTime.now;

  final CourseRepository _course;
  final JobDedupeRepository _dedupe;
  final AdminAlertPort _alerts;
  final QuietHours _quietHours;
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    final now = _nowProvider();
    if (MoscowTime.toMoscow(now).hour < _quietHours.fromHour) {
      return;
    }
    final todayStart = MoscowTime.dayStartUtc(now);
    final fromUtc = todayStart.subtract(const Duration(days: 1));
    final day = MoscowTime.calendarDate(fromUtc);
    final key =
        'funnel-digest:${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    if (!_dedupe.tryClaim(key)) {
      return;
    }
    try {
      final slice = _course.funnelDaySlice(fromUtc: fromUtc, toExclusiveUtc: todayStart);
      if (slice.isEmpty) {
        return;
      }
      await _alerts.notifyFunnelDayDigest(day: day, slice: slice);
    } on Object catch (error, stackTrace) {
      _dedupe.release(key);
      l.w('Funnel day digest failed: $error', stackTrace);
    }
  }
}
