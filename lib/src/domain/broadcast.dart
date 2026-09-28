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
