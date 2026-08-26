import 'dart:async';
import 'dart:convert';

import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/payments/http_json.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:http/http.dart' as http;

/// LeadPay via the documented BotHelp-style link endpoint.
///
/// Spike still needs the customer cabinet: unique URL is known;
/// server-side paid signal is confirmed only with their webhook/settings.
final class LeadPayPaymentGateway implements PaymentGateway {
  LeadPayPaymentGateway({
    required String token,
    String baseUrl = 'https://app.leadpay.ru',
    http.Client? httpClient,
  })  : _token = token,
        _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final String _token;
  final String _baseUrl;
  final http.Client _httpClient;
  final bool _ownsClient;
  bool _closed = false;

  @override
  String get providerId => 'leadpay';

  @override
  Future<CheckoutSession> createPayment({
    required CourseOrder order,
    required PaymentKind kind,
    required int amountKopecks,
    required int paymentDbId,
    String? description,
    String? returnUrl,
  }) async {
    if (_token.trim().isEmpty) {
      throw const PaymentUnavailableException(
        'LEADPAY_TOKEN is empty. Cannot create a personal payment URL.',
      );
    }
    final clientId = '${order.userId}_${order.id}_$paymentDbId';
    final uri = Uri.parse('$_baseUrl/rest/v3/bothelp/link').replace(
      queryParameters: <String, String>{'client_id': clientId},
    );
    final response = await _httpClient
        .post(
          uri,
          headers: <String, String>{
            'Authorization-Token': _token,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, Object?>{
            'order_id': order.id,
            'payment_id': paymentDbId,
            'user_id': order.userId,
            'kind': kind.storageValue,
            'amount_kopecks': amountKopecks,
            'description': description,
          }),
        )
        .timeout(PaymentGateway.requestTimeout);
    final map = decodeJsonObject(response, 'LeadPay');
    final url = _extractUrl(map);
    if (url == null || url.isEmpty) {
      throw const PaymentUnavailableException(
        'LeadPay response has no result.url. Spike: check cabinet / Open API.',
      );
    }
    return CheckoutSession(
      provider: providerId,
      providerPaymentId: clientId,
      confirmationUrl: url,
    );
  }

  @override
  PaymentCallback? parseCallback(Object payload) {
    if (payload is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(payload);
    final clientId = (map['client_id'] ?? map['clientId'] ?? map['id'])?.toString();
    if (clientId == null || clientId.isEmpty) {
      return null;
    }
    final statusRaw =
        (map['pay_status'] ?? map['status'] ?? map['payment_status'])?.toString().toLowerCase();
    final succeeded = statusRaw == 'y' ||
        statusRaw == 'paid' ||
        statusRaw == 'succeeded' ||
        statusRaw == 'success' ||
        statusRaw == 'charged';
    final charged = statusRaw != 'approved' && statusRaw != 'application' && statusRaw != 'pending';
    return PaymentCallback(
      provider: providerId,
      providerPaymentId: clientId,
      succeeded: succeeded,
      charged: charged && succeeded,
      userId: int.tryParse(clientId.split('_').first),
      orderId: _intAt(clientId, 1),
      paymentDbId: _intAt(clientId, 2),
    );
  }

  @override
  Future<PaymentCallback?> verifyCallback(PaymentCallback callback) async {
    // LeadPay has no documented payment-status fetch for this BotHelp link.
    // Authenticity is the webhook secret on PaymentWebhookServer.
    return callback;
  }

  @override
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  String? _extractUrl(Map<String, dynamic> map) {
    final result = map['result'];
    if (result is Map) {
      final url = result['url']?.toString();
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    return map['url']?.toString();
  }

  int? _intAt(String clientId, int index) {
    final parts = clientId.split('_');
    if (index >= parts.length) {
      return null;
    }
    return int.tryParse(parts[index]);
  }
}
