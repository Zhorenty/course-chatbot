part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersFunnel on PrivateHandlers {
  Future<bool> _deliverGuide(PrivateMessageContext context, {required bool sendWarmup}) async {
    final launch = _launch;
    final userId = context.userId!;
    final chatId = context.chatId!;
    final fileId = launch?.leadMagnetFileId;
    final url = launch?.leadMagnetUrl;
    final localPath = leadMagnetPath;
    final menu = _templates.userMenuKeyboard(hasAccess: false);
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
        replyMarkup: _templates.userMenuKeyboard(hasAccess: false),
      );
      return true;
    }
    _funnel.markMagnetIssued(userId);
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
    final user = _course.getUser(userId);
    if (user == null || user.warmupOptOut || user.funnelPhase.excludeSellingDrip) {
      return;
    }
    try {
      await _warmup.deliver(
        decision: WarmupDecision(stepKey: WarmupService.firstStepKey, userId: userId),
        now: _nowProvider(),
        send: () => _sender.sendMessage(
          userId,
          _templates.warmupStep(WarmupService.firstStepKey, launch: _launch),
          parseMode: 'HTML',
          replyMarkup: _templates.warmupKeyboard(showEnroll: true),
        ),
      );
    } on Object catch (error, stackTrace) {
      l.w('Failed to send warmup_0 to $userId: $error', stackTrace);
    }
  }

  Future<bool> _optOut(PrivateMessageContext context) async {
    _funnel.optOutWarmup(context.userId!);
    return _send(
      context,
      _templates.optOutConfirmed(),
      replyMarkup: _templates.userMenuKeyboard(hasAccess: false),
    );
  }

  Future<bool> _showEnroll(PrivateMessageContext context) async {
    final user = _course.getUser(context.userId!);
    if (user != null && user.funnelPhase.hasAccess) {
      return _send(
        context,
        _templates.alreadyHasAccess(),
        replyMarkup: _templates.accessKeyboard(),
      );
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
}
