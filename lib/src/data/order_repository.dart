import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';

abstract interface class OrderRepository {
  CourseOrder createOrder({
    required int userId,
    required int launchId,
    required PaymentKind kind,
    required int priceFullKopecks,
    required int amountDueKopecks,
    required DateTime now,
    DateTime? dueAt,
  });

  CourseOrder? getOrder(int orderId);

  CourseOrder? latestOpenOrder(int userId);

  CourseOrder? latestOrder(int userId);

  List<CourseOrder> listOrdersForUser(int userId, {int limit = 10});

  void updateOrder(CourseOrder order);

  PaymentRecord insertPayment({
    required int orderId,
    required String provider,
    required PaymentKind kind,
    required int amountKopecks,
    required DateTime now,
    String? providerPaymentId,
    String? confirmationUrl,
    PaymentRecordStatus status = PaymentRecordStatus.pending,
  });

  PaymentRecord? getPayment(int paymentId);

  PaymentRecord? findPaymentByProviderId({
    required String provider,
    required String providerPaymentId,
  });

  PaymentRecord? latestPendingPayment(int orderId, {PaymentKind? kind});

  void updatePayment(PaymentRecord payment);

  List<CourseOrder> listAbandonedCheckout({
    required DateTime now,
    required Duration minAge,
    String? excludeDedupeSuffix,
    int limit = 100,
  });

  List<CourseOrder> listRemainderDue({
    required DateTime now,
    String? excludeDedupeDayKey,
    int limit = 100,
  });
}
