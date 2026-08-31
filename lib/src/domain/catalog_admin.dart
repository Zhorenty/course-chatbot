enum CatalogLaunchField {
  title,
  code,
  price,
  deposit,
  depositDue,
  start,
  channel;

  String get token => switch (this) {
    CatalogLaunchField.title => 't',
    CatalogLaunchField.code => 'c',
    CatalogLaunchField.price => 'p',
    CatalogLaunchField.deposit => 'd',
    CatalogLaunchField.depositDue => 'u',
    CatalogLaunchField.start => 's',
    CatalogLaunchField.channel => 'h',
  };

  static CatalogLaunchField? fromToken(String raw) {
    return switch (raw) {
      't' => CatalogLaunchField.title,
      'c' => CatalogLaunchField.code,
      'p' => CatalogLaunchField.price,
      'd' => CatalogLaunchField.deposit,
      'u' => CatalogLaunchField.depositDue,
      's' => CatalogLaunchField.start,
      'h' => CatalogLaunchField.channel,
      _ => null,
    };
  }
}

enum CatalogFieldError {
  emptyTitle,
  badCode,
  codeTaken,
  badPrice,
  badDeposit,
  needDueDate,
  badDate,
  badChannel,
}

enum CatalogAdminFailure {
  sheetsUnavailable,
  lastLaunch,
  activeLaunch,
  hasPeople,
  codeTaken,
  notFound,
  writeFailed,
}

final class LaunchUsage {
  const LaunchUsage({
    required this.enrollments,
    required this.orders,
    required this.channelAccess,
    required this.acquisitionEvents,
    required this.warmupSent,
  });

  final int enrollments;
  final int orders;
  final int channelAccess;
  final int acquisitionEvents;
  final int warmupSent;

  bool get hasPeople =>
      enrollments > 0 || orders > 0 || channelAccess > 0 || acquisitionEvents > 0 || warmupSent > 0;
}
