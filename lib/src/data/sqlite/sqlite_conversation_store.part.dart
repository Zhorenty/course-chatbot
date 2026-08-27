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
    final redacted = _redactInviteLinks(trimmed);
    final plain = redacted.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (plain.isEmpty) {
      return null;
    }
    if (plain.runes.length <= _SqliteCourseStore.previewMaxLength) {
      return plain;
    }
    return '${String.fromCharCodes(plain.runes.take(_SqliteCourseStore.previewMaxLength))}…';
  }

  String _redactInviteLinks(String text) {
    return text
        .replaceAll(RegExp(r'https://t\.me/\+[A-Za-z0-9_-]+'), '[invite]')
        .replaceAll(RegExp(r'https://t\.me/joinchat/[A-Za-z0-9_-]+'), '[invite]');
  }

  void pruneConversationLog({required DateTime olderThan, int keepPerUser = 200}) {
    _db.execute('DELETE FROM conversation_log WHERE occurred_at < ?;', <Object?>[
      olderThan.toUtc().toIso8601String(),
    ]);
    _db.execute(
      '''
      DELETE FROM conversation_log
      WHERE id IN (
        SELECT id FROM (
          SELECT id,
                 ROW_NUMBER() OVER (
                   PARTITION BY peer_user_id
                   ORDER BY occurred_at DESC, id DESC
                 ) AS rn
          FROM conversation_log
        )
        WHERE rn > ?
      );
      ''',
      <Object?>[keepPerUser],
    );
  }
}
