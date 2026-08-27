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
    final menu = _templates.userMenuKeyboard(hasAccess: user.funnelPhase.hasAccess);
    if (user.funnelPhase.hasAccess) {
      return _send(
        context,
        _templates.alreadyHasAccess(),
        replyMarkup: _templates.accessKeyboard(),
      );
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
    if (AcquisitionSource.opensCourseCard(payload)) {
      await _sender.sendMessage(
        context.chatId!,
        _templates.startCourseCard(launch: _launch),
        parseMode: 'HTML',
        replyMarkup: _templates.guideOfferKeyboard(showEnroll: true),
      );
      return _send(context, _templates.menu(user), replyMarkup: menu);
    }
    await _sender.sendMessage(
      context.chatId!,
      _templates.startGuideOffer(),
      parseMode: 'HTML',
      replyMarkup: _templates.guideOfferKeyboard(showEnroll: _funnel.shouldOfferEnroll(user)),
    );
    return _send(context, _templates.menu(user), replyMarkup: menu);
  }

  Future<bool> _showMenu(PrivateMessageContext context) async {
    final user = _course.getUser(context.userId!);
    if (user == null) {
      return _handleStart(context, '/start');
    }
    if (_adminGate.isConfiguredAdmin(user.userId)) {
      return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
    }
    return _send(
      context,
      _templates.menu(user),
      replyMarkup: _templates.userMenuKeyboard(hasAccess: user.funnelPhase.hasAccess),
    );
  }

  String? _parseStartPayload(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return null;
    }
    return parts[1].trim().toLowerCase();
  }
}
