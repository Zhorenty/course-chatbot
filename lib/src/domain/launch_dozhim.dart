import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/warmup.dart';

/// One admin-authored follow-up in a launch’s open-ended dozhim sequence.
///
/// Day 1 is the first day after regular sales start, day 2 the next, and so on.
/// Content is a Telegram message (text / photo / album / file, including rich
/// formatting) copied from the admin chat — COURSES only stores a presence flag.
final class LaunchDozhimMessage {
  LaunchDozhimMessage({
    required this.id,
    required this.launchId,
    required this.dayIndex,
    required this.sourceChatId,
    required this.sourceMessageId,
    required this.contentKind,
    List<int>? sourceMessageIds,
    this.previewText,
  }) : sourceMessageIds = _normalizedSourceMessageIds(sourceMessageId, sourceMessageIds);

  final int id;
  final int launchId;

  /// 1-based day after regular sales. Delay is [Duration] of this many days.
  final int dayIndex;
  final int sourceChatId;
  final int sourceMessageId;
  final List<int> sourceMessageIds;
  final BroadcastContentKind contentKind;
  final String? previewText;

  bool get isAlbum => contentKind == BroadcastContentKind.album || sourceMessageIds.length > 1;

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

List<int> _normalizedSourceMessageIds(int sourceMessageId, List<int>? sourceMessageIds) {
  final ids = <int>{sourceMessageId, ...?sourceMessageIds}.where((id) => id > 0).toList()..sort();
  if (ids.isEmpty) {
    return <int>[sourceMessageId];
  }
  return List<int>.unmodifiable(ids);
}
