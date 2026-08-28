import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/jobs/claimed_outbound.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';

final class RemainderReminderJob {
  RemainderReminderJob({
    required CourseRepository course,
    required JobDedupeRepository dedupe,
    required MessageSender sender,
    required MessageTemplates templates,
    required QuietHours quietHours,
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
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    if (_quietHours.isQuiet(_nowProvider())) {
      return;
    }
    final now = _nowProvider();
    await _sendWave(
      now: now,
      wave: RemainderWave.beforeDue,
      suffix: 'before',
      textOf: _templates.remainderBeforeDue,
    );
    await _sendWave(
      now: now,
      wave: RemainderWave.onDueDay,
      suffix: 'due',
      textOf: _templates.remainderReminder,
    );
    await _sendWave(
      now: now,
      wave: RemainderWave.overdue,
      suffix: 'overdue',
      textOf: _templates.remainderReminder,
    );
  }

  Future<void> _sendWave({
    required DateTime now,
    required RemainderWave wave,
    required String suffix,
    required String Function(CourseOrder order) textOf,
  }) {
    return sendClaimedBatch(
      items: _course.listRemainderDue(now: now, wave: wave, excludeDedupeSuffix: suffix),
      claimKey: (order) => 'remainder:${order.id}:$suffix',
      dedupe: _dedupe,
      errorLabel: (order) => 'Remainder reminder failed for order ${order.id}',
      userId: (order) => order.userId,
      course: _course,
      send: (order) {
        return _sender.sendMessage(
          order.userId,
          textOf(order),
          parseMode: 'HTML',
          replyMarkup: _templates.remainderKeyboard(),
        );
      },
    );
  }
}
