String? normalizeTelegramUsername(String? username) {
  final trimmed = username?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final raw = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
  if (raw.isEmpty) {
    return null;
  }
  return raw.toLowerCase();
}
