import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/admin_payment_status.dart';
import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/catalog_admin.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/enrollment.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/domain/moscow_time.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/sales_window.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/messages/html_escaper.dart';
import 'package:course_chatbot/src/messages/keyboards/keyboard_builders.dart';
import 'package:course_chatbot/src/messages/rich_html.dart';
import 'package:intl/intl.dart';

part 'templates/message_templates_keyboards.part.dart';
part 'templates/message_templates_admin_catalog.part.dart';
part 'templates/message_templates_admin_links.part.dart';
part 'templates/message_templates_rich.part.dart';

/// User-facing copy and keyboards. Marketing tone lives here, not in handlers.
final class MessageTemplates {
  MessageTemplates({String? botUsername}) : _botUsername = botUsername;

  final String? _botUsername;
  final DateFormat _date = DateFormat('dd.MM.yyyy');
  final DateFormat _dateTime = DateFormat('dd.MM.yyyy HH:mm');

  static const String buttonGuide = 'Забрать гайд';
  static const String buttonEnroll = 'Записаться на курс';
  static const String buttonRsvp = 'Буду на эфире';
  static const String buttonCourseStatus = 'Мой курс';
  static const String buttonHelp = 'Помощь';
  static const String buttonOptOut = 'Отписаться от рассылки';
  static const String buttonPayFull = 'Оплатить';
  static const String buttonPayDeposit = 'Предоплата';
  static const String buttonPayInstallment = 'Рассрочка в кассе';
  static const String buttonPayRemainder = 'Доплатить';
  static const String buttonGoToPay = 'Перейти к оплате';
  static const String buttonContinuePay = 'Продолжить оплату';
  static const String buttonOpenInvite = 'Открыть канал';
  static const String buttonCopyInvite = 'Скопировать ссылку';
  static const String buttonAcceptConsent = 'Принимаю оферту';
  static const String buttonAdminSearch = '🔍 Поиск человека';
  static const String buttonAdminAddUser = '➕ Добавить на курс';
  static const String buttonAdminSheetsHub = '📊 Google Sheets';
  static const String buttonAdminCatalog = '📚 Управление курсами';
  static const String buttonAdminFunnelLogic = 'ℹ️ Логика воронки';
  static const String buttonAdminBroadcast = '📣 Рассылка';
  static const String buttonAdminLinks = '🔗 Управление диплинками';
  static const String buttonAdminSheets = '📊 Обновить Sheets';
  static const String buttonAdminBack = '↩️ Назад';
  // TODO(mvp-reset): remove this debug button after the first live launch.
  static const String buttonAdminClearFunnel = '🧹 Очистить воронку';
  static const String buttonAdminMenu = '🛠 Админка';
  static const String buttonAdminChangeStatus = '✏️ Изменить статус';
  static const String buttonAdminStatusUnpaid = '⏳ Не оплачено';
  static const String buttonAdminStatusDeposit = '💵 Предоплата';
  static const String buttonAdminStatusPaid = '✅ Оплачено полностью';
  static const String buttonAdminCancel = '🚫 Убрать с курса';
  static const String buttonAdminStatusBack = '↩️ К карточке';
  static const String buttonAdminReinvite = '🔗 Выдать ссылку в канал';
  static const String buttonAdminDm = '✉️ Написать';
  static const String buttonAdminConfirmYes = 'Убрать с курса';
  static const String buttonAdminConfirmNo = 'Оставить';
  static const String buttonAdminClearFunnelYes = 'Очистить воронку';
  static const String buttonAdminClearFunnelNo = 'Не очищать';
  static const String buttonAdminCreateUser = '➕ Создать карточку';
  static const String buttonAdminBroadcastSend = 'Отправить';
  static const String buttonAdminBroadcastContinue = 'Далее';
  static const String buttonAdminBroadcastOtherSegment = 'Изменить сегменты';
  static const String buttonAdminBroadcastCancel = '✖️ Отмена';
  static const String buttonAdminBroadcastSkipOptOut = 'Кроме «Не писать»';
  static const String buttonAdminBroadcastIncludeOptOut = 'Включая отписавшихся';
  static const String buttonAdminGuideSave = '💾 Сохранить гайд';
  static const String buttonAdminGuideDiscard = '✖️ Не сохранять';
  static const String buttonAdminOpenCard = 'Открыть карточку';
  static const String buttonAdminCatalogNew = '🆕 Создать курс';
  static const String buttonAdminCatalogEdit = '✏️ Изменить поле';
  static const String buttonAdminCatalogReplaceGuide = '📘 Заменить гайд';
  static const String buttonAdminCatalogAttachGuide = '📘 Прикрепить гайд';
  static const String buttonAdminCatalogActivate = '⭐ Сделать активным';
  static const String buttonAdminCatalogDelete = '🗑 Удалить';
  static const String buttonAdminCatalogBack = '↩️ К списку';
  static const String buttonAdminCatalogSave = '💾 Записать';
  static const String buttonAdminCatalogKeepCode = '✅ Оставить этот код';
  static const String buttonAdminCatalogSkipChannel = 'Без своего канала';
  static const String buttonAdminCatalogSkip = 'Пропустить';
  static const String buttonAdminCatalogYes = '✅ Да';
  static const String buttonAdminCatalogNo = '❌ Нет';
  static const String buttonAdminLinksNew = '🆕 Создать диплинк';
  static const String buttonAdminLinksEdit = '✏️ Изменить поле';
  static const String buttonAdminLinksDelete = '🗑 Удалить';
  static const String buttonAdminLinksBack = '↩️ К списку';
  static const String buttonAdminLinksSave = '💾 Записать';
  static const String buttonAdminLinksDestGuide = '📘 Гайд';
  static const String buttonAdminLinksDestCourse = '✨ Курс';
  static const String buttonAdminLinksSkipLaunch = 'Текущий набор';

  static const String cbGuide = 'g';
  static const String cbEnroll = 'e';
  static const String cbRsvp = 'wr';
  static const String cbPayFull = 'pf';
  static const String cbPayDeposit = 'pd';
  static const String cbPayInstallment = 'pi';
  static const String cbPayRemainder = 'pr:';
  static const String cbToggleOffer = 'oo';
  static const String cbTogglePersonalData = 'op';
  static const String cbGoToPay = 'og';
  static const String cbOptOut = 'o';
  static const String cbHelp = 'hp';
  static const String cbContinuePay = 'cp:';
  static const String cbNewInvite = 'ni';
  static const String cbAdminPaid = 'ap:';
  static const String cbAdminPaidConfirm = 'apy:';
  static const String cbAdminDeposit = 'ad:';
  static const String cbAdminDepositConfirm = 'ady:';
  static const String cbAdminCancel = 'ac:';
  static const String cbAdminCancelConfirm = 'acy:';
  static const String cbAdminInvite = 'ai:';
  static const String cbAdminCreate = 'an:';
  static const String cbAdminDm = 'am:';
  static const String cbAdminActionAbort = 'az:';
  static const String cbAdminStatusMenu = 'aq:';
  static const String cbAdminStatusSet = 'as:';
  static const String cbBroadcastSegment = 'bs:';
  static const String cbBroadcastSend = 'bp';
  static const String cbBroadcastSegmentsDone = 'bn';
  static const String cbBroadcastOtherSegment = 'br';
  static const String cbBroadcastCancel = 'bx';
  static const String cbBroadcastToggleOptOut = 'bt';
  static const String cbGuideSave = 'gs';
  static const String cbGuideDiscard = 'gx';
  static const String cbAdminCard = 'ak:';
  static const String cbCatalogMenu = 'cm';
  static const String cbCatalogNew = 'cn';
  static const String cbCatalogOpen = 'cl:';
  static const String cbCatalogEdit = 'ce:';
  static const String cbCatalogField = 'cf:';
  static const String cbCatalogActivate = 'ca:';
  static const String cbCatalogDelete = 'cd:';
  static const String cbCatalogDeleteYes = 'cdy:';
  static const String cbCatalogCreateYes = 'ccy';
  static const String cbCatalogCreateNo = 'ccn';
  static const String cbCatalogActiveYes = 'cay';
  static const String cbCatalogActiveNo = 'can';
  static const String cbCatalogKeepCode = 'ckc';
  static const String cbCatalogSkipChannel = 'csk';
  static const String cbCatalogSkipOptional = 'cso';
  static const String cbLinksMenu = 'lm';
  static const String cbLinksNew = 'ln';
  static const String cbLinksOpen = 'lo:';
  static const String cbLinksEdit = 'le:';
  static const String cbLinksField = 'lf:';
  static const String cbLinksDelete = 'ld:';
  static const String cbLinksDeleteYes = 'ldy:';
  static const String cbLinksCreateYes = 'lcy';
  static const String cbLinksCreateNo = 'lcn';
  static const String cbLinksDestGuide = 'ldg';
  static const String cbLinksDestCourse = 'ldc';
  static const String cbLinksSkipLaunch = 'lsk';
  static const String cbLinksPickLaunch = 'lp:';
  // TODO(mvp-reset): remove with buttonAdminClearFunnel.
  static const String cbAdminClearFunnelConfirm = 'cfy';
  static const String cbAdminClearFunnelAbort = 'cfn';

