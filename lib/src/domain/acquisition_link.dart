import 'package:course_chatbot/src/domain/funnel.dart';

const Object _unset = Object();

enum AcquisitionDestination { guide, course }

/// One start-payload row: where the person came from and which first screen to open.
final class AcquisitionLink {
  const AcquisitionLink({
    required this.origin,
    required this.destination,
    required this.payload,
    this.url,
    this.launchCode,
  });

  final String origin;
  final AcquisitionDestination destination;
  final String payload;
  final String? url;

  /// Optional COURSES / SQLite launch code. Empty means resolve to the active launch at click time.
  final String? launchCode;

  bool get opensCourse => destination == AcquisitionDestination.course;

  String get destinationLabel => switch (destination) {
    AcquisitionDestination.guide => 'гайд',
    AcquisitionDestination.course => 'курс',
  };

  AcquisitionLink copyWith({
    Object? origin = _unset,
    Object? destination = _unset,
    Object? payload = _unset,
    Object? url = _unset,
    Object? launchCode = _unset,
  }) {
    return AcquisitionLink(
      origin: identical(origin, _unset) ? this.origin : origin as String,
      destination: identical(destination, _unset)
          ? this.destination
          : destination as AcquisitionDestination,
      payload: identical(payload, _unset) ? this.payload : payload as String,
      url: identical(url, _unset) ? this.url : url as String?,
      launchCode: identical(launchCode, _unset) ? this.launchCode : launchCode as String?,
    );
  }

  static const List<AcquisitionLink> starters = <AcquisitionLink>[
    AcquisitionLink(
      origin: 'Instagram Reels',
      destination: AcquisitionDestination.guide,
      payload: 'ig_reels_guide',
    ),
    AcquisitionLink(
      origin: 'Threads, пост',
      destination: AcquisitionDestination.guide,
      payload: 'threads_guide',
    ),
    AcquisitionLink(
      origin: 'Telegram, анонс курса',
      destination: AcquisitionDestination.course,
      payload: 'tg_announce',
    ),
    AcquisitionLink(
      origin: 'Прямая ссылка',
      destination: AcquisitionDestination.course,
      payload: 'direct_course',
    ),
  ];

  static String? telegramStartUrl(String payload, String? botUsername) {
    final bot = botUsername?.trim() ?? '';
    if (bot.isEmpty) {
      return null;
    }
    final normalized = AcquisitionSource.normalize(payload);
    if (normalized == null) {
      return null;
    }
    return 'https://t.me/$bot?start=$normalized';
  }
}

/// In-memory catalog of start links. Seeded with TZ starters; Sheets extras replace the list.
final class AcquisitionLinkCatalog {
  AcquisitionLinkCatalog({List<AcquisitionLink>? seed})
    : _entries = List<AcquisitionLink>.from(seed ?? AcquisitionLink.starters);

  List<AcquisitionLink> _entries;

  List<AcquisitionLink> get entries => List<AcquisitionLink>.unmodifiable(_entries);

  /// Payloads that open the course card on first `/start`, including ССЫЛКИ extras.
  Set<String> get courseEntryPayloads {
    return <String>{
      ...AcquisitionSource.coursePayloads,
      for (final link in _entries)
        if (link.opensCourse) link.payload,
    };
  }

  void replaceAll(Iterable<AcquisitionLink> links) {
    final next = dedupe(links);
    _entries = next.isEmpty ? List<AcquisitionLink>.from(AcquisitionLink.starters) : next;
  }

  AcquisitionLink? byPayload(String? payload) {
    final normalized = AcquisitionSource.normalize(payload);
    if (normalized == null) {
      return null;
    }
    for (final link in _entries) {
      if (link.payload == normalized) {
        return link;
      }
    }
    return null;
  }

  bool opensCourseCard(String? payload) {
    final normalized = AcquisitionSource.normalize(payload);
    if (normalized == null) {
      return false;
    }
    if (AcquisitionSource.coursePayloads.contains(normalized)) {
      return true;
    }
    if (AcquisitionSource.guidePayloads.contains(normalized)) {
      return false;
    }
    final link = byPayload(normalized);
    return link?.opensCourse ?? false;
  }

  static List<AcquisitionLink> dedupe(Iterable<AcquisitionLink> links) {
    final seen = <String>{};
    final result = <AcquisitionLink>[];
    for (final link in links) {
      if (!seen.add(link.payload)) {
        continue;
      }
      result.add(link);
    }
    return result;
  }
}
