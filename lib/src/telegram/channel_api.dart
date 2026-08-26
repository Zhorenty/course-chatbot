abstract interface class ChannelApi {
  Future<String> createChatInviteLink({
    required int chatId,
    int memberLimit = 1,
    String? name,
    int? expireDate,
  });

  Future<void> revokeChatInviteLink({
    required int chatId,
    required String inviteLink,
  });

  Future<void> banChatMember(
    int chatId, {
    required int userId,
    bool revokeMessages = true,
  });

  Future<void> unbanChatMember(
    int chatId, {
    required int userId,
    bool onlyIfBanned = true,
  });
}
