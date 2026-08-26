final class TelegramApiException implements Exception {
  const TelegramApiException(
    this.message, {
    this.statusCode,
    this.retryAfterSeconds,
  });

  final String message;
  final int? statusCode;
  final int? retryAfterSeconds;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' [statusCode=$statusCode]';
    return 'TelegramApiException$code: $message';
  }
}
