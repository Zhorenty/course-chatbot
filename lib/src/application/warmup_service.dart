import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/launch_windows.dart';
import 'package:course_chatbot/src/domain/moscow_time.dart';
import 'package:course_chatbot/src/domain/sales_window.dart';
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
    bool quiet = false,
  }) {
    final elapsedMagnet = now.toUtc().difference(candidate.magnetAnchor.toUtc());
    final elapsedStart = now.toUtc().difference(candidate.firstStartedAt.toUtc());
    for (final step in steps) {
      if (!step.enabled || candidate.sentKeys.contains(step.stepKey)) {
        continue;
      }
      if (quiet && !step.ignoreQuietHours) {
        continue;
      }
      if (!_inAudience(step: step, candidate: candidate, launch: launch, now: now)) {
        continue;
      }
      final due = switch (step.anchor) {
        WarmupAnchor.magnet => elapsedMagnet >= step.delay,
        WarmupAnchor.firstStart => elapsedStart >= step.delay,
        WarmupAnchor.courseStart => _beforeAnchorDue(
          step: step,
          steps: steps,
          now: now,
          anchor: launch?.courseStartAt?.toUtc(),
          sameAnchor: WarmupAnchor.courseStart,
        ),
        WarmupAnchor.webinar => _webinarDue(step: step, steps: steps, now: now, launch: launch),
        WarmupAnchor.webinarFollowup => _afterAnchorDue(
          step: step,
          steps: steps,
          now: now,
          anchor: launch?.webinarAt?.toUtc(),
          sameAnchor: WarmupAnchor.webinarFollowup,
          cap: launch == null ? null : LaunchSales.regularSalesAt(launch),
        ),
        WarmupAnchor.regularSales => _afterAnchorDue(
          step: step,
          steps: steps,
          now: now,
          anchor: launch == null ? null : LaunchSales.regularSalesAt(launch)?.toUtc(),
          sameAnchor: WarmupAnchor.regularSales,
          cap: launch?.salesEndAt?.toUtc(),
        ),
        WarmupAnchor.salesEnd => _salesEndDue(now: now, salesEnd: launch?.salesEndAt?.toUtc()),
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

  bool _inAudience({
    required WarmupStep step,
    required WarmupCandidate candidate,
    required Launch? launch,
    required DateTime now,
  }) {
    final waitingLead =
        candidate.funnelPhase == FunnelPhase.lead && candidate.magnetIssuedAt == null;
    final afterGuide =
        candidate.funnelPhase == FunnelPhase.magnetIssued ||
        candidate.funnelPhase == FunnelPhase.warming;
    if (step.rsvpOnly && !candidate.webinarRsvp) {
      return false;
    }
    // Selling drip only while this person can actually pay.
    if (step.anchor == WarmupAnchor.firstStart && candidate.enrollIntentAt != null) {
      return false;
    }
    final selling =
        step.anchor == WarmupAnchor.firstStart ||
        step.anchor == WarmupAnchor.webinarFollowup ||
        step.anchor == WarmupAnchor.regularSales ||
        step.anchor == WarmupAnchor.salesEnd;
    if (selling) {
      if (launch == null) {
        return false;
      }
      final quote = LaunchSales.quote(launch, rsvp: candidate.webinarRsvp, now: now);
      if (!quote.checkoutOpen) {
        return false;
      }
    }
    return switch (step.anchor) {
      WarmupAnchor.magnet || WarmupAnchor.webinar || WarmupAnchor.webinarFollowup => afterGuide,
      WarmupAnchor.firstStart => waitingLead,
      WarmupAnchor.courseStart ||
      WarmupAnchor.regularSales ||
      WarmupAnchor.salesEnd => afterGuide || waitingLead,
    };
  }

  bool _webinarDue({
    required WarmupStep step,
    required List<WarmupStep> steps,
    required DateTime now,
    required Launch? launch,
  }) {
    final webinar = launch?.webinarAt?.toUtc();
    if (webinar == null) {
      return false;
    }
    if (step.delay == Duration.zero) {
      final nowUtc = now.toUtc();
      return !nowUtc.isBefore(webinar) && nowUtc.isBefore(webinar.add(LaunchSales.liveWindow));
    }
    return _beforeAnchorDue(
      step: step,
      steps: steps,
      now: now,
      anchor: webinar,
      sameAnchor: WarmupAnchor.webinar,
    );
  }

  bool _salesEndDue({required DateTime now, required DateTime? salesEnd}) {
    if (salesEnd == null) {
      return false;
    }
    final nowUtc = now.toUtc();
    final dayStart = MoscowTime.dayStartUtc(salesEnd);
    final windowEnd = salesEnd.add(LaunchWindows.afterStartGrace);
    return !nowUtc.isBefore(dayStart) && nowUtc.isBefore(windowEnd);
  }

  /// Each before-anchor step occupies the slice until the next tighter delay.
  /// Missed slices are skipped so late joiners do not get «через неделю» two days out.
  bool _beforeAnchorDue({
    required WarmupStep step,
    required List<WarmupStep> steps,
    required DateTime now,
    required DateTime? anchor,
    required WarmupAnchor sameAnchor,
  }) {
    if (anchor == null) {
      return false;
    }
    final start = anchor.toUtc();
    final nowUtc = now.toUtc();
    final tighter = steps
        .where(
          (other) =>
              other.anchor == sameAnchor &&
              other.enabled &&
              other.delay > Duration.zero &&
              other.delay < step.delay,
        )
        .map((other) => other.delay)
        .fold<Duration?>(null, (best, delay) => best == null || delay > best ? delay : best);
    final windowStart = start.subtract(step.delay);
    final windowEnd = tighter != null
        ? start.subtract(tighter)
        : start.add(LaunchWindows.afterStartGrace);
    return !nowUtc.isBefore(windowStart) && nowUtc.isBefore(windowEnd);
  }

  bool _afterAnchorDue({
    required WarmupStep step,
    required List<WarmupStep> steps,
    required DateTime now,
    required DateTime? anchor,
    required WarmupAnchor sameAnchor,
    DateTime? cap,
  }) {
    if (anchor == null) {
      return false;
    }
    final start = anchor.toUtc();
    final nowUtc = now.toUtc();
    final looser = steps
        .where((other) => other.anchor == sameAnchor && other.enabled && other.delay > step.delay)
        .map((other) => other.delay)
        .fold<Duration?>(null, (best, delay) => best == null || delay < best ? delay : best);
    final windowStart = start.add(step.delay);
    var windowEnd = looser != null
        ? start.add(looser)
        : start.add(step.delay + const Duration(days: 1));
    if (cap != null && cap.toUtc().isBefore(windowEnd)) {
      windowEnd = cap.toUtc();
    }
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
