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
  return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
