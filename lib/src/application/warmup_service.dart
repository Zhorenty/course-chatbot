import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/warmup.dart';

final class WarmupService {
  const WarmupService({
    required CourseRepository course,
    required JobDedupeRepository dedupe,
  })  : _course = course,
        _dedupe = dedupe;

  final CourseRepository _course;
  final JobDedupeRepository _dedupe;

  WarmupDecision? nextFor(WarmupCandidate candidate, DateTime now) {
    final steps = _course.listWarmupSteps();
    final elapsed = now.toUtc().difference(candidate.anchorAt.toUtc());
    for (final step in steps) {
      if (elapsed < step.delay) {
        continue;
      }
      if (candidate.sentKeys.contains(step.stepKey)) {
        continue;
      }
      if (_course.hasWarmupBeenSent(userId: candidate.userId, stepKey: step.stepKey)) {
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
  }
}
