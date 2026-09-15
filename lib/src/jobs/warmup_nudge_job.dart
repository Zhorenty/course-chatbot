import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/application/warmup_service.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/launch_dozhim.dart';
import 'package:course_chatbot/src/domain/sales_window.dart';
import 'package:course_chatbot/src/domain/warmup.dart';
import 'package:course_chatbot/src/jobs/claimed_outbound.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/prefer_rich_send.dart';
import 'package:course_chatbot/src/telegram/telegram_errors.dart';
import 'package:l/l.dart';

final class WarmupNudgeJob {
  WarmupNudgeJob({
    required CourseRepository course,
    required WarmupService warmup,
    required MessageSender sender,
    required MessageTemplates templates,
    required QuietHours quietHours,
    Set<int> skipUserIds = const <int>{},
    DateTime Function()? nowProvider,
  }) : _course = course,
       _warmup = warmup,
       _sender = sender,
       _templates = templates,
       _quietHours = quietHours,
       _skipUserIds = skipUserIds,
       _nowProvider = nowProvider ?? DateTime.now;

  final CourseRepository _course;
  final WarmupService _warmup;
  final MessageSender _sender;
  final MessageTemplates _templates;
  final QuietHours _quietHours;
  final Set<int> _skipUserIds;
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    final now = _nowProvider();
    final quiet = _quietHours.isQuiet(now);
    final globalSteps = _course.listWarmupSteps();
    final dozhimByLaunch = <int, List<LaunchDozhimMessage>>{};
    final candidates = _course.listWarmupCandidates(now: now);
    var sent = 0;
    for (final candidate in candidates) {
      try {
        final user = _course.getUser(candidate.userId);
        if (user == null ||
            _skipUserIds.contains(candidate.userId) ||
            candidate.funnelPhase.excludeSellingDrip) {
          continue;
        }
        final launch = _course.getLaunch(candidate.launchId);
        final custom = dozhimByLaunch.putIfAbsent(
          candidate.launchId,
          () => _course.listLaunchDozhim(candidate.launchId),
        );
        final decision = _warmup.nextFor(
          candidate,
          now,
          steps: _warmup.stepsFor(global: globalSteps, dozhim: custom),
          launch: launch,
          quiet: quiet,
        );
        if (decision == null) {
          continue;
        }
        final delivered = await _warmup.deliver(
          decision: decision,
          now: now,
          send: () => _deliverStep(
            candidate: candidate,
            decision: decision,
            launch: launch,
            custom: custom,
            now: now,
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

  Future<void> _deliverStep({
    required WarmupCandidate candidate,
    required WarmupDecision decision,
    required Launch? launch,
    required List<LaunchDozhimMessage> custom,
    required DateTime now,
  }) async {
    for (final message in custom) {
      if (message.stepKey != decision.stepKey) {
        continue;
      }
      await _sender.copyMessage(
        chatId: candidate.userId,
        fromChatId: message.sourceChatId,
        messageId: message.sourceMessageId,
      );
      return;
    }
    await sendPreferRich(
      _sender,
      candidate.userId,
      _templates.warmupStep(decision.stepKey, launch: launch, rsvp: candidate.webinarRsvp),
      replyMarkup: launch == null
          ? null
          : _templates.warmupKeyboard(
              decision.stepKey,
              launch: launch,
              rsvp: candidate.webinarRsvp,
              rsvpOpen: LaunchSales.rsvpOpen(launch, now),
            ),
    );
  }
}
