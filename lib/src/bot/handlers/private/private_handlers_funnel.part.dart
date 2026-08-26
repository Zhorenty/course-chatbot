part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersFunnel on PrivateHandlers {
  Future<bool> _deliverGuide(PrivateMessageContext context, {required bool sendWarmup}) async {
    final launch = _launch;
    final userId = context.userId!;
    final chatId = context.chatId!;
    final fileId = launch?.leadMagnetFileId;
    final url = launch?.leadMagnetUrl;
    if (fileId != null && fileId.isNotEmpty) {
      await _sender.sendDocument(chatId, document: fileId);
      await _sender.sendMessage(chatId, _templates.guideReady(), parseMode: 'HTML');
    } else if (url != null && url.isNotEmpty) {
      await _sender.sendMessage(chatId, _templates.guideAsUrl(url), parseMode: 'HTML');
    } else {
      await _sender.sendMessage(chatId, _templates.guideMissing(), parseMode: 'HTML');
      return true;
    }
    await _funnel.markMagnetIssued(userId);
    if (sendWarmup) {
      await _sendWarmupZero(userId);
    }
    return true;
  }

  Future<void> _sendWarmupZero(int userId) async {
    final user = _course.getUser(userId);
    if (user == null || user.warmupOptOut || user.funnelPhase.excludeSellingDrip) {
      return;
    }
    if (_course.hasWarmupBeenSent(userId: userId, stepKey: 'warmup_0')) {
      return;
    }
    final decision = WarmupDecision(stepKey: 'warmup_0', userId: userId);
    if (!_warmup.tryClaim(decision)) {
      return;
    }
    try {
      await _sender.sendMessage(
        userId,
        _templates.warmupStep('warmup_0'),
        parseMode: 'HTML',
        replyMarkup: _templates.warmupKeyboard(showEnroll: true),
      );
      _warmup.markSent(decision, _nowProvider());
    } on Object catch (error, stackTrace) {
      _warmup.release(decision);
      l.w('Failed to send warmup_0 to $userId: $error', stackTrace);
    }
  }

  Future<bool> _optOut(PrivateMessageContext context) async {
    await _funnel.optOutWarmup(context.userId!);
    return _send(context, _templates.optOutConfirmed());
  }

  Future<bool> _showEnroll(PrivateMessageContext context) async {
    final user = _course.getUser(context.userId!);
    if (user != null && user.funnelPhase.hasAccess) {
      return _send(context, _templates.alreadyHasAccess(),
          replyMarkup: _templates.accessKeyboard());
    }
    final launch = _launch;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    await _funnel.markCheckout(context.userId!);
    return _send(
      context,
      _templates.enrollOptions(launch),
      replyMarkup: _templates.enrollKeyboard(launch),
    );
  }
}
