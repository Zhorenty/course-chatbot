part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersAdmin on PrivateHandlers {
  Future<bool> _handleAdminMessage(PrivateMessageContext context) async {
    final userId = context.userId!;
    final text = context.text;
    final flow = _flowByUserId[userId];
    if (text == MessageTemplates.buttonAdminMenu || text == '/admin') {
      if (_isSheetsSection(flow?.step)) {
        await _deleteInboundMessage(context);
      }
      await _dismissCatalogUi(context);
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.idle);
      return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
    }
    if (text == MessageTemplates.buttonAdminBack && _isSheetsSection(flow?.step)) {
      return _leaveSheetsSection(context);
    }
    if (text == MessageTemplates.buttonAdminBroadcastCancel && _isSheetsSection(flow?.step)) {
      return _leaveSheetsSection(context);
    }
    if (text == MessageTemplates.buttonAdminSheetsHub) {
      return _openSheetsHub(context);
    }
    if (text == MessageTemplates.buttonAdminCatalog) {
      return _openCatalogFromMenu(context);
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
      return _presentBroadcastPicker(context, forceNewMessage: true);
    }
    if (text == MessageTemplates.buttonAdminSheets || text == '/sheets') {
      return _adminRefreshSheets(context, keepHub: _isSheetsSection(flow?.step));
    }
    if (text == MessageTemplates.buttonAdminLinks || text == '/links') {
      return _openLinksFromMenu(context);
    }
    // TODO(mvp-reset): remove this branch with the clear-funnel button.
    if (text == MessageTemplates.buttonAdminClearFunnel) {
      return _adminAskClearFunnel(context);
    }
    if (_isBroadcastStep(flow?.step)) {
      return _captureBroadcastDraft(context);
    }
    if (_isCatalogStep(flow?.step)) {
      return _captureCatalog(context);
    }
    if (_isLinksStep(flow?.step)) {
      return _captureLinks(context);
    }
    if (flow?.step == PrivateFlowStep.adminSheetsHub) {
      await _deleteInboundMessage(context);
      return true;
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

  Future<bool> _openSheetsHub(PrivateMessageContext context) async {
    await _deleteInboundMessage(context);
    await _dismissCatalogUi(context);
    _flowByUserId[context.userId!] = const PrivateFlowState(step: PrivateFlowStep.adminSheetsHub);
    await _pinSheetsHub(context);
    return _presentCatalog(context, _templates.adminSheetsHub());
  }

  Future<bool> _leaveSheetsSection(PrivateMessageContext context) async {
    await _deleteInboundMessage(context);
    final step = _flowByUserId[context.userId!]?.step;
    if (step != PrivateFlowStep.adminSheetsHub && _isSheetsSection(step)) {
      await _ensureSheetsHubPinned(context);
      _flowByUserId[context.userId!] = PrivateFlowState(
        step: PrivateFlowStep.adminSheetsHub,
        catalogMessageId: _flowByUserId[context.userId!]?.catalogMessageId,
        catalogPinMessageId: _flowByUserId[context.userId!]?.catalogPinMessageId,
      );
      return _presentCatalog(context, _templates.adminSheetsHub());
    }
    await _dismissCatalogUi(context);
    _flowByUserId[context.userId!] = const PrivateFlowState(step: PrivateFlowStep.idle);
    return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
  }

  bool _isSheetsSection(PrivateFlowStep? step) {
    return step == PrivateFlowStep.adminSheetsHub || _isCatalogStep(step) || _isLinksStep(step);
  }

  Future<bool> _adminRefreshSheets(PrivateMessageContext context, {bool keepHub = false}) async {
    final sync = _catalogSync;
    final job = _sheetsExportJob;
    if (sync == null && job == null) {
      if (keepHub) {
        return _presentCatalog(context, _templates.adminSheetsDisabled());
      }
      return _send(
        context,
        _templates.adminSheetsDisabled(),
        replyMarkup: _templates.adminMenuKeyboard(),
      );
    }

    final progressId = await _sendProgress(context, _templates.adminSheetsRefreshing());
    CatalogSyncResult? catalogResult;
    String? catalogError;
    var funnelOk = job == null;
    String? funnelError;
    try {
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
    } finally {
      await _deleteProgress(context, progressId);
    }

    final result = _templates.adminSheetsRefreshResult(
      catalogAttempted: sync != null,
      catalogOk: sync == null || catalogError == null,
      catalogError: catalogError,
      funnelAttempted: job != null,
      funnelOk: funnelOk,
      funnelError: funnelError,
      launch: catalogResult?.launch ?? _launch,
    );
    if (keepHub) {
      await _deleteInboundMessage(context);
      await _ensureSheetsHubPinned(context);
      _flowByUserId[context.userId!] = PrivateFlowState(
        step: PrivateFlowStep.adminSheetsHub,
        catalogMessageId: _flowByUserId[context.userId!]?.catalogMessageId,
        catalogPinMessageId: _flowByUserId[context.userId!]?.catalogPinMessageId,
      );
      return _presentCatalog(context, result);
    }
    return _send(context, result, replyMarkup: _templates.adminMenuKeyboard());
  }

  // TODO(mvp-reset): remove with the admin «Очистить воронку» button.
  Future<bool> _adminAskClearFunnel(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    return _send(
      context,
      _templates.adminAskClearFunnel(),
      replyMarkup: _templates.adminConfirmKeyboard(
        yesData: MessageTemplates.cbAdminClearFunnelConfirm,
        noData: MessageTemplates.cbAdminClearFunnelAbort,
      ),
    );
  }

  // TODO(mvp-reset): remove with the admin «Очистить воронку» button.
  Future<bool> _adminClearFunnel(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final people = _course.clearFunnelPeople();
    _flowByUserId.clear();
    final job = _sheetsExportJob;
    if (job != null) {
      try {
        await job.export();
      } on Object catch (error, stackTrace) {
        l.w('Admin ВОРОНКА export after clear failed: $error', stackTrace);
      }
    }
    return _send(
      context,
      _templates.adminFunnelCleared(people: people),
      replyMarkup: _templates.adminMenuKeyboard(),
    );
  }

  Future<int?> _sendProgress(PrivateMessageContext context, String text) async {
    final chatId = context.chatId;
    if (chatId == null) {
      return null;
    }
    try {
      return await _sender.sendMessage(chatId, text, parseMode: 'HTML');
    } on Object catch (error, stackTrace) {
      l.w('Admin progress message failed: $error', stackTrace);
      return null;
    }
  }

  Future<void> _deleteProgress(PrivateMessageContext context, int? messageId) async {
    final chatId = context.chatId;
    if (chatId == null || messageId == null) {
      return;
    }
    try {
      await _sender.deleteMessage(chatId, messageId: messageId);
    } on Object catch (error, stackTrace) {
      l.w('Admin progress delete failed: $error', stackTrace);
    }
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
    final status = AdminPaymentStatusX.resolve(order: order, phase: enrollment?.funnelPhase);
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
      replyMarkup: _templates.adminCardKeyboard(
        user.userId,
        status: status,
        inChannel: access?.hasJoined ?? false,
      ),
    );
  }

  bool _canRemoveFromCourse({required int userId, required Launch launch}) {
    final status = _checkout.currentAdminStatus(userId: userId, launch: launch);
    final access = _course.accessFor(userId: userId, launchId: launch.id);
    return status.canRemoveFromCourse(inChannel: access?.hasJoined ?? false);
  }

  Future<bool> _adminAskCardCancel(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final launch = _launch;
    final user = _course.getUser(targetUserId);
    if (launch == null || user == null) {
      return user == null
          ? _send(context, _templates.adminNotFound('$targetUserId'))
          : _send(context, _templates.payManualFallback());
    }
    if (!_canRemoveFromCourse(userId: targetUserId, launch: launch)) {
      return _presentAdminCard(context, user);
    }
    return _adminAskConfirm(context, targetUserId, kind: _AdminConfirmKind.cancel);
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

  Future<bool> _adminShowStatusPicker(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final launch = _launch;
    final current = launch == null
        ? AdminPaymentStatus.unpaid
        : _checkout.currentAdminStatus(userId: targetUserId, launch: launch);
    return _send(
      context,
      _templates.adminAskStatus(current),
      replyMarkup: _templates.adminStatusKeyboard(targetUserId, current),
    );
  }

  Future<bool> _adminSetPaymentStatus(
    PrivateMessageContext context,
    int? targetUserId,
    AdminPaymentStatus? target,
  ) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null || target == null) {
      return false;
    }
    if (target == AdminPaymentStatus.cancelled) {
      return _adminAskConfirm(context, targetUserId, kind: _AdminConfirmKind.cancel);
    }
    final launch = _launch;
    if (launch == null) {
      return _send(context, _templates.adminStatusFailed());
    }
    _course.ensureUser(userId: targetUserId, now: _nowProvider());
    final already = _checkout.currentAdminStatus(userId: targetUserId, launch: launch) == target;
    try {
      final result = await _checkout.applyAdminPaymentStatus(
        userId: targetUserId,
        launch: launch,
        target: target,
      );
      if (result != null) {
        await _notifyPaymentResult(result);
      }
    } on Object catch (error, stackTrace) {
      l.w('Admin status $target for $targetUserId failed: $error', stackTrace);
      await _send(context, _templates.adminStatusFailed());
      final failed = _course.getUser(targetUserId);
      if (failed == null) {
        return true;
      }
      return _presentAdminCard(context, failed);
    }
    if (!already) {
      await _send(context, _templates.adminStatusChanged(target));
    }
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
    if (launch == null) {
      return _send(context, _templates.inviteUnavailable());
    }
    final status = _checkout.currentAdminStatus(userId: targetUserId, launch: launch);
    if (!status.canIssueChannelInvite) {
      final user = _course.getUser(targetUserId);
      if (user == null) {
        return _send(context, _templates.adminNotFound('$targetUserId'));
      }
      return _presentAdminCard(context, user);
    }
    final order = _course.latestOrder(targetUserId, launchId: launch.id);
    if (order == null) {
      return _send(context, _templates.inviteUnavailable());
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

  Set<String> get _broadcastCourseEntrySources => _funnel.links.courseEntryPayloads;

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
    final recipientCount = _broadcast
        .listRecipients(segments: selected, courseEntrySources: _broadcastCourseEntrySources)
        .length;
    final text = _templates.adminBroadcastPickSegment(
      counts,
      selected: selected,
      recipientCount: recipientCount,
      draftSaved: draftSaved,
    );
    final markup = _templates.broadcastSegmentKeyboard(counts, selected: selected);
    final messageId = forceNewMessage ? null : flow.broadcastPickerMessageId;
    if (messageId != null) {
      try {
        await _sender.editMessageText(
          chatId,
          messageId: messageId,
          text: text,
          parseMode: 'HTML',
          replyMarkup: markup,
        );
        return true;
      } on TelegramApiException catch (error, stackTrace) {
        if (error.message.toLowerCase().contains('not modified')) {
          return true;
        }
        l.w('Broadcast picker editMessageText failed: $error', stackTrace);
      } on Object catch (error, stackTrace) {
        l.w('Broadcast picker editMessageText failed: $error', stackTrace);
      }
    }
    final sentId = await _sender.sendMessage(chatId, text, parseMode: 'HTML', replyMarkup: markup);
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

  Future<bool> _confirmBroadcastSegments(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final previous = _flowByUserId[context.userId!];
    if (previous == null || !previous.hasBroadcastSegments) {
      return _presentBroadcastPicker(context);
    }
    _flowByUserId[context.userId!] = previous.copyWith(step: PrivateFlowStep.adminBroadcastCompose);
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
    final hasSegments = previous.hasBroadcastSegments;
    _flowByUserId[userId] = previous.copyWith(
      step: hasSegments ? PrivateFlowStep.adminBroadcastCompose : previous.step,
      broadcastFromChatId: chatId,
      broadcastMessageId: messageId,
      broadcastContentKind: kind,
      broadcastPreviewText: context.text,
    );
    if (!hasSegments) {
      return _presentBroadcastPicker(context, forceNewMessage: true, draftSaved: true);
    }
    return _showBroadcastPreview(context);
  }

  Future<bool> _showBroadcastPreview(PrivateMessageContext context) async {
    final flow = _flowByUserId[context.userId!];
    final segments = flow?.broadcastSegments ?? const <BroadcastSegment>{};
    final fromChatId = flow?.broadcastFromChatId;
    final messageId = flow?.broadcastMessageId;
    final kind = flow?.broadcastContentKind;
    final chatId = context.chatId;
    if (flow == null ||
        segments.isEmpty ||
        fromChatId == null ||
        messageId == null ||
        kind == null ||
        chatId == null) {
      return _presentBroadcastPicker(context, forceNewMessage: true);
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
        segments: segments,
        recipientCount: _broadcast
            .listRecipients(
              segments: segments,
              excludeOptOut: flow.broadcastExcludeOptOut,
              courseEntrySources: _broadcastCourseEntrySources,
            )
            .length,
        kind: kind,
        previewText: flow.broadcastPreviewText,
        optOutCount: _broadcast.countOptOut(
          segments: segments,
          courseEntrySources: _broadcastCourseEntrySources,
        ),
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
    if (previous == null || !previous.hasBroadcastSegments) {
      return _presentBroadcastPicker(context, forceNewMessage: true);
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
          broadcastPickerMessageId: null,
        );
    return _presentBroadcastPicker(context, forceNewMessage: true);
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
    final segments = flow?.broadcastSegments ?? const <BroadcastSegment>{};
    final fromChatId = flow?.broadcastFromChatId;
    final messageId = flow?.broadcastMessageId;
    if (segments.isEmpty) {
      return _presentBroadcastPicker(context, forceNewMessage: true);
    }
    if (fromChatId == null || messageId == null) {
      return _send(context, _templates.adminBroadcastNeedDraft());
    }
    _flowByUserId.remove(context.userId);
    final result = await _broadcast.send(
      segments: segments,
      fromChatId: fromChatId,
      messageId: messageId,
      excludeOptOut: flow?.broadcastExcludeOptOut ?? false,
      courseEntrySources: _broadcastCourseEntrySources,
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
