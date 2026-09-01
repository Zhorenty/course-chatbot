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
      case MessageTemplates.cbCatalogMenu:
        return _showCatalogList(context);
      case MessageTemplates.cbCatalogNew:
        return _startCatalogCreate(context);
      case MessageTemplates.cbCatalogCreateYes:
        return _confirmCatalogCreate(context);
      case MessageTemplates.cbCatalogCreateNo:
        return _showCatalogList(context);
      case MessageTemplates.cbCatalogActiveYes:
        return _setCatalogCreateActive(context, true);
      case MessageTemplates.cbCatalogActiveNo:
        return _setCatalogCreateActive(context, false);
      case MessageTemplates.cbCatalogKeepCode:
        return _keepCatalogCreateCode(context);
      case MessageTemplates.cbCatalogSkipChannel:
        return _skipCatalogChannel(context);
      case MessageTemplates.cbLinksMenu:
        return _showLinksList(context);
      case MessageTemplates.cbLinksNew:
        return _startLinksCreate(context);
      case MessageTemplates.cbLinksCreateYes:
        return _confirmLinksCreate(context);
      case MessageTemplates.cbLinksCreateNo:
        return _showLinksList(context);
      case MessageTemplates.cbLinksDestGuide:
        return _setLinksCreateDestination(context, AcquisitionDestination.guide);
      case MessageTemplates.cbLinksDestCourse:
        return _setLinksCreateDestination(context, AcquisitionDestination.course);
      case MessageTemplates.cbLinksSkipLaunch:
        return _setLinksCreateLaunch(context, skip: true);
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
      case MessageTemplates.cbToggleOffer:
      case MessageTemplates.cbTogglePersonalData:
        return _toggleOfferCheck(context);
      case MessageTemplates.cbGoToPay:
        return _confirmOfferAndPay(context);
      case MessageTemplates.cbOptOut:
        return _optOut(context);
      case MessageTemplates.cbHelp:
        return _showHome(context);
      case MessageTemplates.cbNewInvite:
        return _send(context, _templates.inviteAskAdmin());
      case MessageTemplates.cbBroadcastSend:
        return _confirmBroadcast(context);
      case MessageTemplates.cbBroadcastSegmentsDone:
        return _confirmBroadcastSegments(context);
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
      // TODO(mvp-reset): remove with the admin «Очистить воронку» button.
      case MessageTemplates.cbAdminClearFunnelConfirm:
        return _adminClearFunnel(context);
      case MessageTemplates.cbAdminClearFunnelAbort:
        if (!_adminGate.isConfiguredAdmin(context.userId)) {
          return false;
        }
        return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
    }
    if (data.startsWith(MessageTemplates.cbBroadcastSegment)) {
      return _toggleBroadcastSegment(context, MessageTemplates.segmentFromCallback(data));
    }
    if (data.startsWith(MessageTemplates.cbContinuePay)) {
      return _continuePay(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbContinuePay),
      );
    }
    if (data.startsWith(MessageTemplates.cbPayRemainder)) {
      return _showOffer(
        context,
        PaymentKind.remainder,
        orderId: MessageTemplates.idFromCallback(data, MessageTemplates.cbPayRemainder),
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminStatusSet)) {
      final parsed = MessageTemplates.adminStatusFromCallback(data);
      return _adminSetPaymentStatus(context, parsed?.userId, parsed?.status);
    }
    if (data.startsWith(MessageTemplates.cbAdminPaidConfirm)) {
      return _adminSetPaymentStatus(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminPaidConfirm),
        AdminPaymentStatus.paid,
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminDepositConfirm)) {
      return _adminSetPaymentStatus(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminDepositConfirm),
        AdminPaymentStatus.deposit,
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminStatusMenu) ||
        data.startsWith(MessageTemplates.cbAdminPaid) ||
        data.startsWith(MessageTemplates.cbAdminDeposit)) {
      final prefix = data.startsWith(MessageTemplates.cbAdminStatusMenu)
          ? MessageTemplates.cbAdminStatusMenu
          : data.startsWith(MessageTemplates.cbAdminPaid)
          ? MessageTemplates.cbAdminPaid
          : MessageTemplates.cbAdminDeposit;
      return _adminShowStatusPicker(context, MessageTemplates.idFromCallback(data, prefix));
    }
    if (data.startsWith(MessageTemplates.cbAdminCancelConfirm)) {
      return _adminCancel(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbAdminCancelConfirm),
      );
    }
    if (data.startsWith(MessageTemplates.cbAdminCancel)) {
      return _adminAskCardCancel(
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
    if (data.startsWith(MessageTemplates.cbCatalogDeleteYes)) {
      return _confirmCatalogDelete(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbCatalogDeleteYes),
      );
    }
    if (data.startsWith(MessageTemplates.cbCatalogDelete)) {
      return _askCatalogDelete(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbCatalogDelete),
      );
    }
    if (data.startsWith(MessageTemplates.cbCatalogField)) {
      final parsed = MessageTemplates.catalogFieldFromCallback(data);
      return _askCatalogEditField(context, parsed?.id, parsed?.field);
    }
    if (data.startsWith(MessageTemplates.cbCatalogEdit)) {
      return _showCatalogFields(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbCatalogEdit),
      );
    }
    if (data.startsWith(MessageTemplates.cbCatalogActivate)) {
      return _activateCatalogLaunch(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbCatalogActivate),
      );
    }
    if (data.startsWith(MessageTemplates.cbCatalogOpen)) {
      return _showCatalogCard(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbCatalogOpen),
      );
    }
    if (data.startsWith(MessageTemplates.cbLinksDeleteYes)) {
      return _confirmLinksDelete(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbLinksDeleteYes),
      );
    }
    if (data.startsWith(MessageTemplates.cbLinksDelete)) {
      return _askLinksDelete(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbLinksDelete),
      );
    }
    if (data.startsWith(MessageTemplates.cbLinksField)) {
      final parsed = MessageTemplates.linksFieldFromCallback(data);
      return _askLinksEditField(context, parsed?.index, parsed?.field);
    }
    if (data.startsWith(MessageTemplates.cbLinksEdit)) {
      return _showLinksFields(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbLinksEdit),
      );
    }
    if (data.startsWith(MessageTemplates.cbLinksOpen)) {
      return _showLinksCard(
        context,
        MessageTemplates.idFromCallback(data, MessageTemplates.cbLinksOpen),
      );
    }
    if (data.startsWith(MessageTemplates.cbLinksPickLaunch)) {
      return _setLinksCreateLaunch(
        context,
        launchId: MessageTemplates.idFromCallback(data, MessageTemplates.cbLinksPickLaunch),
      );
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
    if (text == MessageTemplates.buttonCourseStatus || text == '/course') {
      return _showCourseStatus(context);
    }
    if (text == '👤 Профиль' || text == '📋 Меню' || text == '/profile' || text == '/menu') {
      return _showHome(context);
    }
    if (text == MessageTemplates.buttonHelp || text == '/help') {
      return _showHome(context);
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
          _templates.adminIncomingUserMessage(
            user: user,
            text: context.text,
            phase: _funnel.phaseOf(user),
          ),
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
