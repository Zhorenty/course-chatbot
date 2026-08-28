import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
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

  Future<BroadcastResult> send({
    required BroadcastSegment segment,
    required int fromChatId,
    required int messageId,
    bool excludeOptOut = false,
    Set<String>? courseEntrySources,
  }) async {
    final userIds = _course.listBroadcastUserIds(
      segment: segment,
      excludeOptOut: excludeOptOut,
      courseEntrySources: courseEntrySources ?? AcquisitionSource.coursePayloads,
    );
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
