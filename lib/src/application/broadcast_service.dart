import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/jobs/claimed_outbound.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';
import 'package:course_chatbot/src/telegram/telegram_errors.dart';
import 'package:l/l.dart';

final class BroadcastResult {
  const BroadcastResult({required this.sent, required this.failed, required this.total});

  final int sent;
  final int failed;
  final int total;
}

final class BroadcastService {
  BroadcastService({required MessageSender sender, required CourseRepository course})
    : _sender = sender,
      _course = course;

  final MessageSender _sender;
  final CourseRepository _course;

  List<int> listRecipients({
    required Iterable<BroadcastSegment> segments,
    bool excludeOptOut = false,
  }) {
    final ids = <int>{};
    for (final segment in BroadcastSegment.ordered(segments)) {
      ids.addAll(_course.listBroadcastUserIds(segment: segment, excludeOptOut: excludeOptOut));
    }
    return (ids.toList()..sort());
  }

  int countOptOut({required Iterable<BroadcastSegment> segments}) {
    return listRecipients(segments: segments).length -
        listRecipients(segments: segments, excludeOptOut: true).length;
  }

  /// Copies [parts] in order. [replyMarkup] is attached to the last part when
  /// that part is a single message. Telegram albums have no keyboard.
  Future<void> copySequence({
    required int chatId,
    required int fromChatId,
    required List<BroadcastDraftPart> parts,
    Map<String, Object?>? replyMarkup,
  }) async {
    for (var i = 0; i < parts.length; i++) {
      final ids = parts[i].messageIds;
      if (ids.isEmpty) {
        continue;
      }
      final attach = replyMarkup != null && i == parts.length - 1 && ids.length == 1;
      if (ids.length == 1) {
        await _sender.copyMessage(
          chatId: chatId,
          fromChatId: fromChatId,
          messageId: ids.single,
          replyMarkup: attach ? replyMarkup : null,
        );
        continue;
      }
      await _sender.copyMessages(chatId: chatId, fromChatId: fromChatId, messageIds: ids);
    }
  }

  Future<BroadcastResult> send({
    required Iterable<BroadcastSegment> segments,
    required int fromChatId,
    required List<BroadcastDraftPart> parts,
    Map<String, Object?>? replyMarkup,
    bool excludeOptOut = false,
  }) async {
    final userIds = listRecipients(segments: segments, excludeOptOut: excludeOptOut);
    var sent = 0;
    var failed = 0;
    for (var i = 0; i < userIds.length; i++) {
      final userId = userIds[i];
      try {
        await copySequence(
          chatId: userId,
          fromChatId: fromChatId,
          parts: parts,
          replyMarkup: replyMarkup,
        );
        sent++;
      } on TelegramApiException catch (error) {
        failed++;
        if (isUserBlockedError(error)) {
          _course.setBotBlocked(userId: userId, blocked: true);
        }
        l.w('Broadcast failed for $userId: $error');
      } on Object catch (error, stackTrace) {
        failed++;
        l.w('Broadcast unexpected error for $userId: $error', stackTrace);
      }
      await paceOutboundBatch(i + 1);
    }
    return BroadcastResult(sent: sent, failed: failed, total: userIds.length);
  }
}
