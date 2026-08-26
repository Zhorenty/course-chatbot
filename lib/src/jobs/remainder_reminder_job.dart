import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:l/l.dart';

final class RemainderReminderJob {
  RemainderReminderJob({
    required CourseRepository course,
    required JobDedupeRepository dedupe,
    required MessageSender sender,
    required MessageTemplates templates,
    required QuietHours quietHours,
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
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    if (_quietHours.isQuiet(_nowProvider())) {
      return;
    }
    final now = _nowProvider();
    final orders = _course.listRemainderDue(now: now);
    for (final order in orders) {
      final dayKey = now.toUtc().toIso8601String().substring(0, 10);
      final key = 'remainder:${order.id}:$dayKey';
      if (!_dedupe.tryClaim(key)) {
        continue;
      }
      try {
        await _sender.sendMessage(
          order.userId,
          _templates.remainderReminder(order),
          parseMode: 'HTML',
          replyMarkup: _templates.remainderKeyboard(),
        );
      } on Object catch (error, stackTrace) {
        _dedupe.release(key);
        l.w('Remainder reminder failed for order ${order.id}: $error', stackTrace);
      }
    }
  }
}
