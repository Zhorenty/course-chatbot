import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/payments/leadpay_payment_gateway.dart';
import 'package:course_chatbot/src/payments/yookassa_payment_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('LeadPay callback maps pay_status Y to succeeded charge', () {
    final gateway = LeadPayPaymentGateway(token: 't');
    final callback = gateway.parseCallback(<String, Object?>{
      'client_id': '42_1_9',
      'pay_status': 'Y',
    });
    expect(callback, isNotNull);
    expect(callback!.succeeded, isTrue);
    expect(callback.charged, isTrue);
    expect(callback.userId, 42);
    expect(callback.orderId, 1);
  });

  test('YooKassa payment.succeeded is charged, canceled is not', () {
    final gateway = YooKassaPaymentGateway(shopId: 's', secretKey: 'k');
    final succeeded = gateway.parseCallback(<String, Object?>{
      'event': 'payment.succeeded',
      'object': <String, Object?>{
        'id': 'pay-1',
        'status': 'succeeded',
        'paid': true,
        'metadata': <String, Object?>{
          'order_id': '3',
          'payment_db_id': '8',
          'user_id': '42',
          'kind': 'full',
        },
        'amount': <String, Object?>{'value': '10000.00', 'currency': 'RUB'},
      },
    });
    expect(succeeded!.succeeded, isTrue);
    expect(succeeded.charged, isTrue);
    expect(succeeded.orderId, 3);

    final canceled = gateway.parseCallback(<String, Object?>{
      'event': 'payment.canceled',
      'object': <String, Object?>{
        'id': 'pay-2',
        'status': 'canceled',
      },
    });
    expect(canceled!.succeeded, isFalse);
  });

  test('LeadPay application-approved is not a charge', () {
    final gateway = LeadPayPaymentGateway(token: 't');
    final callback = gateway.parseCallback(<String, Object?>{
      'client_id': '42_1_9',
      'pay_status': 'approved',
    });
    expect(callback, isNotNull);
    expect(callback!.succeeded, isFalse);
    expect(callback.charged, isFalse);
  });

  test('YooKassa verifyCallback re-reads the payment from the API', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, contains('/v3/payments/pay-1'));
      return http.Response(
        '{"id":"pay-1","status":"succeeded","paid":true,'
        '"metadata":{"order_id":"3","payment_db_id":"8","user_id":"42","kind":"full"},'
        '"amount":{"value":"100.00"}}',
        200,
      );
    });
    final gateway = YooKassaPaymentGateway(shopId: 's', secretKey: 'k', httpClient: client);
    final verified = await gateway.verifyCallback(
      const PaymentCallback(
        provider: 'yookassa',
        providerPaymentId: 'pay-1',
        succeeded: true,
      ),
    );
    expect(verified, isNotNull);
    expect(verified!.succeeded, isTrue);
    expect(verified.orderId, 3);
    gateway.close();
  });

  test('YooKassa amount is parsed in kopecks without float rounding', () {
    final gateway = YooKassaPaymentGateway(shopId: 's', secretKey: 'k');
    final callback = gateway.parseCallback(<String, Object?>{
      'event': 'payment.succeeded',
      'object': <String, Object?>{
        'id': 'pay-3',
        'status': 'succeeded',
        'paid': true,
        'amount': <String, Object?>{'value': '19.99', 'currency': 'RUB'},
      },
    });
    expect(callback!.amountKopecks, 1999);
  });
}
