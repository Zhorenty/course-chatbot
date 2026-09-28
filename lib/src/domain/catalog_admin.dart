enum CatalogLaunchField {
  title,
  description,
  code,
  price,
  promo,
  promoUrl,
  deposit,
  start,
  webinar,
  webinarUrl,
  salesStart,
  salesEnd,
  channel,
  guide;

  static const List<CatalogLaunchField> paramsFields = <CatalogLaunchField>[
    CatalogLaunchField.title,
    CatalogLaunchField.code,
    CatalogLaunchField.price,
    CatalogLaunchField.promo,
    CatalogLaunchField.promoUrl,
    CatalogLaunchField.deposit,
    CatalogLaunchField.start,
    CatalogLaunchField.webinar,
    CatalogLaunchField.webinarUrl,
    CatalogLaunchField.salesStart,
    CatalogLaunchField.salesEnd,
    CatalogLaunchField.channel,
  ];

  String get token => switch (this) {
    CatalogLaunchField.title => 't',
    CatalogLaunchField.description => 'b',
    CatalogLaunchField.code => 'c',
    CatalogLaunchField.price => 'p',
    CatalogLaunchField.promo => 'r',
    CatalogLaunchField.promoUrl => 'u',
    CatalogLaunchField.deposit => 'd',
    CatalogLaunchField.start => 's',
    CatalogLaunchField.webinar => 'w',
    CatalogLaunchField.webinarUrl => 'l',
    CatalogLaunchField.salesStart => 'n',
    CatalogLaunchField.salesEnd => 'e',
    CatalogLaunchField.channel => 'h',
    CatalogLaunchField.guide => 'f',
  };

  static CatalogLaunchField? fromToken(String raw) {
    return switch (raw) {
      't' => CatalogLaunchField.title,
      'b' => CatalogLaunchField.description,
      'c' => CatalogLaunchField.code,
      'p' => CatalogLaunchField.price,
      'r' => CatalogLaunchField.promo,
      'u' => CatalogLaunchField.promoUrl,
      'd' => CatalogLaunchField.deposit,
      's' => CatalogLaunchField.start,
      'w' => CatalogLaunchField.webinar,
      'l' => CatalogLaunchField.webinarUrl,
      'n' => CatalogLaunchField.salesStart,
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
