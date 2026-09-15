import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/stored_telegram_message.dart';
import 'package:course_chatbot/src/messages/telegram_html.dart';

StoredTelegramMessage? snapshotTelegramMessage(Map<String, dynamic>? message) {
  if (message == null) {
    return null;
  }
  final html = _htmlFrom(message);
  final album = _isAlbum(message);
  final media = mediaFromTelegramMessage(message);
  if (album) {
    if (media == null) {
      return null;
    }
    return StoredTelegramMessage(
      kind: BroadcastContentKind.album,
      html: html,
      media: <StoredTelegramMedia>[media],
    );
  }
  if (media != null) {
    return StoredTelegramMessage(
      kind: _kindFor(media.type),
      html: html,
      media: <StoredTelegramMedia>[media],
    );
  }
  final location = message['location'];
  if (location is Map) {
    final latitude = _asDouble(location['latitude']);
    final longitude = _asDouble(location['longitude']);
    if (latitude != null && longitude != null) {
      return StoredTelegramMessage(
        kind: BroadcastContentKind.location,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }
  final contact = message['contact'];
  if (contact is Map) {
    final phone = contact['phone_number']?.toString().trim();
    final firstName = contact['first_name']?.toString().trim();
    if (phone != null && phone.isNotEmpty && firstName != null && firstName.isNotEmpty) {
      return StoredTelegramMessage(
        kind: BroadcastContentKind.contact,
        contactPhone: phone,
        contactFirstName: firstName,
        contactLastName: contact['last_name']?.toString(),
        contactUserId: _asInt(contact['user_id']),
      );
    }
  }
  if (html != null && html.isNotEmpty) {
    return StoredTelegramMessage(kind: BroadcastContentKind.text, html: html);
  }
  return null;
}

StoredTelegramMedia? mediaFromTelegramMessage(Map<String, dynamic> message) {
  final photoId = largestPhotoFileId(message);
  if (photoId != null) {
    return StoredTelegramMedia(type: StoredTelegramMediaType.photo, fileId: photoId);
  }
  final video = _fileMap(message['video']);
  if (video != null) {
    return StoredTelegramMedia(type: StoredTelegramMediaType.video, fileId: video.fileId);
  }
  final document = _fileMap(message['document']);
  if (document != null) {
    return StoredTelegramMedia(
      type: StoredTelegramMediaType.document,
      fileId: document.fileId,
      filename: document.filename,
    );
  }
  final audio = _fileMap(message['audio']);
  if (audio != null) {
    return StoredTelegramMedia(type: StoredTelegramMediaType.audio, fileId: audio.fileId);
  }
  final voice = _fileMap(message['voice']);
  if (voice != null) {
    return StoredTelegramMedia(type: StoredTelegramMediaType.voice, fileId: voice.fileId);
  }
  final animation = _fileMap(message['animation']);
  if (animation != null) {
    return StoredTelegramMedia(type: StoredTelegramMediaType.animation, fileId: animation.fileId);
  }
  final sticker = _fileMap(message['sticker']);
  if (sticker != null) {
    return StoredTelegramMedia(type: StoredTelegramMediaType.sticker, fileId: sticker.fileId);
  }
  final videoNote = _fileMap(message['video_note']);
  if (videoNote != null) {
    return StoredTelegramMedia(type: StoredTelegramMediaType.videoNote, fileId: videoNote.fileId);
  }
  return null;
}

String? largestPhotoFileId(Map<String, dynamic> message) {
  final photo = message['photo'];
  if (photo is! List || photo.isEmpty) {
    return null;
  }
  Map<dynamic, dynamic>? best;
  var bestArea = -1;
  for (final item in photo) {
    if (item is! Map) {
      continue;
    }
    final fileId = item['file_id']?.toString().trim();
    if (fileId == null || fileId.isEmpty) {
      continue;
    }
    final width = _asInt(item['width']) ?? 0;
    final height = _asInt(item['height']) ?? 0;
    final area = width * height;
    if (best == null || area >= bestArea) {
      best = item;
      bestArea = area;
    }
  }
  final fileId = best?['file_id']?.toString().trim();
  if (fileId == null || fileId.isEmpty) {
    return null;
  }
  return fileId;
}

StoredTelegramMessage mergeAlbumSnapshots(List<StoredTelegramMessage> parts) {
  final media = <StoredTelegramMedia>[for (final part in parts) ...part.media];
  String? html;
  for (final part in parts) {
    final caption = part.captionHtml;
    if (caption != null) {
      html = caption;
      break;
    }
  }
  return StoredTelegramMessage(kind: BroadcastContentKind.album, html: html, media: media);
}

bool _isAlbum(Map<String, dynamic> message) {
  final raw = message['media_group_id']?.toString().trim();
  return raw != null && raw.isNotEmpty;
}

BroadcastContentKind _kindFor(StoredTelegramMediaType type) {
  return switch (type) {
    StoredTelegramMediaType.photo => BroadcastContentKind.photo,
    StoredTelegramMediaType.video => BroadcastContentKind.video,
    StoredTelegramMediaType.document => BroadcastContentKind.document,
    StoredTelegramMediaType.audio => BroadcastContentKind.audio,
    StoredTelegramMediaType.voice => BroadcastContentKind.voice,
    StoredTelegramMediaType.animation => BroadcastContentKind.animation,
    StoredTelegramMediaType.sticker => BroadcastContentKind.sticker,
    StoredTelegramMediaType.videoNote => BroadcastContentKind.videoNote,
  };
}

String? _htmlFrom(Map<String, dynamic> message) {
  final hasText = message['text'] != null;
  final raw = (hasText ? message['text'] : message['caption'])?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final entities = hasText ? message['entities'] : message['caption_entities'];
  return telegramEntitiesToHtml(raw, entities);
}

({String fileId, String? filename})? _fileMap(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final fileId = raw['file_id']?.toString().trim();
  if (fileId == null || fileId.isEmpty) {
    return null;
  }
  final filename = raw['file_name']?.toString().trim();
  return (fileId: fileId, filename: filename == null || filename.isEmpty ? null : filename);
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

double? _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}
