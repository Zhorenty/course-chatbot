import 'package:course_chatbot/src/domain/launch_dozhim.dart';
import 'package:course_chatbot/src/domain/stored_telegram_message.dart';
import 'package:course_chatbot/src/telegram/copy_source_messages.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';

/// Replay a stored dozhim payload. Legacy rows without a payload still copy
/// the original admin messages.
Future<List<int>> replayDozhimContent({
  required MessageSender sender,
  required int chatId,
  required LaunchDozhimMessage message,
  StoredTelegramMessage? payload,
  bool disableNotification = true,
}) async {
  final content = payload ?? message.payload;
  if (content != null && content.canReplay) {
    return sender.sendStoredMessage(chatId, content, disableNotification: disableNotification);
  }
  return sender.copySourceMessages(
    chatId: chatId,
    fromChatId: message.sourceChatId,
    messageIds: message.sourceMessageIds,
    disableNotification: disableNotification,
  );
}
