import 'package:course_chatbot/src/telegram/message_sender.dart';

extension CopySourceMessages on MessageSender {
  Future<List<int>> copySourceMessages({
    required int chatId,
    required int fromChatId,
    required List<int> messageIds,
    bool disableNotification = true,
  }) async {
    final ids = <int>{
      for (final id in messageIds)
        if (id > 0) id,
    }.toList()..sort();
    if (ids.isEmpty) {
      throw ArgumentError('messageIds must not be empty');
    }
    if (ids.length == 1) {
      return <int>[
        await copyMessage(
          chatId: chatId,
          fromChatId: fromChatId,
          messageId: ids.single,
          disableNotification: disableNotification,
        ),
      ];
    }
    return copyMessages(
      chatId: chatId,
      fromChatId: fromChatId,
      messageIds: ids,
      disableNotification: disableNotification,
    );
  }
}
