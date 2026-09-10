part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersFunnel on PrivateHandlers {
  Future<bool> _deliverGuide(PrivateMessageContext context, {required bool sendWarmup}) async {
    final launch = _launch;
    final userId = context.userId!;
    final chatId = context.chatId!;
    final fileId = launch?.leadMagnetFileId;
    final url = launch?.leadMagnetUrl;
    final localPath = leadMagnetPath;
    final menu = _homeKeyboard(userId);
    if (fileId != null && fileId.isNotEmpty) {
      await _deliverGuideFile(chatId: chatId, menu: menu, fileId: fileId);
    } else if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      await _deliverGuideFile(chatId: chatId, menu: menu, localPath: localPath);
    } else if (url != null && url.isNotEmpty) {
      await _sendHtml(chatId, _templates.guideAsUrl(url), replyMarkup: menu);
    } else {
      await _sendHtml(chatId, _templates.guideMissing());
      await _notifyGuideMissing(userId);
      await _sendHtml(chatId, _templates.menuPinned(), replyMarkup: _homeKeyboard(userId));
      return true;
    }
    final firstIssue = !_guideAlreadyIssued(userId, launch);
    _funnel.markMagnetIssued(userId, launchId: launch?.id);
    if (firstIssue) {
      await _notifyGuideIssued(userId, launch: launch);
    }
    if (sendWarmup) {
      await _sendWarmupZero(userId);
    }
    return true;
  }

  Future<void> _deliverGuideFile({
    required int chatId,
    required Map<String, Object?> menu,
    String? fileId,
    String? localPath,
  }) async {
    final useFileId = fileId != null && fileId.isNotEmpty;
    final media = InputRichMessageMedia.document(
      id: MessageTemplates.guideDocumentMediaId,
      document: useFileId
          ? InputRichDocument.fileId(fileId)
          : InputRichDocument.file(localPath: localPath!, filename: leadMagnetFilename),
    );
    try {
      final sent = await _sender.sendRichMessage(
        chatId,
        InputRichMessage(html: _templates.guideReadyRich(), media: <InputRichMessageMedia>[media]),
        replyMarkup: menu,
      );
      if (!useFileId) {
        _cacheLeadMagnetFileId(sent.fileId);
      }
      return;
    } on Object catch (error, stackTrace) {
      l.w(
        'sendRichMessage with guide file failed, falling back to sendDocument: $error',
        stackTrace,
      );
    }
    await _deliverGuideFileClassic(
      chatId: chatId,
      menu: menu,
      fileId: fileId,
      localPath: localPath,
      useFileId: useFileId,
    );
  }

  Future<void> _deliverGuideFileClassic({
    required int chatId,
    required Map<String, Object?> menu,
    required String? fileId,
    required String? localPath,
    required bool useFileId,
  }) async {
    if (useFileId) {
      await _sender.sendDocument(chatId, document: fileId!);
    } else {
      final sent = await _sender.sendDocument(
        chatId,
        document: localPath!,
        filename: leadMagnetFilename,
        fromFile: true,
      );
      _cacheLeadMagnetFileId(sent.fileId);
    }
    await _sendHtml(chatId, _templates.guideReady(), replyMarkup: menu);
  }

  void _cacheLeadMagnetFileId(String? fileId) {
    if (fileId == null || fileId.isEmpty) {
      return;
    }
    _course.setLeadMagnetFileId(fileId);
  }

  bool _guideAlreadyIssued(int userId, Launch? launch) {
    final enrollment = launch == null ? null : _funnel.enrollmentFor(userId, launch: launch);
    if (enrollment?.magnetIssuedAt != null) {
      return true;
    }
    return _course.getUser(userId)?.magnetIssuedAt != null;
  }

  Future<void> _notifyGuideMissing(int userId) async {
    final port = _adminAlerts;
    if (port == null) {
      return;
    }
    final now = _nowProvider();
    final last = _lastGuideMissingAlertAt;
    if (last != null && now.difference(last) < const Duration(minutes: 15)) {
      return;
    }
    _lastGuideMissingAlertAt = now;
    try {
      await port.notifyGuideMissing(userId: userId);
    } on Object catch (error, stackTrace) {
      l.w('Failed to alert admins about missing guide: $error', stackTrace);
    }
  }

  Future<void> _notifyGuideIssued(int userId, {Launch? launch}) async {
    final port = _adminAlerts;
    if (port == null) {
      return;
    }
    final user = _course.getUser(userId);
    if (user == null) {
      return;
    }
    try {
      await port.notifyGuideIssued(user: user, launch: launch ?? _launch);
    } on Object catch (error, stackTrace) {
      l.w('Failed to alert admins about guide issued for $userId: $error', stackTrace);
    }
  }

  Future<void> _notifyWebinarRsvp(int userId, Launch launch) async {
    final port = _adminAlerts;
    if (port == null) {
      return;
    }
    final user = _course.getUser(userId);
    if (user == null) {
      return;
    }
    try {
      await port.notifyWebinarRsvp(user: user, launch: launch);
    } on Object catch (error, stackTrace) {
      l.w('Failed to alert admins about webinar RSVP for $userId: $error', stackTrace);
    }
  }

  Future<void> _sendWarmupZero(int userId) async {
    final launch = _launch;
    if (launch == null) {
      return;
    }
    final enrollment = _funnel.enrollmentFor(userId, launch: launch);
    if (enrollment == null ||
        enrollment.warmupOptOut ||
        enrollment.funnelPhase.excludeSellingDrip) {
      return;
    }
    try {
      await _warmup.deliver(
        decision: WarmupDecision(
          stepKey: WarmupService.firstStepKey,
          userId: userId,
          launchId: launch.id,
        ),
        now: _nowProvider(),
        send: () => sendPreferRich(
          _sender,
          userId,
          _templates.warmupStep(WarmupService.firstStepKey, launch: launch),
          replyMarkup: _templates.warmupKeyboard(
            WarmupService.firstStepKey,
            launch: launch,
            rsvp: enrollment.webinarRsvp,
            rsvpOpen: LaunchSales.rsvpOpen(launch, _nowProvider()),
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      l.w('Failed to send warmup_0 to $userId: $error', stackTrace);
    }
  }

  Future<bool> _optOut(PrivateMessageContext context) async {
    _funnel.optOutWarmup(context.userId!, launchId: _launch?.id);
    return _send(
      context,
      _templates.optOutConfirmed(),
      replyMarkup: _homeKeyboard(context.userId!),
    );
  }

  Future<bool> _showEnroll(PrivateMessageContext context) async {
    if (await _syncPaidCheckout(context)) {
      return true;
    }
    final user = _course.getUser(context.userId!);
    if (user != null && _funnel.phaseOf(user).showsCourseStatus) {
      return _showCourseStatus(context);
    }
    final launch = _launch;
    final userId = context.userId!;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    _funnel.markEnrollIntent(userId, launchId: launch.id);
    final enrollment = _funnel.enrollmentFor(userId, launch: launch);
    final quote = LaunchSales.quote(
      launch,
      rsvp: enrollment?.webinarRsvp ?? false,
      now: _nowProvider(),
    );
    return _send(
      context,
      _templates.enrollOptions(launch, quote: quote),
      richHtml: _templates.enrollOptionsRich(launch, quote: quote),
      replyMarkup: _templates.enrollKeyboard(
        launch,
        quote: quote,
        rsvpOpen: LaunchSales.rsvpOpen(launch, _nowProvider()),
      ),
    );
  }

  Future<bool> _rsvpWebinar(PrivateMessageContext context) async {
    final launch = _launch;
    final userId = context.userId!;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    final now = _nowProvider();
    if (!LaunchSales.rsvpOpen(launch, now)) {
      await _answerCallback(context, text: 'Регистрация на эфир уже закрыта.');
      return true;
    }
    final firstRsvp = !(_funnel.enrollmentFor(userId, launch: launch)?.webinarRsvp ?? false);
    _funnel.markWebinarRsvp(userId, launchId: launch.id);
    if (firstRsvp) {
      await _notifyWebinarRsvp(userId, launch);
    }
    await _answerCallback(context, text: 'Ты в списке на эфир.');
    final url = launch.webinarUrl?.trim();
    final started = launch.webinarAt != null && !now.toUtc().isBefore(launch.webinarAt!.toUtc());
    return _send(
      context,
      _templates.webinarRsvpConfirmed(launch, showLink: started && url != null && url.isNotEmpty),
      replyMarkup: started && url != null && url.isNotEmpty
          ? _templates.webinarLinkKeyboard(url)
          : null,
    );
  }

  Future<bool> _showCourseStatus(PrivateMessageContext context) async {
    final userId = context.userId!;
    final user = _course.getUser(userId);
    if (user == null || !_funnel.phaseOf(user).showsCourseStatus) {
      return _showEnroll(context);
    }
    final launch = _launch;
    final order = launch == null
        ? _course.latestOrder(userId)
        : _course.latestOrder(userId, launchId: launch.id);
    final access = launch == null ? null : _course.accessFor(userId: userId, launchId: launch.id);
    return _send(
      context,
      _templates.courseStatus(launch: launch, order: order, access: access, now: _nowProvider()),
      richHtml: _templates.courseStatusRich(
        launch: launch,
        order: order,
        access: access,
        now: _nowProvider(),
      ),
      replyMarkup: _templates.courseStatusKeyboard(order: order, access: access),
    );
  }
}
