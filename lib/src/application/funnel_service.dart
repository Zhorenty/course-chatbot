import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
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

  UserProfile start({required int userId, String? username, String? firstName, String? payload}) {
    final source = AcquisitionSource.normalize(payload);
    return _course.ensureUser(
      userId: userId,
      username: username,
      firstName: firstName,
      source: source,
      now: _nowProvider(),
    );
  }

  void markMagnetIssued(int userId) {
    _course.setFunnelPhase(
      userId: userId,
      phase: FunnelPhase.magnetIssued,
      magnetIssuedAt: _nowProvider(),
    );
  }

  void markCheckout(int userId) {
    final user = _course.getUser(userId);
    if (user == null || user.funnelPhase.excludeSellingDrip) {
      return;
    }
    _course.setFunnelPhase(userId: userId, phase: FunnelPhase.checkout);
  }

  void optOutWarmup(int userId) {
    _course.setWarmupOptOut(userId: userId, optOut: true);
  }

  bool shouldOfferEnroll(UserProfile user) => !user.funnelPhase.showsCourseStatus;
}
