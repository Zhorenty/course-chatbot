final class PrivateMessageContext {
  const PrivateMessageContext({
    required this.chat,
    required this.from,
    required this.text,
    required this.message,
    required this.callbackQueryId,
    this.callbackData,
    this.callbackMessage,
  });

  final Map<String, dynamic> chat;
  final Map<String, dynamic>? from;
  final String? text;
  final Map<String, dynamic>? message;
  final String? callbackQueryId;
  final String? callbackData;
  final Map<String, dynamic>? callbackMessage;

  int? get chatId => _asInt(chat['id']);

  int? get userId => _asInt(from?['id']);

  String? get username => from?['username']?.toString();

  String? get firstName => from?['first_name']?.toString();
}

PrivateMessageContext? extractPrivateMessageContext(Map<String, dynamic> update) {
  final callback = update['callback_query'];
  if (callback is Map) {
    final callbackMap = Map<String, dynamic>.from(callback);
    final callbackMessageRaw = callbackMap['message'];
    final fromRaw = callbackMap['from'];
    if (callbackMessageRaw is! Map) {
      return null;
    }
    final callbackMessage = Map<String, dynamic>.from(callbackMessageRaw);
    final callbackChatRaw = callbackMessage['chat'];
    if (callbackChatRaw is! Map) {
      return null;
    }
    return PrivateMessageContext(
      chat: Map<String, dynamic>.from(callbackChatRaw),
      from: fromRaw is Map ? Map<String, dynamic>.from(fromRaw) : null,
      text: null,
      message: null,
      callbackQueryId: callbackMap['id']?.toString(),
      callbackData: callbackMap['data']?.toString(),
      callbackMessage: callbackMessage,
    );
  }

  final messageRaw = update['message'];
  if (messageRaw is Map) {
    final message = Map<String, dynamic>.from(messageRaw);
    final chatRaw = message['chat'];
    if (chatRaw is! Map) {
      return null;
    }
    final fromRaw = message['from'];
    return PrivateMessageContext(
      chat: Map<String, dynamic>.from(chatRaw),
      from: fromRaw is Map ? Map<String, dynamic>.from(fromRaw) : null,
      text: message['text']?.toString().trim(),
      message: message,
      callbackQueryId: null,
    );
  }
  return null;
}

int? asTelegramInt(Object? value) => _asInt(value);

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

String? extractDocumentFileId(Map<String, dynamic>? message) {
  final document = message?['document'];
  if (document is! Map) {
    return null;
  }
  final fileId = document['file_id']?.toString().trim();
  if (fileId == null || fileId.isEmpty) {
    return null;
  }
  return fileId;
}
