import 'package:course_chatbot/src/messages/rich_html.dart';
import 'package:course_chatbot/src/telegram/input_rich_message.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';
import 'package:l/l.dart';

/// Send [text] as `sendRichMessage` (dedicated [richHtml] or classic→rich).
/// On 400 / unknown rich errors, fall back to `sendMessage` + parse_mode=HTML.
/// Local photos from [media] go in the rich payload; classic fallback sends them first.
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
      l.w('sendRichMessage failed, falling back to sendMessage: $error', stackTrace);
    }
  }
  await _sendFallbackPhotos(sender, chatId, media, disableNotification: disableNotification);
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

Future<void> _sendFallbackPhotos(
  MessageSender sender,
  int chatId,
  List<InputRichMessageMedia> media, {
  required bool disableNotification,
}) async {
  final paths = <String>[
    for (final item in media)
      if (item.isPhoto && item.isLocal) item.document.localPath!,
  ];
  if (paths.isEmpty) {
    return;
  }
  try {
    await sender.sendPhotos(
      chatId,
      paths,
      fromFile: true,
      disableNotification: disableNotification,
    );
  } on Object catch (error, stackTrace) {
    l.w('Fallback sendPhotos failed: $error', stackTrace);
  }
}
