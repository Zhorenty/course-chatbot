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

  Future<BroadcastResult> send({
    required Iterable<BroadcastSegment> segments,
    required int fromChatId,
    required int messageId,
    bool excludeOptOut = false,
  }) async {
    final userIds = listRecipients(segments: segments, excludeOptOut: excludeOptOut);
    var sent = 0;
    var failed = 0;
    for (var i = 0; i < userIds.length; i++) {
      final userId = userIds[i];
      try {
        await _sender.copyMessage(chatId: userId, fromChatId: fromChatId, messageId: messageId);
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
