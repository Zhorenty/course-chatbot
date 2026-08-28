enum BroadcastSegment {
  allStarted,
  leadNoGuide,
  guideNotPaid,
  courseLeadNoCheckout,
  checkoutOpen,
  depositPaid,
  paidAccess,
  paidNotJoined,
  cancelled;

  String get code => switch (this) {
    BroadcastSegment.allStarted => 'a',
    BroadcastSegment.leadNoGuide => 'l',
    BroadcastSegment.guideNotPaid => 'g',
    BroadcastSegment.courseLeadNoCheckout => 'k',
    BroadcastSegment.checkoutOpen => 'c',
    BroadcastSegment.depositPaid => 'd',
    BroadcastSegment.paidAccess => 'p',
    BroadcastSegment.paidNotJoined => 'n',
    BroadcastSegment.cancelled => 'x',
  };

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
}
