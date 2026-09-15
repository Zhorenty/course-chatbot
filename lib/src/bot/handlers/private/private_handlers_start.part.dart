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
    final phase = _funnel.phaseOf(user);
    if (phase == FunnelPhase.checkout || phase == FunnelPhase.depositPaid) {
      if (await _syncPaidCheckout(context)) {
        return true;
      }
    }
    if (phase.showsCourseStatus) {
      return _showCourseStatus(context);
    }
    if (phase == FunnelPhase.checkout) {
      return _showEnroll(context);
    }
    if (phase == FunnelPhase.magnetIssued || phase == FunnelPhase.warming) {
      return _send(
        context,
        _templates.alreadyInFunnel(),
        richHtml: _templates.alreadyInFunnelRich(),
        replyMarkup: _homeKeyboard(user.userId),
      );
    }
    final destination = user.source ?? payload;
    if (_funnel.opensCourseCard(destination)) {
      if (_launch != null) {
        await _showEnroll(context, markIntent: false);
        return _send(context, _templates.menuPinned(), replyMarkup: _homeKeyboard(user.userId));
      }
      return _send(
        context,
        _templates.startCourseCard(launch: _launch),
        richHtml: _templates.startCourseCardRich(launch: _launch),
        replyMarkup: _homeKeyboard(user.userId),
      );
    }
    return _send(
      context,
      _templates.startGuideOffer(),
      richHtml: _templates.startGuideOfferRich(),
      replyMarkup: _homeKeyboard(user.userId),
    );
  }

  Future<bool> _showHome(PrivateMessageContext context) async {
    final user = _course.getUser(context.userId!);
    if (user == null) {
      return _handleStart(context, '/start');
    }
    if (_adminGate.isConfiguredAdmin(user.userId)) {
      return _send(context, _templates.adminMenu(), replyMarkup: _templates.adminMenuKeyboard());
    }
    return _sendHelp(context);
  }

  Future<bool> _sendHelp(PrivateMessageContext context) {
    return _send(
      context,
      _templates.help(),
      richHtml: _templates.helpRich(),
      replyMarkup: _templates.helpKeyboard(),
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
