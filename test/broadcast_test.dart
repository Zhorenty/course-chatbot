import 'package:course_chatbot/src/bot/handlers/private/private_flow_store.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  late HandlerHarness harness;
  final now = DateTime.utc(2026, 1, 1);
  final templates = MessageTemplates();

  setUp(() async {
    harness = HandlerHarness();
    await harness.init(adminUserIds: const <int>{1});
  });

  tearDown(() => harness.dispose());

  test('broadcast segments include and exclude the right people', () {
    _seed(harness, 10, phase: FunnelPhase.warming, magnet: now);
    _seed(harness, 11, phase: FunnelPhase.accessGranted);
    _seed(harness, 12, phase: FunnelPhase.lead);
    _seed(harness, 13, phase: FunnelPhase.checkout);
    _seed(harness, 14, phase: FunnelPhase.depositPaid);
    _seed(harness, 15, phase: FunnelPhase.paid);
    _seed(harness, 16, phase: FunnelPhase.cancelled);
    _seed(harness, 17, phase: FunnelPhase.warming, magnet: now, blocked: true);
    _seed(harness, 18, phase: FunnelPhase.warming, magnet: now, optOut: true);
    _seed(harness, 19, phase: FunnelPhase.magnetIssued, magnet: now);

    expect(harness.course.listBroadcastUserIds(segment: BroadcastSegment.allStarted), <int>[
      10,
      12,
      13,
      14,
      18,
      19,
    ]);
    expect(harness.course.listBroadcastUserIds(segment: BroadcastSegment.leadNoGuide), <int>[12]);
    expect(harness.course.listBroadcastUserIds(segment: BroadcastSegment.guideNotPaid), <int>[
      10,
      18,
      19,
    ]);
    expect(harness.course.listBroadcastUserIds(segment: BroadcastSegment.checkoutOpen), <int>[13]);
    expect(harness.course.listBroadcastUserIds(segment: BroadcastSegment.depositPaid), <int>[14]);
    expect(harness.course.listBroadcastUserIds(segment: BroadcastSegment.paidAccess), <int>[
      11,
      15,
    ]);
    expect(harness.course.listBroadcastUserIds(segment: BroadcastSegment.cancelled), <int>[16]);
    harness.course.ensureUser(userId: 21, source: 'tg_announce', now: now);
    expect(
      harness.course.listBroadcastUserIds(segment: BroadcastSegment.courseLeadNoCheckout),
      <int>[21],
    );
    expect(harness.course.listBroadcastUserIds(segment: BroadcastSegment.leadNoGuide), <int>[12]);

    for (final segment in BroadcastSegment.values) {
      expect(
        harness.course.listBroadcastUserIds(segment: segment),
        isNot(contains(17)),
        reason: '$segment must skip blocked users',
      );
      expect(
        harness.course.countBroadcastUsers(segment: segment),
        harness.course.listBroadcastUserIds(segment: segment).length,
      );
    }
  });

  test('picker shows human labels and recipient counts', () async {
    _seed(harness, 10, phase: FunnelPhase.warming, magnet: now);
    _seed(harness, 11, phase: FunnelPhase.accessGranted);
    await _openBroadcast(harness);

    final picker = harness.sender.messages.last;
    expect(picker.text, contains('Гайд, без записи — 1'));
    expect(picker.text, contains('Оплатили / доступ — 1'));
    expect(picker.text, contains('Все, кроме купивших и отмен — '));
    final buttons = _inlineButtonTexts(picker.replyMarkup);
    expect(buttons, contains('Гайд, без записи (1)'));
    expect(buttons, contains('Оплатили / доступ (1)'));
    expect(buttons, contains(MessageTemplates.buttonAdminBroadcastCancel));
    final data = _inlineCallbackData(picker.replyMarkup);
    expect(data, contains('${MessageTemplates.cbBroadcastSegment}g'));
    expect(data, contains('${MessageTemplates.cbBroadcastSegment}a'));
    expect(data, isNot(contains('bg')));
  });

  test('preview copies to admin and does not copy to recipients yet', () async {
    _seed(harness, 10, phase: FunnelPhase.warming, magnet: now);
    await _openBroadcast(harness);
    await _pickSegment(harness, BroadcastSegment.guideNotPaid);
    await harness.handlers.handle(
      privateMessageUpdate(chatId: 1, userId: 1, text: 'Привет поток', messageId: 41),
    );

    expect(harness.sender.copies, hasLength(1));
    expect(harness.sender.copies.single.chatId, 1);
    expect(harness.sender.copies.single.fromChatId, 1);
    expect(harness.sender.copies.single.messageId, 41);
    expect(harness.sender.copies.any((c) => c.chatId == 10), isFalse);
    final preview = harness.sender.messages.last;
    expect(preview.text, contains('Превью'));
    expect(preview.text, contains('Гайд, без записи'));
    expect(preview.text, contains('Получателей: 1'));
    expect(preview.text, contains('текст'));
    expect(preview.text, contains('Привет поток'));
    final data = _inlineCallbackData(preview.replyMarkup);
    expect(data, contains(MessageTemplates.cbBroadcastSend));
    expect(data, contains(MessageTemplates.cbBroadcastOtherSegment));
    expect(data, contains(MessageTemplates.cbBroadcastCancel));
    expect(data, contains(MessageTemplates.cbBroadcastToggleOptOut));
    expect(data, isNot(contains('bg')));
  });

  test('confirm copies only to the chosen segment', () async {
    _seed(harness, 10, phase: FunnelPhase.warming, magnet: now);
    _seed(harness, 11, phase: FunnelPhase.accessGranted);
    await _draftBroadcast(
      harness,
      BroadcastSegment.guideNotPaid,
      privateMessageUpdate(chatId: 1, userId: 1, text: 'Только гайд', messageId: 42),
    );
    await _confirmBroadcast(harness);

    expect(
      harness.sender.copies.where((c) => c.chatId == 10).map((c) => c.messageId).toList(),
      <int>[42],
    );
    expect(harness.sender.copies.any((c) => c.chatId == 11), isFalse);
    expect(harness.sender.messages.last.text, contains('отправлено 1'));
    expect(harness.sender.messages.last.text, contains('в сегменте 1'));
  });

  test('cancel sends to nobody', () async {
    _seed(harness, 10, phase: FunnelPhase.warming, magnet: now);
    await _draftBroadcast(
      harness,
      BroadcastSegment.guideNotPaid,
      privateMessageUpdate(chatId: 1, userId: 1, text: 'Не слать', messageId: 43),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'bx',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.cbBroadcastCancel,
      ),
    );

    expect(harness.sender.copies.any((c) => c.chatId == 10), isFalse);
    expect(harness.sender.messages.last.text, contains('Админка'));
  });

  test('changing segment keeps the same message id and targets the new list', () async {
    _seed(harness, 10, phase: FunnelPhase.warming, magnet: now);
    _seed(harness, 11, phase: FunnelPhase.accessGranted);
    await _draftBroadcast(
      harness,
      BroadcastSegment.guideNotPaid,
      privateMessageUpdate(chatId: 1, userId: 1, text: 'Тот же черновик', messageId: 44),
    );
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'br',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.cbBroadcastOtherSegment,
      ),
    );
    await _pickSegment(harness, BroadcastSegment.paidAccess);
    expect(harness.sender.copies.last.messageId, 44);
    expect(harness.sender.messages.last.text, contains('Оплатили / доступ'));
    expect(harness.sender.messages.last.text, contains('Получателей: 1'));
    await _confirmBroadcast(harness);

    expect(
      harness.sender.copies.where((c) => c.chatId == 11).map((c) => c.messageId).toList(),
      <int>[44],
    );
    expect(harness.sender.copies.any((c) => c.chatId == 10), isFalse);
  });

  test('photo document and video in broadcast do not save the guide', () async {
    await _openBroadcast(harness);
    await _pickSegment(harness, BroadcastSegment.allStarted);

    await harness.handlers.handle(privatePhotoUpdate(chatId: 1, userId: 1, caption: 'фото'));
    expect(harness.course.activeLaunch()?.leadMagnetFileId, 'file-guide');
    expect(
      harness.sender.messages.any((m) => m.text.contains('Сохранить этот файл как гайд')),
      isFalse,
    );

    await harness.handlers.handle(
      privateDocumentUpdate(chatId: 1, userId: 1, fileId: 'not-a-guide', messageId: 51),
    );
    expect(harness.course.activeLaunch()?.leadMagnetFileId, 'file-guide');
    expect(harness.sender.copies.last.messageId, 51);
    expect(harness.sender.messages.last.text, contains('файл'));

    await harness.handlers.handle(
      privateVideoUpdate(chatId: 1, userId: 1, caption: 'ролик', messageId: 52),
    );
    expect(harness.course.activeLaunch()?.leadMagnetFileId, 'file-guide');
    expect(harness.sender.copies.last.messageId, 52);
    expect(harness.sender.messages.last.text, contains('видео'));
    expect(
      harness.sender.messages.any((m) => m.text.contains('Сохранить этот файл как гайд')),
      isFalse,
    );
  });

  test('document in idle without caption still offers to save the guide', () async {
    await harness.handlers.handle(privateDocumentUpdate(chatId: 1, userId: 1, fileId: 'new-guide'));
    expect(harness.sender.messages.last.text, contains('Сохранить этот файл как гайд'));
    await harness.handlers.handle(
      privateCallbackUpdate(
        callbackId: 'gs',
        chatId: 1,
        userId: 1,
        data: MessageTemplates.cbGuideSave,
      ),
    );
    expect(harness.course.activeLaunch()?.leadMagnetFileId, 'new-guide');
  });

  test('caption is kept by copying the original message id', () async {
    _seed(harness, 10, phase: FunnelPhase.warming, magnet: now);
    await _draftBroadcast(
      harness,
      BroadcastSegment.guideNotPaid,
      privatePhotoUpdate(chatId: 1, userId: 1, caption: 'Подпись к фото', messageId: 61),
    );
    expect(harness.sender.messages.last.text, contains('Подпись к фото'));
    expect(harness.sender.copies.single.messageId, 61);
    await _confirmBroadcast(harness);
    final sent = harness.sender.copies.where((c) => c.chatId == 10).toList();
    expect(sent, hasLength(1));
    expect(sent.single.fromChatId, 1);
    expect(sent.single.messageId, 61);
  });

  test('album is rejected and nobody is sent the broadcast', () async {
    _seed(harness, 10, phase: FunnelPhase.warming, magnet: now);
    await _openBroadcast(harness);
    await _pickSegment(harness, BroadcastSegment.guideNotPaid);
    await harness.handlers.handle(
      privatePhotoUpdate(chatId: 1, userId: 1, mediaGroupId: 'grp-1', caption: 'альбом'),
    );
    expect(harness.sender.messages.last.text, contains('не альбом'));
    expect(harness.sender.copies, isEmpty);
    await _confirmBroadcast(harness);
    expect(harness.sender.copies.any((c) => c.chatId == 10), isFalse);
    expect(harness.sender.messages.last.text, contains('Сначала пришли'));
  });

  test('empty message without attachment is rejected', () async {
    await _openBroadcast(harness);
    await _pickSegment(harness, BroadcastSegment.allStarted);
    await harness.handlers.handle(privateEmptyMessageUpdate(chatId: 1, userId: 1));
    expect(harness.sender.messages.last.text, contains('Пришли текст или файл'));
    expect(harness.sender.copies, isEmpty);
  });

  test('confirm keyboard is send / other segment / cancel, not a single hardcoded segment', () {
    final markup = templates.broadcastConfirmKeyboard();
    final texts = _inlineButtonTexts(markup);
    final data = _inlineCallbackData(markup);
    expect(texts, contains(MessageTemplates.buttonAdminBroadcastSend));
    expect(texts, contains(MessageTemplates.buttonAdminBroadcastOtherSegment));
    expect(texts, contains(MessageTemplates.buttonAdminBroadcastCancel));
    expect(texts, contains(MessageTemplates.buttonAdminBroadcastSkipOptOut));
    expect(texts.join(), isNot(contains('Гайд, без записи')));
    expect(data, contains(MessageTemplates.cbBroadcastSend));
    expect(data, contains(MessageTemplates.cbBroadcastOtherSegment));
    expect(data, contains(MessageTemplates.cbBroadcastToggleOptOut));
    expect(data, isNot(contains('bg')));
  });

  test('last message wins for the draft', () async {
    _seed(harness, 10, phase: FunnelPhase.warming, magnet: now);
    await _draftBroadcast(
      harness,
      BroadcastSegment.guideNotPaid,
      privateMessageUpdate(chatId: 1, userId: 1, text: 'первый', messageId: 71),
    );
    await harness.handlers.handle(
      privatePhotoUpdate(chatId: 1, userId: 1, caption: 'второй', messageId: 72),
    );
    await _confirmBroadcast(harness);
    expect(
      harness.sender.copies.where((c) => c.chatId == 10).map((c) => c.messageId).toList(),
      <int>[72],
    );
  });

  test('flow copyWith can clear broadcast draft fields', () {
    const state = PrivateFlowState(
      step: PrivateFlowStep.adminBroadcastCompose,
      broadcastMessageId: 5,
      broadcastPreviewText: 'x',
    );
    final cleared = state.copyWith(broadcastMessageId: null, broadcastPreviewText: null);
    expect(cleared.broadcastMessageId, isNull);
    expect(cleared.broadcastPreviewText, isNull);
    expect(cleared.step, PrivateFlowStep.adminBroadcastCompose);
  });
}

