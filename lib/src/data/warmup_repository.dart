import 'package:course_chatbot/src/domain/warmup.dart';

abstract interface class WarmupRepository {
  List<WarmupStep> listWarmupSteps();

  void seedDefaultWarmupSteps();

  bool hasWarmupBeenSent({required int userId, required String stepKey, int? launchId});

  void recordWarmupSent({
    required int userId,
    required String stepKey,
    required DateTime sentAt,
    int? launchId,
  });

  List<WarmupCandidate> listWarmupCandidates({required DateTime now, int limit = 200});
}
