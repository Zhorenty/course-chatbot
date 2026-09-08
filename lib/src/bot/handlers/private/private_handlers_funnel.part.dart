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
      await _sendHtml(chatId, _templates.guideReady(), replyMarkup: menu);
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
      await _sendHtml(chatId, _templates.guideReady(), replyMarkup: menu);
    } else if (url != null && url.isNotEmpty) {
      await _sendHtml(chatId, _templates.guideAsUrl(url), replyMarkup: menu);
    } else {
      await _sendHtml(chatId, _templates.guideMissing());
      await _notifyGuideMissing(userId);
      await _sendHtml(chatId, _templates.menuPinned(), replyMarkup: _homeKeyboard(userId));
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
    _funnel.markWebinarRsvp(userId, launchId: launch.id);
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
