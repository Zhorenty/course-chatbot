import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/jobs/claimed_outbound.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/prefer_rich_send.dart';

final class AbandonedPaymentJob {
  AbandonedPaymentJob({
    required CourseRepository course,
    required JobDedupeRepository dedupe,
    required MessageSender sender,
    required MessageTemplates templates,
    required QuietHours quietHours,
    this.firstDelay = const Duration(hours: 6),
    DateTime Function()? nowProvider,
  }) : _course = course,
       _dedupe = dedupe,
       _sender = sender,
       _templates = templates,
       _quietHours = quietHours,
       _nowProvider = nowProvider ?? DateTime.now;

  final CourseRepository _course;
  final JobDedupeRepository _dedupe;
  final MessageSender _sender;
  final MessageTemplates _templates;
  final QuietHours _quietHours;
  final Duration firstDelay;
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    if (_quietHours.isQuiet(_nowProvider())) {
      return;
    }
    final now = _nowProvider();
    final keySuffix = 'h${firstDelay.inHours}';
    await sendClaimedBatch(
      items: _course.listAbandonedCheckout(
        now: now,
        minAge: firstDelay,
        excludeDedupeSuffix: keySuffix,
      ),
      claimKey: (order) => 'abandon:${order.id}:$keySuffix',
      dedupe: _dedupe,
      errorLabel: (order) => 'Abandoned payment reminder failed for order ${order.id}',
      userId: (order) => order.userId,
      course: _course,
      send: (order) => _sendReminder(order, _templates.abandonedFirst()),
    );
  }

  Future<void> _sendReminder(CourseOrder order, String text) async {
    if (order.status.isFullyPaid) {
      return;
    }
    final pending = _course.latestPendingPayment(order.id);
    await sendPreferRich(
      _sender,
      order.userId,
      text,
      replyMarkup: pending?.confirmationUrl != null
          ? _templates.payUrlKeyboard(pending!.confirmationUrl!)
          : _templates.continuePayKeyboard(order.id),
    );
  }
}
