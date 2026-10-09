import 'package:course_chatbot/src/domain/participant_list.dart';

/// Same slices as «Список участников», scoped to the active launch.
enum BroadcastSegment {
  webinarRsvp,
  paid,
  deposit,
  checkout,
  enrollIntent,
  magnet,
  started,
  cancelled;

  ParticipantListSegment get participantSegment => switch (this) {
    BroadcastSegment.webinarRsvp => ParticipantListSegment.webinarRsvp,
    BroadcastSegment.paid => ParticipantListSegment.paid,
    BroadcastSegment.deposit => ParticipantListSegment.deposit,
    BroadcastSegment.checkout => ParticipantListSegment.checkout,
    BroadcastSegment.enrollIntent => ParticipantListSegment.enrollIntent,
    BroadcastSegment.magnet => ParticipantListSegment.magnet,
    BroadcastSegment.started => ParticipantListSegment.started,
    BroadcastSegment.cancelled => ParticipantListSegment.cancelled,
  };

  String get code => participantSegment.code;

  static BroadcastSegment? fromCode(String? raw) {
    final code = raw?.trim();
    if (code == null || code.isEmpty) {
      return null;
    }
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }

  static List<BroadcastSegment> ordered(Iterable<BroadcastSegment> selected) {
    final set = selected.toSet();
    return <BroadcastSegment>[
      for (final segment in values)
        if (set.contains(segment)) segment,
    ];
  }

  static bool coversAll(Iterable<BroadcastSegment> selected) {
    return selected.toSet().containsAll(values);
  }
}

enum BroadcastContentKind {
  text,
  photo,
  document,
  video,
  voice,
  audio,
  animation,
  sticker,
  videoNote,
  album,
  location,
  contact,
  other,
}

/// One outbound message, or a Telegram album (several ids, one bubble group).
final class BroadcastDraftPart {
  const BroadcastDraftPart({required this.messageIds, required this.kind, this.previewText});

  static const int maxCount = 10;

  final List<int> messageIds;
  final BroadcastContentKind kind;
  final String? previewText;

  bool get isAlbum => messageIds.length > 1;
}

/// What a broadcast button does when the recipient taps it.
enum BroadcastButtonAction {
  payFull,
  payDeposit,
  payRemainder,
  enroll,
  url;

  String get code => switch (this) {
    BroadcastButtonAction.payFull => 'f',
    BroadcastButtonAction.payDeposit => 'd',
    BroadcastButtonAction.payRemainder => 'r',
    BroadcastButtonAction.enroll => 'e',
    BroadcastButtonAction.url => 'u',
  };

  static BroadcastButtonAction? fromCode(String? raw) {
    final code = raw?.trim();
    if (code == null || code.isEmpty) {
      return null;
    }
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }
}

/// Label is what the recipient sees. [action] is where the tap goes.
final class BroadcastButton {
  const BroadcastButton({required this.action, required this.label, this.url});

  static const int maxCount = 6;
  static const int maxLabelLength = 64;
  static const int maxUrlLength = 500;

  final BroadcastButtonAction action;
  final String label;
  final String? url;

  static String? parseLabel(String raw) {
    final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty || text.length > maxLabelLength) {
      return null;
    }
    return text;
  }

  static String? parseUrl(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.length > maxUrlLength || text.contains(' ')) {
      return null;
    }
    final uri = Uri.tryParse(text);
    final scheme = uri?.scheme;
    if (uri == null || !uri.hasAuthority || (scheme != 'http' && scheme != 'https')) {
      return null;
    }
    return text;
  }
}

bool broadcastButtonsAttachable({
  required List<BroadcastDraftPart> parts,
  required List<BroadcastButton> buttons,
}) {
  if (buttons.isEmpty) {
    return true;
  }
  if (parts.isEmpty) {
    return false;
  }
  return !parts.last.isAlbum;
}
