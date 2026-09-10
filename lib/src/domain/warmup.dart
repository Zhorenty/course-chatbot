import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/storage_enum.dart';

enum WarmupAnchor {
  magnet,
  firstStart,
  courseStart,
  webinar,
  webinarFollowup,
  salesStart,
  regularSales,
  salesEnd,
}

extension WarmupAnchorX on WarmupAnchor {
  String get storageValue => switch (this) {
    WarmupAnchor.magnet => 'magnet',
    WarmupAnchor.firstStart => 'first_start',
    WarmupAnchor.courseStart => 'course_start',
    WarmupAnchor.webinar => 'webinar',
    WarmupAnchor.webinarFollowup => 'webinar_followup',
    WarmupAnchor.salesStart => 'sales_start',
    WarmupAnchor.regularSales => 'regular_sales',
    WarmupAnchor.salesEnd => 'sales_end',
  };

  static WarmupAnchor parse(String? raw) {
    return parseStoredEnum(
      raw,
      values: WarmupAnchor.values,
      storage: (value) => value.storageValue,
      fallback: WarmupAnchor.magnet,
    );
  }
}

final class WarmupStep {
  const WarmupStep({
    required this.stepKey,
    required this.delay,
    required this.sortOrder,
    this.anchor = WarmupAnchor.magnet,
    this.enabled = true,
    this.ignoreQuietHours = false,
    this.rsvpOnly = false,
  });

  final String stepKey;
  final Duration delay;
  final int sortOrder;
  final WarmupAnchor anchor;
  final bool enabled;
  final bool ignoreQuietHours;
  final bool rsvpOnly;

  static const Set<String> retiredKeys = <String>{
    'warmup_d1',
    'warmup_d3',
    'warmup_d7',
    'warmup_start_d7',
    'warmup_start_d3',
    'warmup_start_d1',
  };

  /// Seeded with INSERT OR IGNORE so a live DB picks up new keys without
  /// resetting customer-edited delays.
  static const List<WarmupStep> defaults = <WarmupStep>[
    WarmupStep(stepKey: 'warmup_0', delay: Duration.zero, sortOrder: 0),
    WarmupStep(stepKey: 'warmup_d1', delay: Duration(days: 1), sortOrder: 1, enabled: false),
    WarmupStep(stepKey: 'warmup_d3', delay: Duration(days: 3), sortOrder: 2, enabled: false),
    WarmupStep(stepKey: 'warmup_d7', delay: Duration(days: 7), sortOrder: 3, enabled: false),
    WarmupStep(
      stepKey: 'enroll_d1',
      delay: Duration(days: 1),
      sortOrder: 10,
      anchor: WarmupAnchor.firstStart,
    ),
    WarmupStep(
      stepKey: 'enroll_d3',
      delay: Duration(days: 3),
      sortOrder: 11,
      anchor: WarmupAnchor.firstStart,
    ),
    WarmupStep(
      stepKey: 'webinar_24h',
      delay: Duration(days: 1),
      sortOrder: 20,
      anchor: WarmupAnchor.webinar,
    ),
    WarmupStep(
      stepKey: 'webinar_10m',
      delay: Duration(minutes: 10),
      sortOrder: 21,
      anchor: WarmupAnchor.webinar,
      ignoreQuietHours: true,
    ),
    WarmupStep(
      stepKey: 'webinar_live',
      delay: Duration.zero,
      sortOrder: 22,
      anchor: WarmupAnchor.webinar,
      ignoreQuietHours: true,
      rsvpOnly: true,
    ),
    WarmupStep(
      stepKey: 'webinar_next',
      delay: Duration(days: 1),
      sortOrder: 23,
      anchor: WarmupAnchor.webinarFollowup,
      rsvpOnly: true,
    ),
    WarmupStep(
      stepKey: 'sales_open',
      delay: Duration.zero,
      sortOrder: 25,
      anchor: WarmupAnchor.salesStart,
    ),
    WarmupStep(
      stepKey: 'sales_regular',
      delay: Duration.zero,
      sortOrder: 30,
      anchor: WarmupAnchor.regularSales,
    ),
    WarmupStep(
      stepKey: 'dozhim_d1',
      delay: Duration(days: 1),
      sortOrder: 31,
      anchor: WarmupAnchor.regularSales,
    ),
    WarmupStep(
      stepKey: 'dozhim_d2',
      delay: Duration(days: 2),
      sortOrder: 32,
      anchor: WarmupAnchor.regularSales,
    ),
    WarmupStep(
      stepKey: 'dozhim_d3',
      delay: Duration(days: 3),
      sortOrder: 33,
      anchor: WarmupAnchor.regularSales,
    ),
    WarmupStep(
      stepKey: 'dozhim_d4',
      delay: Duration(days: 4),
      sortOrder: 34,
      anchor: WarmupAnchor.regularSales,
    ),
    WarmupStep(
      stepKey: 'last_wagon',
      delay: Duration.zero,
      sortOrder: 40,
      anchor: WarmupAnchor.salesEnd,
    ),
    WarmupStep(
      stepKey: 'warmup_start_d7',
      delay: Duration(days: 7),
      sortOrder: 50,
      anchor: WarmupAnchor.courseStart,
      enabled: false,
    ),
    WarmupStep(
      stepKey: 'warmup_start_d3',
      delay: Duration(days: 3),
      sortOrder: 51,
      anchor: WarmupAnchor.courseStart,
      enabled: false,
    ),
    WarmupStep(
      stepKey: 'warmup_start_d1',
      delay: Duration(days: 1),
      sortOrder: 52,
      anchor: WarmupAnchor.courseStart,
      enabled: false,
    ),
  ];
}

final class WarmupCandidate {
  const WarmupCandidate({
    required this.userId,
    required this.launchId,
    required this.firstStartedAt,
    required this.funnelPhase,
    required this.sentKeys,
    this.magnetIssuedAt,
    this.source,
    this.webinarRsvp = false,
    this.enrollIntentAt,
  });

  final int userId;
  final int launchId;
  final DateTime firstStartedAt;
  final DateTime? magnetIssuedAt;
  final String? source;
  final FunnelPhase funnelPhase;
  final Set<String> sentKeys;
  final bool webinarRsvp;
  final DateTime? enrollIntentAt;

  DateTime get magnetAnchor => magnetIssuedAt ?? firstStartedAt;
}

final class WarmupDecision {
  const WarmupDecision({required this.stepKey, required this.userId, required this.launchId});

  final String stepKey;
  final int userId;
  final int launchId;
}
