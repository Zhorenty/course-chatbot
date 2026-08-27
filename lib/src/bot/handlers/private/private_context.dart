import 'package:course_chatbot/src/domain/broadcast.dart';

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
      text: _trimmedMessageText(message),
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

String? _trimmedMessageText(Map<String, dynamic> message) {
  final raw = message['text'] ?? message['caption'];
  final text = raw?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
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

bool isTelegramAlbum(Map<String, dynamic>? message) {
  final raw = message?['media_group_id']?.toString().trim();
  return raw != null && raw.isNotEmpty;
}

BroadcastContentKind? broadcastContentKindOf(Map<String, dynamic>? message) {
  if (message == null) {
    return null;
  }
  if (message['photo'] != null) {
    return BroadcastContentKind.photo;
  }
  if (message['document'] != null) {
    return BroadcastContentKind.document;
  }
  if (message['video'] != null) {
    return BroadcastContentKind.video;
  }
  if (message['video_note'] != null) {
    return BroadcastContentKind.videoNote;
  }
  if (message['animation'] != null) {
    return BroadcastContentKind.animation;
  }
  if (message['voice'] != null) {
    return BroadcastContentKind.voice;
  }
  if (message['audio'] != null) {
    return BroadcastContentKind.audio;
  }
  if (message['sticker'] != null) {
    return BroadcastContentKind.sticker;
  }
  if (_trimmedMessageText(message) != null) {
    return BroadcastContentKind.text;
  }
  return null;
}
