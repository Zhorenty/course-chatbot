import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:l/l.dart';

/// Re-reads pending kassa payments so a missed webhook still grants access.
final class PendingPaymentSyncJob {
  PendingPaymentSyncJob({
    required CheckoutService checkout,
    required PaymentResultNotifier notifier,
    this.limit = 50,
  }) : _checkout = checkout,
       _notifier = notifier;

  final CheckoutService _checkout;
  final PaymentResultNotifier _notifier;
  final int limit;

  Future<void> run() async {
    final results = await _checkout.syncPendingPayments(limit: limit);
    for (final result in results) {
      try {
        await _notifier.notifyPaymentResult(result);
      } on Object catch (error, stackTrace) {
        l.w('Failed to notify payment result for order ${result.order.id}: $error', stackTrace);
      }
    }
  }
}
