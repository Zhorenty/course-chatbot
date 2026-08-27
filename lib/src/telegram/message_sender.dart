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
}
