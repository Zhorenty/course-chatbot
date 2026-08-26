import 'package:course_chatbot/src/domain/funnel.dart';

final class UserProfile {
  const UserProfile({
    required this.userId,
    required this.funnelPhase,
    required this.firstStartedAt,
    required this.lastSeenAt,
    this.username,
    this.firstName,
    this.source,
    this.warmupOptOut = false,
    this.botBlocked = false,
    this.magnetIssuedAt,
  });

  final int userId;
  final String? username;
  final String? firstName;
  final String? source;
  final FunnelPhase funnelPhase;
  final bool warmupOptOut;
  final bool botBlocked;
  final DateTime? magnetIssuedAt;
  final DateTime firstStartedAt;
  final DateTime lastSeenAt;

  String get displayName {
    final name = firstName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) {
      return '@$handle';
    }
    return 'id $userId';
  }
}
