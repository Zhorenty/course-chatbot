import 'package:course_chatbot/src/application/payment_alert_notifier.dart';
import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/application/warmup_service.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/launch_dozhim.dart';
import 'package:course_chatbot/src/domain/sales_window.dart';
import 'package:course_chatbot/src/domain/warmup.dart';
import 'package:course_chatbot/src/jobs/claimed_outbound.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/prefer_rich_send.dart';
import 'package:course_chatbot/src/telegram/replay_dozhim.dart';
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
    AdminAlertPort? alerts,
    JobDedupeRepository? dedupe,
  }) : _course = course,
       _warmup = warmup,
       _sender = sender,
       _templates = templates,
       _quietHours = quietHours,
       _skipUserIds = skipUserIds,
       _nowProvider = nowProvider ?? DateTime.now,
       _alerts = alerts,
       _dedupe = dedupe;

  final CourseRepository _course;
  final WarmupService _warmup;
  final MessageSender _sender;
  final MessageTemplates _templates;
  final QuietHours _quietHours;
  final Set<int> _skipUserIds;
  final DateTime Function() _nowProvider;
  final AdminAlertPort? _alerts;
  final JobDedupeRepository? _dedupe;
  final Map<String, _CourseLetterWave> _pendingLetterNotices = <String, _CourseLetterWave>{};

  Future<void> run() async {
    final now = _nowProvider();
    final quiet = _quietHours.isQuiet(now);
    final globalSteps = _course.listWarmupSteps();
    final dozhimByLaunch = <int, List<LaunchDozhimMessage>>{};
    final candidates = _course.listWarmupCandidates(now: now);
    final sentThisRun = <String, _CourseLetterWave>{};
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
          _noteCourseLetter(
            sentThisRun,
            candidate: candidate,
            stepKey: decision.stepKey,
            launch: launch,
            custom: custom,
          );
          await paceOutboundBatch(sent);
        }
      } on Object catch (error, stackTrace) {
        if (isUserBlockedError(error)) {
          _course.setBotBlocked(userId: candidate.userId, blocked: true);
        }
        l.w('Warmup candidate ${candidate.userId} failed: $error', stackTrace);
      }
    }
    await _flushCourseLetterNotices(sentThisRun);
  }

  void _noteCourseLetter(
    Map<String, _CourseLetterWave> sentThisRun, {
    required WarmupCandidate candidate,
    required String stepKey,
    required Launch? launch,
    required List<LaunchDozhimMessage> custom,
  }) {
    if (!_announcesCourseLetter(stepKey)) {
      return;
    }
    final key = '${candidate.launchId}:$stepKey';
    final wave = sentThisRun.putIfAbsent(
      key,
      () => _CourseLetterWave(
        launchId: candidate.launchId,
        stepKey: stepKey,
        launch: launch,
        dozhimDay: _dozhimDay(stepKey, custom),
      ),
    );
    wave.count++;
  }

  Future<void> _flushCourseLetterNotices(Map<String, _CourseLetterWave> sentThisRun) async {
    final alerts = _alerts;
    final dedupe = _dedupe;
    if (alerts == null || dedupe == null) {
      return;
    }
    for (final wave in sentThisRun.values) {
      final pending = _pendingLetterNotices.putIfAbsent(wave.noticeKey, () => wave);
      if (!identical(pending, wave)) {
        pending.count += wave.count;
      }
    }
    final delivered = <String>[];
    for (final wave in _pendingLetterNotices.values) {
      final key = 'course-letter:${wave.launchId}:${wave.stepKey}';
      if (!dedupe.tryClaim(key)) {
        delivered.add(wave.noticeKey);
        continue;
      }
      try {
        await alerts.notifyCourseLetterSent(
          stepKey: wave.stepKey,
          recipientCount: wave.count,
          launch: wave.launch,
          dozhimDay: wave.dozhimDay,
        );
        delivered.add(wave.noticeKey);
      } on Object catch (error, stackTrace) {
        dedupe.release(key);
        l.w(
          'Course letter notice ${wave.stepKey} for launch ${wave.launchId} failed: $error',
          stackTrace,
        );
      }
    }
    for (final key in delivered) {
      _pendingLetterNotices.remove(key);
    }
  }

  bool _announcesCourseLetter(String stepKey) {
    if (stepKey == WarmupService.firstStepKey) {
      return false;
    }
    return !WarmupStep.retiredKeys.contains(stepKey);
  }

  int? _dozhimDay(String stepKey, List<LaunchDozhimMessage> custom) {
    for (final message in custom) {
      if (message.stepKey == stepKey) {
        return message.dayIndex;
      }
    }
    return null;
  }

  Future<void> _deliverStep({
    required WarmupCandidate candidate,
    required WarmupDecision decision,
    required Launch? launch,
    required List<LaunchDozhimMessage> custom,
    required DateTime now,
  }) async {
    final keyboard = launch == null
        ? null
        : _templates.warmupKeyboard(
            decision.stepKey,
            launch: launch,
            rsvp: candidate.webinarRsvp,
            rsvpOpen: LaunchSales.rsvpOpen(launch, now),
          );
    for (final message in custom) {
      if (message.stepKey != decision.stepKey) {
        continue;
      }
      final raw = message.payload;
      final ids = await replayDozhimContent(
        sender: _sender,
        chatId: candidate.userId,
        message: message,
        payload: raw == null ? null : _templates.renderDozhimCopy(raw, launch),
      );
      if (keyboard != null) {
        await _attachInlineKeyboard(chatId: candidate.userId, messageIds: ids, keyboard: keyboard);
      }
      return;
    }
    await sendPreferRich(
      _sender,
      candidate.userId,
      _templates.warmupStep(decision.stepKey, launch: launch, rsvp: candidate.webinarRsvp),
      media: _templates.warmupMedia(decision.stepKey, launch: launch),
      replyMarkup: keyboard,
    );
  }

  Future<void> _attachInlineKeyboard({
    required int chatId,
    required List<int> messageIds,
    required Map<String, Object?> keyboard,
  }) async {
    if (messageIds.isNotEmpty) {
      try {
        await _sender.editMessageReplyMarkup(
          chatId,
          messageId: messageIds.last,
          replyMarkup: keyboard,
        );
        return;
      } on Object catch (error, stackTrace) {
        l.w('Failed to attach enroll CTA to dozhim for $chatId: $error', stackTrace);
      }
    }
  }
}

final class _CourseLetterWave {
  _CourseLetterWave({
    required this.launchId,
    required this.stepKey,
    required this.launch,
    required this.dozhimDay,
  });

  final int launchId;
  final String stepKey;
  final Launch? launch;
  final int? dozhimDay;
  int count = 0;

  String get noticeKey => '$launchId:$stepKey';
}
