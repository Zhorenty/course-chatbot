import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/prefer_rich_send.dart';
import 'package:l/l.dart';

abstract interface class AdminAlertPort {
  Future<void> notifyGuideMissing({required int userId});

  Future<void> notifyFunnelDayDigest({required DateTime day, required FunnelDaySlice slice});

  Future<void> notifyPaidWithInvite({
    required UserProfile user,
    required CourseOrder order,
    Launch? launch,
  });
}

/// Pushes the same admin chats used for `_escalateToAdmin` (see
/// `AdminGate.notificationChatIds`) for kassa outages, a missing lead magnet,
/// paid + invite, and the daily guide/RSVP digest.
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
  Future<void> notifyFunnelDayDigest({required DateTime day, required FunnelDaySlice slice}) {
    return _pushAdmins(
      _templates.adminFunnelDayDigest(day: day, slice: slice),
      richHtml: _templates.adminFunnelDayDigestRich(day: day, slice: slice),
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

  Future<void> _pushAdmins(String text, {int? userId, String? richHtml}) async {
    final markup = userId == null ? null : _templates.adminIncomingKeyboard(userId);
    var delivered = 0;
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
        delivered++;
      } on Object catch (error, stackTrace) {
        l.w('Failed to notify admin $chatId: $error', stackTrace);
      }
    }
    if (delivered == 0 && _notificationChatIds.where((id) => id != userId).isNotEmpty) {
      throw StateError('Admin alert reached no chats');
    }
  }
}
