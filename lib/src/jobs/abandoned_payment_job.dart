import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/launch_windows.dart';
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
    this.prestartWindow = LaunchWindows.prestart,
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
  final Duration secondDelay;
  final Duration prestartWindow;
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    if (_quietHours.isQuiet(_nowProvider())) {
      return;
    }
    final now = _nowProvider();
    final prestart = _course.listAbandonedPrestart(
      now: now,
      windowBeforeStart: prestartWindow,
      minAge: firstDelay,
      afterStartGrace: LaunchWindows.afterStartGrace,
      excludeDedupeSuffix: 'prestart',
    );
    final prestartIds = <int>{for (final order in prestart) order.id};
    await _sendWave(
      now: now,
      minAge: firstDelay,
      keySuffix: 'h${firstDelay.inHours}',
      text: _templates.abandonedFirst(),
      skipIds: prestartIds,
    );
    await _sendWave(
      now: now,
      minAge: secondDelay,
      keySuffix: 'h${secondDelay.inHours}',
      text: _templates.abandonedSecond(),
      skipIds: prestartIds,
    );
    await sendClaimedBatch(
      items: prestart,
      claimKey: (order) => 'abandon:${order.id}:prestart',
      dedupe: _dedupe,
      errorLabel: (order) => 'Abandoned prestart reminder failed for order ${order.id}',
      userId: (order) => order.userId,
      course: _course,
      send: (order) => _sendReminder(order, _templates.abandonedPrestart()),
    );
  }

  Future<void> _sendWave({
    required DateTime now,
    required Duration minAge,
    required String keySuffix,
    required String text,
    required Set<int> skipIds,
  }) {
    return sendClaimedBatch(
      items: _course
          .listAbandonedCheckout(now: now, minAge: minAge, excludeDedupeSuffix: keySuffix)
          .where((order) => !skipIds.contains(order.id)),
      claimKey: (order) => 'abandon:${order.id}:$keySuffix',
      dedupe: _dedupe,
      errorLabel: (order) => 'Abandoned payment reminder failed for order ${order.id}',
      userId: (order) => order.userId,
      course: _course,
      send: (order) => _sendReminder(order, text),
    );
  }

  Future<void> _sendReminder(CourseOrder order, String text) async {
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
  }
}
