import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/catalog_admin.dart';

const Object _unset = Object();

enum PrivateFlowStep {
  idle,
  adminSearch,
  adminAddUser,
  adminBroadcastSegment,
  adminBroadcastCompose,
  adminGuideConfirm,
  adminComposeDm,
  adminCatalogMenu,
  adminCatalogCreateProductCode,
  adminCatalogCreateProductTitle,
  adminCatalogCreateTitle,
  adminCatalogCreateCode,
  adminCatalogCreatePrice,
  adminCatalogCreatePromo,
  adminCatalogCreateDeposit,
  adminCatalogCreateStart,
  adminCatalogCreateWebinar,
  adminCatalogCreateWebinarUrl,
  adminCatalogCreateSalesStart,
  adminCatalogCreateSalesEnd,
  adminCatalogCreateChannel,
  adminCatalogCreateGuide,
  adminCatalogCreateActive,
  adminCatalogCreateConfirm,
  adminCatalogEditValue,
  adminSheetsHub,
  adminLinksMenu,
  adminLinksCreateOrigin,
  adminLinksCreateDestination,
  adminLinksCreatePayload,
  adminLinksCreateLaunch,
  adminLinksCreateConfirm,
  adminLinksEditValue,
}

final class CatalogWizardDraft {
  const CatalogWizardDraft({
    this.productCode,
    this.productTitle,
    this.title,
    this.code,
    this.priceKopecks,
    this.pricePromoKopecks,
    this.depositKopecks,
    this.courseStartAt,
    this.webinarAt,
    this.webinarUrl,
    this.salesStartAt,
    this.salesEndAt,
    this.channelId,
    this.channelSkipped = false,
    this.guideFileId,
    this.isActive,
    this.editLaunchId,
    this.editField,
  });

  final String? productCode;
  final String? productTitle;
  final String? title;
  final String? code;
  final int? priceKopecks;
  final int? pricePromoKopecks;
  final int? depositKopecks;
  final DateTime? courseStartAt;
  final DateTime? webinarAt;
  final String? webinarUrl;
  final DateTime? salesStartAt;
  final DateTime? salesEndAt;
  final int? channelId;
  final bool channelSkipped;
  final String? guideFileId;
  final bool? isActive;
  final int? editLaunchId;
  final CatalogLaunchField? editField;

  CatalogWizardDraft copyWith({
    Object? productCode = _unset,
    Object? productTitle = _unset,
    Object? title = _unset,
    Object? code = _unset,
    Object? priceKopecks = _unset,
    Object? pricePromoKopecks = _unset,
    Object? depositKopecks = _unset,
    Object? courseStartAt = _unset,
    Object? webinarAt = _unset,
    Object? webinarUrl = _unset,
    Object? salesStartAt = _unset,
    Object? salesEndAt = _unset,
    Object? channelId = _unset,
    bool? channelSkipped,
    Object? guideFileId = _unset,
    Object? isActive = _unset,
    Object? editLaunchId = _unset,
    Object? editField = _unset,
  }) {
    return CatalogWizardDraft(
      productCode: identical(productCode, _unset) ? this.productCode : productCode as String?,
      productTitle: identical(productTitle, _unset) ? this.productTitle : productTitle as String?,
      title: identical(title, _unset) ? this.title : title as String?,
      code: identical(code, _unset) ? this.code : code as String?,
      priceKopecks: identical(priceKopecks, _unset) ? this.priceKopecks : priceKopecks as int?,
      pricePromoKopecks: identical(pricePromoKopecks, _unset)
          ? this.pricePromoKopecks
          : pricePromoKopecks as int?,
      depositKopecks: identical(depositKopecks, _unset)
          ? this.depositKopecks
          : depositKopecks as int?,
      courseStartAt: identical(courseStartAt, _unset)
          ? this.courseStartAt
          : courseStartAt as DateTime?,
      webinarAt: identical(webinarAt, _unset) ? this.webinarAt : webinarAt as DateTime?,
      webinarUrl: identical(webinarUrl, _unset) ? this.webinarUrl : webinarUrl as String?,
      salesStartAt: identical(salesStartAt, _unset) ? this.salesStartAt : salesStartAt as DateTime?,
      salesEndAt: identical(salesEndAt, _unset) ? this.salesEndAt : salesEndAt as DateTime?,
      channelId: identical(channelId, _unset) ? this.channelId : channelId as int?,
      channelSkipped: channelSkipped ?? this.channelSkipped,
      guideFileId: identical(guideFileId, _unset) ? this.guideFileId : guideFileId as String?,
      isActive: identical(isActive, _unset) ? this.isActive : isActive as bool?,
      editLaunchId: identical(editLaunchId, _unset) ? this.editLaunchId : editLaunchId as int?,
      editField: identical(editField, _unset) ? this.editField : editField as CatalogLaunchField?,
    );
  }
}

final class LinksWizardDraft {
  const LinksWizardDraft({
    this.origin,
    this.destination,
    this.payload,
    this.launchCode,
    this.launchSkipped = false,
    this.editPayload,
    this.editIndex,
    this.editField,
  });

  final String? origin;
  final AcquisitionDestination? destination;
  final String? payload;
  final String? launchCode;
  final bool launchSkipped;
  final String? editPayload;
  final int? editIndex;
  final CatalogLinkField? editField;

  LinksWizardDraft copyWith({
    Object? origin = _unset,
    Object? destination = _unset,
    Object? payload = _unset,
    Object? launchCode = _unset,
    bool? launchSkipped,
    Object? editPayload = _unset,
    Object? editIndex = _unset,
    Object? editField = _unset,
  }) {
    return LinksWizardDraft(
      origin: identical(origin, _unset) ? this.origin : origin as String?,
      destination: identical(destination, _unset)
          ? this.destination
          : destination as AcquisitionDestination?,
      payload: identical(payload, _unset) ? this.payload : payload as String?,
      launchCode: identical(launchCode, _unset) ? this.launchCode : launchCode as String?,
      launchSkipped: launchSkipped ?? this.launchSkipped,
      editPayload: identical(editPayload, _unset) ? this.editPayload : editPayload as String?,
      editIndex: identical(editIndex, _unset) ? this.editIndex : editIndex as int?,
      editField: identical(editField, _unset) ? this.editField : editField as CatalogLinkField?,
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
    this.broadcastExcludeOptOut = false,
    this.catalogDraft,
    this.linksDraft,
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
  final bool broadcastExcludeOptOut;
  final CatalogWizardDraft? catalogDraft;
  final LinksWizardDraft? linksDraft;
  final int? catalogMessageId;
  final int? catalogPinMessageId;

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
    bool? broadcastExcludeOptOut,
    Object? catalogDraft = _unset,
    Object? linksDraft = _unset,
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
      broadcastExcludeOptOut: broadcastExcludeOptOut ?? this.broadcastExcludeOptOut,
      catalogDraft: identical(catalogDraft, _unset)
          ? this.catalogDraft
          : catalogDraft as CatalogWizardDraft?,
      linksDraft: identical(linksDraft, _unset) ? this.linksDraft : linksDraft as LinksWizardDraft?,
      catalogMessageId: identical(catalogMessageId, _unset)
          ? this.catalogMessageId
          : catalogMessageId as int?,
      catalogPinMessageId: identical(catalogPinMessageId, _unset)
          ? this.catalogPinMessageId
          : catalogPinMessageId as int?,
    );
  }
}
