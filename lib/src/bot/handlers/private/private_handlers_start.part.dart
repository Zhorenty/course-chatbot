part of 'package:course_chatbot/src/bot/handlers/private_handlers.dart';

extension _PrivateHandlersStart on PrivateHandlers {
  Future<bool> _handleStart(PrivateMessageContext context, String text) async {
    final payload = _parseStartPayload(text);
    final user = _funnel.start(
      userId: context.userId!,
      username: context.username,
      firstName: context.firstName,
      payload: payload,
    );
    if (_adminGate.isConfiguredAdmin(user.userId)) {
      return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
    }
    if (user.funnelPhase.hasAccess) {
      await _startAccessReply(context, user.userId);
      return _pinUserMenu(context, hasAccess: true);
    }
    if (user.funnelPhase.isPaidOrAccess) {
      await _send(context, _templates.inviteUnavailable());
      return _pinUserMenu(context, hasAccess: true);
    }
    if (user.funnelPhase == FunnelPhase.depositPaid) {
      final order = _course.latestOpenOrder(user.userId);
      if (order != null) {
        await _send(
          context,
          _templates.depositSucceeded(order),
          replyMarkup: _templates.remainderKeyboard(),
        );
        return _pinUserMenu(context, hasAccess: false);
      }
    }
    if (user.funnelPhase == FunnelPhase.checkout) {
      await _showEnroll(context);
      return _pinUserMenu(context, hasAccess: false);
    }
    if (user.funnelPhase == FunnelPhase.magnetIssued || user.funnelPhase == FunnelPhase.warming) {
      return _send(
        context,
        _templates.alreadyInFunnel(),
        replyMarkup: _templates.userMenuKeyboard(hasAccess: false),
      );
    }
    final destination = user.source ?? payload;
    if (_funnel.opensCourseCard(destination)) {
      await _send(
        context,
        _templates.startCourseCard(launch: _launch),
        replyMarkup: _templates.courseCardKeyboard(),
      );
      return _pinUserMenu(context, hasAccess: false);
    }
    await _send(
      context,
      _templates.startGuideOffer(),
      replyMarkup: _templates.guideOfferKeyboard(showEnroll: true),
    );
    return _pinUserMenu(context, hasAccess: false);
  }

  Future<bool> _pinUserMenu(PrivateMessageContext context, {required bool hasAccess}) {
    return _send(
      context,
      _templates.menuPinned(),
      replyMarkup: _templates.userMenuKeyboard(hasAccess: hasAccess),
    );
  }

  Future<bool> _startAccessReply(PrivateMessageContext context, int userId) {
    final launch = _launch;
    final access = launch == null ? null : _course.accessFor(userId: userId, launchId: launch.id);
    if (access != null && !access.hasJoined && access.revokedAt == null) {
      return _send(context, _templates.unjoinedInviteReminder());
    }
    return _send(context, _templates.alreadyHasAccess(), replyMarkup: _templates.accessKeyboard());
  }

  Future<bool> _showHome(PrivateMessageContext context) async {
    final user = _course.getUser(context.userId!);
    if (user == null) {
      return _handleStart(context, '/start');
    }
    if (_adminGate.isConfiguredAdmin(user.userId)) {
      return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
    }
    return _send(context, _templates.help(), replyMarkup: _homeKeyboard(user.userId));
  }

  String? _parseStartPayload(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return null;
    }
    return parts[1].trim().toLowerCase();
  }
}
