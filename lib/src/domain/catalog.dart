import 'package:course_chatbot/src/domain/moscow_time.dart';

abstract final class LaunchPrices {
  static const int promoKopecks = 1500000;
  static const int fullKopecks = 1900000;
}

final class Product {
  const Product({required this.id, required this.code, required this.title});

  final int id;
  final String code;
  final String title;
}

final class Launch {
  const Launch({
    required this.id,
    required this.productId,
    required this.code,
    required this.title,
    required this.priceFullKopecks,
    required this.depositKopecks,
    required this.depositDueDays,
    this.pricePromoKopecks = 0,
    this.depositDueAt,
    this.courseStartAt,
    this.webinarAt,
    this.webinarUrl,
    this.salesStartAt,
    this.salesEndAt,
    this.channelId,
    this.offerUrl,
    this.leadMagnetFileId,
    this.leadMagnetUrl,
    this.isActive = false,
  });

  final int id;
  final int productId;
  final String code;
  final String title;
  final int? channelId;
  final int priceFullKopecks;
  final int pricePromoKopecks;
  final int depositKopecks;
  final int depositDueDays;
  final DateTime? depositDueAt;
  final DateTime? courseStartAt;
  final DateTime? webinarAt;
  final String? webinarUrl;
  final DateTime? salesStartAt;
  final DateTime? salesEndAt;
  final String? offerUrl;
  final String? leadMagnetFileId;
  final String? leadMagnetUrl;
  final bool isActive;

  int get resolvedPriceFullKopecks =>
      priceFullKopecks > 0 ? priceFullKopecks : LaunchPrices.fullKopecks;

  int get resolvedPricePromoKopecks =>
      pricePromoKopecks > 0 ? pricePromoKopecks : LaunchPrices.promoKopecks;

  bool get hasDepositOption => depositKopecks > 0 && depositKopecks < resolvedPriceFullKopecks;

  bool hasDepositOptionFor(int payableKopecks) =>
      depositKopecks > 0 && depositKopecks < payableKopecks;

  DateTime? get impliedDepositDueAt =>
      MoscowTime.daysBeforeCourseStart(courseStartAt, days: depositDueDays);

  DateTime resolveDepositDueAt(DateTime now) {
    return impliedDepositDueAt ?? depositDueAt ?? now.add(Duration(days: depositDueDays));
  }
}
