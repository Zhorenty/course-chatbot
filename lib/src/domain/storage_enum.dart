T parseStoredEnum<T>(
  String? raw, {
  required Iterable<T> values,
  required String Function(T value) storage,
  required T fallback,
}) {
  if (raw == null || raw.isEmpty) {
    return fallback;
  }
  for (final value in values) {
    if (storage(value) == raw) {
      return value;
    }
  }
  return fallback;
}
