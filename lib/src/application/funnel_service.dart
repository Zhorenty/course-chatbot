import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/enrollment.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';

final class FunnelService {
  FunnelService({
    required CourseRepository course,
    AcquisitionLinkCatalog? links,
    DateTime Function()? nowProvider,
  }) : _course = course,
       links = links ?? AcquisitionLinkCatalog(),
       _nowProvider = nowProvider ?? DateTime.now;

  final CourseRepository _course;
  final AcquisitionLinkCatalog links;
  final DateTime Function() _nowProvider;

  bool opensCourseCard(String? payload) => links.opensCourseCard(payload);

  /// Launch for attribution (`acquisition_events`, optional enrollment row).
  /// Missing or unknown stream (code or COURSES title) → active launch.
  /// MVP card/checkout still use active.
  Launch? resolveLaunch(String? payload) {
    final link = links.byPayload(payload);
    final raw = link?.launchCode?.trim();
    if (raw != null && raw.isNotEmpty) {
      return _course.launchByCode(raw) ?? _course.launchByTitle(raw) ?? _course.activeLaunch();
    }
    return _course.activeLaunch();
  }

  UserEnrollment? enrollmentFor(int userId, {Launch? launch}) {
    final resolved = launch ?? _course.activeLaunch();
    if (resolved == null) {
      return null;
    }
    return _course.getEnrollment(userId: userId, launchId: resolved.id);
  }

  FunnelPhase phaseOf(UserProfile user, {Launch? launch}) {
    final enrollment = enrollmentFor(user.userId, launch: launch);
    if (enrollment != null) {
      return enrollment.funnelPhase;
    }
    if ((launch ?? _course.activeLaunch()) != null) {
      return FunnelPhase.lead;
    }
    return user.funnelPhase;
  }

  UserProfile start({required int userId, String? username, String? firstName, String? payload}) {
    final source = AcquisitionSource.normalize(payload);
    final now = _nowProvider();
    final user = _course.ensureUser(
      userId: userId,
      username: username,
      firstName: firstName,
      source: source,
      now: now,
    );
    if (source != null) {
      final launch = resolveLaunch(source);
      _course.recordAcquisitionEvent(
        userId: userId,
        payload: source,
        occurredAt: now,
        destination: opensCourseCard(source)
            ? AcquisitionDestination.course
            : AcquisitionDestination.guide,
        productId: launch?.productId,
        launchId: launch?.id,
      );
      if (launch != null) {
        _course.ensureEnrollment(userId: userId, launchId: launch.id, now: now);
      }
    }
    return _course.getUser(userId) ?? user;
  }

  void markMagnetIssued(int userId, {int? launchId}) {
    _course.setFunnelPhase(
      userId: userId,
      phase: FunnelPhase.magnetIssued,
      magnetIssuedAt: _nowProvider(),
      launchId: launchId,
    );
  }

  void markCheckout(int userId, {int? launchId}) {
    final user = _course.getUser(userId);
    if (user == null) {
      return;
    }
    final launch = launchId == null ? null : _course.getLaunch(launchId);
    if (phaseOf(user, launch: launch).excludeSellingDrip) {
      return;
    }
    _course.setFunnelPhase(userId: userId, phase: FunnelPhase.checkout, launchId: launchId);
  }

  void optOutWarmup(int userId, {int? launchId}) {
    _course.setWarmupOptOut(userId: userId, optOut: true, launchId: launchId);
  }

  bool shouldOfferEnroll(UserProfile user, {Launch? launch}) {
    return !phaseOf(user, launch: launch).showsCourseStatus;
  }
}
