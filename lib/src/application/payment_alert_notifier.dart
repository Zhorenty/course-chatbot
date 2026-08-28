import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:l/l.dart';

abstract interface class AdminAlertPort {
  Future<void> notifyGuideMissing({required int userId});
}

/// Pushes the same admin chats used for `_escalateToAdmin` (see
/// `AdminGate.notificationChatIds`) the moment the kassa is down or the
/// lead magnet is missing, so the admin does not depend on the user writing in.
final class PaymentAlertNotifier implements PaymentGatewayAlertPort, AdminAlertPort {
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
    String? username,
    String? firstName,
  }) async {
    final text = _templates.adminPaymentGatewayDown(
      userId: userId,
      provider: provider,
      kind: kind,
      reason: reason,
      username: username,
      firstName: firstName,
    );
    await _pushAdmins(text, userId: userId);
  }

  @override
  Future<void> notifyGuideMissing({required int userId}) {
    return _pushAdmins(_templates.adminGuideMissing(userId: userId), userId: userId);
  }

  Future<void> _pushAdmins(String text, {required int userId}) async {
    final markup = _templates.adminIncomingKeyboard(userId);
    for (final chatId in _notificationChatIds) {
      try {
        await _sender.sendMessage(
          chatId,
          text,
          parseMode: 'HTML',
          disableNotification: false,
          replyMarkup: markup,
        );
      } on Object catch (error, stackTrace) {
        l.w('Failed to notify admin $chatId: $error', stackTrace);
      }
    }
  }
}