  String startGuideOffer() {
    return '<b>Гайд «Язык цвета»</b>\n\n'
        'Какие оттенки тебе идут — и почему любимый цвет в зеркале вдруг «не работает». '
        'PDF пришлю сюда: без имени, почты и телефона.\n\n'
        'Гайд — кнопка в меню внизу.';
  }

  String startCourseCard({Launch? launch}) {
    final start = _formatDate(launch?.courseStartAt);
    final price = _formatPrice(launch?.priceFullKopecks);
    final rawTitle = launch?.title.trim();
    final headline = rawTitle == null || rawTitle.isEmpty
        ? 'Курс по колористике'
        : escapeHtml(rawTitle);
    final buf = StringBuffer()
      ..writeln('<b>$headline</b>')
      ..writeln()
      ..write('Собрать свой язык цвета и гардероб, который не спорит с тоном кожи.');
    if (start != null) {
      buf.write(' Старт $start.');
    }
    if (price != null) {
      buf.write(' Стоимость $price.');
    }
    buf
      ..writeln()
      ..writeln()
      ..write(
        'Дальше — записаться на поток или сначала забрать гайд «Язык цвета». Оба в меню внизу.',
      );
    return buf.toString();
  }

  String alreadyInFunnel() {
    return '<b>Продолжаем с того же места</b>\n\n'
        'В меню внизу: гайд, запись на поток и помощь.';
  }

  String menuPinned() {
    return 'Меню внизу: гайд, запись и помощь.';
  }

  String courseMenuPinned() {
    return 'В меню вместо записи — «${MessageTemplates.buttonCourseStatus}»: оплата, старт и канал.';
  }

  String courseStatus({
    Launch? launch,
    CourseOrder? order,
    ChannelAccess? access,
    required DateTime now,
  }) {
    final buf = StringBuffer()
      ..writeln('<b>Твой поток</b>')
      ..writeln()
      ..writeln(_coursePaymentLine(order))
      ..writeln(_courseStartLine(launch, now))
      ..write(_courseChannelLine(order: order, access: access));
    final next = _courseStatusNextStep(order: order, access: access);
    if (next != null) {
      buf
        ..writeln()
        ..writeln()
        ..write(next);
    }
    return buf.toString();
  }

  String _coursePaymentLine(CourseOrder? order) {
    if (order == null) {
      return 'Оплата: доступ к этому потоку уже есть.';
    }
    final paid = formatRubFromKopecks(order.amountPaidKopecks);
    final full = formatRubFromKopecks(order.priceFullKopecks);
    switch (order.status) {
      case OrderStatus.depositPaid:
        final due = _dueDateLabel(order.dueAt, fallback: 'по договорённости');
        return 'Оплата: предоплата, $paid из $full. '
            'Остаток ${formatRubFromKopecks(order.amountDueKopecks)} — до $due.';
      case OrderStatus.paid:
        if (order.kind == PaymentKind.installment) {
          return 'Оплата: списание по рассрочке, $paid.';
        }
        return 'Оплата: закрыта, $paid из $full.';
      case OrderStatus.checkoutStarted:
      case OrderStatus.awaitingPayment:
        return 'Оплата: ещё не закрыта, пока $paid из $full.';
      case OrderStatus.cancelled:
        return 'Оплата: отменена.';
    }
  }

  String _courseStartLine(Launch? launch, DateTime now) {
    final start = _formatDate(launch?.courseStartAt);
    if (start == null) {
      return 'Курс: дата старта пока не указана.';
    }
    if (_courseHasStarted(launch?.courseStartAt, now)) {
      return 'Курс: идёт с $start.';
    }
    return 'Курс: старт $start, ещё не начался.';
  }

  String _courseChannelLine({CourseOrder? order, ChannelAccess? access}) {
    if (order != null && order.hasRemainder) {
      return 'Канал: открою после полной суммы.';
    }
    if (access == null) {
      return 'Канал: оплата есть, канал ещё не привязан. Напиши сюда — новую ссылку выдаст админ.';
    }
    if (access.revokedAt != null) {
      return 'Канал: доступ снят. Напиши сюда, если это ошибка.';
    }
    if (access.hasJoined) {
      return 'Канал: ты уже внутри.';
    }
    final link = access.inviteLink?.trim();
    if (link == null || link.isEmpty) {
      return 'Канал: ссылка ещё не выдана. Напиши сюда — новую выдаст админ.';
    }
    return 'Канал: ссылка выдана, входа пока нет.\n\n'
        '🔗 ${escapeHtml(link)}';
  }

  String? _courseStatusNextStep({CourseOrder? order, ChannelAccess? access}) {
    if (order != null && order.hasRemainder) {
      return 'Дальше — доплатить остаток.';
    }
    if (access != null &&
        access.revokedAt == null &&
        !access.hasJoined &&
        (access.inviteLink?.trim().isNotEmpty ?? false)) {
      return 'Открой канал кнопкой ниже. Если ссылка не сработает — напиши сюда, новую выдаст админ.';
    }
    if (access == null || access.revokedAt != null || access.inviteLink == null) {
      return 'Новую ссылку в канал выдаёт админ. Напиши сюда.';
    }
    if (access.hasJoined) {
      return 'Если что-то не так — напиши сюда.';
    }
    return null;
  }

  bool _courseHasStarted(DateTime? startAt, DateTime now) {
    if (startAt == null) {
      return false;
    }
    return !MoscowTime.calendarDate(now).isBefore(MoscowTime.calendarDate(startAt));
  }

  String help() {
    return '<b>Помощь</b>\n\n'
        'Гайд, запись и статус — в меню внизу. Если что-то сломалось, напиши сюда: '
        'перешлю человеку на связи.\n\n'
        '• Гайд не пришёл — «${MessageTemplates.buttonGuide}» в меню, пришлю ещё раз.\n'
        '• Касса не открылась — «${MessageTemplates.buttonEnroll}», затем «Продолжить оплату».\n'
        '• Ссылка в канал не сработала — напиши сюда, новую выдаст админ.\n'
        '• Продающие сообщения не нужны — «${MessageTemplates.buttonOptOut}» ниже. '
        'Гайд, запись и напоминания про оплату останутся.';
  }

  String helpReceived() {
    return 'Передал админу. Напишет тебе в личные сообщения.';
  }

  String helpForwardFailed() {
    return 'Не смог передать админу. Напиши ещё раз чуть позже.';
  }

  String adminIncomingUserMessage({required UserProfile user, String? text, FunnelPhase? phase}) {
    final handle = user.username == null || user.username!.trim().isEmpty
        ? ''
        : ' · @${escapeHtml(user.username!.trim())}';
    final body = (text == null || text.trim().isEmpty)
        ? 'без текста — фото или файл'
        : escapeHtml(text.trim());
    return '<b>Написал ${escapeHtml(user.displayName)}</b>\n'
        'id <code>${user.userId}</code>$handle\n'
        '${escapeHtml(_adminPhaseLabel(phase ?? user.funnelPhase))}\n\n'
        '$body';
  }

