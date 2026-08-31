import 'dart:io';

import 'package:course_chatbot/src/application/access_service.dart';
import 'package:course_chatbot/src/application/broadcast_service.dart';
import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/application/funnel_service.dart';
import 'package:course_chatbot/src/application/payment_alert_notifier.dart';
import 'package:course_chatbot/src/application/warmup_service.dart';
import 'package:course_chatbot/src/bot/handlers/private/admin_gate.dart';
import 'package:course_chatbot/src/bot/handlers/private/interaction_whitelist.dart';
import 'package:course_chatbot/src/bot/handlers/private/private_context.dart';
import 'package:course_chatbot/src/bot/handlers/private/private_flow_store.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/google_sheets_catalog_sync.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/domain/warmup.dart';
import 'package:course_chatbot/src/jobs/google_sheets_funnel_export_job.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';
import 'package:l/l.dart';

part 'private/private_handlers_dispatch.part.dart';
part 'private/private_handlers_start.part.dart';
part 'private/private_handlers_funnel.part.dart';
part 'private/private_handlers_checkout.part.dart';
part 'private/private_handlers_admin.part.dart';
part 'private/private_handlers_chat_member.part.dart';

final class PrivateHandlers implements PaymentResultNotifier {
  PrivateHandlers({
    required MessageSender sender,
    required MessageTemplates templates,
    required CourseRepository course,
    required FunnelService funnel,
    required CheckoutService checkout,
    required AccessService access,
    required WarmupService warmup,
    required BroadcastService broadcast,
    required Set<int> adminUserIds,
    int? adminChatId,
    InteractionWhitelist interactionWhitelist = InteractionWhitelist.production,
    GoogleSheetsCatalogSync? catalogSync,
    GoogleSheetsFunnelExportJob? sheetsExportJob,
    DateTime Function()? nowProvider,
    AdminAlertPort? adminAlerts,
    this.leadMagnetPath,
    this.leadMagnetFilename = 'Гайд Язык цвета.pdf',
  }) : _sender = sender,
       _templates = templates,
       _course = course,
       _funnel = funnel,
       _checkout = checkout,
       _access = access,
       _warmup = warmup,
       _broadcast = broadcast,
       _adminGate = AdminGate(adminUserIds),
       _adminChatId = adminChatId,
       _interactionWhitelist = interactionWhitelist,
       _catalogSync = catalogSync,
       _sheetsExportJob = sheetsExportJob,
       _adminAlerts = adminAlerts,
       _nowProvider = nowProvider ?? DateTime.now;

  final MessageSender _sender;
  final MessageTemplates _templates;
  final CourseRepository _course;
  final FunnelService _funnel;
  final CheckoutService _checkout;
  final AccessService _access;
  final WarmupService _warmup;
  final BroadcastService _broadcast;
  final AdminGate _adminGate;
  final int? _adminChatId;
  final InteractionWhitelist _interactionWhitelist;
  final GoogleSheetsCatalogSync? _catalogSync;
  final GoogleSheetsFunnelExportJob? _sheetsExportJob;
  final AdminAlertPort? _adminAlerts;
  final DateTime Function() _nowProvider;
  final String? leadMagnetPath;
  final String leadMagnetFilename;
  final Map<int, PrivateFlowState> _flowByUserId = <int, PrivateFlowState>{};
  DateTime? _lastGuideMissingAlertAt;

  Launch? get _launch => _course.activeLaunch();

  Map<String, Object?> _homeKeyboard(int userId) {
    if (_adminGate.isConfiguredAdmin(userId)) {
      return _templates.adminMenuKeyboard();
    }
    return _templates.userMenuKeyboard(
      showCourseStatus: _funnel.enrollmentFor(userId)?.funnelPhase.showsCourseStatus ?? false,
    );
  }

  Future<void> _pinCourseMenu(int userId) {
    return _sender.sendMessage(
      userId,
      _templates.courseMenuPinned(),
      parseMode: 'HTML',
      replyMarkup: _homeKeyboard(userId),
    );
  }

  Future<bool> handle(Map<String, dynamic> update) async {
    if (await _handleChatMember(update)) {
      return true;
    }
    final context = extractPrivateMessageContext(update);
    if (context == null) {
      return false;
    }
    if (context.chat['type']?.toString() != 'private') {
      return false;
    }
    return _dispatch(context);
  }

  @override
  Future<void> notifyPaymentResult(PaymentApplyResult result) {
    return _notifyPaymentResult(result);
  }
}

enum _AdminConfirmKind { paid, deposit, cancel }
