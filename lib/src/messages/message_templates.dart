import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/messages/html_escaper.dart';
import 'package:course_chatbot/src/messages/keyboards/keyboard_builders.dart';
import 'package:intl/intl.dart';

part 'templates/message_templates_keyboards.part.dart';

/// Stub copy until the customer delivers marketing texts.
final class MessageTemplates {
  MessageTemplates({String? botUsername}) : _botUsername = botUsername;

  final String? _botUsername;
  final DateFormat _date = DateFormat('dd.MM.yyyy');

  static const String buttonGuide = 'Получить гайд';
  static const String buttonEnroll = 'Записаться на курс';
  static const String buttonMenu = 'Меню';
  static const String buttonHelp = 'Помощь';
  static const String buttonOptOut = 'Не писать';
  static const String buttonPayFull = 'Оплатить полностью';
  static const String buttonPayDeposit = 'Предоплата';
  static const String buttonPayInstallment = 'Рассрочка';
  static const String buttonPayRemainder = 'Доплатить';
  static const String buttonContinuePay = 'Продолжить оплату';
  static const String buttonNewInvite = 'Новая ссылка в канал';
  static const String buttonAdminSearch = 'Поиск человека';
  static const String buttonAdminBroadcast = 'Рассылка';
  static const String buttonAdminMenu = 'Админка';

  static const String cbGuide = 'g';
  static const String cbEnroll = 'e';
  static const String cbPayFull = 'pf';
  static const String cbPayDeposit = 'pd';
  static const String cbPayInstallment = 'pi';
  static const String cbPayRemainder = 'pr';
  static const String cbOptOut = 'o';
  static const String cbContinuePay = 'cp:';
  static const String cbNewInvite = 'ni';
  static const String cbAdminPaid = 'ap:';
  static const String cbAdminDeposit = 'ad:';
  static const String cbAdminCancel = 'ac:';
  static const String cbAdminInvite = 'ai:';
  static const String cbBroadcastGuide = 'bg';
  static const String cbBroadcastCancel = 'bx';

  String startGuideOffer({String? source}) {
    final mark = source == null ? 'без метки' : escapeHtml(source);
    return '<b>Гайд по колористике</b>\n\n'
        'Источник: $mark.\n'
        'Нажми кнопку — пришлю материал в этот чат. Имя, почту и телефон не спрашиваю.';
  }

  String startCourseCard({String? source}) {
    final mark = source == null ? 'без метки' : escapeHtml(source);
    return '<b>Запись на курс</b>\n\n'
        'Источник: $mark.\n'
        'Можно сразу записаться или сначала забрать бесплатный гайд.';
  }

  String alreadyHasAccess() {
    return '<b>Доступ уже есть</b>\n\n'
        'Ты в канале этого запуска. Если ссылка потерялась — нажми «Новая ссылка».';
  }

  String menu(UserProfile user) {
    return '<b>Меню</b>\n\n'
        'Сейчас: ${escapeHtml(_phaseLabel(user.funnelPhase))}.\n'
        'Дальше: гайд, запись на курс или помощь.';
  }

  String help() {
    return 'Это бот запуска курса.\n'
        'Гайд — бесплатно. Запись — через оплату. '
        'Если что-то сломалось с оплатой, напиши сюда — админ увидит.';
  }

  String guideReady() {
    return 'Гайд ушёл. Сразу ниже — первое сообщение прогрева.';
  }

  String guideAsUrl(String url) {
    return 'Материал здесь: ${escapeHtml(url)}';
  }

  String guideMissing() {
    return 'Гайд ещё не загружен. Напиши «Помощь» — админ пришлёт файл.';
  }

  String warmupStep(String stepKey) {
    return switch (stepKey) {
      'warmup_0' => '<b>Первое касание после гайда</b>\n\n'
          'Это заглушка. Здесь будет текст заказчика.\n'
          'Можно сразу записаться на курс.',
      'warmup_d1' => '<b>Прогрев, день 1</b>\n\nЗаглушка цепочки. Можно записаться.',
      'warmup_d3' => '<b>Прогрев, день 3</b>\n\nЗаглушка цепочки. Можно записаться.',
      _ => '<b>Прогрев</b>\n\nШаг <code>${escapeHtml(stepKey)}</code>. Можно записаться.',
    };
  }

  String optOutConfirmed() {
    return 'Ок, продающие сообщения больше не пришлю. '
        'Меню, гайд и запись остаются. Напоминания про начатую оплату тоже.';
  }

  String enrollOptions(Launch launch) {
    final price = launch.priceFullKopecks > 0
        ? formatRubFromKopecks(launch.priceFullKopecks)
        : 'цену уточнит админ';
    final offer = launch.offerUrl == null ? '' : '\nОферта: ${escapeHtml(launch.offerUrl!)}';
    final deposit = launch.hasDepositOption
        ? '\nПредоплата: ${formatRubFromKopecks(launch.depositKopecks)}.'
        : '';
    return '<b>Запись на курс</b>\n\n'
        'Полная оплата: $price.$deposit\n'
        'Рассрочка — на странице кассы, бот график не ведёт.$offer';
  }

  String payButton(String url) {
    if (url.isEmpty) {
      return payManualFallback();
    }
    return 'Ссылка на оплату готова. После успешного платежа статус обновится сам.';
  }

