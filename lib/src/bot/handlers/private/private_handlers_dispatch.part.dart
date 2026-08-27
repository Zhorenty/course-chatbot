part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersDispatch on PrivateHandlers {
  Future<bool> _dispatch(PrivateMessageContext context) async {
    final chatId = context.chatId;
    final userId = context.userId;
    if (chatId == null || userId == null) {
      return false;
    }
    if (!_interactionWhitelist.allows(context.username)) {
      if (context.callbackQueryId != null) {
        await _answerCallback(context);
      }
      return _send(context, _templates.botInDevelopment());
    }
    _course.touchUser(
      userId: userId,
      username: context.username,
      firstName: context.firstName,
      now: _nowProvider(),
    );
    if (context.message != null && context.text != null) {
      _course.appendConversation(
        direction: ConversationDirection.inbound,
        peerUserId: userId,
        peerUsername: context.username,
        chatId: chatId,
        telegramMessageId: asTelegramInt(context.message?['message_id']),
        contentType: ConversationContentType.text,
        textPreview: context.text,
      );
    }
    if (context.callbackQueryId != null) {
      final data = context.callbackData ?? '';
      if (!_defersCallbackAnswer(data)) {
        await _answerCallback(context);
      }
      return _handleCallback(context);
    }
    final text = context.text;
    if (text != null && text.startsWith('/start')) {
      return _handleStart(context, text);
    }
    if (_adminGate.isConfiguredAdmin(userId)) {
      final handled = await _handleAdminMessage(context);
      if (handled) {
        return true;
      }
    }
    return _handleUserText(context);
  }

  bool _defersCallbackAnswer(String data) {
    return data == MessageTemplates.cbToggleOffer ||
        data == MessageTemplates.cbTogglePersonalData ||
        data == MessageTemplates.cbGoToPay;
  }

  Future<void> _answerCallback(
    PrivateMessageContext context, {
    String? text,
    bool showAlert = false,
  }) async {
    final id = context.callbackQueryId;
    if (id == null) {
      return;
    }
    try {
      await _sender.answerCallbackQuery(id, text: text, showAlert: showAlert);
    } on TelegramApiException catch (error, stackTrace) {
      l.w('answerCallbackQuery failed: $error', stackTrace);
    }
  }

  Future<bool> _handleCallback(PrivateMessageContext context) async {
    final data = context.callbackData ?? '';
    switch (data) {
      case MessageTemplates.cbGuide:
        return _deliverGuide(context, sendWarmup: true);
      case MessageTemplates.cbEnroll:
        return _showEnroll(context);
      case MessageTemplates.cbPayFull:
        return _showOffer(context, PaymentKind.full);
      case MessageTemplates.cbPayDeposit:
        return _showOffer(context, PaymentKind.deposit);
      case MessageTemplates.cbPayInstallment:
        return _showOffer(context, PaymentKind.installment);
      case MessageTemplates.cbPayRemainder:
        return _showOffer(context, PaymentKind.remainder);
      case MessageTemplates.cbToggleOffer:
        return _toggleOfferCheck(context, offer: true);
      case MessageTemplates.cbTogglePersonalData:
        return _toggleOfferCheck(context, offer: false);
      case MessageTemplates.cbGoToPay:
        return _confirmOfferAndPay(context);
      case MessageTemplates.cbOptOut:
        return _optOut(context);
      case MessageTemplates.cbNewInvite:
        return _reissueInvite(context);
      case MessageTemplates.cbBroadcastGuide:
        return _confirmBroadcast(context);
      case MessageTemplates.cbBroadcastCancel:
        _flowByUserId.remove(context.userId);
        return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
      case MessageTemplates.cbGuideSave:
        return _savePendingGuide(context);
      case MessageTemplates.cbGuideDiscard:
        _flowByUserId.remove(context.userId);
        return _send(
          context,
          _templates.adminGuideDiscarded(),
          replyMarkup: _templates.adminMenuKeyboard(),
        );
    }
    if (data.startsWith(MessageTemplates.cbContinuePay)) {
      return _continuePay(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbContinuePay),
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminPaid)) {
      return _adminMarkPaid(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminPaid),
        PaymentKind.full,
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminDeposit)) {
      return _adminMarkPaid(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminDeposit),
        PaymentKind.deposit,
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminCancel)) {
      return _adminCancel(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminCancel),
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminInvite)) {
      return _adminReinvite(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminInvite),
      );
    }
    return false;
  }

  Future<bool> _handleUserText(PrivateMessageContext context) async {
    final text = context.text;
    if (text == null) {
      return false;
    }
    if (text == MessageTemplates.buttonGuide || text == '/guide') {
      return _deliverGuide(context, sendWarmup: true);
    }
    if (text == MessageTemplates.buttonEnroll || text == '/enroll') {
      return _showEnroll(context);
    }
    if (text == MessageTemplates.buttonMenu || text == '/menu') {
      return _showMenu(context);
    }
    if (text == MessageTemplates.buttonHelp || text == '/help') {
      if (_adminGate.isConfiguredAdmin(context.userId)) {
        return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
      }
      return _send(context, _templates.help(), replyMarkup: _homeKeyboard(context.userId!));
    }
    return _showMenu(context);
  }

  Future<bool> _send(
    PrivateMessageContext context,
    String text, {
    Map<String, Object?>? replyMarkup,
  }) async {
    final chatId = context.chatId;
    if (chatId == null) {
      return false;
    }
    await _sender.sendMessage(chatId, text, parseMode: 'HTML', replyMarkup: replyMarkup);
    return true;
  }
}
