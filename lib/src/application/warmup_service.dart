import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/warmup.dart';

final class WarmupService {
  const WarmupService({
    required CourseRepository course,
    required JobDedupeRepository dedupe,
  })  : _course = course,
        _dedupe = dedupe;

  static const String firstStepKey = 'warmup_0';

  final CourseRepository _course;
  final JobDedupeRepository _dedupe;

  WarmupDecision? nextFor(
    WarmupCandidate candidate,
    DateTime now, {
    required List<WarmupStep> steps,
  }) {
    final elapsed = now.toUtc().difference(candidate.anchorAt.toUtc());
    for (final step in steps) {
      if (elapsed < step.delay) {
        continue;
      }
      if (candidate.sentKeys.contains(step.stepKey)) {
        continue;
      }
      return WarmupDecision(stepKey: step.stepKey, userId: candidate.userId);
    }
    return null;
  }

  bool tryClaim(WarmupDecision decision) {
    return _dedupe.tryClaim('warmup:${decision.userId}:${decision.stepKey}');
  }

  void release(WarmupDecision decision) {
    _dedupe.release('warmup:${decision.userId}:${decision.stepKey}');
  }

  void markSent(WarmupDecision decision, DateTime now) {
    _course.recordWarmupSent(
      userId: decision.userId,
      stepKey: decision.stepKey,
      sentAt: now,
    );
    if (decision.stepKey != firstStepKey) {
      return;
    }
    final user = _course.getUser(decision.userId);
    if (user != null && user.funnelPhase == FunnelPhase.magnetIssued) {
      _course.setFunnelPhase(userId: decision.userId, phase: FunnelPhase.warming);
    }
  }

  Future<bool> deliver({
    required WarmupDecision decision,
    required DateTime now,
    required Future<void> Function() send,
  }) async {
    if (_course.hasWarmupBeenSent(userId: decision.userId, stepKey: decision.stepKey)) {
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
