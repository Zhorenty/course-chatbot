import 'package:course_chatbot/src/domain/acquisition_link.dart';

/// One `/start` with a payload. First-touch [UserProfile.source] is separate and is not overwritten.
final class AcquisitionEvent {
  const AcquisitionEvent({
    required this.id,
    required this.userId,
    required this.payload,
    required this.occurredAt,
    this.destination,
    this.productId,
    this.launchId,
  });

  final int id;
  final int userId;
  final String payload;
  final AcquisitionDestination? destination;
  final int? productId;
  final int? launchId;
  final DateTime occurredAt;
}
