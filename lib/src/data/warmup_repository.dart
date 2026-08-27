import 'package:course_chatbot/src/domain/warmup.dart';

abstract interface class WarmupRepository {
  List<WarmupStep> listWarmupSteps();

  void seedDefaultWarmupSteps();

  bool hasWarmupBeenSent({required int userId, required String stepKey});

  void recordWarmupSent({required int userId, required String stepKey, required DateTime sentAt});

  List<WarmupCandidate> listWarmupCandidates({required DateTime now, int limit = 100});
}
