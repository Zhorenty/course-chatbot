import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';

final class FunnelService {
  FunnelService({
    required CourseRepository course,
    DateTime Function()? nowProvider,
  })  : _course = course,
        _nowProvider = nowProvider ?? DateTime.now;

  final CourseRepository _course;
  final DateTime Function() _nowProvider;

  Future<UserProfile> start({
    required int userId,
    String? username,
    String? firstName,
    String? payload,
  }) {
    final source = AcquisitionSource.normalize(payload);
    return _course.ensureUser(
      userId: userId,
      username: username,
      firstName: firstName,
      source: source,
      now: _nowProvider(),
    );
  }

  Future<void> markMagnetIssued(int userId) async {
    _course.setFunnelPhase(
      userId: userId,
      phase: FunnelPhase.warming,
      magnetIssuedAt: _nowProvider(),
    );
  }

  Future<void> markCheckout(int userId) async {
    final user = _course.getUser(userId);
    if (user == null || user.funnelPhase.excludeSellingDrip) {
      return;
    }
    _course.setFunnelPhase(userId: userId, phase: FunnelPhase.checkout);
  }

  Future<void> optOutWarmup(int userId) async {
    _course.setWarmupOptOut(userId: userId, optOut: true);
  }

  bool shouldOfferEnroll(UserProfile user) => !user.funnelPhase.hasAccess;
}
