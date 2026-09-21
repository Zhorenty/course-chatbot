import 'package:course_chatbot/src/domain/telegram_username.dart';

/// Usernames whose person card can reset the funnel so `/start` can be replayed.
abstract final class FunnelReplayAllowlist {
  static const Set<String> usernames = <String>{'dvor_support'};

  static bool allows(String? username) {
    final handle = normalizeTelegramUsername(username);
    return handle != null && usernames.contains(handle);
  }
}
