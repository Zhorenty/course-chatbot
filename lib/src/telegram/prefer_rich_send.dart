import 'package:course_chatbot/src/messages/rich_html.dart';
import 'package:course_chatbot/src/telegram/input_rich_message.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';
import 'package:l/l.dart';

const int _maxPhotoCaptionLength = 1024;

/// Send [text] as `sendRichMessage` (dedicated [richHtml] or classic→rich).
/// On 400 / unknown rich errors, fall back to classic HTML.
///
/// Photos stay in the same message: Rich HTML uses a media block
/// (`<img src="tg://photo?id=…"/>` + `InputRichMessage.media`). If that fails,
/// classic `sendPhoto` / album carries the copy as a caption.
Future<int> sendPreferRich(
  MessageSender sender,
  int chatId,
  String text, {
  String? richHtml,
  List<InputRichMessageMedia> media = const <InputRichMessageMedia>[],
  bool disableNotification = true,
  bool disableWebPagePreview = true,
  Map<String, Object?>? replyMarkup,
}) async {
  final html = _withPhotos(_resolveRichHtml(text, richHtml), media);
  if (html.isNotEmpty) {
    try {
      final sent = await sender.sendRichMessage(
        chatId,
        InputRichMessage(html: html, media: media),
        disableNotification: disableNotification,
        replyMarkup: replyMarkup,
      );
      return sent.messageId;
    } on Object catch (error, stackTrace) {
      l.w('sendRichMessage failed, falling back to classic: $error', stackTrace);
    }
  }
  final photoIds = await _sendClassicPhotosWithCaption(
    sender,
    chatId,
    text: text,
    media: media,
    disableNotification: disableNotification,
    replyMarkup: replyMarkup,
  );
  if (photoIds != null && photoIds.isNotEmpty) {
    return photoIds.last;
  }
  return sender.sendMessage(
    chatId,
    text,
    parseMode: 'HTML',
    replyMarkup: replyMarkup,
    disableNotification: disableNotification,
    disableWebPagePreview: disableWebPagePreview,
  );
}

/// Edit as rich first; fall back to classic `editMessageText`.
Future<void> editPreferRich(
  MessageSender sender,
  int chatId, {
  required int messageId,
  required String text,
  String? richHtml,
  Map<String, Object?>? replyMarkup,
}) async {
  final html = _resolveRichHtml(text, richHtml);
  if (html.isNotEmpty) {
    try {
      await sender.editRichMessage(
        chatId,
        messageId: messageId,
        richMessage: InputRichMessage(html: html),
        replyMarkup: replyMarkup,
      );
      return;
    } on TelegramApiException catch (error, stackTrace) {
      if (error.message.toLowerCase().contains('not modified')) {
        return;
      }
      l.w('editRichMessage failed, falling back to editMessageText: $error', stackTrace);
    } on Object catch (error, stackTrace) {
      l.w('editRichMessage failed, falling back to editMessageText: $error', stackTrace);
    }
  }
  await sender.editMessageText(
    chatId,
    messageId: messageId,
    text: text,
    parseMode: 'HTML',
    replyMarkup: replyMarkup,
  );
}

String _resolveRichHtml(String text, String? richHtml) {
  if (richHtml != null && richHtml.isNotEmpty) {
    return richHtml;
  }
  return richHtmlFromClassic(text);
}

String _withPhotos(String html, List<InputRichMessageMedia> media) {
  final photos = <String>[
    for (final item in media)
      if (item.isPhoto) item.id,
  ];
  if (photos.isEmpty) {
    return html;
  }
  return '${richPhotoBlock(photos)}$html';
}

Future<List<int>?> _sendClassicPhotosWithCaption(
  MessageSender sender,
  int chatId, {
  required String text,
  required List<InputRichMessageMedia> media,
  required bool disableNotification,
  required Map<String, Object?>? replyMarkup,
}) async {
  final local = <String>[
    for (final item in media)
      if (item.isPhoto && item.isLocal) item.document.localPath!,
  ];
  final remote = <String>[
    for (final item in media)
      if (item.isPhoto && !item.isLocal && (item.document.fileId?.isNotEmpty ?? false))
        item.document.fileId!,
  ];
  final fromFile = local.isNotEmpty;
  final refs = fromFile ? local : remote;
  if (refs.isEmpty) {
    return null;
  }
  try {
    return await sender.sendPhotos(
      chatId,
      refs,
      fromFile: fromFile,
      disableNotification: disableNotification,
      caption: _captionForPhotos(text),
      parseMode: 'HTML',
      replyMarkup: refs.length == 1 ? replyMarkup : null,
    );
  } on Object catch (error, stackTrace) {
    l.w('Classic sendPhotos with caption failed: $error', stackTrace);
    return null;
  }
}

String? _captionForPhotos(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.length <= _maxPhotoCaptionLength) {
    return trimmed;
  }
  final cut = trimmed.substring(0, _maxPhotoCaptionLength);
  final breakAt = cut.lastIndexOf('\n');
  if (breakAt >= _maxPhotoCaptionLength ~/ 2) {
    return cut.substring(0, breakAt).trimRight();
  }
  return cut;
}
