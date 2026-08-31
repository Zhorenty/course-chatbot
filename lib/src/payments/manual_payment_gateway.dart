import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';

/// Fallback when YooKassa keys are empty or PAYMENT_PROVIDER is manual.
final class ManualPaymentGateway implements PaymentGateway {
  const ManualPaymentGateway();

  @override
  String get providerId => 'manual';

  /// Manual override is a deliberate fallback, not a failure — always "up".
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<CheckoutSession> createPayment({
    required CourseOrder order,
    required PaymentKind kind,
    required int amountKopecks,
    required int paymentDbId,
    String? description,
    String? returnUrl,
  }) async {
    return CheckoutSession(provider: providerId, providerPaymentId: 'manual-$paymentDbId');
  }

  @override
  PaymentCallback? parseCallback(Object payload) => null;

  @override
  Future<PaymentCallback?> verifyCallback(PaymentCallback callback) async => callback;

  @override
  void close() {}
}
