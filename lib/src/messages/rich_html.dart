import 'package:course_chatbot/src/messages/html_escaper.dart';

/// Builders for Bot API 10.1+ rich HTML. Values that already contain tags
/// (`<code>`, `<a>`) must be escaped by the caller first, then wrapped here.
String richH2(String text) => '<h2>${escapeHtml(text)}</h2>';

String richH3(String text) => '<h3>${escapeHtml(text)}</h3>';

String richP(String innerHtml) => '<p>$innerHtml</p>';

String richHr() => '<hr>';

String richFooter(String innerHtml) => '<footer>$innerHtml</footer>';

String richQuote(String innerHtml) => '<blockquote>$innerHtml</blockquote>';

String richUl(List<String> items) {
  final buf = StringBuffer('<ul>');
  for (final item in items) {
    buf.write('<li>$item</li>');
  }
  buf.write('</ul>');
  return buf.toString();
}

String richOl(List<String> items) {
  final buf = StringBuffer('<ol>');
  for (final item in items) {
    buf.write('<li>$item</li>');
  }
  buf.write('</ol>');
  return buf.toString();
}

/// Two-column table: label (escaped) · value (HTML allowed).
String richTable(List<(String label, String valueHtml)> rows) {
  final buf = StringBuffer('<table>');
  for (final row in rows) {
    buf.write('<tr><td>${escapeHtml(row.$1)}</td><td>${row.$2}</td></tr>');
  }
  buf.write('</table>');
  return buf.toString();
}

String richDetails(String summary, String bodyHtml, {bool open = false}) {
  final openAttr = open ? ' open' : '';
  return '<details$openAttr><summary>${escapeHtml(summary)}</summary>$bodyHtml</details>';
}

/// Embed a file from `InputRichMessage.media` (`<tg-document>`, Bot API 10.3).
String richDocument({required String mediaId, String? caption}) {
  final tag = '<tg-document src="tg://document?id=${escapeHtml(mediaId)}"></tg-document>';
  final captionText = caption?.trim();
  if (captionText == null || captionText.isEmpty) {
    return tag;
  }
  return '<figure>$tag<figcaption>${escapeHtml(captionText)}</figcaption></figure>';
}

final _richBlockTag = RegExp(
  r'<(h[1-6]|p|table|details|ul|ol|footer|blockquote|tg-document|figure)\b',
  caseSensitive: false,
);
final _boldOnly = RegExp(r'^<b>(.*?)</b>$', dotAll: true);
final _kvLine = RegExp(r'^([^:\n]{1,40}):\s+(.+)$');
final _bulletLine = RegExp(r'^[•·]\s+');

bool looksLikeRichHtml(String html) => _richBlockTag.hasMatch(html);

/// Turn classic `parse_mode=HTML` copy into Rich HTML (`h2`/`p`/`ul`/`table`).
/// Already-rich markup is returned unchanged.
String richHtmlFromClassic(String html) {
  final trimmed = html.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (looksLikeRichHtml(trimmed)) {
    return trimmed;
  }
  final buf = StringBuffer();
  var usedH2 = false;
  for (final raw in trimmed.split(RegExp(r'\n{2,}'))) {
    final block = raw.trim();
    if (block.isEmpty) {
      continue;
    }
    buf.write(_classicBlockToRich(block, useH2: !usedH2, onHeading: () => usedH2 = true));
  }
  return buf.toString();
}

String _classicBlockToRich(
  String block, {
  required bool useH2,
  required void Function() onHeading,
}) {
  final lines = block.split('\n');
  final first = lines.first.trim();
  final bold = _boldOnly.firstMatch(first);
  if (bold != null) {
    onHeading();
    final tag = useH2 ? 'h2' : 'h3';
    final heading = '<$tag>${bold.group(1)}</$tag>';
    final rest = lines.skip(1).join('\n').trim();
    if (rest.isEmpty) {
      return heading;
    }
    return '$heading${_classicPlainBlock(rest)}';
  }
  return _classicPlainBlock(block);
}

