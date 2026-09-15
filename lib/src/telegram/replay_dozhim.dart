import 'package:course_chatbot/src/domain/launch_dozhim.dart';
import 'package:course_chatbot/src/telegram/copy_source_messages.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';

/// Replay a stored dozhim payload. Legacy rows without a payload still copy
/// the original admin messages.
Future<List<int>> replayDozhimContent({
  required MessageSender sender,
  required int chatId,
  required LaunchDozhimMessage message,
  bool disableNotification = true,
}) async {
  final payload = message.payload;
  if (payload != null && payload.canReplay) {
    return sender.sendStoredMessage(chatId, payload, disableNotification: disableNotification);
  }
  return sender.copySourceMessages(
    chatId: chatId,
    fromChatId: message.sourceChatId,
    messageIds: message.sourceMessageIds,
    disableNotification: disableNotification,
  );
}
