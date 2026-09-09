/// Payload for Telegram `sendRichMessage` / `editMessageText.rich_message`.
///
/// Uses the HTML flavour of [InputRichMessage] (`html` field). Exactly one of
/// `html` / `markdown` / `blocks` is allowed by the API; this bot only sends HTML.
final class InputRichMessage {
  const InputRichMessage({
    required this.html,
    this.skipEntityDetection = true,
    this.media = const <InputRichMessageMedia>[],
  });

  /// Rich HTML. Caller must escape every user- or payload-derived string.
  final String html;

  /// Skip autolink detection so leftover URLs in copy stay as written.
  final bool skipEntityDetection;

  /// Files referenced from HTML via `tg://document?id=` (Bot API 10.2+).
  final List<InputRichMessageMedia> media;

  bool get hasLocalFiles => media.any((item) => item.isLocal);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'html': html,
      if (skipEntityDetection) 'skip_entity_detection': true,
      if (media.isNotEmpty)
        'media': <Map<String, Object?>>[for (final item in media) item.toJson()],
    };
  }
}

/// One entry in `InputRichMessage.media` (`InputRichMessageMedia` in the Bot API).
final class InputRichMessageMedia {
  const InputRichMessageMedia.document({required this.id, required this.document});

  /// 1–64 characters: `A–Z`, `a–z`, `0–9`, `_`, `-`.
  final String id;
  final InputRichDocument document;

  bool get isLocal => document.isLocal;

  /// Multipart field name for `attach://` uploads.
  String get attachName => 'rich_$id';

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'media': document.toJson(attachName: isLocal ? attachName : null),
    };
  }
}

/// `InputMediaDocument` as used inside [InputRichMessageMedia].
final class InputRichDocument {
  const InputRichDocument.fileId(this.fileId) : localPath = null, filename = null;

  const InputRichDocument.file({required this.localPath, this.filename}) : fileId = null;

  final String? fileId;
  final String? localPath;
  final String? filename;

  bool get isLocal => localPath != null && localPath!.isNotEmpty;

  /// `file_id` or local path — used by tests and conversation-log previews.
  String get ref => localPath ?? fileId ?? '';

  Map<String, Object?> toJson({String? attachName}) {
    return <String, Object?>{
      'type': 'document',
      'media': attachName != null ? 'attach://$attachName' : fileId!,
    };
  }
}
