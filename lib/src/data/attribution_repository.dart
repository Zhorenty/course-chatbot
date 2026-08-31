import 'package:course_chatbot/src/domain/acquisition_event.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';

abstract interface class AttributionRepository {
  void recordAcquisitionEvent({
    required int userId,
    required String payload,
    required DateTime occurredAt,
    AcquisitionDestination? destination,
    int? productId,
    int? launchId,
  });

  List<AcquisitionEvent> listAcquisitionEvents(int userId, {int limit = 20});
}
