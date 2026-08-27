import 'package:course_chatbot/src/domain/storage_enum.dart';

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

  /// Selling/payment phases only move forward. `cancelled` is a side door:
  /// admin override may return to deposit/paid/access.
  int get rank => switch (this) {
    FunnelPhase.lead => 0,
    FunnelPhase.magnetIssued => 1,
    FunnelPhase.warming => 2,
    FunnelPhase.checkout => 3,
    FunnelPhase.depositPaid => 4,
    FunnelPhase.paid => 5,
    FunnelPhase.accessGranted => 6,
    FunnelPhase.cancelled => -1,
  };

  bool canTransitionTo(FunnelPhase next) {
    if (this == next) {
      return true;
    }
    if (next == FunnelPhase.cancelled) {
      return true;
    }
    if (this == FunnelPhase.cancelled) {
      return next == FunnelPhase.depositPaid ||
          next == FunnelPhase.paid ||
          next == FunnelPhase.accessGranted;
    }
    return next.rank >= rank;
  }

  static FunnelPhase parse(String? raw, {FunnelPhase fallback = FunnelPhase.lead}) {
    return parseStoredEnum(
      raw,
      values: FunnelPhase.values,
      storage: (value) => value.storageValue,
      fallback: fallback,
    );
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

  static const Set<String> coursePayloads = <String>{'tg_announce', 'direct_course'};

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
