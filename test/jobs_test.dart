import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/application/warmup_service.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/domain/warmup.dart';
import 'package:course_chatbot/src/jobs/abandoned_payment_job.dart';
import 'package:course_chatbot/src/jobs/remainder_reminder_job.dart';
import 'package:course_chatbot/src/jobs/unjoined_invite_job.dart';
import 'package:course_chatbot/src/jobs/warmup_nudge_job.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late HandlerHarness harness;

  setUp(() async {
    harness = HandlerHarness();
    await harness.init();
  });

  tearDown(() => harness.dispose());

  const quietHours = QuietHours(timezoneOffsetHours: 3, fromHour: 10, toHour: 21);
  final templates = MessageTemplates();

  test('abandoned payment job skips quiet hours and claims a key once', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.full,
    );
    await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch.priceFullKopecks,
    );
    harness.db.execute('UPDATE orders SET checkout_started_at = ? WHERE id = ?;', <Object?>[
      '2026-01-01T00:00:00.000Z',
      order.id,
    ]);

    final dedupe = JobDedupeRepository(databaseHandle: harness.handle)..initSchema();
    final job = AbandonedPaymentJob(
      course: harness.course,
      dedupe: dedupe,
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      firstDelay: const Duration(hours: 1),
      secondDelay: const Duration(hours: 24),
      nowProvider: () => DateTime.utc(2026, 1, 1, 6),
    );
    await job.run();
    expect(harness.sender.messages, isEmpty);

    final dayJob = AbandonedPaymentJob(
      course: harness.course,
      dedupe: dedupe,
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      firstDelay: const Duration(hours: 1),
      secondDelay: const Duration(hours: 24),
      nowProvider: () => DateTime.utc(2026, 1, 1, 12),
    );
    await dayJob.run();
    expect(
      harness.sender.messages.where((m) => m.text.contains('Оформление началось')),
      hasLength(1),
    );

    await dayJob.run();
    expect(
      harness.sender.messages.where((m) => m.text.contains('Оформление началось')),
      hasLength(1),
    );
  });

  test('remainder job reminds deposit-paid orders after due date', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.deposit,
    );
    final deposit = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.deposit,
      amountKopecks: launch.depositKopecks,
    );
    await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: deposit.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.deposit,
        orderId: order.id,
        paymentDbId: deposit.id,
        userId: 42,
        amountKopecks: launch.depositKopecks,
      ),
      launch: launch,
    );

    final due = harness.course.getOrder(order.id)!;
    harness.course.updateOrder(due.copyWith(dueAt: DateTime.utc(2026, 1, 2)));

    final job = RemainderReminderJob(
      course: harness.course,
      dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      nowProvider: () => DateTime.utc(2026, 1, 3, 12),
    );
    harness.sender.messages.clear();
    await job.run();
    expect(harness.sender.messages.any((m) => m.text.contains('Доплата')), isTrue);
  });

  test('warmup job sends the next unsent step after the delay', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    harness.course.setFunnelPhase(
      userId: 42,
      phase: FunnelPhase.magnetIssued,
      magnetIssuedAt: DateTime.utc(2026, 1, 1),
    );

    final dedupe = JobDedupeRepository(databaseHandle: harness.handle)..initSchema();
    final job = WarmupNudgeJob(
      course: harness.course,
      warmup: WarmupService(course: harness.course, dedupe: dedupe),
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      nowProvider: () => DateTime.utc(2026, 1, 1, 12),
    );
    harness.sender.messages.clear();
    await job.run();
    expect(harness.sender.messages.any((m) => m.text.contains('алфавит')), isTrue);
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.warming);
  });

  test('warmup job skips users who already received every step', () async {
    final now = DateTime.utc(2026, 1, 10, 12);
    harness.course.ensureUser(userId: 1, now: DateTime.utc(2026, 1, 1));
    harness.course.setFunnelPhase(
      userId: 1,
      phase: FunnelPhase.warming,
      magnetIssuedAt: DateTime.utc(2026, 1, 1),
    );
    for (final step in harness.course.listWarmupSteps()) {
      harness.course.recordWarmupSent(userId: 1, stepKey: step.stepKey, sentAt: now);
    }
    harness.course.ensureUser(userId: 2, now: DateTime.utc(2026, 1, 9));
    harness.course.setFunnelPhase(
      userId: 2,
      phase: FunnelPhase.magnetIssued,
      magnetIssuedAt: DateTime.utc(2026, 1, 9),
    );

    final job = WarmupNudgeJob(
      course: harness.course,
      warmup: WarmupService(
        course: harness.course,
        dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
      ),
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      nowProvider: () => now,
    );
    harness.sender.messages.clear();
    await job.run();
    expect(harness.sender.messages.where((m) => m.chatId == 1), isEmpty);
    expect(harness.sender.messages.where((m) => m.chatId == 2), isNotEmpty);
  });

  test('warmup job nudges course-card leads who never took the guide', () async {
    harness.course.ensureUser(userId: 7, source: 'tg_announce', now: DateTime.utc(2026, 1, 1));
    final job = WarmupNudgeJob(
      course: harness.course,
      warmup: WarmupService(
        course: harness.course,
        dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
      ),
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      nowProvider: () => DateTime.utc(2026, 1, 2, 12),
    );
    harness.sender.messages.clear();
    await job.run();
    expect(
      harness.sender.messages.any(
        (m) => m.chatId == 7 && m.text.contains('Гайд и запись ещё здесь'),
      ),
      isTrue,
    );
  });

  test('warmup job nudges organic leads who never took the guide', () async {
    harness.course.ensureUser(userId: 8, now: DateTime.utc(2026, 1, 1));
    final job = WarmupNudgeJob(
      course: harness.course,
      warmup: WarmupService(
        course: harness.course,
        dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
      ),
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      nowProvider: () => DateTime.utc(2026, 1, 2, 12),
    );
    harness.sender.messages.clear();
    await job.run();
    expect(
      harness.sender.messages.any(
        (m) => m.chatId == 8 && m.text.contains('Гайд и запись ещё здесь'),
      ),
      isTrue,
    );
  });

  test('remainder job reminds before the due date', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch,
      kind: PaymentKind.deposit,
    );
    final deposit = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.deposit,
      amountKopecks: launch.depositKopecks,
    );
    await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: deposit.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.deposit,
        orderId: order.id,
        paymentDbId: deposit.id,
        userId: 42,
        amountKopecks: launch.depositKopecks,
      ),
      launch: launch,
    );
    final due = harness.course.getOrder(order.id)!;
    harness.course.updateOrder(due.copyWith(dueAt: DateTime.utc(2026, 1, 5, 12)));

    final job = RemainderReminderJob(
      course: harness.course,
      dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      nowProvider: () => DateTime.utc(2026, 1, 3, 12),
    );
    harness.sender.messages.clear();
    await job.run();
    expect(harness.sender.messages.any((m) => m.text.contains('Напоминаю про доплату')), isTrue);
  });

  test('course-start warmup uses the current slot and skips a missed week copy', () {
    final warmup = WarmupService(
      course: harness.course,
      dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
    );
    final launch = harness.course.activeLaunch()!;
    const sent = <String>{
      'warmup_0',
      'warmup_d1',
      'warmup_d3',
      'warmup_d7',
      'enroll_d1',
      'enroll_d3',
    };
    final candidate = WarmupCandidate(
      userId: 1,
      launchId: launch.id,
      firstStartedAt: DateTime.utc(2026, 10, 1),
      magnetIssuedAt: DateTime.utc(2026, 10, 1),
      funnelPhase: FunnelPhase.warming,
      sentKeys: sent,
    );
    final decision = warmup.nextFor(
      candidate,
      DateTime.utc(2026, 10, 10, 12),
      steps: WarmupStep.defaults,
      launch: launch,
    );
    expect(decision?.stepKey, 'warmup_start_d3');
  });

  test('unjoined invite job sends one reminder when 24h and prestart overlap', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 10, 1));
    harness.course.setFunnelPhase(userId: 42, phase: FunnelPhase.accessGranted);
    final launch = harness.course.activeLaunch()!;
    harness.course.upsertAccess(
      userId: 42,
      launchId: launch.id,
      orderId: 1,
      inviteLink: 'https://t.me/+keep',
      inviteCreatedAt: DateTime.utc(2026, 10, 9, 12),
    );
    final job = UnjoinedInviteJob(
      course: harness.course,
      dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
      sender: harness.sender,
      templates: templates,
      quietHours: quietHours,
      nowProvider: () => DateTime.utc(2026, 10, 10, 12),
    );
    harness.sender.messages.clear();
    await job.run();
    final toUser = harness.sender.messages.where((m) => m.chatId == 42).toList();
    expect(toUser, hasLength(1));
    expect(toUser.single.text, contains('https://t.me/+keep'));
    expect('${toUser.single.replyMarkup}', contains(MessageTemplates.buttonOpenInvite));
    expect('${toUser.single.replyMarkup}', isNot(contains(MessageTemplates.buttonGuide)));
    expect('${toUser.single.replyMarkup}', isNot(contains(MessageTemplates.buttonHelp)));
    await job.run();
    expect(harness.sender.messages.where((m) => m.chatId == 42), hasLength(1));
  });
}
