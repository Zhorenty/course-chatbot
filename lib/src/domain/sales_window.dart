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
      priceFullKopecks: launch.resolvedPriceFullKopecks,
      pricePromoKopecks: launch.resolvedPricePromoKopecks,
      webinarAt: launch.webinarAt,
      promoEndsAt: promoEndsAt(launch),
      regularSalesAt: regularSalesAt(launch),
      salesEndAt: launch.salesEndAt,
      courseStartAt: launch.courseStartAt,
    );
  }

  static SalesPhase phaseOf(Launch launch, DateTime now) {
    final webinar = launch.webinarAt?.toUtc();
    if (webinar == null) {
      return SalesPhase.preSales;
    }
    final nowUtc = now.toUtc();
    if (nowUtc.isBefore(webinar)) {
      return SalesPhase.preSales;
    }
    final end = launch.salesEndAt?.toUtc();
    if (end != null && !nowUtc.isBefore(end)) {
      return SalesPhase.closed;
    }
    final promoEnd = webinar.add(promoDuration);
    if (nowUtc.isBefore(promoEnd)) {
      return SalesPhase.promo;
    }
    return SalesPhase.regular;
  }

  static DateTime? promoEndsAt(Launch launch) {
    final webinar = launch.webinarAt?.toUtc();
    return webinar?.add(promoDuration);
  }

  static DateTime? regularSalesAt(Launch launch) => promoEndsAt(launch);

  static bool rsvpOpen(Launch launch, DateTime now) {
    final webinar = launch.webinarAt?.toUtc();
    if (webinar == null) {
      return true;
    }
    return now.toUtc().isBefore(webinar.add(rsvpGrace));
  }
}

final class SalesQuote {
  const SalesQuote({
    required this.phase,
    required this.rsvp,
    required this.priceFullKopecks,
    required this.pricePromoKopecks,
    this.webinarAt,
    this.promoEndsAt,
    this.regularSalesAt,
    this.salesEndAt,
    this.courseStartAt,
  });

  final SalesPhase phase;
  final bool rsvp;
  final int priceFullKopecks;
  final int pricePromoKopecks;
  final DateTime? webinarAt;
  final DateTime? promoEndsAt;
  final DateTime? regularSalesAt;
  final DateTime? salesEndAt;
  final DateTime? courseStartAt;

  bool get checkoutOpen => switch (phase) {
    SalesPhase.preSales || SalesPhase.closed => false,
    SalesPhase.promo => rsvp,
    SalesPhase.regular => true,
  };

  bool get promoPriceApplies => phase == SalesPhase.promo && rsvp;

  int get payableKopecks => promoPriceApplies ? pricePromoKopecks : priceFullKopecks;

  DateTime? get moscowDayStartOfSalesEnd {
    final end = salesEndAt;
    if (end == null) {
      return null;
    }
    return MoscowTime.dayStartUtc(end);
  }
}
