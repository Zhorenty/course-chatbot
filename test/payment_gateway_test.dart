import 'package:course_chatbot/src/config/app_config.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/payments/payment_gateway_factory.dart';
import 'package:course_chatbot/src/payments/yookassa_payment_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
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
      'object': <String, Object?>{'id': 'pay-2', 'status': 'canceled'},
    });
    expect(canceled!.succeeded, isFalse);
    expect(canceled.charged, isFalse);
  });

  test('YooKassa ignores events other than succeeded and canceled', () {
    final gateway = YooKassaPaymentGateway(shopId: 's', secretKey: 'k');
    expect(
      gateway.parseCallback(<String, Object?>{
        'event': 'payment.waiting_for_capture',
        'object': <String, Object?>{'id': 'pay-w', 'status': 'waiting_for_capture'},
      }),
      isNull,
    );
    expect(
      gateway.parseCallback(<String, Object?>{
        'event': 'payment.pending',
        'object': <String, Object?>{'id': 'pay-p', 'status': 'pending'},
      }),
      isNull,
    );
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
      const PaymentCallback(provider: 'yookassa', providerPaymentId: 'pay-1', succeeded: true),
    );
    expect(verified, isNotNull);
    expect(verified!.succeeded, isTrue);
    expect(verified.orderId, 3);
    gateway.close();
  });

  test('YooKassa createPayment keeps a succeeded idempotent replay', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      return http.Response(
        '{"id":"pay-replay","status":"succeeded","paid":true,'
        '"confirmation":{"confirmation_url":"https://yookassa.example/pay"},'
        '"metadata":{"order_id":"3","payment_db_id":"8","user_id":"42","kind":"full"},'
        '"amount":{"value":"100.00","currency":"RUB"}}',
        200,
      );
    });
    final gateway = YooKassaPaymentGateway(shopId: 's', secretKey: 'k', httpClient: client);
    final session = await gateway.createPayment(
      order: CourseOrder(
        id: 3,
        userId: 42,
        launchId: 1,
        status: OrderStatus.checkoutStarted,
        kind: PaymentKind.full,
        priceFullKopecks: 10000,
        amountPaidKopecks: 0,
        amountDueKopecks: 10000,
        checkoutStartedAt: DateTime.utc(2026, 1, 1),
      ),
      kind: PaymentKind.full,
      amountKopecks: 10000,
      paymentDbId: 8,
    );
    expect(session.providerPaymentId, 'pay-replay');
    expect(session.settled?.succeeded, isTrue);
    expect(session.settled?.charged, isTrue);
    expect(session.settled?.orderId, 3);
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

  test('YooKassa isAvailable is config-only and does not call the API', () async {
    var httpCalls = 0;
    final client = MockClient((request) async {
      httpCalls += 1;
      return http.Response('{}', 200);
    });
    final withKeys = YooKassaPaymentGateway(shopId: 's', secretKey: 'k', httpClient: client);
    final empty = YooKassaPaymentGateway(shopId: '', secretKey: '', httpClient: client);
    expect(await withKeys.isAvailable(), isTrue);
    expect(await empty.isAvailable(), isFalse);
    expect(httpCalls, 0);
    withKeys.close();
    empty.close();
  });

  test('empty YooKassa keys fall back to manual', () {
    const config = AppConfig(botToken: 't', adminUserIds: {1}, adminChatId: null);
    expect(createPaymentGateway(config).providerId, 'manual');
  });

  test('YooKassa keys produce the live gateway', () {
    const config = AppConfig(
      botToken: 't',
      adminUserIds: {1},
      adminChatId: null,
      yookassaShopId: 'shop',
      yookassaSecretKey: 'secret',
    );
    final gateway = createPaymentGateway(config);
    expect(gateway.providerId, 'yookassa');
    gateway.close();
  });
}
