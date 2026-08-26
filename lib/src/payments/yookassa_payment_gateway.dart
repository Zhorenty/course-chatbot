import 'dart:async';
import 'dart:convert';

import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/payments/http_json.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:http/http.dart' as http;

final class YooKassaPaymentGateway implements PaymentGateway {
  YooKassaPaymentGateway({
    required String shopId,
    required String secretKey,
    http.Client? httpClient,
  })  : _shopId = shopId,
        _secretKey = secretKey,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final String _shopId;
  final String _secretKey;
  final http.Client _httpClient;
  final bool _ownsClient;
  bool _closed = false;

  @override
  String get providerId => 'yookassa';

  String get _basicAuth => 'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}';

  @override
  Future<CheckoutSession> createPayment({
    required CourseOrder order,
    required PaymentKind kind,
    required int amountKopecks,
    required int paymentDbId,
    String? description,
    String? returnUrl,
  }) async {
    if (_shopId.trim().isEmpty || _secretKey.trim().isEmpty) {
      throw const PaymentUnavailableException('YooKassa shop id or secret key is empty.');
    }
    final amountRub = (amountKopecks / 100).toStringAsFixed(2);
    final idempotenceKey = 'course-$paymentDbId-${kind.storageValue}';
    final body = <String, Object?>{
      'amount': <String, Object?>{
        'value': amountRub,
        'currency': 'RUB',
      },
      'capture': true,
      'description': description ?? 'Курс, заказ ${order.id}',
      'metadata': <String, Object?>{
        'order_id': '${order.id}',
        'payment_db_id': '$paymentDbId',
        'user_id': '${order.userId}',
        'kind': kind.storageValue,
      },
      'confirmation': <String, Object?>{
        'type': 'redirect',
        'return_url': returnUrl ?? 'https://t.me',
      },
    };
    final response = await _httpClient
        .post(
          Uri.parse('https://api.yookassa.ru/v3/payments'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Idempotence-Key': idempotenceKey,
            'Authorization': _basicAuth,
          },
          body: jsonEncode(body),
        )
        .timeout(PaymentGateway.requestTimeout);
    final map = decodeJsonObject(response, 'YooKassa');
    final id = map['id']?.toString();
    final confirmation = map['confirmation'];
    String? url;
    if (confirmation is Map) {
      url = confirmation['confirmation_url']?.toString();
    }
    if (id == null || id.isEmpty) {
      throw const PaymentUnavailableException('YooKassa payment id is missing.');
    }
    return CheckoutSession(
      provider: providerId,
      providerPaymentId: id,
      confirmationUrl: url,
    );
  }

  @override
  PaymentCallback? parseCallback(Object payload) {
    if (payload is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(payload);
    final event = map['event']?.toString();
    final objectRaw = map['object'];
    if (objectRaw is! Map) {
      return null;
    }
    final object = Map<String, dynamic>.from(objectRaw);
    return _callbackFromPaymentObject(object, event: event);
  }

  @override
  Future<PaymentCallback?> verifyCallback(PaymentCallback callback) async {
    if (callback.providerPaymentId.isEmpty) {
      return null;
    }
    final response = await _httpClient.get(
      Uri.parse('https://api.yookassa.ru/v3/payments/${callback.providerPaymentId}'),
      headers: <String, String>{
        'Authorization': _basicAuth,
      },
    ).timeout(PaymentGateway.requestTimeout);
    final map = decodeJsonObject(response, 'YooKassa');
    return _callbackFromPaymentObject(map);
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

  PaymentCallback? _callbackFromPaymentObject(
    Map<String, dynamic> object, {
    String? event,
  }) {
    final id = object['id']?.toString();
    if (id == null || id.isEmpty) {
      return null;
    }
    final status = object['status']?.toString();
    final paid = object['paid'] == true;
    final metadataRaw = object['metadata'];
    final metadata = metadataRaw is Map ? Map<String, dynamic>.from(metadataRaw) : null;
    final kind = PaymentKindX.parse(metadata?['kind']?.toString());
    final amountRaw = object['amount'];
    int? amountKopecks;
    if (amountRaw is Map) {
      final value = amountRaw['value']?.toString();
      if (value != null) {
        amountKopecks = parseRubStringToKopecks(value);
      }
    }
    final succeeded = event == 'payment.succeeded' || status == 'succeeded' || paid;
    final canceled = event == 'payment.canceled' || status == 'canceled';
    if (!succeeded && !canceled) {
      return null;
    }
    return PaymentCallback(
      provider: providerId,
      providerPaymentId: id,
      succeeded: succeeded,
      charged: succeeded,
      kind: kind,
      orderId: int.tryParse(metadata?['order_id']?.toString() ?? ''),
      paymentDbId: int.tryParse(metadata?['payment_db_id']?.toString() ?? ''),
      userId: int.tryParse(metadata?['user_id']?.toString() ?? ''),
      amountKopecks: amountKopecks,
    );
  }
}
