Future<T> retry<T>(
  Future<T> Function() fn, {
  int attempts = 3,
  Duration delay = const Duration(milliseconds: 500),
  double backoffFactor = 1.5,
  bool Function(Object error)? shouldRetry,
  Duration Function(Object error, Duration currentDelay)? delayForError,
}) async {
  assert(attempts > 0, 'attempts must be greater than zero');
  if (attempts == 1) {
    return fn();
  }

  var currentDelay = delay;
  for (var attempt = 1; attempt <= attempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      final canRetry = shouldRetry?.call(error) ?? true;
      if (attempt == attempts || !canRetry) {
        rethrow;
      }
      final wait = delayForError?.call(error, currentDelay) ?? currentDelay;
      await Future<void>.delayed(wait);
      currentDelay = Duration(
        milliseconds: (currentDelay.inMilliseconds * backoffFactor).round(),
      );
    }
  }

  throw StateError('unreachable retry branch');
}
