final class ChannelAccess {
  const ChannelAccess({
    required this.id,
    required this.userId,
    required this.launchId,
    required this.orderId,
    this.inviteLink,
    this.inviteCreatedAt,
    this.joinedAt,
    this.revokedAt,
  });

  final int id;
  final int userId;
  final int launchId;
  final int orderId;
  final String? inviteLink;
  final DateTime? inviteCreatedAt;
  final DateTime? joinedAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null;

  bool get hasJoined => joinedAt != null && revokedAt == null;
}
