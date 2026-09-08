Map<String, Object?> replyKeyboard(
  List<List<Map<String, Object?>>> rows, {
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

Map<String, Object?> inlineKeyboard(List<List<Map<String, Object?>>> rows) {
  return <String, Object?>{'inline_keyboard': rows};
}

Map<String, Object?> callbackButton(String text, String data, {String? style}) {
  return <String, Object?>{'text': text, 'callback_data': data, if (style != null) 'style': style};
}

Map<String, Object?> urlButton(String text, String url, {String? style}) {
  return <String, Object?>{'text': text, 'url': url, if (style != null) 'style': style};
}

Map<String, Object?> copyTextButton(String text, String copyText, {String? style}) {
  return <String, Object?>{
    'text': text,
    'copy_text': <String, String>{'text': copyText},
    if (style != null) 'style': style,
  };
}
