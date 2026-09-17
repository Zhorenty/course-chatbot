enum ParticipantListSegment {
  webinarRsvp,
  paid,
  deposit,
  checkout,
  enrollIntent,
  magnet,
  started,
  cancelled;

  String get code => switch (this) {
    ParticipantListSegment.webinarRsvp => 'w',
    ParticipantListSegment.paid => 'p',
    ParticipantListSegment.deposit => 'd',
    ParticipantListSegment.checkout => 'c',
    ParticipantListSegment.enrollIntent => 'k',
    ParticipantListSegment.magnet => 'g',
    ParticipantListSegment.started => 'a',
    ParticipantListSegment.cancelled => 'x',
  };

  static ParticipantListSegment? fromCode(String? raw) {
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
