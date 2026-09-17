import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/participant_list.dart';
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

  void setFunnelPhase({
    required int userId,
    required FunnelPhase phase,
    DateTime? magnetIssuedAt,
    int? launchId,
    bool force = false,
  });

  void setWarmupOptOut({required int userId, required bool optOut, int? launchId});

  void setBotBlocked({required int userId, required bool blocked});

  UserProfile? findUserByUsername(String username);

  List<UserProfile> searchUsers(String query, {int limit = 10});

  List<int> listBroadcastUserIds({
    required BroadcastSegment segment,
    bool excludeOptOut = false,
    Set<String> courseEntrySources = AcquisitionSource.coursePayloads,
    int? launchId,
  });

  int countBroadcastUsers({
    required BroadcastSegment segment,
    bool excludeOptOut = false,
    Set<String> courseEntrySources = AcquisitionSource.coursePayloads,
    int? launchId,
  });

  List<UserProfile> listParticipants({
    required ParticipantListSegment segment,
    int? launchId,
    int limit = 8,
    int offset = 0,
    Set<int> excludeUserIds = const <int>{},
  });

  int countParticipants({
    required ParticipantListSegment segment,
    int? launchId,
    Set<int> excludeUserIds = const <int>{},
  });
}
