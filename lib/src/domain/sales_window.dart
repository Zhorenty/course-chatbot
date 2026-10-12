import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/moscow_time.dart';

/// Sales calendar for one launch.
///
/// Promo runs until 23:59 Moscow on the calendar day of webinar + 3 days.
/// During promo the bot kassa stays closed for everyone: RSVP get the special
/// price via an external checkout link, the rest wait. Full / deposit via the
/// bot kassa open after promo.
///
/// One-off for the stream that starts 12 Oct 2026: after [Launch.salesEndAt],
/// full price stays open until 23:59:59 Moscow on 15 Oct 2026. Deposit and
/// selling drip stay closed. [SalesQuote.lateFullOpen] is that window.
enum SalesPhase { preSales, promo, regular, closed }

final class LaunchSales {
  static const int defaultPromoKopecks = LaunchPrices.promoKopecks;
  static const int defaultFullKopecks = LaunchPrices.fullKopecks;
  static const Duration promoDuration = Duration(days: 3);
  static const Duration rsvpGrace = Duration(hours: 4);
  static const Duration liveWindow = Duration(hours: 4);
  static const int defaultWebinarHourMoscow = 19;

  /// Moscow calendar day the one-off late full-price stream starts.
  static final DateTime lateFullStreamStartDay = DateTime.utc(2026, 10, 12);

  /// Last instant full price stays open after sales end: 23:59:59 Moscow on 15 Oct 2026.
  static final DateTime lateFullPriceEndsAt = MoscowTime.endOfMoscowDay(DateTime.utc(2026, 10, 15));

  static SalesQuote quote(Launch launch, {required bool rsvp, required DateTime now}) {
    return SalesQuote(
      phase: phaseOf(launch, now),
      rsvp: rsvp,
      lateFullOpen: lateFullPriceOpen(launch, now),
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

  /// Full price only, after sales end, for the 12 Oct 2026 stream, through 15 Oct 23:59:59 Moscow.
  static bool lateFullPriceOpen(Launch launch, DateTime now) {
    if (phaseOf(launch, now) != SalesPhase.closed) {
      return false;
    }
    final startDay = MoscowTime.calendarDate(launch.courseStartAt);
    if (startDay != lateFullStreamStartDay) {
      return false;
    }
    return !now.toUtc().isAfter(lateFullPriceEndsAt);
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
    if (nowUtc.isBefore(promoEnd)) {
      return SalesPhase.preSales;
    }
    return SalesPhase.regular;
  }

  static DateTime promoEndsAt(Launch launch) {
    return MoscowTime.endOfMoscowDay(launch.webinarAt.toUtc().add(promoDuration));
  }

  /// When the bot kassa opens: 23:59 Moscow on webinar + 3 days, or later «Старт продаж».
  static DateTime regularSalesAt(Launch launch) {
    final open = salesOpenAt(launch);
    final promoEnd = promoEndsAt(launch);
    if (open.isAfter(promoEnd)) {
      return open;
    }
    return promoEnd;
  }

  /// True when RSVP get a special-price window before the bot kassa opens.
  static bool hasPromoWindow(Launch launch) {
    return regularSalesAt(launch).isAfter(salesOpenAt(launch));
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
    required this.lateFullOpen,
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

  /// Full YooKassa price after sales end. Deposit stays on [checkoutOpen].
  final bool lateFullOpen;
  final int priceFullKopecks;
  final int pricePromoKopecks;
  final DateTime webinarAt;
  final DateTime salesStartAt;
  final DateTime promoEndsAt;
  final DateTime regularSalesAt;
  final DateTime salesEndAt;
  final DateTime courseStartAt;

  /// Bot kassa (full / deposit). Closed during promo for everyone.
  bool get checkoutOpen => phase == SalesPhase.regular;

  /// RSVP during promo: special price via the external checkout link.
  bool get promoOffer => phase == SalesPhase.promo && rsvp;

  /// This person can buy right now, in the bot or via the promo link.
  bool get canBuy => checkoutOpen || promoOffer;

  int get payableKopecks => priceFullKopecks;

  DateTime get moscowDayStartOfSalesEnd => MoscowTime.dayStartUtc(salesEndAt);
}
