enum PrivateFlowStep {
  idle,
  adminSearch,
  adminBroadcastText,
}

final class PrivateFlowState {
  const PrivateFlowState({
    required this.step,
    this.broadcastText,
    this.adminTargetUserId,
  });

  final PrivateFlowStep step;
  final String? broadcastText;
  final int? adminTargetUserId;
}
