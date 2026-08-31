import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/launch_windows.dart';
import 'package:course_chatbot/src/domain/warmup.dart';

final class WarmupService {
  const WarmupService({required CourseRepository course, required JobDedupeRepository dedupe})
    : _course = course,
      _dedupe = dedupe;

  static const String firstStepKey = 'warmup_0';

  final CourseRepository _course;
  final JobDedupeRepository _dedupe;

  WarmupDecision? nextFor(
    WarmupCandidate candidate,
    DateTime now, {
    required List<WarmupStep> steps,
    Launch? launch,
  }) {
    final elapsedMagnet = now.toUtc().difference(candidate.magnetAnchor.toUtc());
    final elapsedStart = now.toUtc().difference(candidate.firstStartedAt.toUtc());
    final courseStart = launch?.courseStartAt?.toUtc();
    for (final step in steps) {
      if (candidate.sentKeys.contains(step.stepKey)) {
        continue;
      }
      if (!_inAudience(step: step, candidate: candidate)) {
        continue;
      }
      final due = switch (step.anchor) {
        WarmupAnchor.magnet => elapsedMagnet >= step.delay,
        WarmupAnchor.firstStart => elapsedStart >= step.delay,
        WarmupAnchor.courseStart => _courseStartDue(
          step: step,
          steps: steps,
          now: now,
          courseStart: courseStart,
        ),
      };
      if (!due) {
        continue;
      }
      return WarmupDecision(
        stepKey: step.stepKey,
        userId: candidate.userId,
        launchId: candidate.launchId,
      );
    }
    return null;
  }

  bool _inAudience({required WarmupStep step, required WarmupCandidate candidate}) {
    final waitingLead =
        candidate.funnelPhase == FunnelPhase.lead && candidate.magnetIssuedAt == null;
    final afterGuide =
        candidate.funnelPhase == FunnelPhase.magnetIssued ||
        candidate.funnelPhase == FunnelPhase.warming;
    return switch (step.anchor) {
      WarmupAnchor.magnet => afterGuide,
      WarmupAnchor.firstStart => waitingLead,
      WarmupAnchor.courseStart => afterGuide || waitingLead,
    };
  }

  /// Each course-start step occupies the slice until the next tighter delay.
  /// Missed slices are skipped so late joiners do not get «через неделю» two days out.
  bool _courseStartDue({
    required WarmupStep step,
    required List<WarmupStep> steps,
    required DateTime now,
    required DateTime? courseStart,
  }) {
    if (courseStart == null) {
      return false;
    }
    final start = courseStart.toUtc();
    final nowUtc = now.toUtc();
    final tighter = steps
        .where(
          (other) =>
              other.anchor == WarmupAnchor.courseStart && other.enabled && other.delay < step.delay,
        )
        .map((other) => other.delay)
        .fold<Duration?>(null, (best, delay) => best == null || delay > best ? delay : best);
    final windowStart = start.subtract(step.delay);
    final windowEnd = tighter != null
        ? start.subtract(tighter)
        : start.add(LaunchWindows.afterStartGrace);
    return !nowUtc.isBefore(windowStart) && nowUtc.isBefore(windowEnd);
  }

  bool tryClaim(WarmupDecision decision) {
    return _dedupe.tryClaim('warmup:${decision.launchId}:${decision.userId}:${decision.stepKey}');
  }

  void release(WarmupDecision decision) {
    _dedupe.release('warmup:${decision.launchId}:${decision.userId}:${decision.stepKey}');
  }

  void markSent(WarmupDecision decision, DateTime now) {
    _course.recordWarmupSent(
      userId: decision.userId,
      launchId: decision.launchId,
      stepKey: decision.stepKey,
      sentAt: now,
    );
    if (decision.stepKey != firstStepKey) {
      return;
    }
    final enrollment = _course.getEnrollment(userId: decision.userId, launchId: decision.launchId);
    if (enrollment != null && enrollment.funnelPhase == FunnelPhase.magnetIssued) {
      _course.setFunnelPhase(
        userId: decision.userId,
        phase: FunnelPhase.warming,
        launchId: decision.launchId,
      );
    }
  }

  Future<bool> deliver({
    required WarmupDecision decision,
    required DateTime now,
    required Future<void> Function() send,
  }) async {
    if (_course.hasWarmupBeenSent(
      userId: decision.userId,
      launchId: decision.launchId,
      stepKey: decision.stepKey,
    )) {
      return false;
    }
    if (!tryClaim(decision)) {
      return false;
    }
    try {
      await send();
      markSent(decision, now);
      return true;
    } on Object {
      release(decision);
      rethrow;
    }
  }
}