  String guideReady() {
    return 'Гайд «Язык цвета» — файл выше.';
  }

  String guideAsUrl(String url) {
    return 'Гайд «Язык цвета»: ${escapeHtml(url)}';
  }

  String guideMissing() {
    return 'Гайд ещё не загружен. Напиши сюда — пришлю, как только файл будет на месте.';
  }

  String warmupStep(String stepKey, {Launch? launch}) {
    return switch (stepKey) {
      'warmup_0' => _warmupZero(launch),
      'warmup_d1' => _warmupDay1(),
      'warmup_d3' => _warmupDay3(launch),
      'warmup_d7' => _warmupDay7(launch),
      'enroll_d1' => _enrollDay1(launch),
      'enroll_d3' => _enrollDay3(launch),
      'webinar_24h' => _webinarReminder(launch, when: 'завтра'),
      'webinar_10m' => _webinarReminder(launch, when: 'через 10 минут'),
      'webinar_live' => _webinarLive(launch),
      'webinar_next' => _webinarNextDay(launch),
      'sales_regular' => _salesRegular(launch),
      'dozhim_d1' => _dozhim(launch, headline: 'Кейс'),
      'dozhim_d2' => _dozhim(launch, headline: 'Возражения'),
      'dozhim_d3' => _dozhim(launch, headline: 'До и после'),
      'dozhim_d4' => _dozhim(launch, headline: 'Отзывы'),
      'last_wagon' => _lastWagon(launch),
      'warmup_start_d7' => _startNudge(launch),
      'warmup_start_d3' => _startNudge(launch),
      'warmup_start_d1' => _startNudge(launch),
      _ =>
        '<b>Ещё одно касание</b>\n\n'
            'Можно записаться на поток, когда будет удобно. '
            '«${MessageTemplates.buttonEnroll}» в меню внизу.',
    };
  }

  String _warmupZero(Launch? launch) {
    final webinar = _formatDateTime(launch?.webinarAt);
    final start = _formatDate(launch?.courseStartAt);
    final when = webinar ?? 'когда будет дата';
    final startLine = start == null ? '' : ' Старт потока $start.';
    return '<b>Эфир</b>\n\n'
        'Гайд уже у тебя. Следующий шаг — живой эфир ($when), не касса.$startLine '
        'Отметься, если будешь: после эфира у отметившихся открывается спеццена.\n\n'
        'Продажи откроем на эфире. «Записаться» в меню пока показывает карточку курса, без оплаты.';
  }

  String _webinarReminder(Launch? launch, {required String when}) {
    return '<b>Эфир $when</b>\n\n'
        'Напомню: эфир ${_formatDateTime(launch?.webinarAt) ?? 'уже близко'}. '
        'Если ещё не отметился — кнопка ниже. Ссылку пришлю тем, кто в списке.';
  }

  String _webinarLive(Launch? launch) {
    final url = launch?.webinarUrl?.trim();
    final promo = _formatPrice(launch?.resolvedPricePromoKopecks);
    final promoLine = promo == null
        ? ''
        : ' После эфира — спеццена $promo на 3 дня у отметившихся.';
    if (url == null || url.isEmpty) {
      return '<b>Эфир начался</b>\n\n'
          'Ссылку пришлю, как только она будет в карточке курса. Ты в списке.';
    }
    return '<b>Эфир начался</b>\n\n'
        'Входи по кнопке ниже.$promoLine';
  }

  String _webinarNextDay(Launch? launch) {
    final resolved = launch ?? _placeholderLaunch();
    final until = _formatDate(LaunchSales.promoEndsAt(resolved));
    final promo = _formatPrice(resolved.resolvedPricePromoKopecks) ?? 'спеццена';
    final regular = _formatPrice(resolved.resolvedPriceFullKopecks);
    final untilLine = until == null ? '.' : ' до $until.';
    final next = regular == null ? '' : ' Дальше $regular.';
    return '<b>Спеццена после эфира</b>\n\n'
        'Ты в списке на эфир — курс сейчас $promo$untilLine$next '
        'Запись — в меню внизу.';
  }

  Launch _placeholderLaunch() {
    return const Launch(
      id: 0,
      productId: 0,
      code: '',
      title: '',
      priceFullKopecks: 0,
      depositKopecks: 0,
      depositDueDays: 7,
    );
  }

  String _salesRegular(Launch? launch) {
    final price = _formatPrice(launch?.resolvedPriceFullKopecks);
    final start = _formatDate(launch?.courseStartAt) ?? 'когда будет дата';
    final priceLine = price == null ? '' : ' Стоимость $price.';
    return '<b>Продажи открыты</b>\n\n'
        'Курс: система цвета и базы гардероба. Старт потока $start.$priceLine '
        'Запись — в меню внизу.';
  }

  String _dozhim(Launch? launch, {required String headline}) {
    final price = _formatPrice(launch?.resolvedPriceFullKopecks);
    final openLine = price == null ? 'Запись открыта.' : 'Запись открыта, цена $price.';
    return '<b>$headline</b>\n\n'
        'Сюда встанет ваш текст: $headline. $openLine';
  }

  String _lastWagon(Launch? launch) {
    return '<b>Последний вагон</b>\n\n'
        'Сегодня последний день записи. Старт потока ${_formatDate(launch?.courseStartAt) ?? 'когда будет дата'}. '
        'Запись — в меню внизу.';
  }

  String webinarRsvpConfirmed(Launch launch, {required bool showLink}) {
    if (showLink) {
      return '<b>Ты в списке</b>\n\nЭфир уже идёт — кнопка со ссылкой ниже.';
    }
    final when = _formatDateTime(launch.webinarAt);
    final promo = _formatPrice(launch.resolvedPricePromoKopecks);
    final promoLine = promo == null ? '' : ' Спеццена $promo — 3 дня после эфира.';
    return '<b>Ты в списке на эфир</b>\n\n'
        '${when == null ? 'Напомню ближе к эфиру и пришлю ссылку.' : 'Эфир $when. Напомню и пришлю ссылку.'}'
        '$promoLine';
  }

  String _warmupDay1() {
    return '<b>Почему любимый цвет «не идёт»</b>\n\n'
        'Часто дело не во вкусе, а в подтоне: холодный розовый на тёплой коже выглядит грязновато, '
        'тёплый беж на холодной — желтит.\n\n'
        'Гайд это подсвечивает. На курсе разбираем, как собрать базу, которая не спорит с кожей. '
        'Запись — в меню, когда будет момент.';
  }

  String _warmupDay3(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final price = _formatPrice(launch?.priceFullKopecks);
    final deposit = launch != null && launch.hasDepositOption
        ? formatRubFromKopecks(launch.depositKopecks)
        : null;
    final due = _formatDate(launch?.depositDueAt);
    final buf = StringBuffer()
      ..writeln(start == null ? '<b>Если идёшь в поток</b>' : '<b>Поток $start</b>')
      ..writeln();
    if (price != null) {
      buf.write('Полная стоимость $price.');
      if (deposit != null && due != null) {
        buf.write(' Можно внести предоплату $deposit и закрыть остаток до $due.');
      }
      buf.write(' Рассрочка открывается на странице кассы — график ведёт касса, не бот.');
    } else {
      buf.write(
        'Можно закрыть полную сумму, внести предоплату или открыть рассрочку на странице кассы.',
      );
    }
    buf
      ..writeln()
      ..writeln()
      ..write(
        'В канал потока пускаю после полной суммы или после списания. '
        'Запись — в меню внизу.',
      );
    return buf.toString();
  }

  String _warmupDay7(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start == null ? 'Поток ещё можно успеть.' : 'Старт потока $start.';
    return '<b>Неделя с гайдом</b>\n\n'
        '$startLine Если хочешь собрать гардероб в систему — запись в меню внизу.';
  }

  String _enrollDay1(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start == null ? '' : ' Старт потока $start.';
    return '<b>Гайд и запись ещё здесь</b>\n\n'
        'Можно забрать «Язык цвета» или записаться на поток.$startLine '
        'Оба в меню внизу.';
  }

