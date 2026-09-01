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
      await _sender.sendDocument(chatId, document: fileId);
      await _sender.sendMessage(
        chatId,
        _templates.guideReady(),
        parseMode: 'HTML',
        replyMarkup: menu,
      );
    } else if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      final sent = await _sender.sendDocument(
        chatId,
        document: localPath,
        filename: leadMagnetFilename,
        fromFile: true,
      );
      final cachedId = sent.fileId;
      if (cachedId != null && cachedId.isNotEmpty) {
        _course.setLeadMagnetFileId(cachedId);
      }
      await _sender.sendMessage(
        chatId,
        _templates.guideReady(),
        parseMode: 'HTML',
        replyMarkup: menu,
      );
    } else if (url != null && url.isNotEmpty) {
      await _sender.sendMessage(
        chatId,
        _templates.guideAsUrl(url),
        parseMode: 'HTML',
        replyMarkup: menu,
      );
    } else {
      await _sender.sendMessage(chatId, _templates.guideMissing(), parseMode: 'HTML');
      await _notifyGuideMissing(userId);
      await _sender.sendMessage(
        chatId,
        _templates.menuPinned(),
        parseMode: 'HTML',
        replyMarkup: _homeKeyboard(userId),
      );
      return true;
    }
    _funnel.markMagnetIssued(userId, launchId: launch?.id);
    if (sendWarmup) {
      await _sendWarmupZero(userId);
    }
    return true;
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
        send: () => _sender.sendMessage(
          userId,
          _templates.warmupStep(WarmupService.firstStepKey, launch: launch),
          parseMode: 'HTML',
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
    final user = _course.getUser(context.userId!);
    if (user != null && _funnel.phaseOf(user).showsCourseStatus) {
      return _showCourseStatus(context);
    }
    final launch = _launch;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    return _send(
      context,
      _templates.enrollOptions(launch),
      replyMarkup: _templates.enrollKeyboard(launch),
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
      replyMarkup: _templates.courseStatusKeyboard(order: order, access: access),
    );
  }
}
