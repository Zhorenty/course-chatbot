import 'package:course_chatbot/src/telegram/telegram_api_exception.dart';

bool isUserBlockedError(Object error) {
  if (error is! TelegramApiException) {
    return false;
  }
  if (error.statusCode == 403) {
    return true;
  }
  final message = error.message.toLowerCase();
  return message.contains('bot was blocked') ||
      message.contains('user is deactivated') ||
      message.contains('forbidden: bot was blocked');
}
