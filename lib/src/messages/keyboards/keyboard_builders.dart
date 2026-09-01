Map<String, Object?> replyKeyboard(
  List<List<Map<String, String>>> rows, {
  String? inputFieldPlaceholder,
}) {
  return <String, Object?>{
    'keyboard': rows,
    'resize_keyboard': true,
    'one_time_keyboard': false,
    'is_persistent': true,
    if (inputFieldPlaceholder != null) 'input_field_placeholder': inputFieldPlaceholder,
  };
}

Map<String, Object?> inlineKeyboard(List<List<Map<String, String>>> rows) {
  return <String, Object?>{'inline_keyboard': rows};
}