  String _enrollDay3(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start == null ? 'Поток ещё можно успеть.' : 'Старт потока $start.';
    return '<b>Гайд всё ещё можно забрать</b>\n\n'
        '$startLine «Язык цвета» и запись по-прежнему в меню внизу — '
        'можно открыть, когда будет минута.';
  }

  String _startNudge(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start == null ? 'Поток близко.' : 'Поток $start.';
    return '<b>$startLine</b>\n\n'
        'Записаться ещё можно из меню внизу. Ссылку в канал пришлю после полной оплаты или после списания.';
  }

  String optOutConfirmed() {
    return 'Продающие сообщения больше не пришлю.\n\n'
        'Гайд и запись остаются в меню. Если оплата уже начата или есть доплата — про это напомню, это не реклама.';
  }

  String enrollOptions(Launch launch, {required SalesQuote quote}) {
    final start = _formatDate(launch.courseStartAt) ?? 'когда будет дата';
    final promo = formatRubFromKopecks(quote.pricePromoKopecks);
    final regular = formatRubFromKopecks(quote.priceFullKopecks);
    switch (quote.phase) {
      case SalesPhase.preSales:
        final openAt = quote.salesStartAt ?? quote.webinarAt;
        final when = _formatDateTime(openAt);
        final whenLine = when == null ? 'Продажи ещё не открыты.' : 'Касса откроется $when.';
        return '<b>Курс</b>\n\n'
            'Система цвета и базы гардероба: какие оттенки тебе идут и как собирать образы без «любимый цвет вдруг не работает».\n\n'
            'Старт потока $start. $whenLine '
            'Пока можно ждать — напишу, когда можно будет оплатить.\n\n'
            'Эфир: если ещё не в списке, вернись к сообщению про эфир.';
      case SalesPhase.closed:
        return '<b>Запись закрыта</b>\n\n'
            'Продажи этого потока закончились. Старт $start. '
            'Если оплата уже шла — напиши в «${MessageTemplates.buttonHelp}».';
      case SalesPhase.promo:
        if (quote.rsvp) {
          final until = _formatDate(quote.promoEndsAt);
          return '<b>Запись · спеццена</b>\n\n'
              'Ты в списке на эфир. Сейчас $promo'
              '${until == null ? '.' : ' до $until.'} Дальше $regular.\n\n'
              'Старт потока $start. Ссылку в канал пришлю после полной оплаты.';
        }
        final regularAt = _formatDate(quote.regularSalesAt);
        return '<b>Курс</b>\n\n'
            'Сейчас спеццена только у тех, кто отметился на эфир. '
            'Обычная цена $regular откроется${regularAt == null ? ' после окна спеццены' : ' $regularAt'}. '
            'Старт потока $start.\n\n'
            'Напишу в день старта продаж по основной цене.';
      case SalesPhase.regular:
        return '<b>Запись на поток</b>\n\n'
            'Стоимость: ${formatRubFromKopecks(quote.payableKopecks)}. '
            'Старт потока $start. Ссылку в канал пришлю после полной оплаты.\n\n'
            'Рассрочка только на странице кассы — график ведёт касса, не бот.';
    }
  }

  String offerConsent(Launch launch) {
    final offerPhrase = _offerPhrase(launch);
    return 'Чтобы открыть оплату, поставь галочку ниже.\n\n'
        'Нажимая «${MessageTemplates.buttonGoToPay}», ты подтверждаешь, '
        'что принимаешь условия $offerPhrase '
        'на оказание информационно-консультационных/образовательных услуг '
        'и даёшь согласие на обработку персональных данных.';
  }

  String offerNeedCheck() {
    return 'Сначала поставь галочку ниже — без этого оплата не откроется.';
  }

  String _offerPhrase(Launch launch) {
    final url = launch.offerUrl?.trim();
    if (url == null || url.isEmpty) {
      return 'Публичной оферты';
    }
    return '<a href="${escapeHtml(url)}">Публичной оферты</a>';
  }

  String payButton(String url) {
    if (url.isEmpty) {
      return payManualFallback();
    }
    return 'Ссылка на оплату готова. После успешного платежа статус в этом чате обновится сам. '
        'Если страница кассы не вернула сюда — всё равно жди сообщение здесь. '
        'Если это предоплата, ссылку в канал пришлю после полной оплаты.';
  }

  // TODO(launch): replace the hardcoded @zhorenty support username below with
  //  the real support contact once it's confirmed.
  String payManualFallback() {
    return 'Сейчас онлайн-оплата недоступна, запись временно оформляется через администратора.\n\n'
        'Напиши сюда: @zhorenty — подскажем, как закрыть оплату.';
  }

  String adminPaymentGatewayDown({
    required int userId,
    required String provider,
    required PaymentKind kind,
    String? reason,
    String? username,
    String? firstName,
  }) {
    final reasonLine = (reason == null || reason.trim().isEmpty)
        ? ''
        : '\n${escapeHtml(reason.trim())}';
    return '<b>Ошибка онлайн-оплаты</b>\n\n'
        'Не получилось открыть ссылку на кассу.\n\n'
        '${_adminWhoLine(userId: userId, username: username, firstName: firstName)}\n'
        'Способ: ${_payKindLabel(kind)}\n'
        'Провайдер <code>${escapeHtml(provider)}</code>.$reasonLine\n\n'
        'Человеку показан запасной путь через администратора. '
        'Можно отметить оплату вручную из карточки.';
  }

