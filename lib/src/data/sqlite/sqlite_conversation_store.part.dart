part of 'package:course_chatbot/src/data/sqlite_course_repository.dart';

mixin _SqliteConversationStore on _SqliteCourseStore {
  void appendConversation({
    required ConversationDirection direction,
    required int peerUserId,
    String? peerUsername,
    required int chatId,
    int? telegramMessageId,
    required ConversationContentType contentType,
    String? textPreview,
  }) {
    if (peerUserId <= 0 || chatId <= 0) {
      return;
    }
    final normalized = normalizeTelegramUsername(peerUsername);
    _db.execute(
      '''
      INSERT INTO conversation_log (
        occurred_at, direction, peer_user_id, peer_username, chat_id,
        telegram_message_id, content_type, text_preview
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      <Object?>[
        _nowProvider().toUtc().toIso8601String(),
        direction.name,
        peerUserId,
        normalized,
        chatId,
        telegramMessageId,
        contentType.name,
        _truncatePreview(textPreview),
      ],
    );
  }

  List<ConversationLogEntry> dialogForUser(int userId, {int limit = 30}) {
    final rows = _db.select(
      '''
      SELECT * FROM conversation_log
      WHERE peer_user_id = ?
      ORDER BY occurred_at DESC, id DESC
      LIMIT ?;
      ''',
      <Object?>[userId, limit],
    );
    return rows.map(mapLog).toList().reversed.toList(growable: false);
  }

  String? _truncatePreview(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final plain = trimmed.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (plain.isEmpty) {
      return null;
    }
    if (plain.runes.length <= _SqliteCourseStore.previewMaxLength) {
      return plain;
    }
    return '${String.fromCharCodes(plain.runes.take(_SqliteCourseStore.previewMaxLength))}…';
  }
}
