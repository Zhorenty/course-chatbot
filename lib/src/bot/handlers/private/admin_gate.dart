/// Centralized admin authorization for private-handler flows.
final class AdminGate {
  const AdminGate(this._adminUserIds);

  final Set<int> _adminUserIds;

  bool isConfiguredAdmin(int? userId) => userId != null && _adminUserIds.contains(userId);

  /// Chats that should see user help messages: `ADMIN_CHAT_ID` plus every admin.
  Set<int> notificationChatIds(int? adminChatId) {
    final ids = Set<int>.of(_adminUserIds);
    if (adminChatId != null) {
      ids.add(adminChatId);
    }
    return ids;
  }
}
