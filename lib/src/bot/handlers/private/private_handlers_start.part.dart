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
    if (phase.showsCourseStatus) {
      await _showCourseStatus(context);
      return _pinUserMenu(context);
    }
    if (phase == FunnelPhase.checkout) {
      await _showEnroll(context);
      return _pinUserMenu(context);
    }
    if (phase == FunnelPhase.magnetIssued || phase == FunnelPhase.warming) {
      return _send(context, _templates.alreadyInFunnel(), replyMarkup: _homeKeyboard(user.userId));
    }
    final destination = user.source ?? payload;
    if (_funnel.opensCourseCard(destination)) {
      await _send(context, _templates.startCourseCard(launch: _launch));
      return _pinUserMenu(context);
    }
    await _send(context, _templates.startGuideOffer());
    return _pinUserMenu(context);
  }

  Future<bool> _pinUserMenu(PrivateMessageContext context) {
    return _send(context, _templates.menuPinned(), replyMarkup: _homeKeyboard(context.userId!));
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
