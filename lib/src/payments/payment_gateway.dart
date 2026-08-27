import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';

abstract interface class PaymentGateway {
  static const Duration requestTimeout = Duration(seconds: 20);

  String get providerId;

  /// Cheap, side-effect-free pre-check run right before a payment attempt
  /// (e.g. before showing the pay button). It only catches configuration
  /// gaps (missing token/keys) — it must not call the provider's API, so it
  /// never adds an extra HTTP round-trip per funnel step. Transient outages
  /// are still caught reactively: [createPayment] throws
  /// [PaymentUnavailableException] when the kassa itself fails.
  Future<bool> isAvailable();

  Future<CheckoutSession> createPayment({
    required CourseOrder order,
    required PaymentKind kind,
    required int amountKopecks,
    required int paymentDbId,
    String? description,
    String? returnUrl,
  });

  PaymentCallback? parseCallback(Object payload);

  /// Confirms [callback] with the provider when the kassa supports it.
  /// Returns null if the event should be ignored.
  Future<PaymentCallback?> verifyCallback(PaymentCallback callback);

  void close();
}

final class PaymentUnavailableException implements Exception {
  const PaymentUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'PaymentUnavailableException: $message';
}
