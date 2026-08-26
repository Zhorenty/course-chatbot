import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';
import 'package:l/l.dart';

final class BroadcastResult {
  const BroadcastResult({
    required this.sent,
    required this.failed,
    required this.total,
  });

  final int sent;
  final int failed;
  final int total;
}

final class BroadcastService {
  BroadcastService({
    required MessageSender sender,
    required CourseRepository course,
  })  : _sender = sender,
        _course = course;

  final MessageSender _sender;
  final CourseRepository _course;

  Future<BroadcastResult> send({
    required BroadcastSegment segment,
    required String htmlText,
    Map<String, Object?>? replyMarkup,
  }) async {
    final userIds = _course.listBroadcastUserIds(segment: segment);
    var sent = 0;
    var failed = 0;
    for (final userId in userIds) {
      try {
        await _sender.sendMessage(
          userId,
          htmlText,
          parseMode: 'HTML',
          replyMarkup: replyMarkup,
        );
        sent++;
      } on TelegramApiException catch (error) {
        failed++;
        l.w('Broadcast failed for $userId: $error');
      } on Object catch (error, stackTrace) {
        failed++;
        l.w('Broadcast unexpected error for $userId: $error', stackTrace);
      }
    }
    return BroadcastResult(sent: sent, failed: failed, total: userIds.length);
  }
}
