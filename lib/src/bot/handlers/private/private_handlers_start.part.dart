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
      return _startAccessReply(context, user.userId);
    }
    if (user.funnelPhase.isPaidOrAccess) {
      final handled = await _reissueInvite(context);
      if (handled) {
        return true;
      }
      return _send(context, _templates.inviteUnavailable());
    }
    if (user.funnelPhase == FunnelPhase.depositPaid) {
      final order = _course.latestOpenOrder(user.userId);
      if (order != null) {
        return _send(
          context,
          _templates.depositSucceeded(order),
          replyMarkup: _templates.remainderKeyboard(),
        );
      }
    }
    if (user.funnelPhase == FunnelPhase.checkout) {
      return _showEnroll(context);
    }
    if (user.funnelPhase == FunnelPhase.magnetIssued || user.funnelPhase == FunnelPhase.warming) {
      return _send(
        context,
        _templates.alreadyInFunnel(),
        replyMarkup: _templates.warmupKeyboard(showEnroll: true),
      );
    }
    final justCreated =
        _nowProvider().toUtc().difference(user.firstStartedAt.toUtc()).abs() <
        const Duration(seconds: 2);
    final destination = user.source ?? payload;
    if (_funnel.opensCourseCard(destination)) {
      await _send(
        context,
        _templates.startCourseCard(launch: _launch),
        replyMarkup: _templates.courseCardKeyboard(),
      );
      if (justCreated) {
        await _pinUserMenu(context, user.userId);
      }
      return true;
    }
    await _send(
      context,
      _templates.startGuideOffer(),
      replyMarkup: _templates.guideOfferKeyboard(showEnroll: true),
    );
    if (justCreated) {
      await _pinUserMenu(context, user.userId);
    }
    return true;
  }

  Future<bool> _pinUserMenu(PrivateMessageContext context, int userId) {
    return _send(
      context,
      _templates.menuPinned(),
      replyMarkup: _templates.userMenuKeyboard(hasAccess: false),
    );
  }

  Future<bool> _startAccessReply(PrivateMessageContext context, int userId) {
    final launch = _launch;
    final access = launch == null ? null : _course.accessFor(userId: userId, launchId: launch.id);
    final link = access?.inviteLink;
    if (access != null &&
        !access.hasJoined &&
        access.revokedAt == null &&
        link != null &&
        link.isNotEmpty) {
      return _send(
        context,
        _templates.unjoinedInviteReminder(link),
        replyMarkup: _templates.unjoinedInviteKeyboard(link),
      );
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
