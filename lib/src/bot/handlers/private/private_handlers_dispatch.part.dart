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
    if (context.message != null) {
      _course.appendConversation(
        direction: ConversationDirection.inbound,
        peerUserId: userId,
        peerUsername: context.username,
        chatId: chatId,
        telegramMessageId: asTelegramInt(context.message?['message_id']),
        contentType: _inboundContentType(context.message),
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
      case MessageTemplates.cbHelp:
        return _showHome(context);
      case MessageTemplates.cbNewInvite:
        return _send(
          context,
          _templates.inviteAskAdmin(),
          replyMarkup: _templates.accessKeyboard(),
        );
      case MessageTemplates.cbBroadcastSend:
        return _confirmBroadcast(context);
      case MessageTemplates.cbBroadcastOtherSegment:
        return _reselectBroadcastSegment(context);
      case MessageTemplates.cbBroadcastCancel:
        return _cancelBroadcast(context);
      case MessageTemplates.cbBroadcastToggleOptOut:
        return _toggleBroadcastOptOut(context);
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
    if (data.startsWith(MessageTemplates.cbBroadcastSegment)) {
      return _selectBroadcastSegment(context, MessageTemplates.segmentFromCallback(data));
    }
    if (data.startsWith(MessageTemplates.cbContinuePay)) {
      return _continuePay(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbContinuePay),
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminPaidConfirm)) {
      return _adminMarkPaid(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminPaidConfirm),
        PaymentKind.full,
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminPaid)) {
      return _adminAskConfirm(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminPaid),
        kind: _AdminConfirmKind.paid,
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminDepositConfirm)) {
      return _adminMarkPaid(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminDepositConfirm),
        PaymentKind.deposit,
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminDeposit)) {
      return _adminAskConfirm(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminDeposit),
        kind: _AdminConfirmKind.deposit,
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminCancelConfirm)) {
      return _adminCancel(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminCancelConfirm),
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminCancel)) {
      return _adminAskConfirm(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminCancel),
        kind: _AdminConfirmKind.cancel,
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminInvite)) {
      return _adminReinvite(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminInvite),
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminCard)) {
      if (!_adminGate.isConfiguredAdmin(context.userId)) {
        return false;
      }
      final targetId = MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminCard);
      if (targetId == null) {
        return false;
      }
      return _showAdminCard(context, '$targetId');
    }
    if (data.startsWith(MessageTemplates.cbAdminDm)) {
      return _adminAskDm(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminDm),
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminActionAbort)) {
      return _adminAbortConfirm(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminActionAbort),
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminCreate)) {
      final targetId = MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminCreate);
      if (targetId == null) {
        return false;
      }
      return _adminEnsureAndShowCard(context, targetId);
    }
    return false;
  }

  Future<bool> _handleUserText(PrivateMessageContext context) async {
    final text = context.text;
    if (text == MessageTemplates.buttonGuide || text == '/guide') {
      return _deliverGuide(context, sendWarmup: true);
    }
    if (text == MessageTemplates.buttonEnroll || text == '/enroll') {
      return _showEnroll(context);
    }
    if (text == '👤 Профиль' || text == '📋 Меню' || text == '/profile' || text == '/menu') {
      return _showHome(context);
    }
    if (text == MessageTemplates.buttonHelp || text == '/help') {
      if (_adminGate.isConfiguredAdmin(context.userId)) {
        return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
      }
      return _send(context, _templates.help(), replyMarkup: _homeKeyboard(context.userId!));
    }
    if (text != null && text.startsWith('/')) {
      return _showHome(context);
    }
    if (_adminGate.isConfiguredAdmin(context.userId)) {
      return text == null ? false : _showHome(context);
    }
    if (context.message == null) {
      return false;
    }
    return _escalateToAdmin(context);
  }

  Future<bool> _escalateToAdmin(PrivateMessageContext context) async {
    final userId = context.userId!;
    final chatId = context.chatId!;
    final user = _course.getUser(userId);
    if (user == null) {
      return _showHome(context);
    }
    final targets = _adminGate.notificationChatIds(_adminChatId).difference(<int>{chatId});
    var delivered = false;
    for (final target in targets) {
      try {
        await _sender.sendMessage(
          target,
          _templates.adminIncomingUserMessage(user: user, text: context.text),
          parseMode: 'HTML',
          disableNotification: false,
          replyMarkup: _templates.adminIncomingKeyboard(user.userId),
        );
        delivered = true;
        final messageId = asTelegramInt(context.message?['message_id']);
        if (messageId == null) {
          continue;
        }
        try {
          await _sender.forwardMessage(
            chatId: target,
            fromChatId: chatId,
            messageId: messageId,
            disableNotification: false,
          );
        } on TelegramApiException catch (error, stackTrace) {
          l.w('forward to admin failed: $error', stackTrace);
        }
      } on Object catch (error, stackTrace) {
        l.w('admin notify failed: $error', stackTrace);
      }
    }
    if (!delivered) {
      return _send(context, _templates.helpForwardFailed(), replyMarkup: _homeKeyboard(userId));
    }
    return _send(context, _templates.helpReceived(), replyMarkup: _homeKeyboard(userId));
  }

  ConversationContentType _inboundContentType(Map<String, dynamic>? message) {
    if (message == null) {
      return ConversationContentType.other;
    }
    if (message['photo'] != null) {
      return ConversationContentType.photo;
    }
    if (message['document'] != null) {
      return ConversationContentType.document;
    }
    if (message['video'] != null) {
      return ConversationContentType.video;
    }
    if (message['text'] != null) {
      return ConversationContentType.text;
    }
    return ConversationContentType.other;
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
