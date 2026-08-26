import 'package:course_chatbot/src/messages/html_escaper.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';

final class PrivateHandlers {
  PrivateHandlers({
    required MessageSender sender,
  }) : _sender = sender;

  final MessageSender _sender;

  Future<bool> handle(Map<String, dynamic> update) async {
    final messageRaw = update['message'];
    if (messageRaw is! Map) {
      return false;
    }
    final message = Map<String, dynamic>.from(messageRaw);
    final chatRaw = message['chat'];
    if (chatRaw is! Map) {
      return false;
    }
    final chat = Map<String, dynamic>.from(chatRaw);
    if (chat['type']?.toString() != 'private') {
      return false;
    }
    final chatId = chat['id'];
    if (chatId is! int) {
      return false;
    }
    final text = message['text']?.toString().trim();
    if (text == null || !text.startsWith('/start')) {
      return false;
    }

    final payload = _parseStartPayload(text);
    final payloadNote =
        payload == null ? 'без метки источника' : 'метка <code>${escapeHtml(payload)}</code>';
    await _sender.sendMessage(
      chatId,
      'Бот курса на связи. Старт $payloadNote.\n\n'
      'Дальше здесь будут гайд, прогрев и запись — пока это каркас.',
      parseMode: 'HTML',
    );
    return true;
  }

  String? _parseStartPayload(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return null;
    }
    return parts[1].trim().toLowerCase();
  }
}
