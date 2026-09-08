import 'package:course_chatbot/src/domain/funnel.dart';

/// Funnel state for one person on one launch. Profile and first-touch live on [UserProfile].
final class UserEnrollment {
  const UserEnrollment({
    required this.userId,
    required this.launchId,
    required this.funnelPhase,
    required this.startedAt,
    this.warmupOptOut = false,
    this.magnetIssuedAt,
    this.webinarRsvp = false,
    this.webinarRsvpAt,
    this.enrollIntentAt,
  });

  final int userId;
  final int launchId;
  final FunnelPhase funnelPhase;
  final bool warmupOptOut;
  final DateTime? magnetIssuedAt;
  final DateTime startedAt;
  final bool webinarRsvp;
  final DateTime? webinarRsvpAt;
  final DateTime? enrollIntentAt;
}
