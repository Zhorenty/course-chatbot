import 'package:course_chatbot/src/domain/stored_telegram_message.dart';
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
  ///
  /// [SentTelegramDocument.fileId] is set when the rich payload uploaded or
  /// reused a document (lead-magnet cache).
  Future<SentTelegramDocument> sendRichMessage(
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

  /// Copies 1–100 messages. A media group stays an album when all its ids are passed.
  Future<List<int>> copyMessages({
    required int chatId,
    required int fromChatId,
    required List<int> messageIds,
    bool disableNotification = true,
  });

  /// Send one photo or an album. [photos] are `file_id`s, or local paths when
  /// [fromFile] is true. Empty list is a no-op.
  ///
  /// [caption] / [parseMode] / [replyMarkup] apply to a single photo. For an
  /// album the caption sits on the first item; Telegram has no album keyboard.
  Future<List<int>> sendPhotos(
    int chatId,
    List<String> photos, {
    bool fromFile = false,
    bool disableNotification = true,
    String? caption,
    String? parseMode,
    Map<String, Object?>? replyMarkup,
  });

  Future<List<int>> sendStoredMessage(
    int chatId,
    StoredTelegramMessage content, {
    bool disableNotification = true,
  });
}
