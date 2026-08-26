enum PrivateFlowStep {
  idle,
  adminSearch,
  adminBroadcastText,
  adminGuideConfirm,
}

final class PrivateFlowState {
  const PrivateFlowState({
    required this.step,
    this.broadcastText,
    this.adminTargetUserId,
    this.pendingGuideFileId,
  });

  final PrivateFlowStep step;
  final String? broadcastText;
  final int? adminTargetUserId;
  final String? pendingGuideFileId;
}
