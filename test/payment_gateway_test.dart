import 'package:course_chatbot/src/payments/leadpay_payment_gateway.dart';
import 'package:course_chatbot/src/payments/yookassa_payment_gateway.dart';
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
}
