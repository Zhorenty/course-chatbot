enum FunnelPhase {
  lead,
  magnetIssued,
  warming,
  checkout,
  depositPaid,
  paid,
  accessGranted,
  cancelled,
}

extension FunnelPhaseX on FunnelPhase {
  String get storageValue => switch (this) {
        FunnelPhase.lead => 'lead',
        FunnelPhase.magnetIssued => 'magnet_issued',
        FunnelPhase.warming => 'warming',
        FunnelPhase.checkout => 'checkout',
        FunnelPhase.depositPaid => 'deposit_paid',
        FunnelPhase.paid => 'paid',
        FunnelPhase.accessGranted => 'access_granted',
        FunnelPhase.cancelled => 'cancelled',
      };

  bool get hasAccess => this == FunnelPhase.accessGranted;

  bool get isPaidOrAccess => this == FunnelPhase.paid || this == FunnelPhase.accessGranted;

  bool get excludeSellingDrip =>
      this == FunnelPhase.depositPaid ||
      this == FunnelPhase.paid ||
      this == FunnelPhase.accessGranted ||
      this == FunnelPhase.cancelled;

  static FunnelPhase parse(String? raw, {FunnelPhase fallback = FunnelPhase.lead}) {
    if (raw == null || raw.isEmpty) {
      return fallback;
    }
    for (final value in FunnelPhase.values) {
      if (value.storageValue == raw) {
        return value;
      }
    }
    return fallback;
  }
}

final class AcquisitionSource {
  static const int maxLength = 64;
  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9_]+$');

  static const Set<String> guidePayloads = <String>{
    'ig_reels_guide',
    'threads_guide',
    'ig_stories_guide',
    'email_guide',
  };

  static const Set<String> coursePayloads = <String>{
    'tg_announce',
    'direct_course',
  };

  static String? normalize(String? raw) {
    final trimmed = raw?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    if (trimmed.length > maxLength || !_allowed.hasMatch(trimmed)) {
      return null;
    }
    return trimmed;
  }

  static bool opensCourseCard(String? payload) {
    final normalized = normalize(payload);
    if (normalized == null) {
      return false;
    }
    return coursePayloads.contains(normalized);
  }
}
