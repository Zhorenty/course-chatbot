final class Product {
  const Product({
    required this.id,
    required this.code,
    required this.title,
  });

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
    this.depositDueAt,
    this.courseStartAt,
    this.channelId,
    this.offerUrl,
    this.leadMagnetFileId,
    this.leadMagnetUrl,
  });

  final int id;
  final int productId;
  final String code;
  final String title;
  final int? channelId;
  final int priceFullKopecks;
  final int depositKopecks;
  final int depositDueDays;
  final DateTime? depositDueAt;
  final DateTime? courseStartAt;
  final String? offerUrl;
  final String? leadMagnetFileId;
  final String? leadMagnetUrl;

  bool get hasDepositOption => depositKopecks > 0 && depositKopecks < priceFullKopecks;

  DateTime resolveDepositDueAt(DateTime now) {
    return depositDueAt ?? now.add(Duration(days: depositDueDays));
  }
}