String _classicPlainBlock(String block) {
  final lines = block.split('\n');
  if (lines.length >= 2 && lines.every(_isBulletLine)) {
    return richUl(<String>[for (final line in lines) line.replaceFirst(_bulletLine, '')]);
  }
  if (lines.length >= 2 && lines.every(_isKvLine)) {
    final rows = <(String, String)>[];
    for (final line in lines) {
      final match = _kvLine.firstMatch(line.trim())!;
      rows.add((match.group(1)!.trim(), match.group(2)!.trim()));
    }
    return richTable(rows);
  }
  return '<p>${block.replaceAll('\n', '<br>')}</p>';
}

bool _isBulletLine(String line) => _bulletLine.hasMatch(line.trim());

bool _isKvLine(String line) {
  final trimmed = line.trim();
  if (trimmed.toLowerCase().startsWith('http')) {
    return false;
  }
  final match = _kvLine.firstMatch(trimmed);
  if (match == null) {
    return false;
  }
  final label = match.group(1)!;
  if (label.contains('<') || label.toLowerCase().contains('http')) {
    return false;
  }
  return true;
}

/// Strip rich-only tags into classic `parse_mode=HTML` for old clients.
String classicHtmlFromRich(String richHtml) {
  var text = richHtml;
  text = text.replaceAllMapped(RegExp(r'<h[1-6]>(.*?)</h[1-6]>', dotAll: true), (match) {
    return '<b>${match.group(1)}</b>\n\n';
  });
  text = text.replaceAllMapped(RegExp(r'<p>(.*?)</p>', dotAll: true), (match) {
    return '${match.group(1)}\n\n';
  });
  text = text.replaceAllMapped(
    RegExp(r'<details[^>]*>\s*<summary>(.*?)</summary>(.*?)</details>', dotAll: true),
    (match) {
      return '<b>${match.group(1)}</b>\n${match.group(2)}\n\n';
    },
  );
  text = text.replaceAllMapped(
    RegExp(r'<tr>\s*<td>(.*?)</td>\s*<td>(.*?)</td>\s*</tr>', dotAll: true),
    (match) {
      return '${match.group(1)}: ${match.group(2)}\n';
    },
  );
  text = text.replaceAll(RegExp(r'</?table>'), '');
  text = text.replaceAll(RegExp(r'<t[hd][^>]*>'), '');
  text = text.replaceAll(RegExp(r'</t[hd]>'), '');
  text = text.replaceAll(RegExp(r'</?tr>'), '');
  text = text.replaceAllMapped(RegExp(r'<li>(.*?)</li>', dotAll: true), (match) {
    return '• ${match.group(1)}\n';
  });
  text = text.replaceAll(RegExp(r'</?[uo]l>'), '');
  text = text.replaceAll(RegExp(r'<hr\s*/?>'), '\n');
  text = text.replaceAllMapped(RegExp(r'<footer>(.*?)</footer>', dotAll: true), (match) {
    return '\n${match.group(1)}';
  });
  text = text.replaceAllMapped(RegExp(r'<blockquote>(.*?)</blockquote>', dotAll: true), (match) {
    return '${match.group(1)}\n';
  });
  text = text.replaceAll(RegExp(r'<tg-button-row[\s\S]*?</tg-button-row>'), '');
  text = text.replaceAll(RegExp(r'<tg-button[\s\S]*?</tg-button>'), '');
  text = text.replaceAllMapped(
    RegExp(r'<figcaption>(.*?)</figcaption>', dotAll: true, caseSensitive: false),
    (match) => '${match.group(1)}\n',
  );
  text = text.replaceAll(RegExp(r'<tg-document[\s\S]*?</tg-document>', caseSensitive: false), '');
  text = text.replaceAll(RegExp(r'<tg-document[^>]*/?>', caseSensitive: false), '');
  text = text.replaceAll(RegExp(r'</?figure>', caseSensitive: false), '');
  return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
