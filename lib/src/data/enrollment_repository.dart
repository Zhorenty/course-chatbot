import 'package:course_chatbot/src/domain/enrollment.dart';

abstract interface class EnrollmentRepository {
  UserEnrollment ensureEnrollment({
    required int userId,
    required int launchId,
    required DateTime now,
  });

  UserEnrollment? getEnrollment({required int userId, required int launchId});

  void setEnrollmentWarmupOptOut({
    required int userId,
    required int launchId,
    required bool optOut,
  });
}
