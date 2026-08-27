import 'package:course_chatbot/src/domain/telegram_username.dart';

/// Closed-beta gate: only listed Telegram usernames may use the bot.
///
/// TODO(launch): remove this whitelist before the public funnel goes live.
final class InteractionWhitelist {
  const InteractionWhitelist({required Set<String> usernames, this.allowAll = false})
    : _usernames = usernames;

  static const production = InteractionWhitelist(usernames: <String>{'zhorenty', 'dvor_support'});

  static const permissive = InteractionWhitelist(usernames: <String>{}, allowAll: true);

  final Set<String> _usernames;
  final bool allowAll;

  bool allows(String? username) {
    if (allowAll) {
      return true;
    }
    final normalized = normalizeTelegramUsername(username);
    return normalized != null && _usernames.contains(normalized);
  }
}
