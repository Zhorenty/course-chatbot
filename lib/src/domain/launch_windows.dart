/// Shared windows around [Launch.courseStartAt] for drip and reminders.
abstract final class LaunchWindows {
  static const Duration prestart = Duration(days: 3);
  static const Duration afterStartGrace = Duration(hours: 12);
}
