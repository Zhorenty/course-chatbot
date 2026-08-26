import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/jobs/claimed_outbound.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';

final class AbandonedPaymentJob {
  AbandonedPaymentJob({
    required CourseRepository course,
    required JobDedupeRepository dedupe,
    required MessageSender sender,
    required MessageTemplates templates,
    required QuietHours quietHours,
    this.firstDelay = const Duration(hours: 6),
    this.secondDelay = const Duration(hours: 24),
    DateTime Function()? nowProvider,
  })  : _course = course,
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
  final Duration secondDelay;
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    if (_quietHours.isQuiet(_nowProvider())) {
      return;
    }
    final now = _nowProvider();
    await _sendWave(
      now: now,
      minAge: firstDelay,
      keySuffix: 'h${firstDelay.inHours}',
      text: _templates.abandonedFirst(),
    );
    await _sendWave(
      now: now,
      minAge: secondDelay,
      keySuffix: 'h${secondDelay.inHours}',
      text: _templates.abandonedSecond(),
    );
  }

  Future<void> _sendWave({
    required DateTime now,
    required Duration minAge,
    required String keySuffix,
    required String text,
  }) {
    return sendClaimedBatch(
      items: _course.listAbandonedCheckout(
        now: now,
        minAge: minAge,
        excludeDedupeSuffix: keySuffix,
      ),
      claimKey: (order) => 'abandon:${order.id}:$keySuffix',
      dedupe: _dedupe,
      errorLabel: (order) => 'Abandoned payment reminder failed for order ${order.id}',
      userId: (order) => order.userId,
      course: _course,
      send: (order) async {
        if (order.status.isFullyPaid) {
          return;
        }
        final pending = _course.latestPendingPayment(order.id);
        await _sender.sendMessage(
          order.userId,
          text,
          parseMode: 'HTML',
          replyMarkup: pending?.confirmationUrl != null
              ? _templates.payUrlKeyboard(pending!.confirmationUrl!)
              : _templates.continuePayKeyboard(order.id),
        );
      },
    );
  }
}
