enum CatalogLaunchField {
  title,
  code,
  price,
  promo,
  deposit,
  depositDue,
  start,
  webinar,
  webinarUrl,
  salesEnd,
  channel,
  guide;

  String get token => switch (this) {
    CatalogLaunchField.title => 't',
    CatalogLaunchField.code => 'c',
    CatalogLaunchField.price => 'p',
    CatalogLaunchField.promo => 'r',
    CatalogLaunchField.deposit => 'd',
    CatalogLaunchField.depositDue => 'u',
    CatalogLaunchField.start => 's',
    CatalogLaunchField.webinar => 'w',
    CatalogLaunchField.webinarUrl => 'l',
    CatalogLaunchField.salesEnd => 'e',
    CatalogLaunchField.channel => 'h',
    CatalogLaunchField.guide => 'f',
  };

  static CatalogLaunchField? fromToken(String raw) {
    return switch (raw) {
      't' => CatalogLaunchField.title,
      'c' => CatalogLaunchField.code,
      'p' => CatalogLaunchField.price,
      'r' => CatalogLaunchField.promo,
      'd' => CatalogLaunchField.deposit,
      'u' => CatalogLaunchField.depositDue,
      's' => CatalogLaunchField.start,
      'w' => CatalogLaunchField.webinar,
      'l' => CatalogLaunchField.webinarUrl,
      'e' => CatalogLaunchField.salesEnd,
      'h' => CatalogLaunchField.channel,
      'f' => CatalogLaunchField.guide,
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
  needGuideFile,
}

enum CatalogLinkField {
  origin,
  destination,
  payload,
  launch;

  String get token => switch (this) {
    CatalogLinkField.origin => 'o',
    CatalogLinkField.destination => 'd',
    CatalogLinkField.payload => 'p',
    CatalogLinkField.launch => 'l',
  };

  static CatalogLinkField? fromToken(String raw) {
    return switch (raw) {
      'o' => CatalogLinkField.origin,
      'd' => CatalogLinkField.destination,
      'p' => CatalogLinkField.payload,
      'l' => CatalogLinkField.launch,
      _ => null,
    };
  }
}

enum CatalogLinkFieldError { emptyOrigin, badPayload, payloadTaken, badLaunch }

enum CatalogAdminFailure {
  sheetsUnavailable,
  lastLaunch,
  lastLink,
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
