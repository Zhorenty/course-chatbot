import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/application/quiet_hours.dart';
import 'package:course_chatbot/src/application/warmup_service.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/payment.dart';
import 'package:course_chatbot/src/domain/warmup.dart';
import 'package:course_chatbot/src/jobs/unjoined_invite_job.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

Launch _launch2(
  HandlerHarness harness, {
  bool activate = true,
  int channelId = -2002,
  DateTime? courseStartAt,
}) {
  return harness.course.upsertLaunch(
    productCode: 'course',
    productTitle: 'Курс',
    launchCode: 'launch-2',
    launchTitle: 'Ноябрь',
    priceFullKopecks: 2100000,
    depositKopecks: 500000,
    depositDueDays: 7,
    depositDueAt: DateTime.utc(2026, 11, 5, 20, 59, 59),
    courseStartAt: courseStartAt ?? DateTime.utc(2026, 11, 12),
    channelId: channelId,
    activate: activate,
  );
}

Future<PaymentApplyResult> _payFull(HandlerHarness harness, {required Launch launch}) async {
  final order = harness.checkout.startOrReuseOrder(
    userId: 42,
    launch: launch,
    kind: PaymentKind.full,
  );
  final payment = await harness.checkout.createCheckout(
    order: order,
    kind: PaymentKind.full,
    amountKopecks: launch.priceFullKopecks,
  );
  return harness.checkout.applyCallback(
    PaymentCallback(
      provider: 'fake',
      providerPaymentId: payment.providerPaymentId!,
      succeeded: true,
      charged: true,
      kind: PaymentKind.full,
      orderId: order.id,
      paymentDbId: payment.id,
      userId: 42,
      amountKopecks: launch.priceFullKopecks,
    ),
  );
}

