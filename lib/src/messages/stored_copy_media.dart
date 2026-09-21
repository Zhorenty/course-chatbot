import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/stored_telegram_message.dart';
import 'package:course_chatbot/src/telegram/input_rich_message.dart';

/// Convert a stored copy payload into rich-send media. Missing files are skipped.
List<InputRichMessageMedia> storedCopyToRichMedia(StoredTelegramMessage? payload) {
  if (payload == null) {
    return const <InputRichMessageMedia>[];
  }
  final media = <InputRichMessageMedia>[];
  for (var i = 0; i < payload.media.length; i++) {
    final item = payload.media[i];
    final local = item.localPath?.trim();
    final fileId = item.fileId.trim();
    final InputRichDocument document;
    if (local != null && local.isNotEmpty) {
      document = InputRichDocument.file(localPath: local, filename: item.filename);
    } else if (fileId.isNotEmpty) {
      document = InputRichDocument.fileId(fileId);
    } else {
      continue;
    }
    media.add(
      item.type == StoredTelegramMediaType.photo
          ? InputRichMessageMedia.photo(id: 'p$i', document: document)
          : InputRichMessageMedia.document(id: 'd$i', document: document),
    );
  }
  return media;
}

StoredTelegramMessage storedCopyFromHtml(
  String html, {
  List<String> photoPaths = const <String>[],
}) {
  if (photoPaths.isEmpty) {
    return StoredTelegramMessage(kind: BroadcastContentKind.text, html: html);
  }
  final media = <StoredTelegramMedia>[
    for (final path in photoPaths)
      StoredTelegramMedia(type: StoredTelegramMediaType.photo, localPath: path),
  ];
  return StoredTelegramMessage(
    kind: media.length > 1 ? BroadcastContentKind.album : BroadcastContentKind.photo,
    html: html,
    media: media,
  );
}
