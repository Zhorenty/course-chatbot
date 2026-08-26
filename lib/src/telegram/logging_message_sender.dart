import 'package:course_chatbot/src/data/conversation_log_repository.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:l/l.dart';

final class LoggingMessageSender implements MessageSender {
  LoggingMessageSender({
    required MessageSender inner,
    required ConversationLogRepository conversationLog,
  })  : _inner = inner,
        _conversationLog = conversationLog;

  final MessageSender _inner;
  final ConversationLogRepository _conversationLog;

  @override
  Future<int> sendMessage(
    int chatId,
    String text, {
    bool disableNotification = true,
    bool disableWebPagePreview = true,
    Map<String, Object?>? replyMarkup,
    String? parseMode,
  }) async {
    final messageId = await _inner.sendMessage(
      chatId,
      text,
      disableNotification: disableNotification,
      disableWebPagePreview: disableWebPagePreview,
      replyMarkup: replyMarkup,
      parseMode: parseMode,
    );
    await _safeAppend(
      chatId: chatId,
      telegramMessageId: messageId,
      contentType: ConversationContentType.text,
      textPreview: text,
    );
    return messageId;
  }

  @override
  Future<int> sendDocument(
    int chatId, {
    required String document,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    final messageId = await _inner.sendDocument(
      chatId,
      document: document,
      disableNotification: disableNotification,
      replyMarkup: replyMarkup,
    );
    await _safeAppend(
      chatId: chatId,
      telegramMessageId: messageId,
      contentType: ConversationContentType.document,
      textPreview: 'document $document',
    );
    return messageId;
  }

  @override
  Future<int> sendVideo(
    int chatId, {
    required String video,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    return _inner.sendVideo(
      chatId,
      video: video,
      disableNotification: disableNotification,
      replyMarkup: replyMarkup,
    );
  }

  @override
  Future<int> sendVideoNote(
    int chatId, {
    required String videoNote,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) {
    return _inner.sendVideoNote(
      chatId,
      videoNote: videoNote,
      disableNotification: disableNotification,
      replyMarkup: replyMarkup,
    );
  }

  @override
  Future<int> copyMessage(
    int chatId, {
    required int fromChatId,
    required int messageId,
    bool disableNotification = true,
  }) async {
    final copiedId = await _inner.copyMessage(
      chatId,
      fromChatId: fromChatId,
      messageId: messageId,
      disableNotification: disableNotification,
    );
    await _safeAppend(
      chatId: chatId,
      telegramMessageId: copiedId,
      contentType: ConversationContentType.copy,
      textPreview: 'copy from $fromChatId#$messageId',
    );
    return copiedId;
  }

  @override
  Future<void> deleteMessage(
    int chatId, {
    required int messageId,
  }) {
    return _inner.deleteMessage(chatId, messageId: messageId);
  }

  @override
  Future<void> answerCallbackQuery(
    String callbackQueryId, {
    String? text,
    bool showAlert = false,
  }) {
    return _inner.answerCallbackQuery(
      callbackQueryId,
      text: text,
      showAlert: showAlert,
    );
  }

  @override
  Future<void> editMessageReplyMarkup(
    int chatId, {
    required int messageId,
    Map<String, Object?>? replyMarkup,
  }) {
    return _inner.editMessageReplyMarkup(
      chatId,
      messageId: messageId,
      replyMarkup: replyMarkup,
    );
  }

  Future<void> _safeAppend({
    required int chatId,
    required int telegramMessageId,
    required ConversationContentType contentType,
    String? textPreview,
  }) async {
    if (chatId <= 0) {
      return;
    }
    try {
      _conversationLog.append(
        direction: ConversationDirection.outbound,
        peerUserId: chatId,
        chatId: chatId,
        telegramMessageId: telegramMessageId,
        contentType: contentType,
        textPreview: textPreview,
      );
    } on Object catch (error, stackTrace) {
      l.w('Failed to append outbound conversation log: $error', stackTrace);
    }
  }
}
