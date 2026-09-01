import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/order.dart';

/// Payment states an admin can set from the person card.
enum AdminPaymentStatus { unpaid, deposit, paid, cancelled }

extension AdminPaymentStatusX on AdminPaymentStatus {
  String get code => switch (this) {
    AdminPaymentStatus.unpaid => 'u',
    AdminPaymentStatus.deposit => 'd',
    AdminPaymentStatus.paid => 'p',
    AdminPaymentStatus.cancelled => 'c',
  };

  /// Full payment only. Deposit does not get a channel invite.
  bool get canIssueChannelInvite => this == AdminPaymentStatus.paid;

  /// Kick/revoke shortcut: paid, or already inside the channel.
  bool canRemoveFromCourse({bool inChannel = false}) {
    return this == AdminPaymentStatus.paid || inChannel;
  }

  static AdminPaymentStatus? parseCode(String? raw) => switch (raw) {
    'u' => AdminPaymentStatus.unpaid,
    'd' => AdminPaymentStatus.deposit,
    'p' => AdminPaymentStatus.paid,
    'c' => AdminPaymentStatus.cancelled,
    _ => null,
  };

  static AdminPaymentStatus resolve({CourseOrder? order, FunnelPhase? phase}) {
    if (phase == FunnelPhase.cancelled || order?.status == OrderStatus.cancelled) {
      return AdminPaymentStatus.cancelled;
    }
    if (order?.status.isFullyPaid == true || (phase?.isPaidOrAccess ?? false)) {
      return AdminPaymentStatus.paid;
    }
    if (order?.status == OrderStatus.depositPaid || phase == FunnelPhase.depositPaid) {
      return AdminPaymentStatus.deposit;
    }
    return AdminPaymentStatus.unpaid;
  }
}
