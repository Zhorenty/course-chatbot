import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';

abstract interface class PaymentGateway {
  String get providerId;

  Future<CheckoutSession> createPayment({
    required CourseOrder order,
    required PaymentKind kind,
    required int amountKopecks,
    required int paymentDbId,
    String? description,
    String? returnUrl,
  });

  PaymentCallback? parseCallback(Object payload);
}

final class PaymentUnavailableException implements Exception {
  const PaymentUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'PaymentUnavailableException: $message';
}
