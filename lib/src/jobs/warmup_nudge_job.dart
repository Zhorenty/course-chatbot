import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/application/warmup_service.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/jobs/claimed_outbound.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/telegram_errors.dart';
import 'package:l/l.dart';

final class WarmupNudgeJob {
  WarmupNudgeJob({
    required CourseRepository course,
    required WarmupService warmup,
    required MessageSender sender,
    required MessageTemplates templates,
    required QuietHours quietHours,
    DateTime Function()? nowProvider,
  }) : _course = course,
       _warmup = warmup,
       _sender = sender,
       _templates = templates,
       _quietHours = quietHours,
       _nowProvider = nowProvider ?? DateTime.now;

  final CourseRepository _course;
  final WarmupService _warmup;
  final MessageSender _sender;
  final MessageTemplates _templates;
  final QuietHours _quietHours;
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    if (_quietHours.isQuiet(_nowProvider())) {
      return;
    }
    final now = _nowProvider();
    final steps = _course.listWarmupSteps();
    final candidates = _course.listWarmupCandidates(now: now);
    var sent = 0;
    for (final candidate in candidates) {
      try {
        final user = _course.getUser(candidate.userId);
        if (user == null || user.funnelPhase.excludeSellingDrip || user.warmupOptOut) {
          continue;
        }
        final decision = _warmup.nextFor(candidate, now, steps: steps);
        if (decision == null) {
          continue;
        }
        final delivered = await _warmup.deliver(
          decision: decision,
          now: now,
          send: () => _sender.sendMessage(
            candidate.userId,
            _templates.warmupStep(decision.stepKey, launch: _course.activeLaunch()),
            parseMode: 'HTML',
            replyMarkup: _templates.warmupKeyboard(showEnroll: true),
          ),
        );
        if (delivered) {
          sent++;
          await paceOutboundBatch(sent);
        }
      } on Object catch (error, stackTrace) {
        if (isUserBlockedError(error)) {
          _course.setBotBlocked(userId: candidate.userId, blocked: true);
        }
        l.w('Warmup candidate ${candidate.userId} failed: $error', stackTrace);
      }
    }
  }
}
