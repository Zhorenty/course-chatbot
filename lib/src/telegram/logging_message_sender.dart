import 'package:course_chatbot/src/data/conversation_log_repository.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/stored_telegram_message.dart';
import 'package:course_chatbot/src/telegram/input_rich_message.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:l/l.dart';

final class LoggingMessageSender implements MessageSender {
  LoggingMessageSender({
    required MessageSender inner,
    required ConversationLogRepository conversationLog,
  }) : _inner = inner,
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
  Future<SentTelegramDocument> sendRichMessage(
    int chatId,
    InputRichMessage richMessage, {
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    final sent = await _inner.sendRichMessage(
      chatId,
      richMessage,
      disableNotification: disableNotification,
      replyMarkup: replyMarkup,
    );
    final media = richMessage.media;
    final photosOnly = media.isNotEmpty && media.every((item) => item.isPhoto);
    final document = media.isEmpty ? null : media.first.document;
    await _safeAppend(
      chatId: chatId,
      telegramMessageId: sent.messageId,
      contentType: document == null
          ? ConversationContentType.text
          : photosOnly
          ? ConversationContentType.photo
          : ConversationContentType.document,
      textPreview: document == null
          ? richMessage.html
          : photosOnly
          ? (media.length == 1
                ? 'photo ${document.filename ?? document.ref}'
                : 'album ${media.length}')
          : 'document ${document.filename ?? document.ref}',
    );
    return sent;
  }

  @override
  Future<SentTelegramDocument> sendDocument(
    int chatId, {
    required String document,
    String? filename,
    bool fromFile = false,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    final sent = await _inner.sendDocument(
      chatId,
      document: document,
      filename: filename,
      fromFile: fromFile,
      disableNotification: disableNotification,
      replyMarkup: replyMarkup,
    );
    await _safeAppend(
      chatId: chatId,
      telegramMessageId: sent.messageId,
      contentType: ConversationContentType.document,
      textPreview: 'document ${filename ?? document}',
    );
    return sent;
  }

  @override
  Future<void> answerCallbackQuery(String callbackQueryId, {String? text, bool showAlert = false}) {
    return _inner.answerCallbackQuery(callbackQueryId, text: text, showAlert: showAlert);
  }

  @override
  Future<void> editMessageReplyMarkup(
    int chatId, {
    required int messageId,
    Map<String, Object?>? replyMarkup,
  }) {
    return _inner.editMessageReplyMarkup(chatId, messageId: messageId, replyMarkup: replyMarkup);
  }

  @override
  Future<void> editMessageText(
    int chatId, {
    required int messageId,
    required String text,
    bool disableWebPagePreview = true,
    Map<String, Object?>? replyMarkup,
    String? parseMode,
  }) {
    return _inner.editMessageText(
      chatId,
      messageId: messageId,
      text: text,
      disableWebPagePreview: disableWebPagePreview,
      replyMarkup: replyMarkup,
      parseMode: parseMode,
    );
  }

  @override
  Future<void> editRichMessage(
    int chatId, {
    required int messageId,
    required InputRichMessage richMessage,
    Map<String, Object?>? replyMarkup,
  }) {
    return _inner.editRichMessage(
      chatId,
      messageId: messageId,
      richMessage: richMessage,
      replyMarkup: replyMarkup,
    );
  }

  @override
  Future<void> deleteMessage(int chatId, {required int messageId}) {
    return _inner.deleteMessage(chatId, messageId: messageId);
  }

  @override
  Future<int> forwardMessage({
    required int chatId,
    required int fromChatId,
    required int messageId,
    bool disableNotification = true,
  }) {
    return _inner.forwardMessage(
      chatId: chatId,
      fromChatId: fromChatId,
      messageId: messageId,
      disableNotification: disableNotification,
    );
  }

  @override
  Future<int> copyMessage({
    required int chatId,
    required int fromChatId,
    required int messageId,
    bool disableNotification = true,
  }) async {
    final copiedId = await _inner.copyMessage(
      chatId: chatId,
      fromChatId: fromChatId,
      messageId: messageId,
      disableNotification: disableNotification,
    );
    await _safeAppend(
      chatId: chatId,
      telegramMessageId: copiedId,
      contentType: ConversationContentType.copy,
      textPreview: 'copy $fromChatId:$messageId',
    );
    return copiedId;
  }

  @override
  Future<List<int>> copyMessages({
    required int chatId,
    required int fromChatId,
    required List<int> messageIds,
    bool disableNotification = true,
  }) async {
    final copied = await _inner.copyMessages(
      chatId: chatId,
      fromChatId: fromChatId,
      messageIds: messageIds,
      disableNotification: disableNotification,
    );
    await _safeAppend(
      chatId: chatId,
      telegramMessageId: copied.last,
      contentType: ConversationContentType.copy,
      textPreview: 'copy $fromChatId:${messageIds.join(',')}',
    );
    return copied;
  }

  @override
  Future<List<int>> sendPhotos(
    int chatId,
    List<String> photos, {
    bool fromFile = false,
    bool disableNotification = true,
    String? caption,
    String? parseMode,
    Map<String, Object?>? replyMarkup,
  }) async {
    final ids = await _inner.sendPhotos(
      chatId,
      photos,
      fromFile: fromFile,
      disableNotification: disableNotification,
      caption: caption,
      parseMode: parseMode,
      replyMarkup: replyMarkup,
    );
    if (ids.isNotEmpty) {
      await _safeAppend(
        chatId: chatId,
        telegramMessageId: ids.last,
        contentType: ConversationContentType.photo,
        textPreview: photos.length == 1 ? 'photo ${photos.first}' : 'album ${photos.length}',
      );
    }
    return ids;
  }

  @override
  Future<List<int>> sendStoredMessage(
    int chatId,
    StoredTelegramMessage content, {
    bool disableNotification = true,
  }) async {
    final ids = await _inner.sendStoredMessage(
      chatId,
      content,
      disableNotification: disableNotification,
    );
    await _safeAppend(
      chatId: chatId,
      telegramMessageId: ids.last,
      contentType: ConversationContentType.copy,
      textPreview: content.captionHtml ?? content.kind.name,
    );
    return ids;
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
