import 'package:course_chatbot/src/domain/order.dart';

enum PrivateFlowStep {
  idle,
  offerConsent,
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
    this.pendingPayKind,
    this.acceptedOffer = false,
    this.acceptedPersonalData = false,
  });

  final PrivateFlowStep step;
  final String? broadcastText;
  final int? adminTargetUserId;
  final String? pendingGuideFileId;
  final PaymentKind? pendingPayKind;
  final bool acceptedOffer;
  final bool acceptedPersonalData;

  bool get offerReady => acceptedOffer && acceptedPersonalData;

  PrivateFlowState copyWith({
    PrivateFlowStep? step,
    String? broadcastText,
    int? adminTargetUserId,
    String? pendingGuideFileId,
    PaymentKind? pendingPayKind,
    bool? acceptedOffer,
    bool? acceptedPersonalData,
  }) {
    return PrivateFlowState(
      step: step ?? this.step,
      broadcastText: broadcastText ?? this.broadcastText,
      adminTargetUserId: adminTargetUserId ?? this.adminTargetUserId,
      pendingGuideFileId: pendingGuideFileId ?? this.pendingGuideFileId,
      pendingPayKind: pendingPayKind ?? this.pendingPayKind,
      acceptedOffer: acceptedOffer ?? this.acceptedOffer,
      acceptedPersonalData: acceptedPersonalData ?? this.acceptedPersonalData,
    );
  }
}
