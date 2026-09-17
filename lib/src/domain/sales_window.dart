import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/moscow_time.dart';

/// Sales calendar for one launch. Promo is 3 days from the webinar instant.
enum SalesPhase { preSales, promo, regular, closed }

final class LaunchSales {
  static const int defaultPromoKopecks = LaunchPrices.promoKopecks;
  static const int defaultFullKopecks = LaunchPrices.fullKopecks;
  static const Duration promoDuration = Duration(days: 3);
  static const Duration rsvpGrace = Duration(hours: 4);
  static const Duration liveWindow = Duration(hours: 4);
  static const int defaultWebinarHourMoscow = 19;

  static SalesQuote quote(Launch launch, {required bool rsvp, required DateTime now}) {
    return SalesQuote(
      phase: phaseOf(launch, now),
      rsvp: rsvp,
      priceFullKopecks: launch.priceFullKopecks,
      pricePromoKopecks: launch.pricePromoKopecks,
      webinarAt: launch.webinarAt,
      salesStartAt: launch.salesStartAt,
      promoEndsAt: promoEndsAt(launch),
      regularSalesAt: regularSalesAt(launch),
      salesEndAt: launch.salesEndAt,
      courseStartAt: launch.courseStartAt,
    );
  }

  static DateTime salesOpenAt(Launch launch) => launch.salesStartAt.toUtc();

  static SalesPhase phaseOf(Launch launch, DateTime now) {
    final open = salesOpenAt(launch);
    final nowUtc = now.toUtc();
    if (nowUtc.isBefore(open)) {
      return SalesPhase.preSales;
    }
    if (!nowUtc.isBefore(launch.salesEndAt.toUtc())) {
      return SalesPhase.closed;
    }
    final promoEnd = promoEndsAt(launch);
    if (!nowUtc.isBefore(launch.webinarAt.toUtc()) && nowUtc.isBefore(promoEnd)) {
      return SalesPhase.promo;
    }
    return SalesPhase.regular;
  }

  static DateTime promoEndsAt(Launch launch) {
    return launch.webinarAt.toUtc().add(promoDuration);
  }

  static DateTime regularSalesAt(Launch launch) {
    final open = salesOpenAt(launch);
    final promoEnd = promoEndsAt(launch);
    if (open.isAfter(promoEnd)) {
      return open;
    }
    return promoEnd;
  }

  static bool rsvpOpen(Launch launch, DateTime now) {
    return now.toUtc().isBefore(launch.webinarAt.toUtc().add(rsvpGrace));
  }

  static bool webinarStarted(Launch launch, DateTime now) {
    return !now.toUtc().isBefore(launch.webinarAt.toUtc());
  }
}

final class SalesQuote {
  const SalesQuote({
    required this.phase,
    required this.rsvp,
    required this.priceFullKopecks,
    required this.pricePromoKopecks,
    required this.webinarAt,
    required this.salesStartAt,
    required this.promoEndsAt,
    required this.regularSalesAt,
    required this.salesEndAt,
    required this.courseStartAt,
  });

  final SalesPhase phase;
  final bool rsvp;
  final int priceFullKopecks;
  final int pricePromoKopecks;
  final DateTime webinarAt;
  final DateTime salesStartAt;
  final DateTime promoEndsAt;
  final DateTime regularSalesAt;
  final DateTime salesEndAt;
  final DateTime courseStartAt;

  bool get checkoutOpen => switch (phase) {
    SalesPhase.preSales || SalesPhase.closed => false,
    SalesPhase.promo || SalesPhase.regular => true,
  };

  bool get promoPriceApplies => phase == SalesPhase.promo && rsvp;

  int get payableKopecks => promoPriceApplies ? pricePromoKopecks : priceFullKopecks;

  DateTime get moscowDayStartOfSalesEnd => MoscowTime.dayStartUtc(salesEndAt);
}
