import 'package:course_chatbot/src/domain/moscow_time.dart';

abstract final class LaunchPrices {
  static const int promoKopecks = 1500000;
  static const int fullKopecks = 1900000;
  static const int wasKopecks = 2100000;
  static const int wasRegularKopecks = 2300000;
}

final class Product {
  const Product({required this.id, required this.code, required this.title});

  final int id;
  final String code;
  final String title;
}

final class Launch {
  static const String defaultDescription =
      'Скоро стартует мой курс по интерьерной колористике\n\n'
      '<u>Я сообщу тебе, когда откроются продажи по самой выгодной цене.</u>\n\n'
      'А пока можно записаться на <b>бесплатный Мастер-класс «Как начать работать с цветом смелее и не бояться ошибиться»</b>, после которого понимание цвета в интерьерах у моих учеников-дизайнеров и хоумстейджеров разделилось на до и после.';

  static DateTime impliedSalesStartAt(DateTime webinarAt) {
    return MoscowTime.nextMoscowDayStart(webinarAt);
  }

  static DateTime impliedSalesEndAt(DateTime courseStartAt) {
    return MoscowTime.endOfMoscowDay(courseStartAt);
  }

  const Launch({
    required this.id,
    required this.productId,
    required this.code,
    required this.title,
    required this.priceFullKopecks,
    required this.depositKopecks,
    required this.depositDueDays,
    required this.pricePromoKopecks,
    required this.courseStartAt,
    required this.webinarAt,
    required this.salesStartAt,
    required this.salesEndAt,
    required this.channelId,
    required this.description,
    this.depositDueAt,
    this.webinarUrl,
    this.leadMagnetFileId,
    this.leadMagnetUrl,
    this.isActive = false,
  });

  final int id;
  final int productId;
  final String code;
  final String title;
  final int channelId;
  final int priceFullKopecks;
  final int pricePromoKopecks;
  final int depositKopecks;
  final int depositDueDays;
  final DateTime? depositDueAt;
  final DateTime courseStartAt;
  final DateTime webinarAt;
  final String? webinarUrl;
  final DateTime salesStartAt;
  final DateTime salesEndAt;
  final String? leadMagnetFileId;
  final String? leadMagnetUrl;
  final String description;
  final bool isActive;

  bool get hasCustomDescription => description.trim() != defaultDescription;

  bool get hasDepositOption => depositKopecks > 0 && depositKopecks < priceFullKopecks;

  bool hasDepositOptionFor(int payableKopecks) =>
      depositKopecks > 0 && depositKopecks < payableKopecks;

  String? get resolvedWebinarUrl {
    final url = webinarUrl?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }
    return url;
  }

  bool get hasWebinarUrl => resolvedWebinarUrl != null;

  DateTime get impliedDepositDueAt =>
      MoscowTime.daysBeforeCourseStart(courseStartAt, days: depositDueDays);

  DateTime resolveDepositDueAt(DateTime now) {
    return depositDueAt ?? impliedDepositDueAt;
  }
}
