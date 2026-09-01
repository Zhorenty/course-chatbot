import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/catalog_admin.dart';
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
  adminCatalogMenu,
  adminCatalogCreateTitle,
  adminCatalogCreateCode,
  adminCatalogCreatePrice,
  adminCatalogCreateDeposit,
  adminCatalogCreateDepositDue,
  adminCatalogCreateStart,
  adminCatalogCreateChannel,
  adminCatalogCreateActive,
  adminCatalogCreateConfirm,
  adminCatalogEditValue,
}

final class CatalogWizardDraft {
  const CatalogWizardDraft({
    this.title,
    this.code,
    this.priceKopecks,
    this.depositKopecks,
    this.depositDueAt,
    this.courseStartAt,
    this.channelId,
    this.channelSkipped = false,
    this.isActive,
    this.editLaunchId,
    this.editField,
  });

  final String? title;
  final String? code;
  final int? priceKopecks;
  final int? depositKopecks;
  final DateTime? depositDueAt;
  final DateTime? courseStartAt;
  final int? channelId;
  final bool channelSkipped;
  final bool? isActive;
  final int? editLaunchId;
  final CatalogLaunchField? editField;

  CatalogWizardDraft copyWith({
    Object? title = _unset,
    Object? code = _unset,
    Object? priceKopecks = _unset,
    Object? depositKopecks = _unset,
    Object? depositDueAt = _unset,
    Object? courseStartAt = _unset,
    Object? channelId = _unset,
    bool? channelSkipped,
    Object? isActive = _unset,
    Object? editLaunchId = _unset,
    Object? editField = _unset,
  }) {
    return CatalogWizardDraft(
      title: identical(title, _unset) ? this.title : title as String?,
      code: identical(code, _unset) ? this.code : code as String?,
      priceKopecks: identical(priceKopecks, _unset) ? this.priceKopecks : priceKopecks as int?,
      depositKopecks: identical(depositKopecks, _unset)
          ? this.depositKopecks
          : depositKopecks as int?,
      depositDueAt: identical(depositDueAt, _unset) ? this.depositDueAt : depositDueAt as DateTime?,
      courseStartAt: identical(courseStartAt, _unset)
          ? this.courseStartAt
          : courseStartAt as DateTime?,
      channelId: identical(channelId, _unset) ? this.channelId : channelId as int?,
      channelSkipped: channelSkipped ?? this.channelSkipped,
      isActive: identical(isActive, _unset) ? this.isActive : isActive as bool?,
      editLaunchId: identical(editLaunchId, _unset) ? this.editLaunchId : editLaunchId as int?,
      editField: identical(editField, _unset) ? this.editField : editField as CatalogLaunchField?,
    );
  }
}

final class PrivateFlowState {
  const PrivateFlowState({
    required this.step,
    this.broadcastSegments = const <BroadcastSegment>{},
    this.broadcastFromChatId,
    this.broadcastMessageId,
    this.broadcastContentKind,
    this.broadcastPreviewText,
    this.broadcastPickerMessageId,
    this.adminTargetUserId,
    this.pendingGuideFileId,
    this.pendingPayKind,
    this.pendingLaunchId,
    this.acceptedConsent = false,
    this.broadcastExcludeOptOut = false,
    this.catalogDraft,
    this.catalogMessageId,
    this.catalogPinMessageId,
  });

  final PrivateFlowStep step;
  final Set<BroadcastSegment> broadcastSegments;
  final int? broadcastFromChatId;
  final int? broadcastMessageId;
  final BroadcastContentKind? broadcastContentKind;
  final String? broadcastPreviewText;
  final int? broadcastPickerMessageId;
  final int? adminTargetUserId;
  final String? pendingGuideFileId;
  final PaymentKind? pendingPayKind;
  final int? pendingLaunchId;
  final bool acceptedConsent;
  final bool broadcastExcludeOptOut;
  final CatalogWizardDraft? catalogDraft;
  final int? catalogMessageId;
  final int? catalogPinMessageId;

  bool get offerReady => acceptedConsent;

  bool get hasBroadcastDraft => broadcastFromChatId != null && broadcastMessageId != null;

  bool get hasBroadcastSegments => broadcastSegments.isNotEmpty;

  PrivateFlowState copyWith({
    PrivateFlowStep? step,
    Object? broadcastSegments = _unset,
    Object? broadcastFromChatId = _unset,
    Object? broadcastMessageId = _unset,
    Object? broadcastContentKind = _unset,
    Object? broadcastPreviewText = _unset,
    Object? broadcastPickerMessageId = _unset,
    Object? adminTargetUserId = _unset,
    Object? pendingGuideFileId = _unset,
    Object? pendingPayKind = _unset,
    Object? pendingLaunchId = _unset,
    bool? acceptedConsent,
    bool? broadcastExcludeOptOut,
    Object? catalogDraft = _unset,
    Object? catalogMessageId = _unset,
    Object? catalogPinMessageId = _unset,
  }) {
    return PrivateFlowState(
      step: step ?? this.step,
      broadcastSegments: identical(broadcastSegments, _unset)
          ? this.broadcastSegments
          : Set<BroadcastSegment>.unmodifiable(
              broadcastSegments as Iterable<BroadcastSegment>? ?? const <BroadcastSegment>{},
            ),
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
      broadcastPickerMessageId: identical(broadcastPickerMessageId, _unset)
          ? this.broadcastPickerMessageId
          : broadcastPickerMessageId as int?,
      adminTargetUserId: identical(adminTargetUserId, _unset)
          ? this.adminTargetUserId
          : adminTargetUserId as int?,
      pendingGuideFileId: identical(pendingGuideFileId, _unset)
          ? this.pendingGuideFileId
          : pendingGuideFileId as String?,
      pendingPayKind: identical(pendingPayKind, _unset)
          ? this.pendingPayKind
          : pendingPayKind as PaymentKind?,
      pendingLaunchId: identical(pendingLaunchId, _unset)
          ? this.pendingLaunchId
          : pendingLaunchId as int?,
      acceptedConsent: acceptedConsent ?? this.acceptedConsent,
      broadcastExcludeOptOut: broadcastExcludeOptOut ?? this.broadcastExcludeOptOut,
      catalogDraft: identical(catalogDraft, _unset)
          ? this.catalogDraft
          : catalogDraft as CatalogWizardDraft?,
      catalogMessageId: identical(catalogMessageId, _unset)
          ? this.catalogMessageId
          : catalogMessageId as int?,
      catalogPinMessageId: identical(catalogPinMessageId, _unset)
          ? this.catalogPinMessageId
          : catalogPinMessageId as int?,
    );
  }
}
