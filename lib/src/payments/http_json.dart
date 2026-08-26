import 'dart:convert';

import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic> decodeJsonObject(http.Response response, String provider) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw PaymentUnavailableException(
      '$provider failed HTTP ${response.statusCode}: ${response.body}',
    );
  }
  final decoded = jsonDecode(utf8.decode(response.bodyBytes));
  if (decoded is! Map) {
    throw PaymentUnavailableException('$provider returned a non-object body.');
  }
  return Map<String, dynamic>.from(decoded);
}
