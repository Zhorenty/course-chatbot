import 'package:course_chatbot/src/domain/broadcast.dart';

/// Snapshot of a Telegram message the bot can resend later via file_id / HTML.
///
/// Telegram `file_id` stays valid after the original message is deleted, as long
/// as this bot has seen the file. Text is stored as HTML so formatting survives.
final class StoredTelegramMessage {
  const StoredTelegramMessage({
    required this.kind,
    this.html,
    this.media = const <StoredTelegramMedia>[],
    this.latitude,
    this.longitude,
    this.contactPhone,
    this.contactFirstName,
    this.contactLastName,
    this.contactUserId,
  });

  final BroadcastContentKind kind;
  final String? html;
  final List<StoredTelegramMedia> media;
  final double? latitude;
  final double? longitude;
  final String? contactPhone;
  final String? contactFirstName;
  final String? contactLastName;
  final int? contactUserId;

  bool get canReplay {
    switch (kind) {
      case BroadcastContentKind.text:
        return html != null && html!.isNotEmpty;
      case BroadcastContentKind.location:
        return latitude != null && longitude != null;
      case BroadcastContentKind.contact:
        final phone = contactPhone?.trim();
        final name = contactFirstName?.trim();
        return phone != null && phone.isNotEmpty && name != null && name.isNotEmpty;
      case BroadcastContentKind.other:
        return false;
      case BroadcastContentKind.album:
      case BroadcastContentKind.photo:
      case BroadcastContentKind.video:
      case BroadcastContentKind.document:
      case BroadcastContentKind.audio:
      case BroadcastContentKind.voice:
      case BroadcastContentKind.animation:
      case BroadcastContentKind.sticker:
      case BroadcastContentKind.videoNote:
        return media.any((item) => item.fileId.isNotEmpty);
    }
  }

  String? get captionHtml {
    final own = html?.trim();
    if (own != null && own.isNotEmpty) {
      return own;
    }
    for (final item in media) {
      final caption = item.html?.trim();
      if (caption != null && caption.isNotEmpty) {
        return caption;
      }
    }
    return null;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.name,
      if (html != null) 'html': html,
      if (media.isNotEmpty)
        'media': <Map<String, Object?>>[for (final item in media) item.toJson()],
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (contactFirstName != null) 'contact_first_name': contactFirstName,
      if (contactLastName != null) 'contact_last_name': contactLastName,
      if (contactUserId != null) 'contact_user_id': contactUserId,
    };
  }

  static StoredTelegramMessage? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final kind = _kind(raw['kind']?.toString());
    if (kind == null) {
      return null;
    }
    final mediaRaw = raw['media'];
    final media = <StoredTelegramMedia>[];
    if (mediaRaw is List) {
      for (final item in mediaRaw) {
        final parsed = StoredTelegramMedia.fromJson(item);
        if (parsed != null) {
          media.add(parsed);
        }
      }
    }
    return StoredTelegramMessage(
      kind: kind,
      html: raw['html']?.toString(),
      media: media,
      latitude: _asDouble(raw['latitude']),
      longitude: _asDouble(raw['longitude']),
      contactPhone: raw['contact_phone']?.toString(),
      contactFirstName: raw['contact_first_name']?.toString(),
      contactLastName: raw['contact_last_name']?.toString(),
      contactUserId: _asInt(raw['contact_user_id']),
    );
  }

  static BroadcastContentKind? _kind(String? raw) {
    for (final value in BroadcastContentKind.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}

final class StoredTelegramMedia {
  const StoredTelegramMedia({required this.type, required this.fileId, this.filename, this.html});

  final StoredTelegramMediaType type;
  final String fileId;
  final String? filename;
  final String? html;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type.name,
      'file_id': fileId,
      if (filename != null) 'filename': filename,
      if (html != null) 'html': html,
    };
  }

  static StoredTelegramMedia? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final type = StoredTelegramMediaType.fromName(raw['type']?.toString());
    final fileId = raw['file_id']?.toString().trim();
    if (type == null || fileId == null || fileId.isEmpty) {
      return null;
    }
    return StoredTelegramMedia(
      type: type,
      fileId: fileId,
      filename: raw['filename']?.toString(),
      html: raw['html']?.toString(),
    );
  }
}

enum StoredTelegramMediaType {
  photo,
  video,
  document,
  audio,
  voice,
  animation,
  sticker,
  videoNote;

  static StoredTelegramMediaType? fromName(String? raw) {
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  String get telegramMethod => switch (this) {
    photo => 'sendPhoto',
    video => 'sendVideo',
    document => 'sendDocument',
    audio => 'sendAudio',
    voice => 'sendVoice',
    animation => 'sendAnimation',
    sticker => 'sendSticker',
    videoNote => 'sendVideoNote',
  };

  String get telegramField => switch (this) {
    photo => 'photo',
    video => 'video',
    document => 'document',
    audio => 'audio',
    voice => 'voice',
    animation => 'animation',
    sticker => 'sticker',
    videoNote => 'video_note',
  };

  String get inputMediaType => switch (this) {
    photo => 'photo',
    video => 'video',
    document => 'document',
    audio => 'audio',
    animation => 'animation',
    voice => 'document',
    sticker => 'document',
    videoNote => 'video',
  };

  bool get supportsCaption => switch (this) {
    photo || video || document || audio || animation || voice => true,
    sticker || videoNote => false,
  };
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
