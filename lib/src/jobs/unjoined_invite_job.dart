import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/jobs/claimed_outbound.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:course_chatbot/src/telegram/message_sender.dart';
import 'package:course_chatbot/src/telegram/prefer_rich_send.dart';

final class UnjoinedInviteJob {
  UnjoinedInviteJob({
    required CourseRepository course,
    required JobDedupeRepository dedupe,
    required MessageSender sender,
    required MessageTemplates templates,
    required QuietHours quietHours,
    this.firstDelay = const Duration(hours: 24),
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
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    if (_quietHours.isQuiet(_nowProvider())) {
      return;
    }
    final now = _nowProvider();
    final suffix = 'h${firstDelay.inHours}';
    final items = <ChannelAccess>[];
    final seen = <String>{};
    for (final access in _course.listUnjoinedInvites()) {
      final key = '${access.userId}:${access.launchId}';
      if (!seen.add(key)) {
        continue;
      }
      final created = access.inviteCreatedAt?.toUtc();
      if (created == null || now.toUtc().difference(created) < firstDelay) {
        continue;
      }
      items.add(access);
    }
    await sendClaimedBatch(
      items: items,
      claimKey: (access) => 'unjoined:${access.userId}:${access.launchId}:$suffix',
      dedupe: _dedupe,
      errorLabel: (access) => 'Unjoined invite reminder failed for ${access.userId}',
      userId: (access) => access.userId,
      course: _course,
      send: (access) {
        final link = access.inviteLink!;
        return sendPreferRich(
          _sender,
          access.userId,
          _templates.unjoinedInviteReminder(),
          replyMarkup: _templates.unjoinedInviteKeyboard(link),
        );
      },
    );
  }
}