void _seed(
  HandlerHarness harness,
  int userId, {
  required FunnelPhase phase,
  DateTime? magnet,
  bool blocked = false,
  bool optOut = false,
}) {
  harness.course.ensureUser(userId: userId, now: DateTime.utc(2026, 1, 1));
  harness.course.setFunnelPhase(userId: userId, phase: phase, magnetIssuedAt: magnet);
  if (blocked) {
    harness.course.setBotBlocked(userId: userId, blocked: true);
  }
  if (optOut) {
    harness.course.setWarmupOptOut(userId: userId, optOut: true);
  }
}

Future<void> _openBroadcast(HandlerHarness harness) {
  return harness.handlers.handle(
    privateMessageUpdate(chatId: 1, userId: 1, text: MessageTemplates.buttonAdminBroadcast),
  );
}

Future<void> _pickSegment(HandlerHarness harness, BroadcastSegment segment) {
  return harness.handlers.handle(
    privateCallbackUpdate(
      callbackId: 'bs-${segment.code}',
      chatId: 1,
      userId: 1,
      data: '${MessageTemplates.cbBroadcastSegment}${segment.code}',
    ),
  );
}

Future<void> _draftBroadcast(
  HandlerHarness harness,
  BroadcastSegment segment,
  Map<String, dynamic> payload,
) async {
  await _openBroadcast(harness);
  await _pickSegment(harness, segment);
  await harness.handlers.handle(payload);
}

Future<void> _confirmBroadcast(HandlerHarness harness) {
  return harness.handlers.handle(
    privateCallbackUpdate(
      callbackId: 'bp',
      chatId: 1,
      userId: 1,
      data: MessageTemplates.cbBroadcastSend,
    ),
  );
}

List<String> _inlineButtonTexts(Map<String, Object?>? markup) {
  final rows = markup?['inline_keyboard'] as List<dynamic>? ?? const <dynamic>[];
  return <String>[
    for (final row in rows)
      for (final cell in row as List<dynamic>) (cell as Map)['text'] as String,
  ];
}

List<String> _inlineCallbackData(Map<String, Object?>? markup) {
  final rows = markup?['inline_keyboard'] as List<dynamic>? ?? const <dynamic>[];
  return <String>[
    for (final row in rows)
      for (final cell in row as List<dynamic>) (cell as Map)['callback_data'] as String,
  ];
}
