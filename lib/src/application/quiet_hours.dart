/// Outbound jobs stay silent outside [fromHour, toHour) in the business timezone.
final class QuietHours {
  const QuietHours({
    required this.timezoneOffsetHours,
    required this.fromHour,
    required this.toHour,
  });

  final int timezoneOffsetHours;
  final int fromHour;
  final int toHour;

  DateTime localTime(DateTime now) {
    return now.toUtc().add(Duration(hours: timezoneOffsetHours));
  }

  bool isQuiet(DateTime now) {
    final hour = localTime(now).hour;
    if (fromHour == toHour) {
      return false;
    }
    if (fromHour < toHour) {
      return hour < fromHour || hour >= toHour;
    }
    return hour >= toHour && hour < fromHour;
  }

  bool get canSendNow => !isQuiet(DateTime.now());
}
