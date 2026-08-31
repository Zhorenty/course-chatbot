import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/storage_enum.dart';

enum WarmupAnchor { magnet, firstStart, courseStart }

extension WarmupAnchorX on WarmupAnchor {
  String get storageValue => switch (this) {
    WarmupAnchor.magnet => 'magnet',
    WarmupAnchor.firstStart => 'first_start',
    WarmupAnchor.courseStart => 'course_start',
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
  });

  final String stepKey;
  final Duration delay;
  final int sortOrder;
  final WarmupAnchor anchor;
  final bool enabled;

  /// Seeded with INSERT OR IGNORE so a live DB picks up new keys without
  /// resetting customer-edited delays.
  static const List<WarmupStep> defaults = <WarmupStep>[
    WarmupStep(stepKey: 'warmup_0', delay: Duration.zero, sortOrder: 0),
    WarmupStep(stepKey: 'warmup_d1', delay: Duration(days: 1), sortOrder: 1),
    WarmupStep(stepKey: 'warmup_d3', delay: Duration(days: 3), sortOrder: 2),
    WarmupStep(stepKey: 'warmup_d7', delay: Duration(days: 7), sortOrder: 3),
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
      stepKey: 'warmup_start_d7',
      delay: Duration(days: 7),
      sortOrder: 20,
      anchor: WarmupAnchor.courseStart,
    ),
    WarmupStep(
      stepKey: 'warmup_start_d3',
      delay: Duration(days: 3),
      sortOrder: 21,
      anchor: WarmupAnchor.courseStart,
    ),
    WarmupStep(
      stepKey: 'warmup_start_d1',
      delay: Duration(days: 1),
      sortOrder: 22,
      anchor: WarmupAnchor.courseStart,
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
  });

  final int userId;
  final int launchId;
  final DateTime firstStartedAt;
  final DateTime? magnetIssuedAt;
  final String? source;
  final FunnelPhase funnelPhase;
  final Set<String> sentKeys;

  DateTime get magnetAnchor => magnetIssuedAt ?? firstStartedAt;
}

final class WarmupDecision {
  const WarmupDecision({required this.stepKey, required this.userId, required this.launchId});

  final String stepKey;
  final int userId;
  final int launchId;
}
