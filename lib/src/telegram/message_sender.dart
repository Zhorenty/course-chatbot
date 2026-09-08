import 'package:course_chatbot/src/telegram/input_rich_message.dart';

final class SentTelegramDocument {
  const SentTelegramDocument({required this.messageId, this.fileId});

  final int messageId;
  final String? fileId;
}

abstract interface class MessageSender {
  Future<int> sendMessage(
    int chatId,
    String text, {
    bool disableNotification = true,
    bool disableWebPagePreview = true,
    Map<String, Object?>? replyMarkup,
    String? parseMode,
  });

  /// Structured screen (Bot API 10.1+). Callers must fall back to [sendMessage]
  /// if this throws — old clients show an “update the app” stub.
  Future<int> sendRichMessage(
    int chatId,
    InputRichMessage richMessage, {
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  });

  Future<SentTelegramDocument> sendDocument(
    int chatId, {
    required String document,
    String? filename,
    bool fromFile = false,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  });

  Future<void> answerCallbackQuery(String callbackQueryId, {String? text, bool showAlert = false});

  Future<void> editMessageReplyMarkup(
    int chatId, {
    required int messageId,
    Map<String, Object?>? replyMarkup,
  });

  Future<void> editMessageText(
    int chatId, {
    required int messageId,
    required String text,
    bool disableWebPagePreview = true,
    Map<String, Object?>? replyMarkup,
    String? parseMode,
  });

  /// Edit a message that was sent as rich. Uses `editMessageText.rich_message`.
  Future<void> editRichMessage(
    int chatId, {
    required int messageId,
    required InputRichMessage richMessage,
    Map<String, Object?>? replyMarkup,
  });

  Future<void> deleteMessage(int chatId, {required int messageId});

  Future<int> forwardMessage({
    required int chatId,
    required int fromChatId,
    required int messageId,
    bool disableNotification = true,
  });

  Future<int> copyMessage({
    required int chatId,
    required int fromChatId,
    required int messageId,
    bool disableNotification = true,
  });
}
