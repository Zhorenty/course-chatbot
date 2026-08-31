part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersAdmin on PrivateHandlers {
  Future<bool> _handleAdminMessage(PrivateMessageContext context) async {
    final userId = context.userId!;
    final text = context.text;
    final flow = _flowByUserId[userId];
    if (text == MessageTemplates.buttonAdminMenu || text == '/admin') {
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.idle);
      return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
    }
    if (text == MessageTemplates.buttonAdminSearch) {
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.adminSearch);
      return _send(
        context,
        _templates.adminAskSearch(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }
    if (text == MessageTemplates.buttonAdminAddUser) {
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.adminAddUser);
      return _send(
        context,
        _templates.adminAskAddUser(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }
    if (text == MessageTemplates.buttonAdminBroadcast) {
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.adminBroadcastSegment);
      return _showBroadcastPicker(context);
    }
    if (text == MessageTemplates.buttonAdminSheets || text == '/sheets') {
      return _adminRefreshSheets(context);
    }
    if (text == MessageTemplates.buttonAdminLinks || text == '/links') {
      return _adminShowDeepLinks(context);
    }
    if (_isBroadcastStep(flow?.step)) {
      return _captureBroadcastDraft(context);
    }
    if (flow?.step == PrivateFlowStep.adminComposeDm) {
      return _sendAdminDm(context);
    }
    final step = flow?.step ?? PrivateFlowStep.idle;
    final fileId = extractDocumentFileId(context.message);
    if (step == PrivateFlowStep.idle && fileId != null && text == null) {
      _flowByUserId[userId] = PrivateFlowState(
        step: PrivateFlowStep.adminGuideConfirm,
        pendingGuideFileId: fileId,
      );
      return _send(
        context,
        _templates.adminGuideConfirm(fileId),
        replyMarkup: _templates.guideConfirmKeyboard(),
      );
    }
    if (flow?.step == PrivateFlowStep.adminSearch || flow?.step == PrivateFlowStep.adminAddUser) {
      return _handleAdminPersonLookup(
        context,
        createIfMissing: flow?.step == PrivateFlowStep.adminAddUser,
      );
    }
    return false;
  }

  Future<bool> _adminRefreshSheets(PrivateMessageContext context) async {
    final sync = _catalogSync;
    final job = _sheetsExportJob;
    if (sync == null && job == null) {
      return _send(
        context,
        _templates.adminSheetsDisabled(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }

    CatalogSyncResult? catalogResult;
    String? catalogError;
    if (sync != null) {
      try {
        catalogResult = await sync.sync();
        if (!catalogResult.ok) {
          catalogError = catalogResult.error;
        }
      } on Object catch (error, stackTrace) {
        l.w('Admin COURSES catalog refresh failed: $error', stackTrace);
        catalogError = '$error';
      }
    }

    var funnelOk = job == null;
    String? funnelError;
    if (job != null) {
      try {
        await job.export();
        funnelOk = true;
      } on Object catch (error, stackTrace) {
        l.w('Admin Google Sheets ВОРОНКА refresh failed: $error', stackTrace);
        funnelOk = false;
        funnelError = '$error';
      }
    }

    return _send(
      context,
      _templates.adminSheetsRefreshResult(
        catalogAttempted: sync != null,
        catalogOk: sync == null || catalogError == null,
        catalogError: catalogError,
        funnelAttempted: job != null,
        funnelOk: funnelOk,
        funnelError: funnelError,
        launch: catalogResult?.launch ?? _launch,
      ),
      replyMarkup: _templates.adminMenuKeyboard(),
    );
  }

  Future<bool> _adminShowDeepLinks(PrivateMessageContext context) async {
    final sync = _catalogSync;
    if (sync != null) {
      try {
        await sync.sync();
      } on Object catch (error, stackTrace) {
        l.w('Admin ССЫЛКИ sync failed: $error', stackTrace);
      }
    }
    return _send(
      context,
      _templates.adminDeepLinks(_funnel.links.entries),
      replyMarkup: _templates.adminMenuKeyboard(),
    );
  }

  Future<bool> _handleAdminPersonLookup(
    PrivateMessageContext context, {
    required bool createIfMissing,
  }) async {
    final forwarded = extractForwardedUser(context.message);
    if (forwarded != null) {
      if (createIfMissing) {
        return _adminEnsureAndShowCard(
          context,
          forwarded.userId,
          username: forwarded.username,
          firstName: forwarded.firstName,
        );
      }
      final existing = _course.getUser(forwarded.userId);
      if (existing != null) {
        return _presentAdminCard(context, existing);
      }
      return _send(
        context,
        _templates.adminNotFound('${forwarded.userId}', canCreate: true),
        replyMarkup: _templates.adminCreateUserKeyboard(forwarded.userId),
      );
    }
    final query = context.text;
    if (query == null || query.isEmpty) {
      return _send(
        context,
        _templates.adminNeedNumericId(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }
    if (createIfMissing) {
      final asId = parseTelegramUserId(query);
      if (asId != null) {
        return _adminEnsureAndShowCard(context, asId);
      }
      final matches = _course.searchUsers(query);
      if (matches.isNotEmpty) {
        return _presentAdminCard(context, matches.first);
      }
      return _send(
        context,
        _templates.adminNeedNumericId(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }
    return _showAdminCard(context, query);
  }

  Future<bool> _adminEnsureAndShowCard(
    PrivateMessageContext context,
    int targetUserId, {
    String? username,
    String? firstName,
  }) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId <= 0) {
      return false;
    }
    var user = _course.getUser(targetUserId);
    user ??= _course.ensureUser(
      userId: targetUserId,
      username: username,
      firstName: firstName,
      source: AcquisitionSource.adminManual,
      now: _nowProvider(),
    );
    return _presentAdminCard(context, user);
  }

  Future<bool> _showAdminCard(PrivateMessageContext context, String query) async {
    final matches = _course.searchUsers(query);
    if (matches.isEmpty) {
      final asId = parseTelegramUserId(query);
      if (asId != null) {
        return _send(
          context,
          _templates.adminNotFound(query, canCreate: true),
          replyMarkup: _templates.adminCreateUserKeyboard(asId),
        );
      }
      return _send(
        context,
        _templates.adminNotFound(query),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }
    if (matches.length > 1) {
      return _send(
        context,
        _templates.adminSearchMatches(matches),
        replyMarkup: _templates.adminSearchMatchesKeyboard(matches),
      );
    }
    return _presentAdminCard(context, matches.first);
  }

  Future<bool> _presentAdminCard(PrivateMessageContext context, UserProfile user) async {
    final launch = _launch;
    final enrollment =
        _funnel.enrollmentFor(user.userId, launch: launch) ??
        (launch == null
            ? null
            : UserEnrollment(
                userId: user.userId,
                launchId: launch.id,
                funnelPhase: FunnelPhase.lead,
                startedAt: user.firstStartedAt,
              ));
    final order = launch == null
        ? _course.latestOrder(user.userId)
        : _course.latestOrder(user.userId, launchId: launch.id);
    final access = launch == null
        ? null
        : _course.accessFor(userId: user.userId, launchId: launch.id);
    final dialog = _course.dialogForUser(user.userId);
    _flowByUserId[context.userId!] = PrivateFlowState(
      step: PrivateFlowStep.idle,
      adminTargetUserId: user.userId,
    );
    return _send(
      context,
      _templates.adminCard(
        user: user,
        enrollment: enrollment,
        order: order,
        access: access,
        dialog: dialog,
      ),
      replyMarkup: _templates.adminCardKeyboard(user.userId),
    );
  }

  Future<bool> _adminAskConfirm(
    PrivateMessageContext context,
    int? targetUserId, {
    required _AdminConfirmKind kind,
  }) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final (text, yesPrefix) = switch (kind) {
      _AdminConfirmKind.paid => (
        _templates.adminConfirmMarkPaid(targetUserId),
        MessageTemplates.cbAdminPaidConfirm,
      ),
      _AdminConfirmKind.deposit => (
        _templates.adminConfirmMarkDeposit(targetUserId),
        MessageTemplates.cbAdminDepositConfirm,
      ),
      _AdminConfirmKind.cancel => (
        _templates.adminConfirmCancel(targetUserId),
        MessageTemplates.cbAdminCancelConfirm,
      ),
    };
    return _send(
      context,
      text,
      replyMarkup: _templates.adminConfirmKeyboard(
        yesData: '$yesPrefix$targetUserId',
        noData: '${MessageTemplates.cbAdminActionAbort}$targetUserId',
      ),
    );
  }

  Future<bool> _adminAbortConfirm(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    return _showAdminCard(context, '$targetUserId');
  }

  Future<bool> _adminAskDm(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    _flowByUserId[context.userId!] = PrivateFlowState(
      step: PrivateFlowStep.adminComposeDm,
      adminTargetUserId: targetUserId,
    );
    return _send(context, _templates.adminAskDm(targetUserId));
  }

  Future<bool> _sendAdminDm(PrivateMessageContext context) async {
    final targetId = _flowByUserId[context.userId!]?.adminTargetUserId;
    final text = context.text?.trim();
    _flowByUserId[context.userId!] = const PrivateFlowState(step: PrivateFlowStep.idle);
    if (targetId == null || text == null || text.isEmpty) {
      return _send(context, _templates.adminDmEmpty());
    }
    try {
      await _sender.sendMessage(targetId, text, disableNotification: false);
      await _send(context, _templates.adminDmSent(targetId));
    } on Object catch (error, stackTrace) {
      l.w('Admin DM to $targetId failed: $error', stackTrace);
      await _send(context, _templates.adminDmFailed(targetId));
    }
    final user = _course.getUser(targetId);
    if (user == null) {
      return true;
    }
    return _presentAdminCard(context, user);
  }

  Future<bool> _adminMarkPaid(
    PrivateMessageContext context,
    int? targetUserId,
    PaymentKind kind,
  ) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final launch = _launch;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    _course.ensureUser(userId: targetUserId, now: _nowProvider());
    final order = _checkout.startOrReuseOrder(userId: targetUserId, launch: launch, kind: kind);
    final amount = _checkout.amountFor(launch, order, kind);
    final result = await _checkout.applyManualPaid(
      order: order,
      launch: launch,
      kind: kind,
      amountKopecks: amount <= 0 ? launch.priceFullKopecks : amount,
    );
    await _notifyPaymentResult(result);
    await _send(context, _templates.adminMarkedPaid());
    final user = _course.getUser(targetUserId);
    if (user == null) {
      return true;
    }
    return _presentAdminCard(context, user);
  }

  Future<bool> _adminCancel(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final user = _course.getUser(targetUserId);
    if (user == null) {
      return _send(context, _templates.adminNotFound('$targetUserId'));
    }
    final launch = _launch;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    await _checkout.cancelEnrollment(userId: targetUserId, launch: launch);
    await _send(context, _templates.adminCancelled());
    return _presentAdminCard(context, _course.getUser(targetUserId)!);
  }

  Future<bool> _adminReinvite(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final launch = _launch;
    final order = launch == null ? null : _course.latestOrder(targetUserId, launchId: launch.id);
    if (launch == null || order == null) {
      return false;
    }
    final link = await _access.issueInvite(
      userId: targetUserId,
      orderId: order.id,
      launch: launch,
      reissue: true,
    );
    if (link != null) {
      await _sender.sendMessage(
        targetUserId,
        _templates.inviteMessage(link),
        parseMode: 'HTML',
        replyMarkup: _templates.unjoinedInviteKeyboard(link),
      );
    }
    await _send(
      context,
      link == null ? _templates.inviteUnavailable() : _templates.adminInviteReissued(),
    );
    final user = _course.getUser(targetUserId);
    if (user == null) {
      return true;
    }
    return _presentAdminCard(context, user);
  }

  bool _isBroadcastStep(PrivateFlowStep? step) {
    return step == PrivateFlowStep.adminBroadcastSegment ||
        step == PrivateFlowStep.adminBroadcastCompose;
  }

  Map<BroadcastSegment, int> _broadcastCounts({bool excludeOptOut = false}) {
    final sources = _funnel.links.courseEntryPayloads;
    return <BroadcastSegment, int>{
      for (final segment in BroadcastSegment.values)
        segment: _course.countBroadcastUsers(
          segment: segment,
          excludeOptOut: excludeOptOut,
          courseEntrySources: sources,
        ),
    };
  }

  int _broadcastOptOutCount(BroadcastSegment segment) {
    final sources = _funnel.links.courseEntryPayloads;
    return _course.countBroadcastUsers(segment: segment, courseEntrySources: sources) -
        _course.countBroadcastUsers(
          segment: segment,
          excludeOptOut: true,
          courseEntrySources: sources,
        );
  }

  Future<bool> _showBroadcastPicker(PrivateMessageContext context) {
    final counts = _broadcastCounts();
    return _send(
      context,
      _templates.adminBroadcastPickSegment(counts),
      replyMarkup: _templates.broadcastSegmentKeyboard(counts),
    );
  }

  Future<bool> _selectBroadcastSegment(
    PrivateMessageContext context,
    BroadcastSegment? segment,
  ) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || segment == null) {
      return false;
    }
    final previous =
        _flowByUserId[context.userId!] ??
        const PrivateFlowState(step: PrivateFlowStep.adminBroadcastCompose);
    _flowByUserId[context.userId!] = previous.copyWith(
      step: PrivateFlowStep.adminBroadcastCompose,
      broadcastSegment: segment,
    );
    if (previous.hasBroadcastDraft) {
      return _showBroadcastPreview(context);
    }
    return _send(
      context,
      _templates.adminAskBroadcastContent(),
      replyMarkup: _templates.adminMenuKeyboard(),
    );
  }

  Future<bool> _captureBroadcastDraft(PrivateMessageContext context) async {
    final userId = context.userId!;
    final message = context.message;
    if (message == null) {
      return false;
    }
    if (isTelegramAlbum(message)) {
      return _send(context, _templates.adminBroadcastAlbumRejected());
    }
    final kind = broadcastContentKindOf(message);
    if (kind == null) {
      return _send(context, _templates.adminBroadcastEmptyRejected());
    }
    final messageId = asTelegramInt(message['message_id']);
    final chatId = context.chatId;
    if (messageId == null || chatId == null) {
      return _send(context, _templates.adminBroadcastEmptyRejected());
    }
    final previous =
        _flowByUserId[userId] ??
        const PrivateFlowState(step: PrivateFlowStep.adminBroadcastSegment);
    final hasSegment = previous.broadcastSegment != null;
    _flowByUserId[userId] = previous.copyWith(
      step: hasSegment ? PrivateFlowStep.adminBroadcastCompose : previous.step,
      broadcastFromChatId: chatId,
      broadcastMessageId: messageId,
      broadcastContentKind: kind,
      broadcastPreviewText: context.text,
    );
    if (!hasSegment) {
      final counts = _broadcastCounts();
      return _send(
        context,
        _templates.adminBroadcastDraftSavedPickSegment(),
        replyMarkup: _templates.broadcastSegmentKeyboard(counts),
      );
    }
    return _showBroadcastPreview(context);
  }

  Future<bool> _showBroadcastPreview(PrivateMessageContext context) async {
    final flow = _flowByUserId[context.userId!];
    final segment = flow?.broadcastSegment;
    final fromChatId = flow?.broadcastFromChatId;
    final messageId = flow?.broadcastMessageId;
    final kind = flow?.broadcastContentKind;
    final chatId = context.chatId;
    if (flow == null ||
        segment == null ||
        fromChatId == null ||
        messageId == null ||
        kind == null ||
        chatId == null) {
      return _showBroadcastPicker(context);
    }
    try {
      await _sender.copyMessage(chatId: chatId, fromChatId: fromChatId, messageId: messageId);
    } on Object catch (error, stackTrace) {
      l.w('Broadcast preview copy failed: $error', stackTrace);
      return _send(context, _templates.adminBroadcastCopyFailed());
    }
    return _send(
      context,
      _templates.adminBroadcastPreview(
        segment: segment,
        recipientCount: _course.countBroadcastUsers(
          segment: segment,
          excludeOptOut: flow.broadcastExcludeOptOut,
          courseEntrySources: _funnel.links.courseEntryPayloads,
        ),
        kind: kind,
        previewText: flow.broadcastPreviewText,
        optOutCount: _broadcastOptOutCount(segment),
        excludeOptOut: flow.broadcastExcludeOptOut,
      ),
      replyMarkup: _templates.broadcastConfirmKeyboard(excludeOptOut: flow.broadcastExcludeOptOut),
    );
  }

  Future<bool> _toggleBroadcastOptOut(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final previous = _flowByUserId[context.userId!];
    if (previous == null || previous.broadcastSegment == null) {
      return _showBroadcastPicker(context);
    }
    _flowByUserId[context.userId!] = previous.copyWith(
      broadcastExcludeOptOut: !previous.broadcastExcludeOptOut,
    );
    return _showBroadcastPreview(context);
  }

  Future<bool> _reselectBroadcastSegment(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final previous = _flowByUserId[context.userId!];
    _flowByUserId[context.userId!] =
        (previous ?? const PrivateFlowState(step: PrivateFlowStep.adminBroadcastSegment)).copyWith(
          step: PrivateFlowStep.adminBroadcastSegment,
        );
    return _showBroadcastPicker(context);
  }

  Future<bool> _cancelBroadcast(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    _flowByUserId.remove(context.userId);
    return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
  }

  Future<bool> _confirmBroadcast(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final flow = _flowByUserId[context.userId!];
    final segment = flow?.broadcastSegment;
    final fromChatId = flow?.broadcastFromChatId;
    final messageId = flow?.broadcastMessageId;
    if (segment == null) {
      return _showBroadcastPicker(context);
    }
    if (fromChatId == null || messageId == null) {
      return _send(context, _templates.adminBroadcastNeedDraft());
    }
    _flowByUserId.remove(context.userId);
    final result = await _broadcast.send(
      segment: segment,
      fromChatId: fromChatId,
      messageId: messageId,
      excludeOptOut: flow?.broadcastExcludeOptOut ?? false,
      courseEntrySources: _funnel.links.courseEntryPayloads,
    );
    return _send(
      context,
      _templates.adminBroadcastDone(sent: result.sent, failed: result.failed, total: result.total),
      replyMarkup: _templates.adminMenuKeyboard(),
    );
  }

  Future<bool> _savePendingGuide(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final fileId = _flowByUserId[context.userId!]?.pendingGuideFileId;
    _flowByUserId.remove(context.userId);
    if (fileId == null || fileId.isEmpty) {
      return _send(context, _templates.adminGuideDiscarded());
    }
    _course.setLeadMagnetFileId(fileId);
    return _send(
      context,
      _templates.adminGuideSaved(fileId),
      replyMarkup: _templates.adminMenuKeyboard(),
    );
  }
}
