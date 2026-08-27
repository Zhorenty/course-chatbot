final class WarmupStep {
  const WarmupStep({
    required this.stepKey,
    required this.delay,
    required this.sortOrder,
    this.enabled = true,
  });

  final String stepKey;
  final Duration delay;
  final int sortOrder;
  final bool enabled;
}

final class WarmupCandidate {
  const WarmupCandidate({required this.userId, required this.anchorAt, required this.sentKeys});

  final int userId;
  final DateTime anchorAt;
  final Set<String> sentKeys;
}

final class WarmupDecision {
  const WarmupDecision({required this.stepKey, required this.userId});

  final String stepKey;
  final int userId;
}
