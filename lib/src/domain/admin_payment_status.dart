import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/order.dart';

/// Payment states an admin can set from the person card.
///
/// [promoPaid] is the special price paid outside the bot (LeadPay): full access
/// at `price_promo_kopecks`.
enum AdminPaymentStatus { unpaid, deposit, paid, promoPaid, cancelled }

extension AdminPaymentStatusX on AdminPaymentStatus {
  String get code => switch (this) {
    AdminPaymentStatus.unpaid => 'u',
    AdminPaymentStatus.deposit => 'd',
    AdminPaymentStatus.paid => 'p',
    AdminPaymentStatus.promoPaid => 's',
    AdminPaymentStatus.cancelled => 'c',
  };

  bool get isFullyPaid => this == AdminPaymentStatus.paid || this == AdminPaymentStatus.promoPaid;

  /// Full payment only. Deposit does not get a channel invite.
  bool get canIssueChannelInvite => isFullyPaid;

  /// Kick/revoke shortcut: paid, or already inside the channel.
  bool canRemoveFromCourse({bool inChannel = false}) {
    return isFullyPaid || inChannel;
  }

  static AdminPaymentStatus? parseCode(String? raw) => switch (raw) {
    'u' => AdminPaymentStatus.unpaid,
    'd' => AdminPaymentStatus.deposit,
    'p' => AdminPaymentStatus.paid,
    's' => AdminPaymentStatus.promoPaid,
    'c' => AdminPaymentStatus.cancelled,
    _ => null,
  };

  /// [promoPriceKopecks] marks a fully paid order at that price as [promoPaid].
  static AdminPaymentStatus resolve({
    CourseOrder? order,
    FunnelPhase? phase,
    int? promoPriceKopecks,
  }) {
    if (phase == FunnelPhase.cancelled || order?.status == OrderStatus.cancelled) {
      return AdminPaymentStatus.cancelled;
    }
    if (order?.status.isFullyPaid == true || (phase?.isPaidOrAccess ?? false)) {
      if (promoPriceKopecks != null &&
          promoPriceKopecks > 0 &&
          order != null &&
          order.status.isFullyPaid &&
          order.priceFullKopecks == promoPriceKopecks) {
        return AdminPaymentStatus.promoPaid;
      }
      return AdminPaymentStatus.paid;
    }
    if (order?.status == OrderStatus.depositPaid || phase == FunnelPhase.depositPaid) {
      return AdminPaymentStatus.deposit;
    }
    return AdminPaymentStatus.unpaid;
  }
}
