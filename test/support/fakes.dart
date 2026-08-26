import 'package:course_chatbot/src/telegram/message_sender.dart';

final class FakeMessageSender implements MessageSender {
  final List<SentMessage> messages = <SentMessage>[];

  @override
  Future<int> sendMessage(
    int chatId,
    String text, {
    bool disableNotification = true,
    bool disableWebPagePreview = true,
    Map<String, Object?>? replyMarkup,
    String? parseMode,
  }) async {
    messages.add(SentMessage(chatId: chatId, text: text, parseMode: parseMode));
    return messages.length;
  }

  @override
  Future<int> sendDocument(
    int chatId, {
    required String document,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    return 0;
  }

  @override
  Future<int> sendVideo(
    int chatId, {
    required String video,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    return 0;
  }

  @override
  Future<int> sendVideoNote(
    int chatId, {
    required String videoNote,
    bool disableNotification = true,
    Map<String, Object?>? replyMarkup,
  }) async {
    return 0;
  }

  @override
  Future<int> copyMessage(
    int chatId, {
    required int fromChatId,
    required int messageId,
    bool disableNotification = true,
  }) async {
    return 0;
  }

  @override
  Future<void> deleteMessage(
    int chatId, {
    required int messageId,
  }) async {}

  @override
  Future<void> answerCallbackQuery(
    String callbackQueryId, {
    String? text,
    bool showAlert = false,
  }) async {}

  @override
  Future<void> editMessageReplyMarkup(
    int chatId, {
    required int messageId,
    Map<String, Object?>? replyMarkup,
  }) async {}
}

final class SentMessage {
  const SentMessage({
    required this.chatId,
    required this.text,
    this.parseMode,
  });

  final int chatId;
  final String text;
  final String? parseMode;
}
