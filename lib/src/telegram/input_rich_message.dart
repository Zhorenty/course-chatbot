/// Payload for Telegram `sendRichMessage` / `editMessageText.rich_message`.
///
/// Uses the HTML flavour of [InputRichMessage] (`html` field). Exactly one of
/// `html` / `markdown` / `blocks` is allowed by the API; this bot only sends HTML.
final class InputRichMessage {
  const InputRichMessage({required this.html, this.skipEntityDetection = true});

  /// Rich HTML. Caller must escape every user- or payload-derived string.
  final String html;

  /// Skip autolink detection so leftover URLs in copy stay as written.
  final bool skipEntityDetection;

  Map<String, Object?> toJson() {
    return <String, Object?>{'html': html, if (skipEntityDetection) 'skip_entity_detection': true};
  }
}
