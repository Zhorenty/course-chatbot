import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/telegram/channel_api.dart';
import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';
import 'package:l/l.dart';

final class AccessService {
  AccessService({
    required CourseRepository course,
    required ChannelApi telegram,
    DateTime Function()? nowProvider,
  }) : _course = course,
       _telegram = telegram,
       _nowProvider = nowProvider ?? DateTime.now;

  final CourseRepository _course;
  final ChannelApi _telegram;
  final DateTime Function() _nowProvider;

  Future<String?> issueInvite({
    required int userId,
    required int orderId,
    required Launch launch,
    bool reissue = false,
  }) async {
    final channelId = launch.channelId;
    if (channelId == null) {
      l.w('Cannot issue invite: COURSE_CHANNEL_ID is not set.');
      return null;
    }
    final existing = _course.accessFor(userId: userId, launchId: launch.id);
    if (existing != null && existing.inviteLink != null && existing.revokedAt == null && !reissue) {
      return existing.inviteLink;
    }
    if (existing?.inviteLink != null) {
      try {
        await _telegram.revokeChatInviteLink(chatId: channelId, inviteLink: existing!.inviteLink!);
      } on TelegramApiException catch (error, stackTrace) {
        l.w('Failed to revoke previous invite for user $userId: $error', stackTrace);
      }
    }
    final link = await _telegram.createChatInviteLink(
      chatId: channelId,
      memberLimit: 1,
      name: 'u$userId-o$orderId',
    );
    _course.upsertAccess(
      userId: userId,
      launchId: launch.id,
      orderId: orderId,
      inviteLink: link,
      inviteCreatedAt: _nowProvider(),
    );
    _course.setFunnelPhase(userId: userId, phase: FunnelPhase.accessGranted, launchId: launch.id);
    final order = _course.getOrder(orderId);
    if (order != null) {
      _course.updateOrder(order.copyWith(accessGranted: true));
    }
    return link;
  }

  Future<void> revoke({required int userId, required Launch launch}) async {
    final channelId = launch.channelId;
    final existing = _course.accessFor(userId: userId, launchId: launch.id);
    if (channelId != null) {
      if (existing?.inviteLink != null) {
        try {
          await _telegram.revokeChatInviteLink(
            chatId: channelId,
            inviteLink: existing!.inviteLink!,
          );
        } on TelegramApiException catch (error, stackTrace) {
          l.w('Failed to revoke invite for user $userId: $error', stackTrace);
        }
      }
      try {
        await _telegram.banChatMember(channelId, userId: userId);
        await _telegram.unbanChatMember(channelId, userId: userId);
      } on TelegramApiException catch (error, stackTrace) {
        l.w('Failed to kick user $userId from channel: $error', stackTrace);
      }
    }
    if (existing == null) {
      return;
    }
    _course.upsertAccess(
      userId: userId,
      launchId: launch.id,
      orderId: existing.orderId,
      inviteLink: existing.inviteLink,
      inviteCreatedAt: existing.inviteCreatedAt,
      joinedAt: existing.joinedAt,
      revokedAt: _nowProvider(),
    );
  }

  ChannelAccess? current({required int userId, required int launchId}) {
    return _course.accessFor(userId: userId, launchId: launchId);
  }

  void markJoined({required int userId, required int launchId, required DateTime at}) {
    _course.markJoined(userId: userId, launchId: launchId, joinedAt: at);
  }
}
