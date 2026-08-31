import 'package:course_chatbot/src/config/app_config.dart';
import 'package:course_chatbot/src/payments/manual_payment_gateway.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:course_chatbot/src/payments/yookassa_payment_gateway.dart';
import 'package:http/http.dart' as http;

PaymentGateway createPaymentGateway(AppConfig config, {http.Client? httpClient}) {
  switch (config.paymentProvider) {
    case PaymentProvider.yookassa:
      final shopId = config.yookassaShopId?.trim() ?? '';
      final secret = config.yookassaSecretKey?.trim() ?? '';
      if (shopId.isEmpty || secret.isEmpty) {
        return const ManualPaymentGateway();
      }
      return YooKassaPaymentGateway(shopId: shopId, secretKey: secret, httpClient: httpClient);
    case PaymentProvider.manual:
      return const ManualPaymentGateway();
  }
}
