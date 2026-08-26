part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersAdmin on PrivateHandlers {
  Future<bool> _handleAdminMessage(PrivateMessageContext context) async {
    final userId = context.userId!;
    final text = context.text;
    final flow = _flowByUserId[userId];
    if (text == MessageTemplates.buttonAdminMenu || text == '/admin') {
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.idle);
      return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
    }
    if (text == MessageTemplates.buttonAdminSearch) {
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.adminSearch);
      return _send(context, _templates.adminAskSearch());
    }
    if (text == MessageTemplates.buttonAdminBroadcast) {
      _flowByUserId[userId] = const PrivateFlowState(step: PrivateFlowStep.adminBroadcastText);
      return _send(context, _templates.adminAskBroadcast());
    }
    final fileId = extractDocumentFileId(context.message);
    if (fileId != null && text == null) {
      _course.setLeadMagnetFileId(fileId);
      return _send(context, _templates.adminGuideSaved(fileId));
    }
    if (flow?.step == PrivateFlowStep.adminSearch && text != null) {
      return _showAdminCard(context, text);
    }
    if (flow?.step == PrivateFlowStep.adminBroadcastText && text != null) {
      _flowByUserId[userId] = PrivateFlowState(
        step: PrivateFlowStep.adminBroadcastText,
        broadcastText: text,
      );
      return _send(
        context,
        _templates.adminBroadcastConfirm(),
        replyMarkup: _templates.broadcastConfirmKeyboard(),
      );
    }
    return false;
  }

  Future<bool> _showAdminCard(PrivateMessageContext context, String query) async {
    final matches = _course.searchUsers(query);
    if (matches.isEmpty) {
      return _send(context, _templates.adminNotFound(query));
    }
    final user = matches.first;
    final launch = _launch;
    final order = _course.latestOrder(user.userId);
    final access =
        launch == null ? null : _course.accessFor(userId: user.userId, launchId: launch.id);
    final dialog = _course.dialogForUser(user.userId);
    _flowByUserId[context.userId!] = PrivateFlowState(
      step: PrivateFlowStep.idle,
      adminTargetUserId: user.userId,
    );
    return _send(
      context,
      _templates.adminCard(user: user, order: order, access: access, dialog: dialog),
      replyMarkup: _templates.adminCardKeyboard(user.userId),
    );
  }

  Future<bool> _adminMarkPaid(
    PrivateMessageContext context,
    int? targetUserId,
    PaymentKind kind,
  ) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final launch = _launch;
    if (launch == null) {
      return _send(context, _templates.payManualFallback());
    }
    _course.ensureUser(userId: targetUserId, now: _nowProvider());
    final order = _checkout.startOrReuseOrder(
      userId: targetUserId,
      launch: launch,
      kind: kind,
    );
    final amount = _checkout.amountFor(launch, order, kind);
    final result = await _checkout.applyManualPaid(
      order: order,
      launch: launch,
      kind: kind,
      amountKopecks: amount <= 0 ? launch.priceFullKopecks : amount,
    );
    await _notifyPaymentResult(result);
    return _send(context, _templates.adminMarkedPaid());
  }

  Future<bool> _adminCancel(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final launch = _launch;
    final order = _course.latestOrder(targetUserId);
    if (launch == null || order == null) {
      return _send(context, _templates.adminNotFound('$targetUserId'));
    }
    await _checkout.cancel(order: order, launch: launch);
    return _send(context, _templates.adminCancelled());
  }

  Future<bool> _adminReinvite(PrivateMessageContext context, int? targetUserId) async {
    if (!_adminGate.isConfiguredAdmin(context.userId) || targetUserId == null) {
      return false;
    }
    final launch = _launch;
    final order = _course.latestOrder(targetUserId);
    if (launch == null || order == null) {
      return false;
    }
    final link = await _access.issueInvite(
      userId: targetUserId,
      orderId: order.id,
      launch: launch,
      reissue: true,
    );
    if (link != null) {
      await _sender.sendMessage(
        targetUserId,
        _templates.inviteMessage(link),
        parseMode: 'HTML',
        replyMarkup: _templates.accessKeyboard(),
      );
    }
    return _send(
        context, link == null ? _templates.inviteUnavailable() : _templates.adminInviteReissued());
  }

  Future<bool> _confirmBroadcast(PrivateMessageContext context) async {
    if (!_adminGate.isConfiguredAdmin(context.userId)) {
      return false;
    }
    final text = _flowByUserId[context.userId!]?.broadcastText;
    _flowByUserId.remove(context.userId);
    if (text == null || text.isEmpty) {
      return _send(context, _templates.adminAskBroadcast());
    }
    final result = await _broadcast.send(
      segment: BroadcastSegment.guideNotPaid,
      htmlText: escapeHtml(text),
    );
    return _send(
      context,
      _templates.adminBroadcastDone(
        sent: result.sent,
        failed: result.failed,
        total: result.total,
      ),
    );
  }
}
