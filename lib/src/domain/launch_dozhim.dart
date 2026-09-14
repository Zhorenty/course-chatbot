import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/warmup.dart';

/// One admin-authored follow-up in a launch’s open-ended dozhim sequence.
///
/// Day 1 is the first day after regular sales start, day 2 the next, and so on.
/// Content is a Telegram message (text / photo / file, including rich formatting)
/// copied from the admin chat — COURSES only stores a presence flag.
final class LaunchDozhimMessage {
  const LaunchDozhimMessage({
    required this.id,
    required this.launchId,
    required this.dayIndex,
    required this.sourceChatId,
    required this.sourceMessageId,
    required this.contentKind,
    this.previewText,
  });

  final int id;
  final int launchId;

  /// 1-based day after regular sales. Delay is [Duration] of this many days.
  final int dayIndex;
  final int sourceChatId;
  final int sourceMessageId;
  final BroadcastContentKind contentKind;
  final String? previewText;

  String get stepKey => WarmupStep.customDozhimKey(id);

  WarmupStep toWarmupStep() {
    return WarmupStep(
      stepKey: stepKey,
      delay: Duration(days: dayIndex),
      sortOrder: 30 + dayIndex,
      anchor: WarmupAnchor.regularSales,
    );
  }
}
