import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/prefer_rich_send.dart';
import 'package:l/l.dart';

abstract interface class AdminAlertPort {
  Future<void> notifyGuideMissing({required int userId});

  Future<void> notifyGuideIssued({required UserProfile user, Launch? launch});

  Future<void> notifyWebinarRsvp({required UserProfile user, required Launch launch});

  Future<void> notifyPaidWithInvite({
    required UserProfile user,
    required CourseOrder order,
    Launch? launch,
  });
}

/// Pushes the same admin chats used for `_escalateToAdmin` (see
/// `AdminGate.notificationChatIds`) for kassa outages, a missing lead magnet,
/// and live funnel events (guide, RSVP, paid + invite).
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
    await _pushAdmins(
      text,
      userId: userId,
      richHtml: _templates.adminPaymentGatewayDownRich(
        userId: userId,
        provider: provider,
        kind: kind,
        reason: reason,
        username: username,
        firstName: firstName,
      ),
    );
  }

  @override
  Future<void> notifyGuideMissing({required int userId}) {
    return _pushAdmins(_templates.adminGuideMissing(userId: userId), userId: userId);
  }

  @override
  Future<void> notifyGuideIssued({required UserProfile user, Launch? launch}) {
    return _pushAdmins(
      _templates.adminGuideIssued(user: user, launch: launch),
      userId: user.userId,
      richHtml: _templates.adminGuideIssuedRich(user: user, launch: launch),
    );
  }

  @override
  Future<void> notifyWebinarRsvp({required UserProfile user, required Launch launch}) {
    return _pushAdmins(
      _templates.adminWebinarRsvp(user: user, launch: launch),
      userId: user.userId,
      richHtml: _templates.adminWebinarRsvpRich(user: user, launch: launch),
    );
  }

  @override
  Future<void> notifyPaidWithInvite({
    required UserProfile user,
    required CourseOrder order,
    Launch? launch,
  }) {
    return _pushAdmins(
      _templates.adminPaidWithInvite(user: user, order: order, launch: launch),
      userId: user.userId,
      richHtml: _templates.adminPaidWithInviteRich(user: user, order: order, launch: launch),
    );
  }

  Future<void> _pushAdmins(String text, {required int userId, String? richHtml}) async {
    final markup = _templates.adminIncomingKeyboard(userId);
    for (final chatId in _notificationChatIds) {
      if (chatId == userId) {
        continue;
      }
      try {
        await sendPreferRich(
          _sender,
          chatId,
          text,
          richHtml: richHtml,
          disableNotification: false,
          replyMarkup: markup,
        );
      } on Object catch (error, stackTrace) {
        l.w('Failed to notify admin $chatId: $error', stackTrace);
      }
    }
  }
}
