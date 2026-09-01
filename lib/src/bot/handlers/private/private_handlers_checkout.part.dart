part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersCheckout on PrivateHandlers {
  Future<bool> _showOffer(
    PrivateMessageContext context,
    PaymentKind kind, {
    Launch? launch,
    int? orderId,
  }) async {
    if (orderId != null) {
      final existing = _course.getOrder(orderId);
      if (existing != null && existing.userId == context.userId) {
        if (existing.status == OrderStatus.cancelled) {
          return _send(
            context,
            _templates.accessRevoked(),
            replyMarkup: _homeKeyboard(existing.userId),
          );
        }
        if (kind == PaymentKind.remainder && existing.status != OrderStatus.depositPaid) {
          return _showEnroll(context);
        }
      }
    }
    final resolved = _launchForPay(kind, userId: context.userId, launch: launch, orderId: orderId);
    if (resolved == null) {
      return _send(context, _templates.payManualFallback());
    }
    _flowByUserId[context.userId!] = PrivateFlowState(
      step: PrivateFlowStep.offerConsent,
      pendingPayKind: kind,
      pendingLaunchId: resolved.id,
    );
    return _send(
      context,
      _templates.offerConsent(resolved),
      replyMarkup: _templates.offerKeyboard(accepted: false),
    );
  }

  Launch? _launchForPay(PaymentKind kind, {int? userId, Launch? launch, int? orderId}) {
    if (launch != null) {
      return launch;
    }
    if (orderId != null) {
      final order = _course.getOrder(orderId);
      if (order != null && (userId == null || order.userId == userId)) {
        return _course.getLaunch(order.launchId);
      }
    }
    if (kind == PaymentKind.remainder && userId != null) {
      for (final order in _course.listOrdersForUser(userId)) {
        if (order.status == OrderStatus.depositPaid) {
          return _course.getLaunch(order.launchId) ?? _launch;
        }
      }
    }
    return _launch;
  }

  Future<bool> _toggleOfferCheck(PrivateMessageContext context) async {
    final userId = context.userId!;
    final flow = _flowByUserId[userId];
    if (flow == null || flow.step != PrivateFlowStep.offerConsent || flow.pendingPayKind == null) {
      await _answerCallback(context, text: 'Выбери способ оплаты ещё раз.');
      return _showEnroll(context);
    }
    final next = flow.copyWith(acceptedConsent: !flow.acceptedConsent);
    _flowByUserId[userId] = next;
    await _answerCallback(context);
    final markup = _templates.offerKeyboard(accepted: next.acceptedConsent);
    final messageId = asTelegramInt(context.callbackMessage?['message_id']);
    final chatId = context.chatId;
    final launch = flow.pendingLaunchId == null
        ? _launch
        : _course.getLaunch(flow.pendingLaunchId!) ?? _launch;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    if (chatId != null && messageId != null) {
      try {
        await _sender.editMessageReplyMarkup(chatId, messageId: messageId, replyMarkup: markup);
        return true;
      } on TelegramApiException catch (error, stackTrace) {
        l.w('editMessageReplyMarkup failed: $error', stackTrace);
      }
    }
    return _send(context, _templates.offerConsent(launch), replyMarkup: markup);
  }

  Future<bool> _confirmOfferAndPay(PrivateMessageContext context) async {
    final flow = _flowByUserId[context.userId!];
    final kind = flow?.pendingPayKind;
    if (flow == null || flow.step != PrivateFlowStep.offerConsent || kind == null) {
      await _answerCallback(context, text: 'Выбери способ оплаты ещё раз.');
      return _showEnroll(context);
    }
    if (!flow.offerReady) {
      await _answerCallback(context, text: _templates.offerNeedCheck(), showAlert: true);
      return true;
    }
    await _answerCallback(context);
    final launch = flow.pendingLaunchId == null ? null : _course.getLaunch(flow.pendingLaunchId!);
    _flowByUserId.remove(context.userId);
    return _startPay(context, kind, launch: launch);
  }

  Future<bool> _startPay(PrivateMessageContext context, PaymentKind kind, {Launch? launch}) async {
    final resolved = launch ?? _launch;
    final userId = context.userId!;
    if (resolved == null) {
      return _send(context, _templates.payManualFallback());
    }
    if (kind == PaymentKind.remainder) {
      final latest = _course.latestOrder(userId, launchId: resolved.id);
      if (latest == null || latest.status != OrderStatus.depositPaid) {
        if (latest?.status == OrderStatus.cancelled) {
          return _send(context, _templates.accessRevoked(), replyMarkup: _homeKeyboard(userId));
        }
        return _showEnroll(context);
      }
    }
    try {
      final order = _checkout.startOrReuseOrder(userId: userId, launch: resolved, kind: kind);
      final amount = _checkout.amountFor(resolved, order, kind);
      final created = await _checkout.createCheckout(
        order: order,
        kind: kind,
        amountKopecks: amount,
      );
      if (created.applied != null || created.alreadySettled) {
        if (created.applied != null) {
          await _notifyPaymentResult(created.applied!);
        }
        return true;
      }
      final url = created.payment.confirmationUrl;
      if (url == null || url.isEmpty) {
        return _send(context, _templates.payManualFallback());
      }
      return _send(context, _templates.payButton(url), replyMarkup: _templates.payUrlKeyboard(url));
    } on CheckoutBlockedException catch (error) {
      if (error.reason == CheckoutBlockReason.alreadyPaid) {
        return _showCourseStatus(context);
      }
      return _send(context, _templates.payManualFallback());
    } on PaymentUnavailableException catch (error, stackTrace) {
      l.w('Checkout unavailable: $error', stackTrace);
      return _send(context, _templates.payManualFallback());
    }
  }

  Future<bool> _continuePay(PrivateMessageContext context, int? orderId) async {
    if (orderId == null) {
      return false;
    }
    final order = _course.getOrder(orderId);
    if (order == null || order.userId != context.userId) {
      return false;
    }
    if (order.status == OrderStatus.cancelled) {
      return _send(context, _templates.accessRevoked(), replyMarkup: _homeKeyboard(order.userId));
    }
    if (await _syncPaidCheckout(context, orderId: order.id)) {
      return true;
    }
    final pending = _course.latestPendingPayment(order.id);
    final url = pending?.confirmationUrl;
    if (url != null && url.isNotEmpty) {
      return _send(context, _templates.payButton(url), replyMarkup: _templates.payUrlKeyboard(url));
    }
    return _showOffer(
      context,
      order.kind,
      launch: _course.getLaunch(order.launchId),
      orderId: order.id,
    );
  }

  Future<bool> _syncPaidCheckout(PrivateMessageContext context, {int? orderId}) async {
    final userId = context.userId;
    if (userId == null) {
      return false;
    }
    try {
      final result = await _checkout.syncOpenCheckout(userId: userId, orderId: orderId);
      if (result == null) {
        return false;
      }
      if (result.alreadyApplied && !result.repairedInvite) {
        if (result.grantedAccess || result.depositOnly || result.order.status.isFullyPaid) {
          return _showCourseStatus(context);
        }
        return false;
      }
      await _notifyPaymentResult(result);
      return true;
    } on Object catch (error, stackTrace) {
      l.w('Failed to sync checkout with kassa for $userId: $error', stackTrace);
      return false;
    }
  }

  Future<bool> _notifyPaymentResult(PaymentApplyResult result) async {
    if (result.alreadyApplied && !result.repairedInvite) {
      return true;
    }
    final userId = result.order.userId;
    if (result.repairedInvite) {
      final link = result.inviteLink;
      if (link == null) {
        return true;
      }
      return _dmUser(
        userId,
        _templates.inviteMessage(link),
        replyMarkup: _templates.unjoinedInviteKeyboard(link),
      );
    }
    if (result.depositOnly) {
      final reached = await _dmUser(
        userId,
        _templates.depositSucceeded(result.order),
        replyMarkup: _templates.remainderKeyboard(result.order.id),
      );
      final pinned = await _dmUser(userId, _templates.courseMenuPinned());
      return reached && pinned;
    }
    if (!result.grantedAccess) {
      return true;
    }
    var reached = await _dmUser(userId, _templates.paymentSucceeded());
    final link = result.inviteLink;
    if (link != null) {
      final inviteReached = await _dmUser(
        userId,
        _templates.inviteMessage(link),
        replyMarkup: _templates.unjoinedInviteKeyboard(link),
      );
      reached = reached && inviteReached;
    } else {
      final missing = await _dmUser(userId, _templates.inviteUnavailable());
      reached = reached && missing;
    }
    return reached;
  }
}
