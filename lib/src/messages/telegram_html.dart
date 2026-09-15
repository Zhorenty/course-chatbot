import 'package:course_chatbot/src/messages/html_escaper.dart';

final _telegramHtmlMarkup = RegExp(
  r'</?(?:b|strong|i|em|u|s|a|code|pre|tg-spoiler|tg-emoji|br)\b|&(?:amp|lt|gt|quot|#39);',
  caseSensitive: false,
);

/// HTML of a Telegram text or caption, or `null` if empty.
String? telegramTextMessageToHtml(Map<String, dynamic>? message) {
  if (message == null) {
    return null;
  }
  final hasText = message['text'] != null;
  final raw = (hasText ? message['text'] : message['caption'])?.toString();
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return telegramEntitiesToHtml(raw, hasText ? message['entities'] : message['caption_entities']);
}

/// Legacy plain copy vs already-escaped Telegram HTML stored in SQLite.
String storedTelegramTextToHtml(String raw) {
  if (_telegramHtmlMarkup.hasMatch(raw)) {
    return raw;
  }
  return escapeHtml(raw);
}

/// Convert Telegram `MessageEntity` offsets (UTF-16) into Bot API HTML.
String telegramEntitiesToHtml(String text, Object? rawEntities) {
  final entities = _parsedEntities(text, rawEntities);
  if (entities.isEmpty) {
    return escapeHtml(text);
  }
  final opens = <int, List<_HtmlEntity>>{};
  final closes = <int, List<_HtmlEntity>>{};
  for (final entity in entities) {
    opens.putIfAbsent(entity.offset, () => <_HtmlEntity>[]).add(entity);
    closes.putIfAbsent(entity.end, () => <_HtmlEntity>[]).add(entity);
  }
  for (final list in opens.values) {
    list.sort((a, b) => b.length.compareTo(a.length));
  }
  for (final list in closes.values) {
    list.sort((a, b) => a.length.compareTo(b.length));
  }
  final buf = StringBuffer();
  final units = text.codeUnits;
  for (var i = 0; i <= units.length; i++) {
    final closing = closes[i];
    if (closing != null) {
      for (final entity in closing) {
        buf.write(entity.closeTag);
      }
    }
    if (i == units.length) {
      break;
    }
    final opening = opens[i];
    if (opening != null) {
      for (final entity in opening) {
        buf.write(entity.openTag);
      }
    }
    buf.write(escapeHtml(String.fromCharCode(units[i])));
  }
  return buf.toString();
}

List<_HtmlEntity> _parsedEntities(String text, Object? rawEntities) {
  if (rawEntities is! List) {
    return const <_HtmlEntity>[];
  }
  final parsed = <_HtmlEntity>[];
  for (final raw in rawEntities) {
    if (raw is! Map) {
      continue;
    }
    final offset = _asInt(raw['offset']);
    final length = _asInt(raw['length']);
    if (offset == null || length == null || offset < 0 || length <= 0) {
      continue;
    }
    if (offset + length > text.length) {
      continue;
    }
    final tags = _tagsFor(raw);
    if (tags == null) {
      continue;
    }
    parsed.add(_HtmlEntity(offset: offset, length: length, openTag: tags.$1, closeTag: tags.$2));
  }
  return parsed;
}

(String, String)? _tagsFor(Map<dynamic, dynamic> raw) {
  final type = raw['type']?.toString();
  switch (type) {
    case 'bold':
      return ('<b>', '</b>');
    case 'italic':
      return ('<i>', '</i>');
    case 'underline':
      return ('<u>', '</u>');
    case 'strikethrough':
      return ('<s>', '</s>');
    case 'spoiler':
      return ('<tg-spoiler>', '</tg-spoiler>');
    case 'code':
      return ('<code>', '</code>');
    case 'pre':
      final language = raw['language']?.toString().trim();
      if (language == null || language.isEmpty) {
        return ('<pre>', '</pre>');
      }
      return ('<pre><code class="language-${escapeHtml(language)}">', '</code></pre>');
    case 'text_link':
    case 'url':
      final href = raw['url']?.toString().trim();
      if (href == null || href.isEmpty) {
        return null;
      }
      return ('<a href="${escapeHtml(href)}">', '</a>');
    case 'text_mention':
      final user = raw['user'];
      if (user is! Map) {
        return null;
      }
      final userId = _asInt(user['id']);
      if (userId == null) {
        return null;
      }
      return ('<a href="tg://user?id=$userId">', '</a>');
    case 'blockquote':
      return ('<blockquote>', '</blockquote>');
    case 'expandable_blockquote':
      return ('<blockquote expandable>', '</blockquote>');
    case 'custom_emoji':
      final emojiId = raw['custom_emoji_id']?.toString().trim();
      if (emojiId == null || emojiId.isEmpty) {
        return null;
      }
      return ('<tg-emoji emoji-id="${escapeHtml(emojiId)}">', '</tg-emoji>');
    default:
      return null;
  }
}

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

final class _HtmlEntity {
  const _HtmlEntity({
    required this.offset,
    required this.length,
    required this.openTag,
    required this.closeTag,
  });

  final int offset;
  final int length;
  final String openTag;
  final String closeTag;

  int get end => offset + length;
}
