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

  static List<BroadcastSegment> ordered(Iterable<BroadcastSegment> selected) {
    final set = selected.toSet();
    return <BroadcastSegment>[
      for (final segment in values)
        if (set.contains(segment)) segment,
    ];
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
