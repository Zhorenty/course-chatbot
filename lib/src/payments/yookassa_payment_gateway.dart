import 'dart:convert';

import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
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

  @override
  String get providerId => 'yookassa';

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
    final response = await _httpClient.post(
      Uri.parse('https://api.yookassa.ru/v3/payments'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Idempotence-Key': idempotenceKey,
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentUnavailableException(
        'YooKassa create payment failed HTTP ${response.statusCode}: ${response.body}',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw const PaymentUnavailableException('YooKassa returned a non-object body.');
    }
    final map = Map<String, dynamic>.from(decoded);
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
        amountKopecks = ((double.tryParse(value) ?? 0) * 100).round();
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

  void close() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }
}
