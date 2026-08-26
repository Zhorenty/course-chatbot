import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';

/// Thin adapter so [LoggingMessageSender] does not depend on the full course store.
abstract interface class ConversationLogRepository {
  void append({
    required ConversationDirection direction,
    required int peerUserId,
    String? peerUsername,
    required int chatId,
    int? telegramMessageId,
    required ConversationContentType contentType,
    String? textPreview,
  });
}

final class CourseConversationLog implements ConversationLogRepository {
  CourseConversationLog(this._course);

  final CourseRepository _course;

  @override
  void append({
    required ConversationDirection direction,
    required int peerUserId,
    String? peerUsername,
    required int chatId,
    int? telegramMessageId,
    required ConversationContentType contentType,
    String? textPreview,
  }) {
    _course.appendConversation(
      direction: direction,
      peerUserId: peerUserId,
      peerUsername: peerUsername,
      chatId: chatId,
      telegramMessageId: telegramMessageId,
      contentType: contentType,
      textPreview: textPreview,
    );
  }
}