  String payManualFallback() {
    return 'Онлайн-касса ещё не подключена или вернула ошибку. '
        'Напиши админу — отметит оплату вручную.';
  }

  String paymentSucceeded() {
    return '<b>Оплата прошла</b>\n\nДальше — одноразовая ссылка в канал этого запуска.';
  }

  String depositSucceeded(CourseOrder order) {
    final due = order.dueAt == null ? 'по договорённости' : _date.format(order.dueAt!.toLocal());
    return '<b>Предоплата получена</b>\n\n'
        'Остаток: ${formatRubFromKopecks(order.amountDueKopecks)} до $due.\n'
        'В канал пущу после полной суммы. Место никого не держит — лимита нет.';
  }

  String inviteMessage(String link) {
    return 'Вот одноразовая ссылка в канал запуска:\n${escapeHtml(link)}\n\n'
        'На одного человека. Если не открылась — запроси новую, старая отключится.';
  }

  String inviteUnavailable() {
    return 'Оплата есть, но канал ещё не привязан. Админ выдаст доступ вручную.';
  }

  String abandonedFirst() {
    return 'Оформление началось, оплата не завершилась. Можно продолжить.';
  }

  String abandonedSecond() {
    return 'Напоминаю про незакрытую оплату. Ссылка ещё действует.';
  }

  String remainderReminder(CourseOrder order) {
    final due = order.dueAt == null ? 'скоро' : _date.format(order.dueAt!.toLocal());
    return 'Доплата по курсу: остаток ${formatRubFromKopecks(order.amountDueKopecks)}, срок $due.';
  }

  String adminMenu() {
    return '<b>Админка</b>\n\nПоиск человека, карточка, ручной статус, рассылка сегменту. '
        'Цифры воронки — в Google Sheets.';
  }

  String adminAskSearch() {
    return 'Пришли Telegram user id или @username.';
  }

  String adminNotFound(String query) {
    return 'Никого не нашёл по «${escapeHtml(query)}».';
  }

  String adminCard({
    required UserProfile user,
    CourseOrder? order,
    ChannelAccess? access,
    List<ConversationLogEntry> dialog = const <ConversationLogEntry>[],
  }) {
    final source = user.source ?? '—';
    final orderLine = order == null
        ? 'заказа нет'
        : '#${order.id} ${order.status.storageValue}, '
            'оплачено ${formatRubFromKopecks(order.amountPaidKopecks)} '
            'из ${formatRubFromKopecks(order.priceFullKopecks)}';
    final channel = access == null
        ? 'канала нет'
        : (access.hasJoined
            ? 'вошёл ${access.joinedAt!.toIso8601String()}'
            : (access.inviteLink == null ? 'ссылка не выдана' : 'ссылка выдана, входа нет'));
    final opt = user.warmupOptOut ? 'да' : 'нет';
    final blocked = user.botBlocked ? 'да' : 'нет';
    final buf = StringBuffer()
      ..writeln('<b>Карточка</b> ${escapeHtml(user.displayName)}')
      ..writeln('id <code>${user.userId}</code>')
      ..writeln('источник: <code>${escapeHtml(source)}</code>')
      ..writeln('фаза: ${escapeHtml(_phaseLabel(user.funnelPhase))}')
      ..writeln('заказ: ${escapeHtml(orderLine)}')
      ..writeln('канал: ${escapeHtml(channel)}')
      ..writeln('не писать: $opt · блок бота: $blocked');
    if (dialog.isNotEmpty) {
      buf.writeln('\nПоследние сообщения:');
      for (final entry in dialog.take(8)) {
        final dir = entry.direction == ConversationDirection.outbound ? '→' : '←';
        buf.writeln('$dir ${escapeHtml(entry.textPreview ?? entry.contentType.name)}');
      }
    }
    return buf.toString();
  }

  String adminAskBroadcast() {
    return 'Пришли текст рассылки. Сегмент: получили гайд и не купили.';
  }

  String adminBroadcastDone({required int sent, required int failed, required int total}) {
    return 'Рассылка: отправлено $sent, ошибок $failed, в сегменте $total.';
  }

  String adminMarkedPaid() => 'Оплата проставлена вручную.';

  String adminCancelled() => 'Статус снят, invite отозван если был.';

  String adminGuideSaved(String fileId) {
    return 'Гайд сохранён. file_id: <code>${escapeHtml(fileId)}</code>';
  }

  String adminBroadcastConfirm() {
    return 'Отправить этот текст сегменту «получили гайд и не купили»?';
  }

  String adminInviteReissued() => 'Invite перевыдан.';

  static int? idFromCallback(String data, String prefix) {
    if (!data.startsWith(prefix)) {
      return null;
    }
    return int.tryParse(data.substring(prefix.length));
  }

  String deepLink(String payload) {
    final bot = _botUsername;
    if (bot == null || bot.isEmpty) {
      return payload;
    }
    return 'https://t.me/$bot?start=$payload';
  }

  String _phaseLabel(FunnelPhase phase) => switch (phase) {
        FunnelPhase.lead => 'пришёл',
        FunnelPhase.magnetIssued => 'получил гайд',
        FunnelPhase.warming => 'в прогреве',
        FunnelPhase.checkout => 'начал оформление',
        FunnelPhase.depositPaid => 'предоплата',
        FunnelPhase.paid => 'оплачено',
        FunnelPhase.accessGranted => 'доступ выдан',
        FunnelPhase.cancelled => 'отменено',
      };
}
