final class SourceFunnelSlice {
  const SourceFunnelSlice({
    required this.source,
    required this.started,
    required this.guideTaken,
    required this.checkoutStarted,
    required this.paid,
  });

  final String source;
  final int started;
  final int guideTaken;
  final int checkoutStarted;
  final int paid;

  double? get paidConversion {
    if (started <= 0) {
      return null;
    }
    return paid / started;
  }
}

final class FunnelAnalytics {
  const FunnelAnalytics({
    required this.generatedAt,
    required this.startedUsersTotal,
    required this.funnelUsers,
    required this.guideTaken,
    required this.checkoutStarted,
    required this.paidUsers,
    required this.startedLast7Days,
    required this.startedLast30Days,
    required this.paidLast7Days,
    required this.paidLast30Days,
    required this.phaseCounts,
    required this.sourceCounts,
    this.sourceFunnels = const <SourceFunnelSlice>[],
    this.inviteIssuedNotJoined = 0,
    this.warmupOptOutCount = 0,
    this.botBlockedCount = 0,
  });

  final DateTime generatedAt;
  final int startedUsersTotal;
  final int funnelUsers;
  final int guideTaken;
  final int checkoutStarted;
  final int paidUsers;
  final int startedLast7Days;
  final int startedLast30Days;
  final int paidLast7Days;
  final int paidLast30Days;
  final Map<String, int> phaseCounts;
  final Map<String, int> sourceCounts;
  final List<SourceFunnelSlice> sourceFunnels;
  final int inviteIssuedNotJoined;
  final int warmupOptOutCount;
  final int botBlockedCount;

  double? get paidConversion {
    if (startedUsersTotal <= 0) {
      return null;
    }
    return paidUsers / startedUsersTotal;
  }
}

final class FunnelStepCount {
  const FunnelStepCount({required this.label, required this.count});

  final String label;
  final int count;
}
