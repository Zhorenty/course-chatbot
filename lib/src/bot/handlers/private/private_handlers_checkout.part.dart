part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersCheckout on PrivateHandlers {
  Future<bool> _showOffer(PrivateMessageContext context, PaymentKind kind) async {
    final launch = _launch;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    _flowByUserId[context.userId!] = PrivateFlowState(
      step: PrivateFlowStep.offerConsent,
      pendingPayKind: kind,
    );
    return _send(
      context,
      _templates.offerConsent(launch),
      replyMarkup: _templates.offerKeyboard(acceptedOffer: false, acceptedPersonalData: false),
    );
  }

  Future<bool> _toggleOfferCheck(PrivateMessageContext context, {required bool offer}) async {
    final userId = context.userId!;
    final flow = _flowByUserId[userId];
    if (flow == null || flow.step != PrivateFlowStep.offerConsent || flow.pendingPayKind == null) {
      await _answerCallback(context, text: 'Выбери способ оплаты ещё раз.');
      return _showEnroll(context);
    }
    final next = offer
        ? flow.copyWith(acceptedOffer: !flow.acceptedOffer)
        : flow.copyWith(acceptedPersonalData: !flow.acceptedPersonalData);
    _flowByUserId[userId] = next;
    await _answerCallback(context);
    final markup = _templates.offerKeyboard(
      acceptedOffer: next.acceptedOffer,
      acceptedPersonalData: next.acceptedPersonalData,
    );
    final messageId = asTelegramInt(context.callbackMessage?['message_id']);
    final chatId = context.chatId;
    if (chatId != null && messageId != null) {
      try {
        await _sender.editMessageReplyMarkup(chatId, messageId: messageId, replyMarkup: markup);
        return true;
      } on TelegramApiException catch (error, stackTrace) {
        l.w('editMessageReplyMarkup failed: $error', stackTrace);
      }
    }
    return _send(context, _templates.offerConsent(_launch!), replyMarkup: markup);
  }

  Future<bool> _confirmOfferAndPay(PrivateMessageContext context) async {
    final flow = _flowByUserId[context.userId!];
    final kind = flow?.pendingPayKind;
    if (flow == null || flow.step != PrivateFlowStep.offerConsent || kind == null) {
      await _answerCallback(context, text: 'Выбери способ оплаты ещё раз.');
      return _showEnroll(context);
    }
    if (!flow.offerReady) {
      await _answerCallback(context, text: _templates.offerNeedBothChecks(), showAlert: true);
      return true;
    }
    await _answerCallback(context);
    _flowByUserId.remove(context.userId);
    return _startPay(context, kind);
  }

  Future<bool> _startPay(PrivateMessageContext context, PaymentKind kind) async {
    final launch = _launch;
    final userId = context.userId!;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    try {
      final order = _checkout.startOrReuseOrder(userId: userId, launch: launch, kind: kind);
      final amount = _checkout.amountFor(launch, order, kind);
      final payment = await _checkout.createCheckout(
        order: order,
        kind: kind,
        amountKopecks: amount,
      );
      final url = payment.confirmationUrl;
      if (url == null || url.isEmpty) {
        return _send(context, _templates.payManualFallback());
      }
      return _send(context, _templates.payButton(url), replyMarkup: _templates.payUrlKeyboard(url));
    } on CheckoutBlockedException catch (error) {
      if (error.reason == CheckoutBlockReason.alreadyPaid) {
        return _send(
          context,
          _templates.alreadyHasAccess(),
          replyMarkup: _templates.accessKeyboard(),
        );
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
    final pending = _course.latestPendingPayment(order.id);
    final url = pending?.confirmationUrl;
    if (url != null && url.isNotEmpty) {
      return _send(context, _templates.payButton(url), replyMarkup: _templates.payUrlKeyboard(url));
    }
    return _showOffer(context, order.kind);
  }

  Future<bool> _issueInviteIfNeeded(PrivateMessageContext context) async {
    final launch = _launch;
    final user = _course.getUser(context.userId!);
    if (launch == null || user == null || !user.funnelPhase.isPaidOrAccess) {
      return false;
    }
    final order = _course.latestOrder(user.userId);
    if (order == null) {
      return false;
    }
    final link = await _access.issueInvite(userId: user.userId, orderId: order.id, launch: launch);
    if (link == null) {
      return _send(context, _templates.inviteUnavailable());
    }
    return _send(
      context,
      _templates.inviteMessage(link),
      replyMarkup: _templates.unjoinedInviteKeyboard(link),
    );
  }

  Future<void> _notifyPaymentResult(PaymentApplyResult result) async {
    if (result.alreadyApplied && !result.repairedInvite) {
      return;
    }
    if (result.repairedInvite) {
      final link = result.inviteLink;
      if (link != null) {
        await _sender.sendMessage(
          result.order.userId,
          _templates.inviteMessage(link),
          parseMode: 'HTML',
          replyMarkup: _templates.unjoinedInviteKeyboard(link),
        );
      }
      return;
    }
    if (result.depositOnly) {
      await _sender.sendMessage(
        result.order.userId,
        _templates.depositSucceeded(result.order),
        parseMode: 'HTML',
        replyMarkup: _templates.remainderKeyboard(),
      );
      return;
    }
    if (result.grantedAccess) {
      await _sender.sendMessage(
        result.order.userId,
        _templates.paymentSucceeded(),
        parseMode: 'HTML',
      );
      final link = result.inviteLink;
      if (link != null) {
        await _sender.sendMessage(
          result.order.userId,
          _templates.inviteMessage(link),
          parseMode: 'HTML',
          replyMarkup: _templates.unjoinedInviteKeyboard(link),
        );
      } else {
        await _sender.sendMessage(
          result.order.userId,
          _templates.inviteUnavailable(),
          parseMode: 'HTML',
          replyMarkup: _templates.accessKeyboard(),
        );
      }
    }
  }
}
