import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/order.dart';

const Object _unset = Object();

enum PrivateFlowStep {
  idle,
  offerConsent,
  adminSearch,
  adminAddUser,
  adminBroadcastSegment,
  adminBroadcastCompose,
  adminGuideConfirm,
  adminComposeDm,
}

final class PrivateFlowState {
  const PrivateFlowState({
    required this.step,
    this.broadcastSegment,
    this.broadcastFromChatId,
    this.broadcastMessageId,
    this.broadcastContentKind,
    this.broadcastPreviewText,
    this.adminTargetUserId,
    this.pendingGuideFileId,
    this.pendingPayKind,
    this.acceptedConsent = false,
    this.broadcastExcludeOptOut = false,
  });

  final PrivateFlowStep step;
  final BroadcastSegment? broadcastSegment;
  final int? broadcastFromChatId;
  final int? broadcastMessageId;
  final BroadcastContentKind? broadcastContentKind;
  final String? broadcastPreviewText;
  final int? adminTargetUserId;
  final String? pendingGuideFileId;
  final PaymentKind? pendingPayKind;
  final bool acceptedConsent;
  final bool broadcastExcludeOptOut;

  bool get offerReady => acceptedConsent;

  bool get hasBroadcastDraft => broadcastFromChatId != null && broadcastMessageId != null;

  PrivateFlowState copyWith({
    PrivateFlowStep? step,
    Object? broadcastSegment = _unset,
    Object? broadcastFromChatId = _unset,
    Object? broadcastMessageId = _unset,
    Object? broadcastContentKind = _unset,
    Object? broadcastPreviewText = _unset,
    Object? adminTargetUserId = _unset,
    Object? pendingGuideFileId = _unset,
    Object? pendingPayKind = _unset,
    bool? acceptedConsent,
    bool? broadcastExcludeOptOut,
  }) {
    return PrivateFlowState(
      step: step ?? this.step,
      broadcastSegment: identical(broadcastSegment, _unset)
          ? this.broadcastSegment
          : broadcastSegment as BroadcastSegment?,
      broadcastFromChatId: identical(broadcastFromChatId, _unset)
          ? this.broadcastFromChatId
          : broadcastFromChatId as int?,
      broadcastMessageId: identical(broadcastMessageId, _unset)
          ? this.broadcastMessageId
          : broadcastMessageId as int?,
      broadcastContentKind: identical(broadcastContentKind, _unset)
          ? this.broadcastContentKind
          : broadcastContentKind as BroadcastContentKind?,
      broadcastPreviewText: identical(broadcastPreviewText, _unset)
          ? this.broadcastPreviewText
          : broadcastPreviewText as String?,
      adminTargetUserId: identical(adminTargetUserId, _unset)
          ? this.adminTargetUserId
          : adminTargetUserId as int?,
      pendingGuideFileId: identical(pendingGuideFileId, _unset)
          ? this.pendingGuideFileId
          : pendingGuideFileId as String?,
      pendingPayKind: identical(pendingPayKind, _unset)
          ? this.pendingPayKind
          : pendingPayKind as PaymentKind?,
      acceptedConsent: acceptedConsent ?? this.acceptedConsent,
      broadcastExcludeOptOut: broadcastExcludeOptOut ?? this.broadcastExcludeOptOut,
    );
  }
}
