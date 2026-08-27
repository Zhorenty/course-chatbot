import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';

abstract interface class UserRepository {
  UserProfile ensureUser({
    required int userId,
    String? username,
    String? firstName,
    String? source,
    required DateTime now,
  });

  UserProfile? getUser(int userId);

  void touchUser({required int userId, String? username, String? firstName, required DateTime now});

  void setFunnelPhase({required int userId, required FunnelPhase phase, DateTime? magnetIssuedAt});

  void setWarmupOptOut({required int userId, required bool optOut});

  void setBotBlocked({required int userId, required bool blocked});

  UserProfile? findUserByUsername(String username);

  List<UserProfile> searchUsers(String query, {int limit = 10});

  List<int> listBroadcastUserIds({required BroadcastSegment segment});
}
