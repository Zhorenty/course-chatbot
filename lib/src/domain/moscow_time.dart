/// Europe/Moscow without DST (UTC+3). Shared by copy, remainder waves, and jobs.
abstract final class MoscowTime {
  static const int offsetHours = 3;

  static DateTime toMoscow(DateTime value) {
    return value.toUtc().add(const Duration(hours: offsetHours));
  }

  /// Moscow calendar date of [now], stored as a UTC midnight of that Y-M-D.
  static DateTime calendarDate(DateTime now) {
    final moscow = toMoscow(now);
    return DateTime.utc(moscow.year, moscow.month, moscow.day);
  }

  /// UTC instant of 00:00 Moscow on the Moscow calendar date of [now].
  static DateTime dayStartUtc(DateTime now) {
    return calendarDate(now).subtract(const Duration(hours: offsetHours));
  }
}
