part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersChatMember on PrivateHandlers {
  Future<bool> _handleChatMember(Map<String, dynamic> update) async {
    if (await _handleMyChatMember(update)) {
      return true;
    }
    return _handleChannelMember(update);
  }

  Future<bool> _handleMyChatMember(Map<String, dynamic> update) async {
    final raw = update['my_chat_member'];
    if (raw is! Map) {
      return false;
    }
    final payload = Map<String, dynamic>.from(raw);
    final chatRaw = payload['chat'];
    final fromRaw = payload['from'];
    final newChatMember = payload['new_chat_member'];
    if (chatRaw is! Map || fromRaw is! Map || newChatMember is! Map) {
      return false;
    }
    final chat = Map<String, dynamic>.from(chatRaw);
    if (chat['type']?.toString() != 'private') {
      return false;
    }
    final userId = asTelegramInt(fromRaw['id']);
    if (userId == null) {
      return false;
    }
    final status = newChatMember['status']?.toString();
    final blocked = status == 'kicked' || status == 'left';
    _course.setBotBlocked(userId: userId, blocked: blocked);
    return true;
  }

  Future<bool> _handleChannelMember(Map<String, dynamic> update) async {
    final raw = update['chat_member'];
    if (raw is! Map) {
      return false;
    }
    final payload = Map<String, dynamic>.from(raw);
    final chatRaw = payload['chat'];
    final newChatMember = payload['new_chat_member'];
    if (chatRaw is! Map || newChatMember is! Map) {
      return false;
    }
    final chatId = asTelegramInt(chatRaw['id']);
    if (chatId == null) {
      return false;
    }
    final launch = _course.launchByChannelId(chatId);
    if (launch == null) {
      return false;
    }
    final userRaw = newChatMember['user'];
    if (userRaw is! Map) {
      return false;
    }
    final userId = asTelegramInt(userRaw['id']);
    final status = newChatMember['status']?.toString();
    if (userId == null) {
      return false;
    }
    if (status == 'member' || status == 'administrator') {
      _access.markJoined(userId: userId, launchId: launch.id, at: _nowProvider());
    }
    return true;
  }
}
