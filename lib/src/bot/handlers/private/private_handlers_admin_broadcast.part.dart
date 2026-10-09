part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersAdminBroadcast on PrivateHandlers {
  bool _isBroadcastStep(PrivateFlowStep? step) {
    return step == PrivateFlowStep.adminBroadcastSegment ||
        step == PrivateFlowStep.adminBroadcastCompose ||
        step == PrivateFlowStep.adminBroadcastButtons ||
        step == PrivateFlowStep.adminBroadcastButtonAction ||
        step == PrivateFlowStep.adminBroadcastButtonUrl ||
        step == PrivateFlowStep.adminBroadcastButtonLabel ||
        step == PrivateFlowStep.adminBroadcastPreview;
  }

  Map<BroadcastSegment, int> _broadcastCounts({bool excludeOptOut = false}) {
    return <BroadcastSegment, int>{
      for (final segment in BroadcastSegment.values)
        segment: _course.countBroadcastUsers(segment: segment, excludeOptOut: excludeOptOut),
    };
  }

  Future<bool> _presentBroadcastPicker(
    PrivateMessageContext context, {
    bool forceNewMessage = false,
    bool draftSaved = false,
  }) async {
    final chatId = context.chatId;
    final userId = context.userId;
    if (chatId == null || userId == null) {
      return false;
    }
    final flow =
        _flowByUserId[userId] ??
        const PrivateFlowState(step: PrivateFlowStep.adminBroadcastSegment);
    final counts = _broadcastCounts();
    final selected = flow.broadcastSegments;
    final recipientCount = _broadcast.listRecipients(segments: selected).length;
    final text = _templates.adminBroadcastPickSegment(
      counts,
      selected: selected,
      recipientCount: recipientCount,
      draftSaved: draftSaved,
    );
    final richHtml = _templates.adminBroadcastPickSegmentRich(
      counts,
      selected: selected,
      recipientCount: recipientCount,
      draftSaved: draftSaved,
    );
    final markup = _templates.broadcastSegmentKeyboard(counts, selected: selected);
    final messageId = forceNewMessage ? null : flow.broadcastPickerMessageId;
    if (messageId != null) {
      try {
        await _editHtml(
          chatId,
          messageId: messageId,
          text: text,
          richHtml: richHtml,
          replyMarkup: markup,
        );
        return true;
      } on TelegramApiException catch (error, stackTrace) {
        if (error.message.toLowerCase().contains('not modified')) {
          return true;
        }
        l.w('Broadcast picker edit failed: $error', stackTrace);
      } on Object catch (error, stackTrace) {
        l.w('Broadcast picker edit failed: $error', stackTrace);
      }
    }
    final sentId = await _sendHtml(chatId, text, richHtml: richHtml, replyMarkup: markup);
    final latest =
        _flowByUserId[userId] ??
        const PrivateFlowState(step: PrivateFlowStep.adminBroadcastSegment);
    _flowByUserId[userId] = latest.copyWith(broadcastPickerMessageId: sentId);
    return true;
  }

  Future<bool> _toggleBroadcastSegment(
    PrivateMessageContext context,
    BroadcastSegment? segment,
  ) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || segment == null) {
      return false;
    }
    final previous =
        _flowByUserId[context.userId!] ??
        const PrivateFlowState(step: PrivateFlowStep.adminBroadcastSegment);
    final next = Set<BroadcastSegment>.from(previous.broadcastSegments);
    if (!next.add(segment)) {
      next.remove(segment);
    }
    _flowByUserId[context.userId!] = previous.copyWith(
      step: PrivateFlowStep.adminBroadcastSegment,
      broadcastSegments: next,
    );
    return _presentBroadcastPicker(context);
  }

  Future<bool> _toggleAllBroadcastSegments(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final previous =
        _flowByUserId[context.userId!] ??
        const PrivateFlowState(step: PrivateFlowStep.adminBroadcastSegment);
    final next = BroadcastSegment.coversAll(previous.broadcastSegments)
        ? <BroadcastSegment>{}
        : BroadcastSegment.values.toSet();
    _flowByUserId[context.userId!] = previous.copyWith(
      step: PrivateFlowStep.adminBroadcastSegment,
      broadcastSegments: next,
    );
    return _presentBroadcastPicker(context);
  }

  Future<bool> _confirmBroadcastSegments(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final previous = _flowByUserId[context.userId!];
    if (previous == null || !previous.hasBroadcastSegments) {
      return _presentBroadcastPicker(context);
    }
    final resume = previous.broadcastResumePreview && previous.hasBroadcastDraft;
    _flowByUserId[context.userId!] = previous.copyWith(broadcastResumePreview: false);
    if (resume) {
      return _showBroadcastPreview(context);
    }
    return _presentBroadcastCompose(context, forceNew: true);
  }

  Future<bool> _captureBroadcastDraft(PrivateMessageContext context) async {
    final userId = context.userId!;
    final step = _flowByUserId[userId]?.step;
    if (step == PrivateFlowStep.adminBroadcastButtonLabel) {
      return _captureBroadcastButtonLabel(context);
    }
    if (step == PrivateFlowStep.adminBroadcastButtonUrl) {
      return _captureBroadcastButtonUrl(context);
    }
    if (step == PrivateFlowStep.adminBroadcastButtonAction) {
      return _presentBroadcastButtonAction(context);
    }
    final message = context.message;
    if (message == null) {
      return false;
    }
    if (_pendingBroadcastAlbums.containsKey(userId) && !isTelegramAlbum(message)) {
      await _flushBroadcastAlbum(userId, present: false);
    }
    if (isTelegramAlbum(message)) {
      return _bufferBroadcastAlbum(context);
    }
    final kind = broadcastContentKindOf(message);
    final messageId = asTelegramInt(message['message_id']);
    final chatId = context.chatId;
    if (kind == null || messageId == null || chatId == null) {
      return _send(context, _templates.adminBroadcastEmptyRejected());
    }
    final stored = _storeBroadcastPart(
      userId,
      BroadcastDraftPart(messageIds: <int>[messageId], kind: kind, previewText: context.text),
      chatId: chatId,
    );
    if (!stored) {
      return _presentBroadcastCompose(context, notice: _broadcastLimitNotice);
    }
    return _refreshBroadcastComposer(context);
  }

  Future<bool> _refreshBroadcastComposer(PrivateMessageContext context, {String? notice}) async {
    final flow = _flowByUserId[context.userId!];
    if (flow == null) {
      return false;
    }
    if (!flow.hasBroadcastSegments) {
      return _presentBroadcastPicker(context, draftSaved: flow.hasBroadcastDraft);
    }
    return _presentBroadcastCompose(context, notice: notice);
  }

  bool _storeBroadcastPart(int userId, BroadcastDraftPart part, {required int chatId}) {
    final flow = _flowByUserId[userId];
    if (flow == null || flow.broadcastParts.length >= BroadcastDraftPart.maxCount) {
      return false;
    }
    _flowByUserId[userId] = flow.copyWith(
      broadcastParts: <BroadcastDraftPart>[...flow.broadcastParts, part],
      broadcastFromChatId: flow.broadcastFromChatId ?? chatId,
    );
    return true;
  }

  Future<bool> _presentBroadcastCompose(
    PrivateMessageContext context, {
    bool forceNew = false,
    String? notice,
  }) async {
    final flow = _flowByUserId[context.userId!];
    final parts = flow?.broadcastParts ?? const <BroadcastDraftPart>[];
    return _presentBroadcastControl(
      context,
      step: PrivateFlowStep.adminBroadcastCompose,
      text: _templates.adminBroadcastCompose(parts, notice: notice),
      richHtml: _templates.adminBroadcastComposeRich(parts, notice: notice),
      replyMarkup: _templates.broadcastComposeKeyboard(hasParts: parts.isNotEmpty),
      forceNew: forceNew,
    );
  }

  Future<bool> _presentBroadcastButtons(PrivateMessageContext context) async {
    final flow = _flowByUserId[context.userId!];
    final buttons = flow?.broadcastButtons ?? const <BroadcastButton>[];
    final parts = flow?.broadcastParts ?? const <BroadcastDraftPart>[];
    final blocked = !broadcastButtonsAttachable(parts: parts, buttons: buttons);
    return _presentBroadcastControl(
      context,
      step: PrivateFlowStep.adminBroadcastButtons,
      text: _templates.adminBroadcastButtons(buttons, albumBlocksButtons: blocked),
      richHtml: _templates.adminBroadcastButtonsRich(buttons, albumBlocksButtons: blocked),
      replyMarkup: _templates.broadcastButtonsKeyboard(buttons),
    );
  }

  Future<bool> _presentBroadcastButtonAction(PrivateMessageContext context) async {
    return _presentBroadcastControl(
      context,
      step: PrivateFlowStep.adminBroadcastButtonAction,
      text: _templates.adminBroadcastButtonActions(),
      richHtml: _templates.adminBroadcastButtonActionsRich(),
      replyMarkup: _templates.broadcastButtonActionKeyboard(),
    );
  }

  Future<bool> _presentBroadcastButtonLabel(PrivateMessageContext context, {String? notice}) async {
    final action = _flowByUserId[context.userId!]?.broadcastPendingAction;
    if (action == null) {
      return _presentBroadcastButtons(context);
    }
    final suggestion = _templates.broadcastSuggestedLabel(action, launch: _launch);
    return _presentBroadcastControl(
      context,
      step: PrivateFlowStep.adminBroadcastButtonLabel,
      text: _templates.adminBroadcastButtonLabel(action, suggestion: suggestion, notice: notice),
      richHtml: _templates.adminBroadcastButtonLabelRich(
        action,
        suggestion: suggestion,
        notice: notice,
      ),
      replyMarkup: _templates.broadcastButtonLabelKeyboard(canKeep: suggestion != null),
    );
  }

  Future<bool> _presentBroadcastButtonUrl(PrivateMessageContext context, {String? notice}) async {
    return _presentBroadcastControl(
      context,
      step: PrivateFlowStep.adminBroadcastButtonUrl,
      text: _templates.adminBroadcastButtonUrl(notice: notice),
      richHtml: _templates.adminBroadcastButtonUrlRich(notice: notice),
      replyMarkup: _templates.broadcastButtonUrlKeyboard(),
    );
  }

  Future<bool> _presentBroadcastControl(
    PrivateMessageContext context, {
    required PrivateFlowStep step,
    required String text,
    required String richHtml,
    required Map<String, Object?> replyMarkup,
    bool forceNew = false,
  }) async {
    final chatId = context.chatId;
    final userId = context.userId;
    if (chatId == null || userId == null) {
      return false;
    }
    if (forceNew) {
      await _deleteBroadcastControl(userId, chatId);
    }
    final flow =
        _flowByUserId[userId] ??
        const PrivateFlowState(step: PrivateFlowStep.adminBroadcastCompose);
    final messageId = flow.broadcastControlMessageId;
    if (messageId != null) {
      try {
        await _editHtml(
          chatId,
          messageId: messageId,
          text: text,
          richHtml: richHtml,
          replyMarkup: replyMarkup,
        );
        _flowByUserId[userId] = (_flowByUserId[userId] ?? flow).copyWith(step: step);
        return true;
      } on TelegramApiException catch (error, stackTrace) {
        if (error.message.toLowerCase().contains('not modified')) {
          _flowByUserId[userId] = (_flowByUserId[userId] ?? flow).copyWith(step: step);
          return true;
        }
        l.w('Broadcast control edit failed: $error', stackTrace);
      } on Object catch (error, stackTrace) {
        l.w('Broadcast control edit failed: $error', stackTrace);
      }
    }
    final sentId = await _sendHtml(chatId, text, richHtml: richHtml, replyMarkup: replyMarkup);
    final latest = _flowByUserId[userId] ?? flow;
    _flowByUserId[userId] = latest.copyWith(step: step, broadcastControlMessageId: sentId);
    return true;
  }

  Future<void> _deleteBroadcastControl(int userId, int chatId) async {
    final id = _flowByUserId[userId]?.broadcastControlMessageId;
    if (id == null) {
      return;
    }
    _flowByUserId[userId] = _flowByUserId[userId]!.copyWith(broadcastControlMessageId: null);
    try {
      await _sender.deleteMessage(chatId, messageId: id);
    } on Object catch (error, stackTrace) {
      l.w('Broadcast control delete failed: $error', stackTrace);
    }
  }

  Future<bool> _openBroadcastButtons(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final flow = _flowByUserId[context.userId!];
    if (flow == null || !flow.hasBroadcastDraft) {
      return _presentBroadcastCompose(context, forceNew: true);
    }
    return _presentBroadcastButtons(context);
  }

  Future<bool> _finishBroadcastButtons(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final flow = _flowByUserId[context.userId!];
    if (flow == null || !flow.hasBroadcastDraft) {
      return _presentBroadcastCompose(context, forceNew: true);
    }
    return _showBroadcastPreview(context);
  }

  Future<bool> _backToBroadcastMessages(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    return _presentBroadcastCompose(context);
  }

  Future<bool> _dropBroadcastPart(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final flow = _flowByUserId[context.userId!];
    if (flow == null || flow.broadcastParts.isEmpty) {
      return _presentBroadcastCompose(context);
    }
    _flowByUserId[context.userId!] = flow.copyWith(
      broadcastParts: flow.broadcastParts.sublist(0, flow.broadcastParts.length - 1),
    );
    return _presentBroadcastCompose(context);
  }

  Future<bool> _startBroadcastButton(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final flow = _flowByUserId[context.userId!];
    if (flow != null && flow.broadcastButtons.length >= BroadcastButton.maxCount) {
      return _presentBroadcastButtons(context);
    }
    return _presentBroadcastButtonAction(context);
  }

  Future<bool> _chooseBroadcastButtonAction(
    PrivateMessageContext context,
    BroadcastButtonAction? action,
  ) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || action == null) {
      return false;
    }
    final flow =
        _flowByUserId[context.userId!] ??
        const PrivateFlowState(step: PrivateFlowStep.adminBroadcastButtons);
    if (flow.broadcastButtons.length >= BroadcastButton.maxCount) {
      return _presentBroadcastButtons(context);
    }
    _flowByUserId[context.userId!] = flow.copyWith(
      broadcastPendingAction: action,
      broadcastPendingUrl: null,
    );
    if (action == BroadcastButtonAction.url) {
      return _presentBroadcastButtonUrl(context);
    }
    return _presentBroadcastButtonLabel(context);
  }

  Future<bool> _captureBroadcastButtonUrl(PrivateMessageContext context) async {
    final raw = context.message?['text'];
    if (raw is! String) {
      return _presentBroadcastButtonUrl(context, notice: 'Нужна ссылка текстом, не файл.');
    }
    final url = BroadcastButton.parseUrl(raw);
    if (url == null) {
      return _presentBroadcastButtonUrl(context, notice: 'Нужна ссылка http или https.');
    }
    final flow = _flowByUserId[context.userId!];
    if (flow == null) {
      return false;
    }
    _flowByUserId[context.userId!] = flow.copyWith(broadcastPendingUrl: url);
    return _presentBroadcastButtonLabel(context);
  }

  Future<bool> _keepBroadcastButtonLabel(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final action = _flowByUserId[context.userId!]?.broadcastPendingAction;
    if (action == null) {
      return _presentBroadcastButtons(context);
    }
    final suggestion = _templates.broadcastSuggestedLabel(action, launch: _launch);
    if (suggestion == null) {
      return _presentBroadcastButtonLabel(context, notice: 'Напиши текст кнопки.');
    }
    return _commitBroadcastButton(context, suggestion);
  }

  Future<bool> _captureBroadcastButtonLabel(PrivateMessageContext context) async {
    final raw = context.message?['text'];
    if (raw is! String) {
      return _presentBroadcastButtonLabel(context, notice: 'Нужен текст кнопки, не файл.');
    }
    final label = BroadcastButton.parseLabel(raw);
    if (label == null) {
      final length = raw.trim().replaceAll(RegExp(r'\s+'), ' ').length;
      final notice = length > BroadcastButton.maxLabelLength
          ? 'До ${BroadcastButton.maxLabelLength} символов. Сейчас $length.'
          : 'Напиши текст кнопки.';
      return _presentBroadcastButtonLabel(context, notice: notice);
    }
    return _commitBroadcastButton(context, label);
  }

  Future<bool> _commitBroadcastButton(PrivateMessageContext context, String label) async {
    final flow = _flowByUserId[context.userId!];
    final action = flow?.broadcastPendingAction;
    if (flow == null || action == null) {
      return _presentBroadcastButtons(context);
    }
    if (action == BroadcastButtonAction.url &&
        (flow.broadcastPendingUrl == null || flow.broadcastPendingUrl!.isEmpty)) {
      return _presentBroadcastButtonUrl(context, notice: 'Сначала пришли адрес.');
    }
    if (flow.broadcastButtons.length >= BroadcastButton.maxCount) {
      return _presentBroadcastButtons(context);
    }
    final button = BroadcastButton(
      action: action,
      label: label,
      url: action == BroadcastButtonAction.url ? flow.broadcastPendingUrl : null,
    );
    _flowByUserId[context.userId!] = flow.copyWith(
      broadcastButtons: <BroadcastButton>[...flow.broadcastButtons, button],
      broadcastPendingAction: null,
      broadcastPendingUrl: null,
    );
    return _presentBroadcastButtons(context);
  }

  Future<bool> _removeBroadcastButton(PrivateMessageContext context, int? index) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final flow = _flowByUserId[context.userId!];
    if (flow == null || index == null || index < 0 || index >= flow.broadcastButtons.length) {
      return _presentBroadcastButtons(context);
    }
    final next = <BroadcastButton>[...flow.broadcastButtons]..removeAt(index);
    _flowByUserId[context.userId!] = flow.copyWith(broadcastButtons: next);
    return _presentBroadcastButtons(context);
  }

  Future<bool> _showBroadcastPreview(PrivateMessageContext context, {bool copyDraft = true}) async {
    final userId = context.userId!;
    final flow = _flowByUserId[userId];
    final chatId = context.chatId;
    final fromChatId = flow?.broadcastFromChatId;
    final parts = flow?.broadcastParts ?? const <BroadcastDraftPart>[];
    if (flow == null || parts.isEmpty || fromChatId == null || chatId == null) {
      return _presentBroadcastCompose(context, forceNew: true);
    }
    final buttons = flow.broadcastButtons;
    final canSend = broadcastButtonsAttachable(parts: parts, buttons: buttons);
    final markup = canSend ? _templates.broadcastOutboundKeyboard(buttons) : null;
    if (copyDraft) {
      try {
        await _broadcast.copySequence(
          chatId: chatId,
          fromChatId: fromChatId,
          parts: parts,
          replyMarkup: markup,
        );
      } on Object catch (error, stackTrace) {
        l.w('Broadcast preview copy failed: $error', stackTrace);
        return _send(context, _templates.adminBroadcastCopyFailed());
      }
      await _deleteBroadcastControl(userId, chatId);
    }
    _flowByUserId[userId] = (_flowByUserId[userId] ?? flow).copyWith(
      step: PrivateFlowStep.adminBroadcastPreview,
    );
    final latest = _flowByUserId[userId]!;
    return _send(
      context,
      _templates.adminBroadcastPreview(
        segments: latest.broadcastSegments,
        recipientCount: _broadcast
            .listRecipients(
              segments: latest.broadcastSegments,
              excludeOptOut: latest.broadcastExcludeOptOut,
            )
            .length,
        parts: latest.broadcastParts,
        buttons: latest.broadcastButtons,
        canSend: canSend,
        optOutCount: _broadcast.countOptOut(segments: latest.broadcastSegments),
        excludeOptOut: latest.broadcastExcludeOptOut,
      ),
      richHtml: _templates.adminBroadcastPreviewRich(
        segments: latest.broadcastSegments,
        recipientCount: _broadcast
            .listRecipients(
              segments: latest.broadcastSegments,
              excludeOptOut: latest.broadcastExcludeOptOut,
            )
            .length,
        parts: latest.broadcastParts,
        buttons: latest.broadcastButtons,
        canSend: canSend,
        optOutCount: _broadcast.countOptOut(segments: latest.broadcastSegments),
        excludeOptOut: latest.broadcastExcludeOptOut,
      ),
      replyMarkup: _templates.broadcastConfirmKeyboard(
        excludeOptOut: latest.broadcastExcludeOptOut,
        canSend: canSend,
      ),
    );
  }

  Future<bool> _toggleBroadcastOptOut(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final previous = _flowByUserId[context.userId!];
    if (previous == null || !previous.hasBroadcastSegments) {
      return _presentBroadcastPicker(context, forceNewMessage: true);
    }
    _flowByUserId[context.userId!] = previous.copyWith(
      broadcastExcludeOptOut: !previous.broadcastExcludeOptOut,
    );
    return _showBroadcastPreview(context, copyDraft: false);
  }

  Future<bool> _reselectBroadcastSegment(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final previous = _flowByUserId[context.userId!];
    final resume = previous?.step == PrivateFlowStep.adminBroadcastPreview;
    _flowByUserId[context.userId!] =
        (previous ?? const PrivateFlowState(step: PrivateFlowStep.adminBroadcastSegment)).copyWith(
          step: PrivateFlowStep.adminBroadcastSegment,
          broadcastPickerMessageId: null,
          broadcastResumePreview: resume,
        );
    return _presentBroadcastPicker(context, forceNewMessage: true);
  }

  Future<bool> _cancelBroadcast(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    _cancelPendingBroadcastAlbum(context.userId!);
    _flowByUserId.remove(context.userId);
    return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
  }

  Future<bool> _confirmBroadcast(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final flow = _flowByUserId[context.userId!];
    final segments = flow?.broadcastSegments ?? const <BroadcastSegment>{};
    final fromChatId = flow?.broadcastFromChatId;
    final parts = flow?.broadcastParts ?? const <BroadcastDraftPart>[];
    if (segments.isEmpty) {
      return _presentBroadcastPicker(context, forceNewMessage: true);
    }
    if (fromChatId == null || parts.isEmpty) {
      return _send(context, _templates.adminBroadcastNeedDraft());
    }
    final buttons = flow?.broadcastButtons ?? const <BroadcastButton>[];
    if (!broadcastButtonsAttachable(parts: parts, buttons: buttons)) {
      return _showBroadcastPreview(context, copyDraft: false);
    }
    final excludeOptOut = flow?.broadcastExcludeOptOut ?? false;
    final markup = _templates.broadcastOutboundKeyboard(buttons);
    _cancelPendingBroadcastAlbum(context.userId!);
    _flowByUserId.remove(context.userId);
    final result = await _broadcast.send(
      segments: segments,
      fromChatId: fromChatId,
      parts: parts,
      replyMarkup: markup,
      excludeOptOut: excludeOptOut,
    );
    return _send(
      context,
      _templates.adminBroadcastDone(sent: result.sent, failed: result.failed, total: result.total),
      replyMarkup: _templates.adminMenuKeyboard(),
    );
  }

  Future<bool> _bufferBroadcastAlbum(PrivateMessageContext context) async {
    final userId = context.userId!;
    final message = context.message;
    final groupId = telegramMediaGroupId(message);
    final messageId = asTelegramInt(message?['message_id']);
    final chatId = context.chatId;
    if (groupId == null || messageId == null || chatId == null) {
      return _send(context, _templates.adminBroadcastEmptyRejected());
    }
    final existing = _pendingBroadcastAlbums[userId];
    if (existing != null && existing.mediaGroupId != groupId) {
      await _flushBroadcastAlbum(userId);
    }
    final flow = _flowByUserId[userId];
    final pending = _pendingBroadcastAlbums[userId];
    if (pending == null &&
        flow != null &&
        flow.broadcastParts.length >= BroadcastDraftPart.maxCount) {
      return _presentBroadcastCompose(context, notice: _broadcastLimitNotice);
    }
    final album = _pendingBroadcastAlbums.putIfAbsent(
      userId,
      () => _PendingBroadcastAlbum(mediaGroupId: groupId, chatId: chatId),
    );
    if (!album.messageIds.contains(messageId)) {
      album.messageIds.add(messageId);
      album.messageIds.sort();
    }
    final leaf = broadcastLeafKindOf(message);
    if (leaf != null) {
      album.leafKind = leaf;
    }
    final preview = context.text?.trim();
    if (preview != null && preview.isNotEmpty) {
      album.previewText ??= preview;
    }
    _broadcastAlbumTimers.remove(userId)?.cancel();
    _broadcastAlbumTimers[userId] = Timer(_albumCollectWindow, () {
      unawaited(_flushBroadcastAlbum(userId));
    });
    return true;
  }

  Future<void> _flushPendingBroadcastAlbums() async {
    final userIds = _pendingBroadcastAlbums.keys.toList();
    for (final userId in userIds) {
      await _flushBroadcastAlbum(userId);
    }
  }

  void _cancelPendingBroadcastAlbums() {
    for (final timer in _broadcastAlbumTimers.values) {
      timer.cancel();
    }
    _broadcastAlbumTimers.clear();
    _pendingBroadcastAlbums.clear();
  }

  void _cancelPendingBroadcastAlbum(int userId) {
    _broadcastAlbumTimers.remove(userId)?.cancel();
    _pendingBroadcastAlbums.remove(userId);
  }

  Future<bool> _flushBroadcastAlbum(int userId, {bool present = true}) async {
    _broadcastAlbumTimers.remove(userId)?.cancel();
    final pending = _pendingBroadcastAlbums.remove(userId);
    if (pending == null || pending.messageIds.isEmpty) {
      return false;
    }
    final flow = _flowByUserId[userId];
    if (flow == null || !_isBroadcastStep(flow.step)) {
      return false;
    }
    final ids = pending.messageIds;
    final stored = _storeBroadcastPart(
      userId,
      BroadcastDraftPart(
        messageIds: ids,
        kind: ids.length > 1 ? BroadcastContentKind.album : pending.leafKind,
        previewText: pending.previewText,
      ),
      chatId: pending.chatId,
    );
    if (!present) {
      return stored;
    }
    final context = _adminContext(userId: userId, chatId: pending.chatId);
    if (!stored) {
      return _presentBroadcastCompose(context, notice: _broadcastLimitNotice);
    }
    return _refreshBroadcastComposer(context);
  }
}

const String _broadcastLimitNotice = 'В одной рассылке не больше 10 сообщений.';

final class _PendingBroadcastAlbum {
  _PendingBroadcastAlbum({required this.mediaGroupId, required this.chatId});

  final String mediaGroupId;
  final int chatId;
  final List<int> messageIds = <int>[];
  String? previewText;
  BroadcastContentKind leafKind = BroadcastContentKind.album;
}