  String _adminWhoLine({required int userId, String? username, String? firstName}) {
    final parts = <String>[];
    final name = firstName?.trim();
    if (name != null && name.isNotEmpty) {
      parts.add(escapeHtml(name));
    }
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) {
      parts.add('@${escapeHtml(handle)}');
    }
    if (parts.isEmpty) {
      return 'Кто: id <code>$userId</code>';
    }
    return 'Кто: ${parts.join(' · ')} · id <code>$userId</code>';
  }

  String _payKindLabel(PaymentKind kind) => switch (kind) {
    PaymentKind.full => 'полная оплата',
    PaymentKind.deposit => 'предоплата',
    PaymentKind.remainder => 'доплата',
    PaymentKind.installment => 'рассрочка',
  };

  String adminGuideMissing({required int userId}) {
    return '<b>Гайд не залит</b>\n\n'
        'Человек id <code>$userId</code> нажал «получить гайд», а файла нет. '
        'Пришли PDF в этот чат и сохрани как гайд запуска.';
  }

  String paymentSucceeded() {
    return '<b>Оплата прошла</b>\n\n'
        'Дальше — одноразовая ссылка в канал этого потока. На одного человека.';
  }

  String depositSucceeded(CourseOrder order) {
    final due = _dueDateLabel(order.dueAt, fallback: 'по договорённости');
    return '<b>Предоплата дошла</b>\n\n'
        'Остаток ${formatRubFromKopecks(order.amountDueKopecks)} — до $due. '
        'Ссылку в канал пришлю, когда закроется полная сумма.';
  }

  String inviteMessage(String link) {
    return 'Одноразовая ссылка в канал потока:\n${escapeHtml(link)}\n\n'
        'На одного человека. Если не открылась — напиши сюда, новую выдаст админ.';
  }

  String inviteUnavailable() {
    return 'Оплата есть, канал ещё не привязан. Напиши сюда — доступ выдаст админ.';
  }

  String abandonedFirst() {
    return 'Оформление началось, оплата пока не закрылась. Можно продолжить с того же места.';
  }

  String abandonedSecond() {
    return 'Напоминаю про незакрытую оплату. Ссылка ещё действует — если поток всё ещё в планах.';
  }

  String abandonedPrestart() {
    return 'Поток близко, а оплата ещё не закрылась. Можно продолжить с того же места.';
  }

  String remainderBeforeDue(CourseOrder order) {
    final due = _dueDateLabel(order.dueAt, fallback: 'скоро');
    return 'Напоминаю про доплату: остаток ${formatRubFromKopecks(order.amountDueKopecks)}, срок $due. '
        'После полной суммы открою канал потока.';
  }

  String remainderReminder(CourseOrder order) {
    final due = _dueDateLabel(order.dueAt, fallback: 'скоро');
    return 'Доплата по курсу: остаток ${formatRubFromKopecks(order.amountDueKopecks)}, срок $due. '
        'После полной суммы открою канал потока.';
  }

  String unjoinedInviteReminder(String link) {
    return 'Ссылка в канал потока ещё не использована:\n${escapeHtml(link)}\n\n'
        'Открой её кнопкой ниже. Если не сработает — напиши сюда, новую выдаст админ.';
  }

  String inviteAskAdmin() {
    return 'Новую ссылку в канал выдаёт админ. Напиши сюда — передам.';
  }

  String accessRevoked() {
    return '<b>Доступ к потоку снят</b>\n\n'
        'Запись на этот поток закрыта. Если была ссылка в канал — она больше не действует, '
        'из канала тебя убрали.\n\n'
        'Если это ошибка или вопрос по возврату — напиши сюда. '
        'Записаться снова можно из меню внизу.';
  }

  String paymentResetToUnpaid() {
    return '<b>Статус оплаты сброшен</b>\n\n'
        'Доступ в канал снят, если был. Записаться снова — '
        '«${MessageTemplates.buttonEnroll}» в меню внизу.\n\n'
        'Если это ошибка — напиши сюда.';
  }

  String adminMenu() {
    return '<b>Админка</b>\n\n'
        'Поиск — карточка, статус, письмо. Нет карточки — создай из поиска. '
        'Как бот пишет людям — «${MessageTemplates.buttonAdminFunnelLogic}». '
        'Курсы, диплинки (метки входа t.me) и срез воронки — «${MessageTemplates.buttonAdminSheetsHub}». '
        // TODO(mvp-reset): drop this sentence with the clear-funnel button.
        'Временно: «${MessageTemplates.buttonAdminClearFunnel}» сотрёт людей из бота.';
  }

  String adminFunnelLogic({Launch? launch}) {
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start ?? 'дата старта из карточки курса';
    return '<b>Как устроена воронка</b>\n\n'
        'Человек заходит в бота → может забрать гайд и/или записаться на поток → '
        'бот сам напоминает, пока нет оплаты или отписки.\n\n'
        '<b>Кто не получает прогрев</b>\n'
        'Аккаунты админов. Карточка может появиться (админ тоже пишет боту), '
        'но продающие сообщения админу не шлём.\n\n'
        '<b>Вход</b>\n'
        'Ссылка с меткой (Reels, Threads, пост и т.д.). Первый переход запоминаем. '
        'Повторный /start уже идущий сценарий не ломает.\n\n'
        'Две двери:\n'
        '• ссылка на гайд — экран про «Язык цвета»;\n'
        '• ссылка на курс — карточка потока.\n'
        'Дальше гайд и запись всегда в меню внизу.\n\n'
        '<b>Гайд</b>\n'
        'Без имени, почты и телефона. Сразу после файла — первое сообщение прогрева.\n\n'
        '<b>Прогрев после гайда</b>\n'
        'Сразу приглашение на эфир и кнопка «Буду на эфире». '
        'Напоминания за сутки и за 10 минут, ссылка в день эфира тем, кто отметился. '
        'Спеццена — 3 дня с эфира, только у отметившихся.\n\n'
        '<b>Продажи</b>\n'
        'До старта продаж «Записаться» — карточка курса и «ждём кассу», без оплаты. '
        'Старт продаж — поле в карточке курса (пусто — как дата эфира). '
        'После окна спеццены — обычная цена и дожим. '
        'В последний день продаж — «последний вагон». Старт потока $startLine.\n\n'
        '<b>Если гайд не забрали</b>\n'
        'Напоминания на 1-й и на 3-й день после первого /start, пока не нажали «Записаться» '
        'и пока касса уже открыта для этого человека. '
        'После записи до старта продаж молчим про оплату. '
        'В день обычной цены и дожим до конца продаж — тоже, даже без гайда.\n\n'
        '<b>Запись и оплата</b>\n'
        '«${MessageTemplates.buttonEnroll}» — пока нет успешной оплаты. Потом в меню «Мой курс».\n'
        '• полная оплата или списание по рассрочке — ссылка в канал этого потока;\n'
        '• предоплата — канала нет, пока не доплатят;\n'
        '• рассрочка считается только после реального списания, не после заявки.\n\n'
        '<b>Открыли оплату и не закончили</b>\n'
        'Напоминание через ~6 часов и через сутки. За 3 дня до старта — одно касание вместо двух.\n\n'
        '<b>Внесли предоплату</b>\n'
        'Напоминание за 1–3 дня до срока, в день срока и один раз после просрочки. '
        'Отписка от рассылки это не глушит.\n\n'
        '<b>Отписка</b>\n'
        '«${MessageTemplates.buttonOptOut}» в «${MessageTemplates.buttonHelp}». '
        'Гайд и запись остаются. Напоминания про начатую оплату и доплату тоже.\n\n'
        '<b>Ночью не пишем</b>\n'
        'Автосообщения только с 10:00 до 21:00 по Москве. '
        'Напоминание за 10 минут до эфира уходит и ночью.\n\n'
        '<b>Канал</b>\n'
        'Одноразовая ссылка после полной оплаты. Новую выдаёшь только ты из карточки человека.';
  }

  String adminAskSearch() {
    return '<b>Поиск человека</b>\n\n'
        'Пришли id — цифры, как в карточке, или @username. '
        'Можно переслать сюда его сообщение — подставлю id сам.\n\n'
        'Карточки нет — создай из результата поиска.';
  }

  String adminAskAddUser() {
    return '<b>Добавить на курс</b>\n\n'
        'Пришли числовой Telegram id (как в @userinfobot). '
        'Можно переслать сюда его сообщение — подставлю id сам.\n\n'
        'Карточку создам, если её ещё нет. Человеку сразу не пишу: сначала проставь оплату '
        'или напиши из карточки. Если он ещё не нажимал /start, бот не сможет ему написать.\n\n'
        'Дальше из карточки: оплата, ссылка в канал или убрать с курса.';
  }

  String adminNeedNumericId() {
    return 'Нужен числовой Telegram id или пересланное сообщение. '
        'По нику без карточки id не подставлю.';
  }

  String adminNotFound(String query, {bool canCreate = false}) {
    final buf = StringBuffer('Никого не нашёл по «${escapeHtml(query)}».');
    if (canCreate) {
      buf.write('\n\nЕсли это Telegram id — создай карточку кнопкой ниже.');
    }
    return buf.toString();
  }

  String adminCard({
    required UserProfile user,
    UserEnrollment? enrollment,
    CourseOrder? order,
    ChannelAccess? access,
    List<ConversationLogEntry> dialog = const <ConversationLogEntry>[],
  }) {
    final phase = enrollment?.funnelPhase ?? user.funnelPhase;
    final optOut = enrollment?.warmupOptOut ?? user.warmupOptOut;
    final buf = StringBuffer()
      ..writeln(_adminCardTitle(user))
      ..writeln('id <code>${user.userId}</code>')
      ..writeln(_adminSourceLine(user.source))
      ..writeln()
      ..writeln('<b>${escapeHtml(_headline(_adminPhaseLabel(phase)))}</b>');
    for (final line in _adminOrderLines(order)) {
      buf.writeln(line);
    }
    buf
      ..writeln()
      ..writeln('<b>Канал</b>')
      ..writeln(_adminChannelLine(access))
      ..writeln()
      ..writeln('<b>Связь</b>')
      ..writeln(_adminWarmupLine(optOut))
      ..writeln(_adminWebinarLine(enrollment))
      ..writeln(_adminBotLine(user.botBlocked));
    if (dialog.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('<b>Диалог</b>');
      for (final entry in _recentDialog(dialog)) {
        final dir = entry.direction == ConversationDirection.outbound ? '→' : '←';
        buf.writeln('$dir ${_dialogPreview(entry)}');
      }
    }
    return buf.toString();
  }

  String adminAskBroadcastContent() {
    return 'Пришли одним сообщением текст, фото, файл, видео или голосовое. Можно с подписью.';
  }

  String adminBroadcastPickSegment(
    Map<BroadcastSegment, int> counts, {
    Set<BroadcastSegment> selected = const <BroadcastSegment>{},
    int recipientCount = 0,
    bool draftSaved = false,
  }) {
    final buf = StringBuffer();
    if (draftSaved) {
      buf
        ..writeln('Сохранил черновик.')
        ..writeln();
    }
    buf
      ..writeln('<b>Рассылка</b>')
      ..writeln()
      ..writeln('Кому отправить? Можно несколько сегментов.')
      ..writeln();
    for (final segment in BroadcastSegment.values) {
      final mark = selected.contains(segment) ? '✓ ' : '';
      buf.writeln('$mark${broadcastSegmentLabel(segment)} — ${counts[segment] ?? 0}');
    }
    if (selected.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('Выбрано: ${escapeHtml(broadcastSegmentsLabel(selected))}')
        ..writeln('Получателей: <b>$recipientCount</b>');
    }
    return buf.toString().trim();
  }

  String adminBroadcastPreview({
    required Iterable<BroadcastSegment> segments,
    required int recipientCount,
    required BroadcastContentKind kind,
    String? previewText,
    int optOutCount = 0,
    bool excludeOptOut = false,
  }) {
    final segmentWord = BroadcastSegment.ordered(segments).length == 1 ? 'Сегмент' : 'Сегменты';
    final buf = StringBuffer()
      ..writeln('<b>Превью</b>')
      ..writeln()
      ..writeln('$segmentWord: ${escapeHtml(broadcastSegmentsLabel(segments))}')
      ..writeln('Получателей: <b>$recipientCount</b>');
    if (optOutCount > 0) {
      buf.writeln(
        excludeOptOut
            ? '«Не писать» в выборке: $optOutCount — не включены'
            : '«Не писать» в выборке: $optOutCount — будут включены',
      );
    }
    buf.write('Содержимое: ${escapeHtml(broadcastContentKindLabel(kind))}');
    final preview = previewText?.trim();
    if (preview != null && preview.isNotEmpty) {
      buf
        ..writeln()
        ..writeln()
        ..write(escapeHtml(_clipBroadcastPreview(preview)));
    }
    return buf.toString();
  }

  String adminBroadcastAlbumRejected() {
    return 'Пришли одно фото или файл, не альбом.';
  }

  String adminBroadcastEmptyRejected() {
    return 'Пришли текст или файл.';
  }

  String adminBroadcastCopyFailed() {
    return 'Не получилось показать превью. Пришли сообщение ещё раз.';
  }

  String adminBroadcastNeedDraft() {
    return 'Сначала пришли текст, фото, файл, видео или голосовое.';
  }

  String adminBroadcastDone({required int sent, required int failed, required int total}) {
    return '📣 Рассылка: отправлено $sent, ошибок $failed, получателей $total.';
  }

  String adminMarkedPaid({bool clientNotified = true, bool clientReached = true}) =>
      '✅ Оплата проставлена вручную.${_adminClientFollowup(attempted: clientNotified, reached: clientReached)}';

  String adminMarkedDeposit({bool clientNotified = true, bool clientReached = true}) =>
      '💵 Предоплата проставлена вручную.${_adminClientFollowup(attempted: clientNotified, reached: clientReached)}';

  String adminMarkedUnpaid({bool clientNotified = true, bool clientReached = true}) =>
      'Статус: не оплачено. Invite отозван, если был.'
      '${_adminClientFollowup(attempted: clientNotified, reached: clientReached)}';

  String adminStatusFailed() => 'Не получилось сменить статус. Попробуй ещё раз.';

  String adminStatusChanged(
    AdminPaymentStatus status, {
    bool clientNotified = true,
    bool clientReached = true,
  }) => switch (status) {
    AdminPaymentStatus.unpaid => adminMarkedUnpaid(
      clientNotified: clientNotified,
      clientReached: clientReached,
    ),
    AdminPaymentStatus.deposit => adminMarkedDeposit(
      clientNotified: clientNotified,
      clientReached: clientReached,
    ),
    AdminPaymentStatus.paid => adminMarkedPaid(
      clientNotified: clientNotified,
      clientReached: clientReached,
    ),
    AdminPaymentStatus.cancelled => adminCancelled(
      clientNotified: clientNotified,
      clientReached: clientReached,
    ),
  };

  String adminCancelled({bool clientNotified = false, bool clientReached = true}) =>
      '🚫 Убрал с курса. Статус снят, invite отозван, из канала выкинул, если был.'
      '${_adminClientFollowup(attempted: clientNotified, reached: clientReached)}';

  String _adminClientFollowup({required bool attempted, required bool reached}) {
    if (!attempted) {
      return '';
    }
    if (reached) {
      return ' Человеку написал.';
    }
    return '\n\nЧеловеку не дошло — возможно, бот заблокирован или ещё не нажимал /start.';
  }

  String adminAskStatus(AdminPaymentStatus current) {
    return 'Сейчас: <b>${escapeHtml(adminPaymentStatusLabel(current))}</b>. '
        'Выбери новый статус.';
  }

  String adminPaymentStatusLabel(AdminPaymentStatus status) => switch (status) {
    AdminPaymentStatus.unpaid => 'не оплачено',
    AdminPaymentStatus.deposit => 'предоплата',
    AdminPaymentStatus.paid => 'оплачено полностью',
    AdminPaymentStatus.cancelled => 'убран с курса',
  };

  String adminStatusButton(AdminPaymentStatus status) => switch (status) {
    AdminPaymentStatus.unpaid => buttonAdminStatusUnpaid,
    AdminPaymentStatus.deposit => buttonAdminStatusDeposit,
    AdminPaymentStatus.paid => buttonAdminStatusPaid,
    AdminPaymentStatus.cancelled => buttonAdminCancel,
  };

  String adminConfirmCancel(UserProfile user) {
    final name = user.firstName?.trim();
    final who = name == null || name.isEmpty ? 'человека' : escapeHtml(name);
    return 'Убрать $who · id <code>${user.userId}</code>? '
        'Ссылка отзовётся, из канала выкину.';
  }

  String adminAskDm(int userId) {
    return 'Напиши текст — отправлю id <code>$userId</code> от имени бота.';
  }

  String adminDmEmpty() {
    return 'Пустое сообщение не отправлю. Напиши текст.';
  }

  String adminDmSent(int userId) => 'Отправил id <code>$userId</code>.';

  String adminDmFailed(int userId) =>
      'Не отправилось id <code>$userId</code>. Возможно, бот заблокирован.';

  String adminSearchMatches(List<UserProfile> users) {
    final buf = StringBuffer()
      ..writeln('<b>Несколько совпадений</b>')
      ..writeln()
      ..writeln('Выбери карточку:');
    for (final user in users) {
      final name = user.firstName?.trim();
      final handle = user.username?.trim();
      final label = <String>[
        if (name != null && name.isNotEmpty) escapeHtml(name),
        if (handle != null && handle.isNotEmpty) '@${escapeHtml(handle)}',
        '<code>${user.userId}</code>',
      ].join(' · ');
      buf.writeln(label);
    }
    return buf.toString();
  }

  String adminGuideSaved(String fileId) {
    return '📘 Гайд сохранён. file_id: <code>${escapeHtml(fileId)}</code>';
  }

  String adminGuideConfirm(String fileId) {
    return '💾 Сохранить этот файл как гайд запуска?\n'
        'file_id: <code>${escapeHtml(fileId)}</code>';
  }

  String adminGuideDiscarded() => 'Файл не сохранён как гайд.';

  String adminInviteReissued({bool clientReached = true}) {
    if (clientReached) {
      return '🔗 Ссылку в канал отправил человеку. Предыдущая больше не действует.';
    }
    return '🔗 Новую ссылку выдал, предыдущая больше не действует.\n\n'
        'Человеку не дошло — возможно, бот заблокирован или ещё не нажимал /start.';
  }

  String adminSheetsRefreshing() {
    return 'Обновляю таблицу — читаю набор и перезаписываю воронку. Подожди несколько секунд.';
  }

  String adminDeepLinksRefreshing() {
    return 'Собираю диплинки с листа ${escapeHtml(LinksSheet.tabTitle)}. '
        'Подожди несколько секунд.';
  }

  String adminSheetsUpdated({Launch? launch}) {
    return adminSheetsRefreshResult(
      catalogAttempted: true,
      catalogOk: true,
      funnelAttempted: true,
      funnelOk: true,
      launch: launch,
    );
  }

  String adminSheetsRefreshResult({
    required bool catalogAttempted,
    required bool catalogOk,
    String? catalogError,
    required bool funnelAttempted,
    required bool funnelOk,
    String? funnelError,
    Launch? launch,
  }) {
    final buf = StringBuffer()
      ..writeln('<b>Таблица</b>')
      ..writeln();
    if (catalogAttempted) {
      if (catalogOk && launch != null) {
        buf.writeln('Набор в боте');
        final title = launch.title.trim();
        if (title.isNotEmpty) {
          buf.writeln('поток: ${escapeHtml(title)}');
        }
        buf.writeln('цена: ${formatRubFromKopecks(launch.priceFullKopecks)}');
        final start = _formatDate(launch.courseStartAt);
        if (start != null) {
          buf.writeln('старт: $start');
        }
      } else if (catalogOk) {
        buf.writeln('Набор в боте');
        buf.writeln('без изменений');
      } else {
        buf.writeln('Набор в боте');
        buf.writeln(
          'лист ${escapeHtml(CoursesSheet.tabTitle)}: не прочитался — '
          '${escapeHtml(catalogError ?? 'ошибка')}',
        );
      }
      buf.writeln();
    }
    if (funnelAttempted) {
      if (funnelOk) {
        buf.writeln('Воронка');
        buf.writeln('лист ВОРОНКА: цифры перезаписаны');
      } else {
        buf.writeln('Воронка');
        buf.writeln('лист ВОРОНКА: не обновился — ${escapeHtml(funnelError ?? 'ошибка')}');
      }
    }
    return buf.toString().trim();
  }

  String adminDeepLinks(List<AcquisitionLink> links) {
    final buf = StringBuffer()
      ..writeln('<b>Диплинки</b>')
      ..writeln();
    final bot = _botUsername?.trim() ?? '';
    if (bot.isEmpty) {
      buf.writeln('Username бота неизвестен — готовые t.me-ссылки не собрались. Метки:');
      buf.writeln();
    }
    for (final link in links) {
      final launch = link.launchCode?.trim();
      final launchSuffix = launch == null || launch.isEmpty ? '' : ' · ${escapeHtml(launch)}';
      buf.writeln('${escapeHtml(link.origin)} → ${escapeHtml(link.destinationLabel)}$launchSuffix');
      if (bot.isEmpty) {
        buf.writeln('<code>${escapeHtml(link.payload)}</code>');
      } else {
        buf.writeln('<code>${escapeHtml(deepLink(link.payload))}</code>');
      }
      buf.writeln();
    }
    buf.write(
      'Те же ссылки на листе ${escapeHtml(LinksSheet.tabTitle)}. '
      'Новая метка — в боте «${MessageTemplates.buttonAdminLinks}» '
      'или строка на листе, затем «${MessageTemplates.buttonAdminSheets}».',
    );
    return buf.toString().trim();
  }

  String adminAskClearFunnel() {
    return '<b>Очистить воронку</b>\n\n'
        'Сотру людей, оплаты, прогрев и лог. Каталог запусков не трогаю. '
        'Это для тестов — потом кнопку уберём.';
  }

  String adminFunnelCleared({required int people}) {
    return 'Воронка очищена. Было людей: $people. Каталог запусков на месте.';
  }

  String adminSheetsDisabled() {
    return '📊 Google Sheets не подключён. Проверь ключ, id таблицы и GOOGLE_SHEETS_WRITE_ENABLED.';
  }

  String adminSheetsFailed(String error) {
    return '📊 Не получилось обновить таблицу: ${escapeHtml(error)}';
  }

  static int? idFromCallback(String data, String prefix) {
    if (!data.startsWith(prefix)) {
      return null;
    }
    return int.tryParse(data.substring(prefix.length));
  }

  static String adminStatusSetData(AdminPaymentStatus status, int userId) {
    return '$cbAdminStatusSet${status.code}:$userId';
  }

  static String catalogFieldData(int launchId, CatalogLaunchField field) {
    return '$cbCatalogField$launchId:${field.token}';
  }

  static ({int id, CatalogLaunchField field})? catalogFieldFromCallback(String data) {
    if (!data.startsWith(cbCatalogField)) {
      return null;
    }
    final rest = data.substring(cbCatalogField.length);
    final sep = rest.indexOf(':');
    if (sep <= 0) {
      return null;
    }
    final id = int.tryParse(rest.substring(0, sep));
    final field = CatalogLaunchField.fromToken(rest.substring(sep + 1));
    if (id == null || field == null) {
      return null;
    }
    return (id: id, field: field);
  }

  static String linksFieldData(int index, CatalogLinkField field) {
    return '$cbLinksField$index:${field.token}';
  }

  static ({int index, CatalogLinkField field})? linksFieldFromCallback(String data) {
    if (!data.startsWith(cbLinksField)) {
      return null;
    }
    final rest = data.substring(cbLinksField.length);
    final sep = rest.indexOf(':');
    if (sep <= 0) {
      return null;
    }
    final index = int.tryParse(rest.substring(0, sep));
    final field = CatalogLinkField.fromToken(rest.substring(sep + 1));
    if (index == null || field == null) {
      return null;
    }
    return (index: index, field: field);
  }

  static ({AdminPaymentStatus status, int userId})? adminStatusFromCallback(String data) {
    if (!data.startsWith(cbAdminStatusSet)) {
      return null;
    }
    final rest = data.substring(cbAdminStatusSet.length);
    final sep = rest.indexOf(':');
    if (sep <= 0) {
      return null;
    }
    final status = AdminPaymentStatusX.parseCode(rest.substring(0, sep));
    final userId = int.tryParse(rest.substring(sep + 1));
    if (status == null || userId == null) {
      return null;
    }
    return (status: status, userId: userId);
  }

  static BroadcastSegment? segmentFromCallback(String data) {
    if (!data.startsWith(cbBroadcastSegment)) {
      return null;
    }
    return BroadcastSegment.fromCode(data.substring(cbBroadcastSegment.length));
  }

  String broadcastSegmentLabel(BroadcastSegment segment) => switch (segment) {
    BroadcastSegment.allStarted => 'Воронка без оплативших',
    BroadcastSegment.leadNoGuide => 'Пришли за гайдом, ещё не забрали',
    BroadcastSegment.guideNotPaid => 'Гайд есть, без записи',
    BroadcastSegment.courseLeadNoCheckout => 'Пришли на курс, без записи',
    BroadcastSegment.checkoutOpen => 'Начали оплату',
    BroadcastSegment.depositPaid => 'Предоплата',
    BroadcastSegment.paidAccess => 'Оплатили / доступ',
    BroadcastSegment.paidNotJoined => 'Оплатили, не вошли',
    BroadcastSegment.cancelled => 'Отмена / возврат',
  };

  String broadcastSegmentButton(BroadcastSegment segment, int count, {bool selected = false}) {
    final label = '${broadcastSegmentLabel(segment)} ($count)';
    return selected ? '✓ $label' : label;
  }

  String broadcastSegmentsLabel(Iterable<BroadcastSegment> segments) {
    final ordered = BroadcastSegment.ordered(segments);
    if (ordered.isEmpty) {
      return 'не выбраны';
    }
    return ordered.map(broadcastSegmentLabel).join(', ');
  }

  String broadcastContentKindLabel(BroadcastContentKind kind) => switch (kind) {
    BroadcastContentKind.text => 'текст',
    BroadcastContentKind.photo => 'фото',
    BroadcastContentKind.document => 'файл',
    BroadcastContentKind.video => 'видео',
    BroadcastContentKind.voice => 'голосовое',
    BroadcastContentKind.audio => 'аудио',
    BroadcastContentKind.animation => 'gif',
    BroadcastContentKind.sticker => 'стикер',
    BroadcastContentKind.videoNote => 'видеосообщение',
  };

  String _clipBroadcastPreview(String text) {
    if (text.length <= 200) {
      return text;
    }
    return '${text.substring(0, 200)}…';
  }

  String deepLink(String payload) {
    final bot = _botUsername;
    if (bot == null || bot.isEmpty) {
      return payload;
    }
    return 'https://t.me/$bot?start=$payload';
  }

  String _adminPhaseLabel(FunnelPhase phase) => switch (phase) {
    FunnelPhase.lead => 'пришёл, без гайда',
    FunnelPhase.magnetIssued => 'гайд выдан',
    FunnelPhase.warming => 'в прогреве',
    FunnelPhase.checkout => 'оформляет оплату',
    FunnelPhase.depositPaid => 'внесена предоплата',
    FunnelPhase.paid => 'оплачено полностью',
    FunnelPhase.accessGranted => 'доступ в канал выдан',
    FunnelPhase.cancelled => 'оплата отменена',
  };

  String _adminCardTitle(UserProfile user) {
    final name = user.firstName?.trim();
    final handle = user.username?.trim();
    final parts = <String>[];
    if (name != null && name.isNotEmpty) {
      parts.add(escapeHtml(name));
    }
    if (handle != null && handle.isNotEmpty) {
      parts.add('@${escapeHtml(handle)}');
    }
    if (parts.isEmpty) {
      return '<b>Карточка</b>';
    }
    return '<b>Карточка</b> ${parts.join(' · ')}';
  }

  String _adminPersonLabel(UserProfile user) {
    final name = user.firstName?.trim();
    final handle = user.username?.trim();
    final parts = <String>[];
    if (name != null && name.isNotEmpty) {
      parts.add(name);
    }
    if (handle != null && handle.isNotEmpty) {
      parts.add('@$handle');
    }
    return parts.join(' · ');
  }

  String _adminSourceLine(String? source) {
    final raw = source?.trim();
    if (raw == null || raw.isEmpty) {
      return 'источник: без метки';
    }
    final label = _adminSourceLabel(raw);
    if (label == raw) {
      return 'источник: <code>${escapeHtml(raw)}</code>';
    }
    return 'источник: $label · <code>${escapeHtml(raw)}</code>';
  }

  String _adminSourceLabel(String raw) => switch (raw) {
    'ig_reels_guide' => 'Instagram Reels',
    'threads_guide' => 'Threads',
    'tg_announce' => 'Telegram, анонс',
    'direct_course' => 'прямая ссылка',
    'ig_stories_guide' => 'Stories',
    'email_guide' => 'рассылка',
    AcquisitionSource.adminManual => 'админ',
    _ => raw,
  };

  Iterable<String> _adminOrderLines(CourseOrder? order) {
    if (order == null) {
      return const <String>['заказа нет'];
    }
    final lines = <String>[
      'заказ #${order.id} · ${_adminPaymentKindLabel(order.kind)} · '
          '${_adminOrderStatusLabel(order.status)}',
      'оплачено ${formatRubFromKopecks(order.amountPaidKopecks)} '
          'из ${formatRubFromKopecks(order.priceFullKopecks)}',
    ];
    if (order.hasRemainder) {
      final due = _formatDate(order.dueAt) ?? 'срок не указан';
      lines.add('остаток ${formatRubFromKopecks(order.amountDueKopecks)} · до $due');
    }
    return lines;
  }

  String _adminPaymentKindLabel(PaymentKind kind) => switch (kind) {
    PaymentKind.full => 'полная оплата',
    PaymentKind.deposit => 'предоплата',
    PaymentKind.remainder => 'доплата',
    PaymentKind.installment => 'рассрочка',
  };

  String _adminOrderStatusLabel(OrderStatus status) => switch (status) {
    OrderStatus.checkoutStarted => 'оформление начато',
    OrderStatus.awaitingPayment => 'ждёт оплату',
    OrderStatus.depositPaid => 'внесена предоплата',
    OrderStatus.paid => 'оплачено',
    OrderStatus.cancelled => 'отменён',
  };

  String _adminChannelLine(ChannelAccess? access) {
    if (access == null) {
      return 'нет доступа';
    }
    if (access.revokedAt != null) {
      if (access.joinedAt != null) {
        return 'был вход ${_formatMoscowDateTime(access.joinedAt!)}, invite отозван';
      }
      return 'invite отозван, входа не было';
    }
    if (access.hasJoined) {
      return 'вошёл ${_formatMoscowDateTime(access.joinedAt!)}';
    }
    final link = access.inviteLink?.trim();
    if (link == null || link.isEmpty) {
      return 'ссылка не выдана';
    }
    return 'ссылка выдана, входа нет';
  }

  String _adminWarmupLine(bool optOut) {
    return optOut ? 'прогрев не шлём («Не писать»)' : 'прогрев идёт';
  }

  String _adminWebinarLine(UserEnrollment? enrollment) {
    if (enrollment == null) {
      return 'эфир: без отметки';
    }
    if (enrollment.webinarRsvp) {
      return 'эфир: в списке';
    }
    if (enrollment.enrollIntentAt != null) {
      return 'эфир: без отметки · было «Записаться»';
    }
    return 'эфир: без отметки';
  }

  String _adminBotLine(bool blocked) {
    return blocked ? 'заблокировал бота' : 'бот на связи';
  }

  List<ConversationLogEntry> _recentDialog(List<ConversationLogEntry> dialog, {int limit = 8}) {
    if (dialog.length <= limit) {
      return dialog;
    }
    return dialog.sublist(dialog.length - limit);
  }

  String _dialogPreview(ConversationLogEntry entry) {
    final preview = entry.textPreview?.trim();
    if (preview == null || preview.isEmpty) {
      return _conversationContentLabel(entry.contentType);
    }
    final compact = _compactDialogPreview(preview);
    if (compact == null || compact.isEmpty) {
      return _conversationContentLabel(entry.contentType);
    }
    return escapeHtml(compact);
  }

  String? _compactDialogPreview(String preview) {
    final firstLine = preview
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) {
      return null;
    }
    final lower = firstLine.toLowerCase();
    if (lower.startsWith('document ')) {
      return 'файл';
    }
    if (lower.startsWith('copy ')) {
      return 'копия';
    }
    if (firstLine.length <= 80) {
      return firstLine;
    }
    return '${firstLine.substring(0, 80)}…';
  }

  String _headline(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return '${trimmed.substring(0, 1).toUpperCase()}${trimmed.substring(1)}';
  }

  String _conversationContentLabel(ConversationContentType type) => switch (type) {
    ConversationContentType.text => 'текст',
    ConversationContentType.photo => 'фото',
    ConversationContentType.document => 'файл',
    ConversationContentType.video => 'видео',
    ConversationContentType.other => 'сообщение',
    ConversationContentType.copy => 'копия',
  };

  String? _formatDateTime(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _formatMoscowDateTime(value);
  }

  String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _date.format(MoscowTime.toMoscow(value));
  }

  String _dueDateLabel(DateTime? value, {required String fallback}) {
    return _formatDate(value) ?? fallback;
  }

  String _formatMoscowDateTime(DateTime value) {
    final moscow = MoscowTime.toMoscow(value);
    return _dateTime.format(moscow);
  }

  String? _formatPrice(int? kopecks) {
    if (kopecks == null || kopecks <= 0) {
      return null;
    }
    return formatRubFromKopecks(kopecks);
  }

  String payFullButtonLabel(int kopecks) {
    return '${MessageTemplates.buttonPayFull} ${formatRubFromKopecks(kopecks)}';
  }

  String payDepositButtonLabel(int kopecks) {
    return '${MessageTemplates.buttonPayDeposit} ${formatRubFromKopecks(kopecks)}';
  }
}
