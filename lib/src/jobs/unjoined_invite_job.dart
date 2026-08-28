import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/launch_windows.dart';
import 'package:course_chatbot/src/jobs/claimed_outbound.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';

final class _UnjoinedTouch {
  const _UnjoinedTouch({
    required this.access,
    required this.suffix,
    this.alsoClaim = const <String>[],
  });

  final ChannelAccess access;
  final String suffix;
  final List<String> alsoClaim;
}

final class UnjoinedInviteJob {
  UnjoinedInviteJob({
    required CourseRepository course,
    required JobDedupeRepository dedupe,
    required MessageSender sender,
    required MessageTemplates templates,
    required QuietHours quietHours,
    this.firstDelay = const Duration(hours: 24),
    this.prestartWindow = LaunchWindows.prestart,
    DateTime Function()? nowProvider,
  }) : _course = course,
       _dedupe = dedupe,
       _sender = sender,
       _templates = templates,
       _quietHours = quietHours,
       _nowProvider = nowProvider ?? DateTime.now;

  final CourseRepository _course;
  final JobDedupeRepository _dedupe;
  final MessageSender _sender;
  final MessageTemplates _templates;
  final QuietHours _quietHours;
  final Duration firstDelay;
  final Duration prestartWindow;
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    if (_quietHours.isQuiet(_nowProvider())) {
      return;
    }
    final now = _nowProvider();
    final launch = _course.activeLaunch();
    final start = launch?.courseStartAt?.toUtc();
    final h24 = 'h${firstDelay.inHours}';
    final items = <_UnjoinedTouch>[];
    final seen = <String>{};
    for (final access in _course.listUnjoinedInvites()) {
      final key = '${access.userId}:${access.launchId}';
      if (!seen.add(key)) {
        continue;
      }
      final created = access.inviteCreatedAt?.toUtc();
      final due24 = created != null && now.toUtc().difference(created) >= firstDelay;
      final duePre =
          start != null &&
          !now.toUtc().isBefore(start.subtract(prestartWindow)) &&
          now.toUtc().isBefore(start.add(LaunchWindows.afterStartGrace));
      if (!due24 && !duePre) {
        continue;
      }
      if (duePre) {
        items.add(
          _UnjoinedTouch(
            access: access,
            suffix: 'prestart',
            alsoClaim: due24 ? <String>[h24] : const <String>[],
          ),
        );
      } else {
        items.add(_UnjoinedTouch(access: access, suffix: h24));
      }
    }
    await sendClaimedBatch(
      items: items,
      claimKey: (item) => 'unjoined:${item.access.userId}:${item.access.launchId}:${item.suffix}',
      dedupe: _dedupe,
      errorLabel: (item) => 'Unjoined invite reminder failed for ${item.access.userId}',
      userId: (item) => item.access.userId,
      course: _course,
      send: (item) async {
        final link = item.access.inviteLink!;
        await _sender.sendMessage(
          item.access.userId,
          _templates.unjoinedInviteReminder(link),
          parseMode: 'HTML',
          replyMarkup: _templates.unjoinedInviteKeyboard(link),
        );
        for (final extra in item.alsoClaim) {
          _dedupe.tryClaim('unjoined:${item.access.userId}:${item.access.launchId}:$extra');
        }
      },
    );
  }
}
