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
    if (text == MessageTemplates.buttonAdminPeople) {
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.idle);
      return _presentPeopleHub(context);
    }
    if (text == MessageTemplates.buttonAdminBroadcast) {
      _cancelPendingBroadcastAlbum(userId);
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.adminBroadcastSegment);
      return _presentBroadcastPicker(context, forceNewMessage: true);
    }
    if (text == MessageTemplates.buttonAdminSheets || text == '/sheets') {
      return _adminRefreshSheets(context, keepHub: _isSheetsSection(flow?.step));
    }
    if (text == MessageTemplates.buttonAdminLinks || text == '/links') {
      return _openLinksFromMenu(context);
    }
    if (text == MessageTemplates.buttonAdminReadiness) {
      return _openCourseReadiness(context);
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
    if (flow?.step == PrivateFlowStep.adminSheetsHub ||
        flow?.step == PrivateFlowStep.adminCourseReadiness) {
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
    return _presentCatalog(
      context,
      _templates.adminSheetsHub(),
      richHtml: _templates.adminSheetsHubRich(),
    );
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
      return _presentCatalog(
        context,
        _templates.adminSheetsHub(),
        richHtml: _templates.adminSheetsHubRich(),
      );
    }
    await _dismissCatalogUi(context);
    _flowByUserId[context.userId!] = const PrivateFlowState(step: PrivateFlowStep.idle);
    return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
  }

  bool _isSheetsSection(PrivateFlowStep? step) {
    return step == PrivateFlowStep.adminSheetsHub ||
        step == PrivateFlowStep.adminCourseReadiness ||
        _isCatalogStep(step) ||
        _isLinksStep(step);
  }

  Future<bool> _openCourseReadiness(PrivateMessageContext context) async {
    await _deleteInboundMessage(context);
    await _ensureSheetsHubPinned(context);
    return _showCourseReadiness(context, refresh: true);
  }

  Future<bool> _showCourseReadiness(
    PrivateMessageContext context, {
    int? launchId,
    bool refresh = false,
  }) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final admin = _catalogAdmin;
    if (admin == null) {
      _setCatalogFlow(context.userId!, PrivateFlowStep.adminCourseReadiness, clearDraft: true);
      return _presentCatalog(context, _templates.adminSheetsDisabled());
    }
    String? notice;
    if (refresh) {
      _setCatalogFlow(context.userId!, PrivateFlowStep.adminCourseReadiness, clearDraft: true);
      await _presentCatalog(context, _templates.adminCatalogRefreshing());
      notice = await _refreshCatalogFromSheets();
    }
    _setCatalogFlow(context.userId!, PrivateFlowStep.adminCourseReadiness, clearDraft: true);
    final launches = admin.listVisibleLaunches();
    final launch = _readinessLaunch(launches, launchId);
    if (launch == null) {
      return _presentCatalog(
        context,
        _templates.adminCourseReadinessEmpty(notice: notice),
        richHtml: _templates.adminCourseReadinessEmptyRich(notice: notice),
      );
    }
    final dozhimCount = _course.listLaunchDozhim(launch.id).length;
    return _presentCatalog(
      context,
      _templates.adminCourseReadiness(launch, dozhimCount: dozhimCount, notice: notice),
      richHtml: _templates.adminCourseReadinessRich(
        launch,
        dozhimCount: dozhimCount,
        notice: notice,
      ),
      replyMarkup: _templates.adminCourseReadinessKeyboard(launches, selectedId: launch.id),
    );
  }

  Launch? _readinessLaunch(List<Launch> launches, int? launchId) {
    if (launches.isEmpty) {
      return null;
    }
    if (launchId != null) {
      for (final launch in launches) {
        if (launch.id == launchId) {
          return launch;
        }
      }
    }
    for (final launch in launches) {
      if (launch.isActive) {
        return launch;
      }
    }
    return launches.first;
  }

  Map<ParticipantListSegment, int> _peopleCounts() {
    final exclude = _adminGate.configuredAdminIds;
    return <ParticipantListSegment, int>{
      for (final segment in ParticipantListSegment.values)
        segment: _course.countParticipants(segment: segment, excludeUserIds: exclude),
    };
  }

  Future<bool> _presentPeopleHub(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final launch = _launch;
    final counts = launch == null ? const <ParticipantListSegment, int>{} : _peopleCounts();
    return _presentPeopleScreen(
      context,
      _templates.adminPeopleHub(launch: launch, counts: counts),
      richHtml: _templates.adminPeopleHubRich(launch: launch, counts: counts),
      replyMarkup: launch == null ? null : _templates.adminPeopleHubKeyboard(counts),
    );
  }

  Future<bool> _presentPeopleSegment(
    PrivateMessageContext context,
    ParticipantListSegment segment, {
    int page = 0,
  }) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final exclude = _adminGate.configuredAdminIds;
    final total = _course.countParticipants(segment: segment, excludeUserIds: exclude);
    final pageSize = MessageTemplates.adminPeoplePageSize;
    final lastPage = total == 0 ? 0 : (total - 1) ~/ pageSize;
    final safePage = page.clamp(0, lastPage);
    final people = _course.listParticipants(
      segment: segment,
      limit: pageSize,
      offset: safePage * pageSize,
      excludeUserIds: exclude,
    );
    return _presentPeopleScreen(
      context,
      _templates.adminPeopleList(
        segment: segment,
        people: people,
        total: total,
        page: safePage,
        launch: _launch,
      ),
      richHtml: _templates.adminPeopleListRich(
        segment: segment,
        people: people,
        total: total,
        page: safePage,
        launch: _launch,
      ),
      replyMarkup: _templates.adminPeopleListKeyboard(
        segment: segment,
        people: people,
        total: total,
        page: safePage,
      ),
    );
  }

  Future<bool> _presentPeopleScreen(
    PrivateMessageContext context,
    String text, {
    String? richHtml,
    Map<String, Object?>? replyMarkup,
  }) async {
    final chatId = context.chatId;
    if (chatId == null) {
      return false;
    }
    final messageId = asTelegramInt(context.callbackMessage?['message_id']);
    if (messageId != null) {
      try {
        await _editHtml(
          chatId,
          messageId: messageId,
          text: text,
          richHtml: richHtml,
          replyMarkup: replyMarkup,
        );
        return true;
      } on TelegramApiException catch (error, stackTrace) {
        if (error.message.toLowerCase().contains('not modified')) {
          return true;
        }
        l.w('Admin people list edit failed: $error', stackTrace);
      } on Object catch (error, stackTrace) {
        l.w('Admin people list edit failed: $error', stackTrace);
      }
    }
    return _send(context, text, richHtml: richHtml, replyMarkup: replyMarkup);
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
    final resultRich = _templates.adminSheetsRefreshResultRich(
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
      return _presentCatalog(context, result, richHtml: resultRich);
    }
    return _send(
      context,
      result,
      richHtml: resultRich,
      replyMarkup: _templates.adminMenuKeyboard(),
    );
  }

  Future<int?> _sendProgress(PrivateMessageContext context, String text) async {
    final chatId = context.chatId;
    if (chatId == null) {
      return null;
    }
    try {
      return await sendPreferRich(_sender, chatId, text);
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
      richHtml: _templates.adminCardRich(
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
        canResetFunnel: FunnelReplayAllowlist.allows(user.username),
      ),
    );
  }

  bool _canRemoveFromCourse({required int userId, required Launch launch}) {
    final status = _checkout.currentAdminStatus(userId: userId, launch: launch);
    final access = _course.accessFor(userId: userId, launchId: launch.id);
    return status.canRemoveFromCourse(inChannel: access?.hasJoined ?? false);
  }

  bool _clientHadCourseSeat({required int userId, required Launch launch}) {
    final status = _checkout.currentAdminStatus(userId: userId, launch: launch);
    if (status.isFullyPaid || status == AdminPaymentStatus.deposit) {
      return true;
    }
    final access = _course.accessFor(userId: userId, launchId: launch.id);
    if (access == null) {
      return false;
    }
    return access.hasJoined || (access.isActive && (access.inviteLink?.trim().isNotEmpty ?? false));
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

  Future<bool> _adminAskResetFunnel(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final user = _course.getUser(targetUserId);
    if (user == null) {
      return _send(context, _templates.adminNotFound('$targetUserId'));
    }
    if (!FunnelReplayAllowlist.allows(user.username)) {
      return _presentAdminCard(context, user);
    }
    return _adminAskConfirm(context, targetUserId, kind: _AdminConfirmKind.resetFunnel);
  }

  Future<bool> _adminResetFunnel(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final user = _course.getUser(targetUserId);
    if (user == null) {
      return _send(context, _templates.adminNotFound('$targetUserId'));
    }
    if (!FunnelReplayAllowlist.allows(user.username)) {
      return _presentAdminCard(context, user);
    }
    for (final launch in _course.listLaunches()) {
      await _access.revoke(userId: targetUserId, launch: launch);
    }
    _course.resetUserFunnel(targetUserId);
    _flowByUserId.remove(targetUserId);
    await _send(context, _templates.adminFunnelReset());
    final reset = _course.getUser(targetUserId);
    if (reset == null) {
      return true;
    }
    return _presentAdminCard(context, reset);
  }

  Future<bool> _adminAskConfirm(
    PrivateMessageContext context,
    int? targetUserId, {
    required _AdminConfirmKind kind,
  }) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final user = _course.getUser(targetUserId);
    if (user == null) {
      return _send(context, _templates.adminNotFound('$targetUserId'));
    }
    final (text, yesPrefix, yesText) = switch (kind) {
      _AdminConfirmKind.cancel => (
        _templates.adminConfirmCancel(user),
        MessageTemplates.cbAdminCancelConfirm,
        MessageTemplates.buttonAdminConfirmYes,
      ),
      _AdminConfirmKind.resetFunnel => (
        _templates.adminConfirmResetFunnel(user),
        MessageTemplates.cbAdminResetFunnelConfirm,
        MessageTemplates.buttonAdminResetConfirmYes,
      ),
    };
    return _send(
      context,
      text,
      replyMarkup: _templates.adminConfirmKeyboard(
        yesData: '$yesPrefix$targetUserId',
        noData: '${MessageTemplates.cbAdminActionAbort}$targetUserId',
        yesText: yesText,
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
    final previous = _checkout.currentAdminStatus(userId: targetUserId, launch: launch);
    final already = previous == target;
    final seatBefore = _clientHadCourseSeat(userId: targetUserId, launch: launch);
    var clientNotified = false;
    var clientReached = true;
    try {
      final result = await _checkout.applyAdminPaymentStatus(
        userId: targetUserId,
        launch: launch,
        target: target,
      );
      if (result != null) {
        clientNotified = true;
        clientReached = await _notifyPaymentResult(result);
      } else if (!already && target == AdminPaymentStatus.unpaid && seatBefore) {
        clientNotified = true;
        clientReached = await _dmUser(targetUserId, _templates.paymentResetToUnpaid());
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
      await _send(
        context,
        _templates.adminStatusChanged(
          target,
          clientNotified: clientNotified,
          clientReached: clientReached,
        ),
      );
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
    final shouldTell = _clientHadCourseSeat(userId: targetUserId, launch: launch);
    await _checkout.cancelEnrollment(userId: targetUserId, launch: launch);
    var reached = true;
    if (shouldTell) {
      reached = await _dmUser(targetUserId, _templates.accessRevoked());
    }
    await _send(
      context,
      _templates.adminCancelled(clientNotified: shouldTell, clientReached: reached),
    );
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
    var reached = true;
    if (link != null) {
      reached = await _dmUser(
        targetUserId,
        _templates.inviteMessage(),
        replyMarkup: _templates.unjoinedInviteKeyboard(link),
      );
    }
    await _send(
      context,
      link == null
          ? _templates.inviteUnavailable()
          : _templates.adminInviteReissued(clientReached: reached),
    );
    final user = _course.getUser(targetUserId);
    if (user == null) {
      return true;
    }
    return _presentAdminCard(context, user);
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