void main() {
  late HandlerHarness harness;

  setUp(() async {
    harness = HandlerHarness();
    await harness.init();
  });

  tearDown(() => harness.dispose());

  test('webhook of a previous launch still invites that launch after active switched', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch1,
      kind: PaymentKind.full,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.full,
      amountKopecks: launch1.priceFullKopecks,
    );
    final launch2 = _launch2(harness);
    expect(harness.course.activeLaunch()?.id, launch2.id);

    final result = await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.full,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
        amountKopecks: launch1.priceFullKopecks,
      ),
    );

    expect(result.grantedAccess, isTrue);
    expect(harness.channel.createdChatIds, <int>[launch1.channelId!]);
    expect(harness.course.accessFor(userId: 42, launchId: launch1.id)?.inviteLink, isNotNull);
    expect(harness.course.accessFor(userId: 42, launchId: launch2.id), isNull);
    expect(
      harness.course.getEnrollment(userId: 42, launchId: launch1.id)?.funnelPhase.isPaidOrAccess,
      isTrue,
    );
    expect(
      harness.course.getEnrollment(userId: 42, launchId: launch2.id)?.funnelPhase.isPaidOrAccess,
      isNot(isTrue),
    );
  });

  test('paid on launch-1 does not block checkout on launch-2', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    await _payFull(harness, launch: launch1);
    final launch2 = _launch2(harness);
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 2));

    expect(
      () => harness.checkout.startOrReuseOrder(userId: 42, launch: launch1, kind: PaymentKind.full),
      throwsA(
        isA<CheckoutBlockedException>().having(
          (error) => error.reason,
          'reason',
          CheckoutBlockReason.alreadyPaid,
        ),
      ),
    );
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch2,
      kind: PaymentKind.full,
    );
    expect(order.launchId, launch2.id);
    expect(order.status, OrderStatus.checkoutStarted);
  });

  test('first-touch source is kept and a later start writes an acquisition event', () async {
    harness.funnel.start(userId: 42, payload: 'ig_reels_guide');
    harness.funnel.start(userId: 42, payload: 'tg_announce');

    expect(harness.course.getUser(42)?.source, 'ig_reels_guide');
    final events = harness.course.listAcquisitionEvents(42);
    expect(events.map((event) => event.payload), <String>['tg_announce', 'ig_reels_guide']);
    expect(events.first.launchId, harness.course.activeLaunch()?.id);
  });

  test('warmup_d1 on launch-1 does not mute warmup_d1 on launch-2', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    harness.course.setFunnelPhase(
      userId: 42,
      phase: FunnelPhase.warming,
      magnetIssuedAt: DateTime.utc(2026, 1, 1),
      launchId: launch1.id,
    );
    harness.course.recordWarmupSent(
      userId: 42,
      launchId: launch1.id,
      stepKey: 'warmup_d1',
      sentAt: DateTime.utc(2026, 1, 2),
    );
    final launch2 = _launch2(harness);
    harness.course.ensureEnrollment(
      userId: 42,
      launchId: launch2.id,
      now: DateTime.utc(2026, 1, 2),
    );
    harness.course.setFunnelPhase(
      userId: 42,
      phase: FunnelPhase.warming,
      magnetIssuedAt: DateTime.utc(2026, 1, 2),
      launchId: launch2.id,
    );

    expect(
      harness.course.hasWarmupBeenSent(userId: 42, launchId: launch1.id, stepKey: 'warmup_d1'),
      isTrue,
    );
    expect(
      harness.course.hasWarmupBeenSent(userId: 42, launchId: launch2.id, stepKey: 'warmup_d1'),
      isFalse,
    );

    final warmup = WarmupService(
      course: harness.course,
      dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
    );
    final delivered = await warmup.deliver(
      decision: WarmupDecision(stepKey: 'warmup_d1', userId: 42, launchId: launch2.id),
      now: DateTime.utc(2026, 1, 3, 12),
      send: () async {},
    );
    expect(delivered, isTrue);
    expect(
      harness.course.hasWarmupBeenSent(userId: 42, launchId: launch2.id, stepKey: 'warmup_d1'),
      isTrue,
    );
  });

  test('ВОРОНКА queries can slice by launch_id', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    await _payFull(harness, launch: launch1);
    final launch2 = _launch2(harness);
    harness.course.ensureUser(userId: 99, now: DateTime.utc(2026, 1, 2));

    final slice1 = harness.course.funnelAnalytics(
      now: DateTime.utc(2026, 1, 3),
      launchId: launch1.id,
    );
    final slice2 = harness.course.funnelAnalytics(
      now: DateTime.utc(2026, 1, 3),
      launchId: launch2.id,
    );
    expect(slice1.paidUsers, 1);
    expect(slice1.checkoutStarted, 1);
    expect(slice2.paidUsers, 0);
    expect(slice2.startedUsersTotal, 1);
    expect(slice2.checkoutStarted, 0);
  });

  test('enrollment phases are independent across launches', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    harness.course.setFunnelPhase(
      userId: 42,
      phase: FunnelPhase.accessGranted,
      launchId: launch1.id,
    );
    final launch2 = _launch2(harness);
    harness.course.ensureEnrollment(
      userId: 42,
      launchId: launch2.id,
      now: DateTime.utc(2026, 1, 2),
    );

    expect(
      harness.course.getEnrollment(userId: 42, launchId: launch1.id)?.funnelPhase,
      FunnelPhase.accessGranted,
    );
    expect(
      harness.course.getEnrollment(userId: 42, launchId: launch2.id)?.funnelPhase,
      FunnelPhase.lead,
    );
    expect(harness.funnel.phaseOf(harness.course.getUser(42)!), FunnelPhase.lead);
    expect(harness.funnel.shouldOfferEnroll(harness.course.getUser(42)!), isTrue);
  });

  test('unjoined prestart uses the invite launch start, not the new active', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    harness.course.upsertAccess(
      userId: 42,
      launchId: launch1.id,
      orderId: 1,
      inviteLink: 'https://t.me/+old',
      inviteCreatedAt: DateTime.utc(2026, 1, 1, 12),
    );
    _launch2(harness, courseStartAt: DateTime.utc(2026, 1, 2, 12));

    final job = UnjoinedInviteJob(
      course: harness.course,
      dedupe: JobDedupeRepository(databaseHandle: harness.handle)..initSchema(),
      sender: harness.sender,
      templates: MessageTemplates(),
      quietHours: const QuietHours(timezoneOffsetHours: 3, fromHour: 10, toHour: 21),
      nowProvider: () => DateTime.utc(2026, 1, 2, 12),
    );
    await job.run();
    expect(harness.sender.messages.where((m) => m.chatId == 42), hasLength(1));
    final keys = harness.db.select(
      "SELECT dedupe_key FROM job_dedupe_log WHERE dedupe_key LIKE 'unjoined:%';",
    );
    expect(keys.single['dedupe_key'], contains(':h24'));
    expect(keys.single['dedupe_key'], isNot(contains('prestart')));
  });

  test('ССЫЛКИ launch_code is parsed and a 4-column sheet still works', () {
    final withCode = LinksSheetParser.parse(<List<Object?>>[
      LinksSheet.displayHeaders,
      <Object?>['Таргет', 'курс', 'ads_nov', 'launch-2', ''],
    ]);
    expect(withCode.rows.single.payload, 'ads_nov');
    expect(withCode.rows.single.launchCode, 'launch-2');
    expect(withCode.rows.single.opensCourse, isTrue);

    final legacy = LinksSheetParser.parse(<List<Object?>>[
      <Object?>['Откуда', 'Куда', 'Метка', 'Ссылка'],
      <Object?>['Reels', 'гайд', 'ig_reels_guide', 'https://t.me/bot?start=ig_reels_guide'],
    ]);
    expect(legacy.rows.single.payload, 'ig_reels_guide');
    expect(legacy.rows.single.launchCode, isNull);
  });

  test('deep link with launch_code resolves that launch while active is another', () {
    final launch2 = _launch2(harness, activate: false);
    expect(harness.course.activeLaunch()?.code, 'launch-1');
    harness.funnel.links.replaceAll(<AcquisitionLink>[
      ...AcquisitionLink.starters,
      AcquisitionLink(
        origin: 'Таргет',
        destination: AcquisitionDestination.course,
        payload: 'ads_nov',
        launchCode: launch2.code,
      ),
    ]);
    expect(harness.funnel.resolveLaunch('ads_nov')?.id, launch2.id);
    expect(harness.funnel.resolveLaunch('ig_reels_guide')?.code, 'launch-1');
  });

  test('chat_member join on an old launch channel is recorded after active switched', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    harness.course.upsertAccess(
      userId: 42,
      launchId: launch1.id,
      orderId: 1,
      inviteLink: 'https://t.me/+x',
    );
    _launch2(harness);
    await harness.handlers.handle(<String, dynamic>{
      'update_id': 9,
      'chat_member': <String, dynamic>{
        'chat': <String, dynamic>{'id': launch1.channelId, 'type': 'channel'},
        'new_chat_member': <String, dynamic>{
          'status': 'member',
          'user': <String, dynamic>{'id': 42},
        },
      },
    });
    expect(harness.course.accessFor(userId: 42, launchId: launch1.id)?.joinedAt, isNotNull);
  });

  test(
    'course card and checkout stay on active when the deep link has another launch_code',
    () async {
      final launch2 = _launch2(harness, activate: false);
      harness.funnel.links.replaceAll(<AcquisitionLink>[
        ...AcquisitionLink.starters,
        AcquisitionLink(
          origin: 'Таргет',
          destination: AcquisitionDestination.course,
          payload: 'ads_nov',
          launchCode: launch2.code,
        ),
      ]);
      await harness.handlers.handle(
        privateMessageUpdate(chatId: 42, userId: 42, text: '/start ads_nov'),
      );
      final texts = harness.sender.messages.map((m) => m.text).join('\n');
      expect(texts, contains('18000 ₽'));
      expect(texts, isNot(contains('21000 ₽')));
      expect(harness.funnel.resolveLaunch('ads_nov')?.id, launch2.id);
    },
  );

  test('phaseOf after switching active is lead even if the profile still says paid', () {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    harness.course.setFunnelPhase(
      userId: 42,
      phase: FunnelPhase.accessGranted,
      launchId: launch1.id,
    );
    expect(harness.course.getUser(42)?.funnelPhase, FunnelPhase.accessGranted);
    _launch2(harness);
    expect(harness.funnel.phaseOf(harness.course.getUser(42)!), FunnelPhase.lead);
    expect(harness.funnel.shouldOfferEnroll(harness.course.getUser(42)!), isTrue);
  });

  test('warmup candidates skip enrollments on an inactive launch', () {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    harness.course.setFunnelPhase(
      userId: 42,
      phase: FunnelPhase.warming,
      magnetIssuedAt: DateTime.utc(2026, 1, 1),
      launchId: launch1.id,
    );
    final launch2 = _launch2(harness, activate: false);
    harness.course.ensureEnrollment(
      userId: 42,
      launchId: launch2.id,
      now: DateTime.utc(2026, 1, 2),
    );
    harness.course.setFunnelPhase(
      userId: 42,
      phase: FunnelPhase.warming,
      magnetIssuedAt: DateTime.utc(2026, 1, 2),
      launchId: launch2.id,
    );
    final candidates = harness.course.listWarmupCandidates(now: DateTime.utc(2026, 1, 3, 12));
    expect(candidates.map((c) => c.launchId), <int>[launch1.id]);
  });

  test('paidNotJoined is scoped to the enrollment launch', () {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    harness.course.setFunnelPhase(
      userId: 42,
      phase: FunnelPhase.accessGranted,
      launchId: launch1.id,
    );
    harness.course.upsertAccess(
      userId: 42,
      launchId: launch1.id,
      orderId: 1,
      inviteLink: 'https://t.me/+old',
    );
    final launch2 = _launch2(harness);
    harness.course.ensureEnrollment(
      userId: 42,
      launchId: launch2.id,
      now: DateTime.utc(2026, 1, 2),
    );
    harness.course.setFunnelPhase(
      userId: 42,
      phase: FunnelPhase.accessGranted,
      launchId: launch2.id,
    );
    harness.course.upsertAccess(
      userId: 42,
      launchId: launch2.id,
      orderId: 2,
      inviteLink: 'https://t.me/+new',
      joinedAt: DateTime.utc(2026, 1, 2, 12),
    );
    expect(harness.course.listBroadcastUserIds(segment: BroadcastSegment.paidNotJoined), isEmpty);
  });

  test('callback without order or payment id does not guess the latest open checkout', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    final order1 = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch1,
      kind: PaymentKind.full,
    );
    final launch2 = _launch2(harness);
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 2));
    final order2 = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch2,
      kind: PaymentKind.full,
    );

    await expectLater(
      harness.checkout.applyCallback(
        PaymentCallback(
          provider: 'fake',
          providerPaymentId: 'orphan-pay',
          succeeded: true,
          charged: true,
          kind: PaymentKind.full,
          userId: 42,
          amountKopecks: launch2.priceFullKopecks,
        ),
      ),
      throwsA(isA<StateError>()),
    );
    expect(harness.course.getOrder(order1.id)?.status, OrderStatus.checkoutStarted);
    expect(harness.course.getOrder(order2.id)?.status, OrderStatus.checkoutStarted);
  });

  test('remainder after active switch charges the deposit launch, not the new one', () async {
    harness.course.ensureUser(userId: 42, now: DateTime.utc(2026, 1, 1));
    final launch1 = harness.course.activeLaunch()!;
    final order = harness.checkout.startOrReuseOrder(
      userId: 42,
      launch: launch1,
      kind: PaymentKind.deposit,
    );
    final payment = await harness.checkout.createCheckout(
      order: order,
      kind: PaymentKind.deposit,
      amountKopecks: launch1.depositKopecks,
    );
    await harness.checkout.applyCallback(
      PaymentCallback(
        provider: 'fake',
        providerPaymentId: payment.providerPaymentId!,
        succeeded: true,
        charged: true,
        kind: PaymentKind.deposit,
        orderId: order.id,
        paymentDbId: payment.id,
        userId: 42,
        amountKopecks: launch1.depositKopecks,
      ),
    );
    _launch2(harness);

    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'r1',
        chatId: 42,
        userId: 42,
        data: '${MessageTemplates.cbPayRemainder}${order.id}',
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'r2',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbToggleOffer,
      ),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'r3',
        chatId: 42,
        userId: 42,
        data: MessageTemplates.cbGoToPay,
      ),
    );

    expect(harness.course.getOrder(order.id)?.launchId, launch1.id);
    expect(harness.course.latestOrder(42, launchId: launch1.id)?.id, order.id);
    expect(harness.course.latestOrder(42, launchId: harness.course.activeLaunch()!.id), isNull);
  });
}
