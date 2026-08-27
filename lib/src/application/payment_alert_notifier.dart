import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:l/l.dart';

/// Pushes the same admin chats used for `_escalateToAdmin` (see
/// `AdminGate.notificationChatIds`) the moment the kassa is down, so the
/// admin does not depend on the user writing in manually.
final class PaymentAlertNotifier implements PaymentGatewayAlertPort {
  PaymentAlertNotifier({
    required MessageSender sender,
    required MessageTemplates templates,
    required Set<int> notificationChatIds,
  }) : _sender = sender,
       _templates = templates,
       _notificationChatIds = notificationChatIds;

  final MessageSender _sender;
  final MessageTemplates _templates;
  final Set<int> _notificationChatIds;

  @override
  Future<void> notifyGatewayUnavailable({
    required int userId,
    required int launchId,
    required PaymentKind kind,
    required String provider,
    String? reason,
  }) async {
    final text = _templates.adminPaymentGatewayDown(
      userId: userId,
      provider: provider,
      reason: reason,
    );
    for (final chatId in _notificationChatIds) {
      try {
        await _sender.sendMessage(chatId, text, parseMode: 'HTML', disableNotification: false);
      } on Object catch (error, stackTrace) {
        l.w('Failed to notify admin $chatId about gateway outage: $error', stackTrace);
      }
    }
  }
}
