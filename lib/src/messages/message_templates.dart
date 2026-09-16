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
import 'package:course_chatbot/src/domain/launch_dozhim.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/domain/moscow_time.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/sales_window.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/domain/warmup.dart';
import 'package:course_chatbot/src/messages/html_escaper.dart';
import 'package:course_chatbot/src/messages/keyboards/keyboard_builders.dart';
import 'package:course_chatbot/src/messages/rich_html.dart';
import 'package:course_chatbot/src/messages/telegram_html.dart';
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
  final DateFormat _clock = DateFormat('HH:mm');
  static const List<String> _monthsGenitive = <String>[
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const String buttonGuide = 'Получить гайд';
  static const String guideDocumentMediaId = 'guide';
  static const String buttonEnroll = 'Курс "Цвет в интерьере. Основы и практика"';
  static const String buttonRsvp = 'Хочу на мастер-класс';
  static const String buttonRsvpList = 'Хочу на мастер-класс';
  static const String buttonRsvpEnroll = 'Хочу на мастер-класс';
  static const String buttonEnrollInline = 'Записаться на курс';
  static const String buttonJoinWebinar = 'Присоединиться';
  static const String buttonCourseStatus = buttonEnroll;
  static const String buttonHelp = 'Помощь';
  static const String buttonOptOut = 'Отписаться от рассылки';
  static const String buttonPayFull = 'Оплатить курс целиком';
  static const String buttonPayFullPromo = 'Оплатить курс по специальной цене';
  static const String buttonPayDeposit = 'Бронь места, предоплата';
  static const String buttonPayRemainder = 'Внести остаток сейчас';
  static const String buttonPayRemainderNow = 'Внести остаток сейчас';
  static const String buttonGoToPay = 'Перейти к оплате';
  static const String buttonContinuePay = 'Продолжить оплату';
  static const String buttonOpenInvite = 'Открыть канал курса';
  static const String defaultCourseTitle = 'Цвет в интерьере. Основы и практика';
  static const String courseShortTitle = 'Цвет в интерьере';
  static const String guideTitle = 'Язык цвета';
  static const String masterClassTitle =
      'Как начать работать с цветом смелее и не бояться ошибиться';
  static const String buttonCopyInvite = 'Скопировать ссылку';
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
  static const String buttonAdminBroadcastSelectAll = 'Выбрать все';
  static const String buttonAdminBroadcastClearAll = 'Снять все';
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
  static const String buttonAdminCatalogDozhim = '📣 Дожим';
  static const String buttonAdminCatalogDozhimAdd = '➕ Добавить день';
  static const String buttonAdminCatalogDozhimReplace = '✏️ Заменить';
  static const String buttonAdminCatalogDozhimDelete = '🗑 Удалить день';
  static const String buttonAdminCatalogActivate = '⭐ Сделать активным';
  static const String buttonAdminCatalogDelete = '🗑 Удалить';
  static const String buttonAdminCatalogBack = '↩️ К списку';
  static const String buttonAdminCatalogSave = '💾 Записать';
  static const String buttonAdminCatalogKeepCode = '✅ Оставить этот код';
  static const String buttonAdminCatalogKeepSuggested = '✅ Оставить так';
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
  static const String cbPayRemainder = 'pr:';
  // Leftover callbacks from the removed offer-consent screen.
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
  static const String cbBroadcastSelectAll = 'ba';
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
  static const String cbCatalogDozhim = 'cz:';
  static const String cbCatalogDozhimAdd = 'cza:';
  static const String cbCatalogDozhimOpen = 'czo:';
  static const String cbCatalogDozhimReplace = 'czr:';
  static const String cbCatalogDozhimDelete = 'czx:';
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
    return 'Привет 🤍\n'
        'На связи Анастасия Дубовскова — дизайнер и автор 80+ узнаваемых проектов, где цвет является частью характера пространства, преподаватель в Академии дизайна, член жюри Евразийской премии по хоумстейджингу 2026 и лауреат премий.\n\n'
        'А это мой бот-помощник! Здесь будут материалы, разборы и анонсы — в первую очередь про то, как перестать бояться цвета и начать использовать его осознанно.\n\n'
        '<b>Для начала у меня для тебя подарок — гайд «${MessageTemplates.guideTitle}».</b>\n'
        'Забирай его по кнопке «Получить гайд» 🍂';
  }

  String startCourseCard({Launch? launch}) {
    return _preSalesCourseCopy(launch);
  }

  String alreadyInFunnel() {
    return '<b>Продолжаем с того же места</b>\n\n'
        'В меню внизу: гайд, курс и помощь.';
  }

  String menuPinned() {
    return 'Меню внизу: гайд, курс и помощь.';
  }

  String courseMenuPinned() {
    return 'После полной оплаты пришлю доступ к каналу курса и чату потока.';
  }

  String courseStatus({
    Launch? launch,
    CourseOrder? order,
    ChannelAccess? access,
    required DateTime now,
  }) {
    final buf = StringBuffer()
      ..writeln('<b>Курс ${_quotedCourseTitle(launch)}</b>')
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
      return 'Доступ к этому потоку уже есть.';
    }
    final paid = formatRubSpaced(order.amountPaidKopecks);
    final full = formatRubSpaced(order.priceFullKopecks);
    switch (order.status) {
      case OrderStatus.depositPaid:
        return 'Внесена предоплата $paid. '
            'Остаток ${formatRubSpaced(order.amountDueKopecks)} до старта программы';
      case OrderStatus.paid:
        return 'Оплата закрыта, $paid из $full.';
      case OrderStatus.checkoutStarted:
      case OrderStatus.awaitingPayment:
        return 'Оплата ещё не закрыта, пока $paid из $full.';
      case OrderStatus.cancelled:
        return 'Оплата отменена.';
    }
  }

  String _courseStartLine(Launch? launch, DateTime now) {
    final start = _formatDate(launch?.courseStartAt);
    if (start == null) {
      return 'Дата старта пока не указана.';
    }
    if (_courseHasStarted(launch?.courseStartAt, now)) {
      return 'Идёт с $start.';
    }
    return start;
  }

  String _courseChannelLine({CourseOrder? order, ChannelAccess? access}) {
    if (order != null && order.hasRemainder) {
      return 'Откроется после полной оплаты';
    }
    if (access == null) {
      return 'Оплата есть, канал ещё не привязан. Напиши сюда — новую ссылку выдаст админ.';
    }
    if (access.revokedAt != null) {
      return 'Доступ снят. Напиши сюда, если это ошибка.';
    }
    if (access.hasJoined) {
      return 'Ты уже внутри.';
    }
    final link = access.inviteLink?.trim();
    if (link == null || link.isEmpty) {
      return 'Ссылка ещё не выдана. Напиши сюда — новую выдаст админ.';
    }
    return 'Доступ по кнопке ниже.';
  }

  String? _courseStatusNextStep({CourseOrder? order, ChannelAccess? access}) {
    if (order != null && order.hasRemainder) {
      return 'После того, как будет внесена полная сумма, пришлю доступ к каналу курса и чату потока.';
    }
    if (access != null &&
        access.revokedAt == null &&
        !access.hasJoined &&
        (access.inviteLink?.trim().isNotEmpty ?? false)) {
      return 'Вижу, что ты еще не открывал(а) доступ в канал курса — скорее жми на кнопку ниже. '
          'Если не сработает, напиши сюда, новую выдаст админ.';
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
        'Если что-то сломалось или не пришло, напиши сюда: перешлю человеку на связи.';
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

  String warmupStep(String stepKey, {Launch? launch, bool rsvp = false}) {
    return switch (stepKey) {
      'warmup_0' => _warmupZero(launch, rsvp: rsvp),
      'warmup_d1' => _warmupDay1(),
      'warmup_d3' => _warmupDay3(launch),
      'warmup_d7' => _warmupDay7(launch),
      'enroll_d1' => _enrollDay1(launch),
      'enroll_d3' => _enrollDay3(launch),
      'webinar_24h' => _webinarTomorrow(launch, rsvp: rsvp),
      'webinar_10m' => _webinarTenMinutes(launch, rsvp: rsvp),
      'webinar_live' => _webinarLive(launch),
      'webinar_next' => _webinarNextDay(launch),
      'sales_open' => _salesOpen(launch),
      'sales_regular' => _salesRegular(launch),
      'dozhim_d1' => _dozhimCase(launch),
      'dozhim_d2' => _dozhimFear(launch),
      'dozhim_d3' => _dozhimBeforeAfter(launch),
      'dozhim_d4' => _dozhimReviews(launch),
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

  String _warmupZero(Launch? launch, {required bool rsvp}) {
    final when = _formatHumanDate(launch?.webinarAt) ?? 'Скоро';
    return 'Отлично, гайд у тебя — это уже первый шаг навстречу цвету🤍\n\n'
        'Готов(а) ли ты пойти дальше?\n'
        '$when я проведу живой мастер-класс — <b>«${MessageTemplates.masterClassTitle}»</b> и приглашаю тебя!\n\n'
        'Разберём, почему интерьерная колористика - это глубже, но при этом проще, чем привычный круг Иттена и схема 60-30-10.\n'
        'Покажу на своих реальных объектах, как принимать решение по цвету с помощью 3-х простых инструментов.\n\n'
        '<u>Особенно жду тебя, если ты уже проходил интенсивы по колористике и всё стало только сложнее!</u>\n'
        'После этого материала ты начнешь работать с цветом в интерьерах легко и осознанно!\n\n'
        '${_webinarScheduleBlock(launch)}\n\n'
        '${_warmupRsvpCta(launch: launch, rsvp: rsvp)}';
  }

  String _webinarTomorrow(Launch? launch, {required bool rsvp}) {
    final time = _formatClock(launch?.webinarAt);
    final when = time == null ? 'завтра' : 'завтра в $time по мск';
    return 'Мастер-класс уже завтра!\n\n'
        'Напоминаю, $when проведу мастер-класс '
        '<b>«${MessageTemplates.masterClassTitle}»</b>!\n\n'
        'Это будет не стандартный набор формул, о которых вы уже много раз слышали.\n'
        'Именно после этого материала мои ученики-дизайнеры говорят "А что, так можно было?!" 🤭, '
        'приходит уверенность и легкость в работе с цветом, а их объекты обретают авторский узнаваемый почерк.\n\n'
        '${_warmupRsvpCta(launch: launch, rsvp: rsvp, listed: 'Ты уже в списке. ${_webinarLinkFollowup(launch)}', unlisted: _joinSentences('Ссылка придет тем, кто отметился по кнопке внизу, нажимай скорее', _webinarLinkLaterIfMissing(launch)))}';
  }

  String _webinarTenMinutes(Launch? launch, {required bool rsvp}) {
    final time = _formatClock(launch?.webinarAt);
    final when = time == null ? 'скоро' : 'ровно в $time мск';
    final unlisted = _joinSentences(
      '🤫 По секрету между нами: нажимай на кнопку, даже если не получится быть онлайн — '
      'пришлю запись и специальное предложение на мой курс по интерьерной колористике.',
      _webinarLinkLaterIfMissing(launch),
    );
    final listed = _joinSentences(
      '🤫 По секрету между нами: даже если не получится быть онлайн — '
      'пришлю запись и специальное предложение на мой курс по интерьерной колористике.',
      _webinarLinkFollowup(launch),
    );
    return 'Начинаем через 10 минут\n\n'
        'Мастер-класс <b>«${MessageTemplates.masterClassTitle}»</b> стартует $when.\n\n'
        '${_warmupRsvpCta(launch: launch, rsvp: rsvp, listed: listed, unlisted: unlisted)}';
  }

  String _webinarLive(Launch? launch) {
    if (!(launch?.hasWebinarUrl ?? false)) {
      return 'Мы начинаем 🔥\n\n'
          '${_webinarLinkLaterLine()} Ты в списке.';
    }
    return 'Мы начинаем 🔥\n\n'
        'Мастер-класс «${MessageTemplates.masterClassTitle}» вот-вот стартует. '
        'Присоединяйся по кнопке ниже.';
  }

  String _webinarNextDay(Launch? launch) {
    final resolved = launch ?? _placeholderLaunch();
    final promo = formatRubSpaced(resolved.resolvedPricePromoKopecks, unit: 'руб.');
    final was = _compareAtRub(resolved);
    return 'Спасибо, что был(а) со мной на Мастер-классе🤍\n\n'
        'Если после эфира захотелось разобраться в цвете уже системно, а не по кусочкам, приглашаю тебя на следующий шаг — '
        '<b>курс ${_quotedCourseTitle(resolved)}.</b>\n\n'
        '${_colorCoursePitchBody(forWebinarAlumni: true)}\n\n'
        '🎁 И только для тех, кто участвовал в Мастер-классе я даю <b>специальные условия</b>: стоимость всего курса для вас — '
        '$promo <s>$was</s>\n'
        '⚡ Предложение действует 3 дня. Далее цена повысится и зайти на программу по специальной цене будет нельзя.\n\n'
        'Успевай сделать финальный шаг навстречу осознанной работе с цветом и узнаваемым объектам со вкусом!\n\n'
        '<i>Запись мастер-класса:</i>';
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

  String _salesOpen(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final startLine = start == null ? '' : 'Старт потока $start. Уроки в телеграм + общий чат.\n\n';
    return 'Курс ${_quotedCourseTitle(launch)} открывает свои двери! 🎉\n\n'
        '${_colorCoursePitchBody(forWebinarAlumni: false)}\n\n'
        'Я не буду грузить вас давно знакомыми формулами и абстрактными правилами. '
        'Я дам вам систему, которая заменяет интуицию на повторяемый алгоритм принятия решений.\n\n'
        '$startLine'
        '🎨 Сделай свой финальный шаг навстречу цвету в интерьере. Жду тебя на курсе!';
  }

  String _salesRegular(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final price = _marketingPrice(launch?.resolvedPriceFullKopecks);
    final deposit = launch != null && launch.hasDepositOption
        ? formatRubSpaced(launch.depositKopecks, unit: 'руб.')
        : null;
    final priceLine = price == null
        ? 'Предложение о специальной цене истекло, но двери курса еще открыты! 🧡'
        : deposit == null
        ? 'Предложение о специальной цене истекло, но двери курса еще открыты! 🧡\n\n'
              'Сейчас ты можешь приобрести программу за $price.'
        : 'Предложение о специальной цене истекло, но двери курса еще открыты! 🧡\n\n'
              'Сейчас ты можешь приобрести программу за $price или забронировать место по предоплате $deposit и внести остаток до старта курса.';
    return 'Вы еще успеваете присоединиться\n\n'
        '$priceLine'
        '${start == null ? '' : '\nСтарт потока $start'}\n\n'
        'Ты с нами?';
  }

  String _dozhimCase(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final startLine = start == null
        ? 'Присоединяйтесь к ближайшему потоку.'
        : 'Присоединяйтесь к ближайшему потоку, стартуем $start.';
    return 'Забудьте про круг Иттена 🎨\n\n'
        'Просто посмотрите на этот проект.\n'
        'Получилось бы его реализовать, если бы я использовала стандартные схемы? — Нет.\n'
        'Мог бы он случиться, если бы я работала только по расчётам? — Тоже нет.\n'
        'Взял ли этот проект премию, напечатали ли его в журналах? — ДА!\n\n'
        'А сколько сердец покорил... 💔\n\n'
        'Он построен на перекличке оттенков, а не на классических схемах. Здесь больше 5 активных цветов: розовый с красным, голубой с холодным жёлтым. Всё открытое, насыщенное. Максимум чистоты, минимум нюансов.\n\n'
        'Неожиданные сочетания, акцент на чистоту и насыщенность цвета вместо привычных нюансных оттенков.\n\n'
        'В курсе разберём инструменты за пределами привычных кругов и формул, потому что цвет это не математика.\n\n'
        'Буду учить вас нарушать правила со вкусом 🤍\n'
        '$startLine\n'
        'Записаться по кнопке внизу';
  }

  String _dozhimFear(Launch? launch) {
    return 'Сколько курсов по цвету вы проходили?\n\n'
        'Изучено столько программ по колористике, в голове путаница и вроде бы знаешь, как правильно, но на деле интерьер не складывается.\n'
        'После такого действительно начинаешь думать:\n'
        '"Чувство цвета либо есть, либо нет. Мне не дано" 🤔\n\n'
        'Спешу обрадовать: это не так.\n'
        'Чувство цвета в интерьере легко развить.\n'
        'Просто вас в очередной раз перегрузили абстрактными формулами вместо того, чтобы дать понятный ориентир.\n\n'
        'Вам нужны не полсотни правил, а лишь 3 рабочих: перекличка, тепло-холодность, светлота. Их видно глазами на объекте.\n\n'
        'Подробнее расскажу на курсе ${_quotedCourseTitle(launch)}\n'
        '🔥 16 конкретных уроков именно по интерьерной колористике для тех, кто хочет создавать вкусные цветовые сочетания без сложных просчетов.\n\n'
        'Большая авторская программа, которая закрывает страх работы с цветом и ставит точку в вопросе цветовых решений.\n\n'
        'Вы с нами?';
  }

  String _dozhimBeforeAfter(Launch? launch) {
    return 'Ещё одно подтверждение, как цвет работает на преображение.\n\n'
        'Оцените «до / после» в этом проекте.\n'
        'Исходный ремонт далеко не самый актуальный. Но, не трогая планировку и отделку, мы расставили цветовые акценты, которые сделали квартиру свежее и визуально дороже. При этом ни один элемент не выглядит чужим: цвет собрал пространство в единую историю, а не добавил в неё ещё один слой.\n\n'
        '🪄 Работа с цветом самый сильный инструмент в руках дизайнера и хоумстейджера, будь то вторичка или ремонт от застройщика. Он позволяет менять восприятие пространства и преображать объекты, которые, казалось бы, уже не спасти.\n'
        'Поэтому цвет — не враг, к которому боязно подступиться, а помощник, который работает на вас и позволяем вам творить чудеса на объектах.\n\n'
        'Умение осознанно работать с цветом — это профессиональное преимущество, которое отличает вас от специалистов со «средней» услугой.\n\n'
        'Если хотите чувствовать себя уверенно в работе с цветом, двери курса ${_quotedCourseTitle(launch)} ещё открыты.\n'
        'Присоединяйтесь по кнопке внизу 👇';
  }

  String _dozhimReviews(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final startLine = start == null
        ? 'Вы еще успеваете присоединиться.'
        : 'Вы еще успеваете присоединиться, стартуем $start.';
    return '"Зачем мне на курс, когда есть Pinterest?"\n\n'
        'Вы будете частично правы: своим ученикам, которые в начале пути, я говорю "пробуйте повторить".\n'
        'Даже если скопируете, всё равно получится по-своему.\n\n'
        'Но если вы хотите пользоваться цветом, как инструментом и осознанно им управлять, растить свой профессионализм и повышать не только насмотренность, но и чек за услуги, уметь пользоваться готовыми палитрами из интернета — недостаточно.\n\n'
        'Мой курс — это не ещё один "список трендовых сочетаний 2026".\n'
        'Он о том, как адаптировать любую палитру:\n'
        '- под свою идею\n'
        '- под сегодняшний день\n'
        '- под конкретное пространство\n'
        '- под конкретного заказчика\n\n'
        '$startLine\n'
        'Добавите уверенности и красок вашим объектам и сформируете авторский почерк!\n'
        'Записаться по кнопке внизу 👇';
  }

  String _lastWagon(Launch? launch) {
    return '<b>Любителям запрыгнуть в последний вагон</b>\n\n'
        'Сегодня последний день, когда можно присоединиться к курсу ${_quotedCourseTitle(launch)}! '
        'Старт потока ${_formatHumanDate(launch?.courseStartAt) ?? 'когда будет дата'}.\n\n'
        'Присоединиться по кнопке ниже.';
  }

  String webinarRsvpConfirmed(Launch launch, {bool showLink = false}) {
    if (showLink) {
      return 'Поздравляю! Ты в списке участников!\n\n'
          'Мастер-класс уже идёт — кнопка со ссылкой ниже.';
    }
    final day = _formatHumanDate(launch.webinarAt);
    final time = _formatClock(launch.webinarAt);
    final when = day == null
        ? ''
        : 'Бесплатный Мастер-класс <b>«${MessageTemplates.masterClassTitle}»</b> пройдет\n'
              '📅 <b>$day${time == null ? '' : ' в $time'}</b>\n\n';
    return 'Поздравляю! Ты в списке участников!\n\n'
        '$when'
        'Напомню ближе дате мастер-класса и пришлю ссылку.\n'
        '${_webinarLinkFollowup(launch)}\n\n'
        'Жду встречи! 🤍';
  }

  String _warmupDay1() {
    return '<b>Почему любимый цвет «не работает» в объекте</b>\n\n'
        'Часто дело не во вкусе, а в том, как оттенок живёт со светом, деревом и металлом: '
        'один и тот же цвет может звучать чисто — или грязно.\n\n'
        'Гайд это подсвечивает. На курсе собираем палитру, которая держит характер пространства. '
        'Курс — в меню, когда будет момент.';
  }

  String _warmupDay3(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final price = _marketingPrice(launch?.priceFullKopecks);
    final deposit = launch != null && launch.hasDepositOption
        ? formatRubSpaced(launch.depositKopecks, unit: 'руб.')
        : null;
    final due = _formatHumanDate(launch?.depositDueAt);
    final buf = StringBuffer()
      ..writeln(start == null ? '<b>Если идёшь на курс</b>' : '<b>Старт потока $start</b>')
      ..writeln();
    buf.write('Курс ${_quotedCourseTitle(launch)}.');
    if (price != null) {
      buf.write(' Полная стоимость $price.');
      if (deposit != null) {
        final until = due == null ? 'до старта' : 'до $due';
        buf.write(' Можно внести предоплату $deposit и закрыть остаток $until.');
      }
    } else {
      buf.write(' Можно закрыть полную сумму или внести предоплату.');
    }
    buf
      ..writeln()
      ..writeln()
      ..write(
        'Ссылка в канал курса придёт после полной оплаты. '
        'Курс — в меню внизу.',
      );
    return buf.toString();
  }

  String _warmupDay7(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final startLine = start == null ? 'Курс ещё можно успеть.' : 'Старт потока $start.';
    return '<b>Неделя с гайдом</b>\n\n'
        '$startLine Если хочешь собирать цвет в интерьере как систему — курс в меню внизу.';
  }

  String _enrollDay1(Launch? launch) {
    return '<b>Подарок всё ещё здесь</b>\n\n'
        'Гайд «${MessageTemplates.guideTitle}» никуда не делся — '
        'и курс ${_quotedCourseTitle(launch)} тоже.'
        '${_startFact(launch)}\n\n'
        'Оба ждут в меню внизу.';
  }

  String _enrollDay3(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final startLine = start == null ? 'Курс ещё можно успеть.' : 'Старт потока $start.';
    return '<b>Гайд никуда не делся</b>\n\n'
        '$startLine «${MessageTemplates.guideTitle}» и курс ${_quotedCourseTitle(launch)} '
        'всё ещё в меню внизу — открой, когда будет минута.';
  }

  String _startNudge(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final headline = start == null ? 'Курс близко' : 'Старт потока $start';
    return '<b>$headline</b>\n\n'
        'Присоединиться ещё можно из меню внизу. '
        'Ссылку в канал курса пришлю после полной оплаты.';
  }

  String _startFact(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    return start == null ? '' : ' Старт потока $start.';
  }

  String? _marketingPrice(int? kopecks) {
    if (kopecks == null || kopecks <= 0) {
      return null;
    }
    return formatRubSpaced(kopecks, unit: 'руб.');
  }

  String optOutConfirmed() {
    return '<b>Вы отписались от сообщений бота</b>\n\n'
        'Жаль, что ты уходишь! Ты в любой момент можешь возобновить чат, чтобы получить полезные материалы и анонсы.';
  }

  String enrollOptions(
    Launch launch, {
    required SalesQuote quote,
    bool rsvpOpen = true,
    bool webinarStarted = false,
    bool hasOpenCheckout = false,
  }) {
    final start = _formatHumanDate(launch.courseStartAt) ?? 'когда будет дата';
    final title = _quotedCourseTitle(launch);
    final promo = formatRubSpaced(quote.pricePromoKopecks, unit: 'руб.');
    final wasRub = _compareAtRub(launch);
    switch (quote.phase) {
      case SalesPhase.preSales:
        return _preSalesCourseCopy(
          launch,
          cta: _preSalesMasterClassCta(
            launch: launch,
            rsvp: quote.rsvp,
            rsvpOpen: rsvpOpen,
            webinarStarted: webinarStarted,
          ),
        );
      case SalesPhase.closed:
        if (hasOpenCheckout) {
          return '<b>Запись закрыта</b>\n\n'
              'Продажи этого потока закончились. Старт $start. '
              'Оплату этого заказа ещё можно закрыть по кнопке ниже.';
        }
        return '<b>Запись закрыта</b>\n\n'
            'Продажи этого потока закончились. Старт $start. '
            'Если оплата уже шла — напиши в «${MessageTemplates.buttonHelp}».';
      case SalesPhase.promo:
        if (quote.rsvp) {
          final until = _formatHumanDate(quote.promoEndsAt);
          final untilLine = until == null
              ? 'Предложение актуально 3 дня'
              : 'Предложение актуально до $until';
          return 'Специальная цена на курс $title\n\n'
              '🎁 Для тебя открыты специальные условия - стоимость курса составляет $promo вместо <s>$wasRub</s>.\n'
              '⚡$untilLine, далее цена сменится на обычную и приобрести программу по специальной стоимости уже не получится.\n\n'
              'Старт потока $start.\n'
              'Оплатить можно по ссылке внизу.\n'
              'После полной оплаты придет ссылка на канал курса.';
        }
        return _regularEnrollCopy(launch: launch, quote: quote, start: start, rsvpOpen: rsvpOpen);
      case SalesPhase.regular:
        return _regularEnrollCopy(launch: launch, quote: quote, start: start);
    }
  }

  String payButton(String url) {
    if (url.isEmpty) {
      return payManualFallback();
    }
    return 'Ссылка на оплату готова. После успешного платежа статус в этом чате обновится сам. '
        'Если ты вносишь предоплату, то ссылка в канал курса придет тебе после внесения остатка.';
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

  String _adminWhoLineFor(UserProfile user) {
    return _adminWhoLine(userId: user.userId, username: user.username, firstName: user.firstName);
  }

  String _adminLaunchLine(Launch? launch) {
    final title = launch?.title.trim();
    if (title == null || title.isEmpty) {
      return 'поток не выбран';
    }
    return 'поток: ${escapeHtml(title)}';
  }

  String _payKindLabel(PaymentKind kind) => switch (kind) {
    PaymentKind.full => 'полная оплата',
    PaymentKind.deposit => 'предоплата',
    PaymentKind.remainder => 'доплата',
  };

  String adminGuideMissing({required int userId}) {
    return '<b>Гайд не залит</b>\n\n'
        'Человек id <code>$userId</code> нажал «получить гайд», а файла нет. '
        'Пришли PDF в этот чат и сохрани как гайд запуска.';
  }

  String adminGuideIssued({required UserProfile user, Launch? launch}) {
    return '<b>Получил гайд</b>\n\n'
        '${_adminWhoLineFor(user)}\n'
        '${_adminSourceLine(user.source)}\n'
        '${_adminLaunchLine(launch)}';
  }

  String adminWebinarRsvp({required UserProfile user, required Launch launch}) {
    final when = _formatDateTime(launch.webinarAt);
    final whenLine = when == null ? 'эфир: дата ещё не стоит' : 'эфир: $when';
    return '<b>Записался на эфир</b>\n\n'
        '${_adminWhoLineFor(user)}\n'
        '${_adminLaunchLine(launch)}\n'
        '$whenLine';
  }

  String adminPaidWithInvite({
    required UserProfile user,
    required CourseOrder order,
    Launch? launch,
  }) {
    return '<b>Оплатил — ссылка в канал выдана</b>\n\n'
        '${_adminWhoLineFor(user)}\n'
        '${_adminLaunchLine(launch)}\n'
        'заказ #${order.id} · ${_adminPaymentKindLabel(order.kind)}\n'
        'оплачено ${formatRubFromKopecks(order.amountPaidKopecks)} '
        'из ${formatRubFromKopecks(order.priceFullKopecks)}';
  }

  String paymentSucceeded({Launch? launch}) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final startLine = start == null ? '' : '\nСтартуем $start.\n';
    return 'Успешная оплата\n\n'
        'Поздравляю с поступлением на курс ${_quotedCourseTitle(launch)}! 🎆\n'
        'Вступай в канал этого потока по ссылке ниже — там тебя будут ждать уроки и чат.$startLine'
        'До встречи!';
  }

  String depositSucceeded(CourseOrder order, {Launch? launch}) {
    final start =
        _formatHumanDate(launch?.courseStartAt, withYear: true) ??
        _dueDateLabel(order.dueAt, fallback: 'старта курса');
    return 'Предоплата прошла\n\n'
        'Остаток необходимо внести до старта курса - $start.\n'
        'Ссылку в канал курса и чат потока пришлю, когда закроется полная сумма.';
  }

  String inviteMessage() {
    return 'Вступай в канал курса\n'
        'Вижу, что ты еще не открывал(а) доступ в канал курса — скорее жми на кнопку ниже.\n\n'
        'Если не сработает, напиши сюда, новую выдаст админ.';
  }

  String inviteUnavailable() {
    return 'Оплата есть, канал ещё не привязан. Напиши сюда — доступ выдаст админ.';
  }

  String abandonedFirst() {
    return 'Кажется, вы кое-что забыли\n\n'
        'Оформление заказа началось, но оплата пока не проведена. Можно продолжить с того же места.';
  }

  String abandonedSecond() {
    return 'Напоминаю про незакрытую оплату. Ссылка ещё действует — если поток всё ещё в планах.';
  }

  String abandonedPrestart() {
    return 'Поток близко, а оплата ещё не закрылась. Можно продолжить с того же места.';
  }

  String remainderBeforeDue(CourseOrder order, {Launch? launch}) {
    final due = _formatDate(order.dueAt) ?? _formatDate(launch?.courseStartAt) ?? 'скоро';
    return 'Напоминаю про внесение остатка за курс ⏰\n\n'
        'Ваше место на курсе забронировано!\n\n'
        'Уже внесена предоплата ${formatRubSpaced(order.amountPaidKopecks, unit: 'руб.')}, '
        'остаток - ${formatRubSpaced(order.amountDueKopecks, unit: 'руб.')}, срок внесения остатка до $due.\n\n'
        'После того, как будет внесена полная сумма, пришлю доступ к каналу курса и чату потока.';
  }

  String remainderReminder(CourseOrder order, {Launch? launch}) {
    return remainderBeforeDue(order, launch: launch);
  }

  String unjoinedInviteReminder() {
    return 'Вступай в канал курса\n'
        'Вижу, что ты еще не открывал(а) доступ в канал курса — скорее жми на кнопку ниже.\n\n'
        'Если не сработает, напиши сюда, новую выдаст админ.';
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
        '• ссылка на гайд — приветствие и гайд;\n'
        '• ссылка на курс — то же приветствие и сразу карточка потока.\n'
        'Дальше гайд и запись всегда в меню внизу.\n\n'
        '<b>Гайд</b>\n'
        'Без имени, почты и телефона. Сразу после файла — первое сообщение прогрева.\n\n'
        '<b>Прогрев после гайда</b>\n'
        'Сразу приглашение на мастер-класс и кнопка «${MessageTemplates.buttonRsvp}». '
        'Напоминания за сутки и за 10 минут, ссылка в день эфира тем, кто отметился. '
        'Спеццена — 3 дня с эфира, только у отметившихся.\n\n'
        '<b>Продажи</b>\n'
        'До старта продаж «${MessageTemplates.buttonEnroll}» — карточка курса и «ждём кассу», без оплаты. '
        'Старт продаж — поле в карточке курса (пусто — следующий день после эфира). '
        'В день старта продаж пишем тем, кто уже может оплатить. '
        'После окна спеццены — обычная цена и дожим. '
        'В последний день продаж — «последний вагон». Старт потока $startLine.\n\n'
        '<b>Если гайд не забрали</b>\n'
        'Напоминания на 1-й и на 3-й день после первого /start, пока не нажали «Записаться» '
        'и пока касса уже открыта для этого человека. '
        'После записи до старта продаж молчим про оплату. '
        'В день обычной цены и дожим до конца продаж — тоже, даже без гайда.\n\n'
        '<b>Запись и оплата</b>\n'
        '«${MessageTemplates.buttonEnroll}» — пока нет успешной оплаты. Потом та же кнопка открывает статус оплаты, старт и канал.\n'
        '• полная оплата — ссылка в канал этого потока;\n'
        '• предоплата — канала нет, пока не доплатят.\n\n'
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
    return 'Пришли текст, фото, файл, видео или голосовое.';
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

  static String catalogDozhimItemData(String prefix, int launchId, int id) {
    return '$prefix$launchId:$id';
  }

  static ({int launchId, int id})? catalogDozhimItemFromCallback(String data, String prefix) {
    if (!data.startsWith(prefix)) {
      return null;
    }
    final rest = data.substring(prefix.length);
    final sep = rest.indexOf(':');
    if (sep <= 0) {
      return null;
    }
    final launchId = int.tryParse(rest.substring(0, sep));
    final id = int.tryParse(rest.substring(sep + 1));
    if (launchId == null || id == null) {
      return null;
    }
    return (launchId: launchId, id: id);
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
    if (BroadcastSegment.coversAll(ordered)) {
      return 'все сегменты';
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
    BroadcastContentKind.album => 'альбом',
    BroadcastContentKind.location => 'геолокация',
    BroadcastContentKind.contact => 'контакт',
    BroadcastContentKind.other => 'другое',
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

  String? _formatHumanDate(DateTime? value, {bool withYear = false}) {
    if (value == null) {
      return null;
    }
    final moscow = MoscowTime.toMoscow(value);
    final month = _monthsGenitive[moscow.month - 1];
    if (withYear) {
      return '${moscow.day} $month ${moscow.year}';
    }
    return '${moscow.day} $month';
  }

  String? _formatClock(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _clock.format(MoscowTime.toMoscow(value));
  }

  String _courseTitle(Launch? launch) {
    final raw = launch?.title.trim();
    if (raw == null ||
        raw.isEmpty ||
        raw == MessageTemplates.defaultCourseTitle ||
        raw.startsWith(MessageTemplates.courseShortTitle)) {
      return MessageTemplates.courseShortTitle;
    }
    return raw;
  }

  String _quotedCourseTitle(Launch? launch, {bool escape = true}) {
    final title = _courseTitle(launch);
    final body = escape ? escapeHtml(title) : title;
    return '"$body"';
  }

  String _resolvedCourseDescription(Launch? launch) {
    return launch?.resolvedDescription ?? Launch.defaultDescription;
  }

  String _courseDescriptionHtml(Launch? launch) {
    return storedTelegramTextToHtml(_resolvedCourseDescription(launch));
  }

  String _preSalesCourseCopy(Launch? launch, {String? cta}) {
    final buf = StringBuffer()
      ..write('Курс ${_quotedCourseTitle(launch)} 🎨')
      ..writeln()
      ..writeln()
      ..write(
        launch != null && launch.hasCustomDescription
            ? _courseDescriptionHtml(launch)
            : _defaultPreSalesBody(launch),
      )
      ..writeln()
      ..writeln()
      ..write(_preSalesMasterClassWhen(launch));
    if (cta != null && cta.isNotEmpty) {
      buf
        ..writeln()
        ..writeln()
        ..write(cta);
    }
    return buf.toString();
  }

  String _defaultPreSalesBody(Launch? launch) {
    final start = _formatHumanDate(launch?.courseStartAt);
    final startPrefix = start == null ? '' : 'Старт потока $start. ';
    return 'Скоро стартует мой курс по интерьерной колористике\n'
        '$startPrefix<u>Я сообщу тебе, когда откроются продажи по самой выгодной цене.</u>\n\n'
        'А пока можно записаться на <b>бесплатный Мастер-класс «${MessageTemplates.masterClassTitle}»</b>, после которого понимание цвета в интерьерах у моих учеников-дизайнеров и хоумстейджеров разделилось на до и после.';
  }

  String _preSalesMasterClassWhen(Launch? launch) {
    final day = _formatHumanDate(launch?.webinarAt);
    final time = _formatClock(launch?.webinarAt);
    if (day != null && time != null) {
      return '📅 Мастер-класс пройдет $day в $time мск';
    }
    if (day != null) {
      return '📅 Мастер-класс пройдет $day';
    }
    if (time != null) {
      return '📅 Мастер-класс пройдет в $time мск';
    }
    return '📅 Мастер-класс: дату и время пришлю отдельно.';
  }

  String _compareAtRub(Launch? launch) {
    final kopecks = LaunchPrices.wasKopecks > 0
        ? LaunchPrices.wasKopecks
        : (launch?.resolvedPriceFullKopecks ?? 0);
    return formatRubSpaced(kopecks, unit: 'руб.');
  }

  String? _regularCompareAtRub(int payableKopecks) {
    if (LaunchPrices.wasRegularKopecks <= payableKopecks) {
      return null;
    }
    return formatRubSpaced(LaunchPrices.wasRegularKopecks);
  }

  String _webinarLinkLaterLine() {
    return 'Ссылку прикрепим позже и пришлём в этот чат.';
  }

  String _webinarLinkFollowup(Launch? launch) {
    if (launch?.hasWebinarUrl ?? false) {
      return 'Ссылка придет в этом боте.';
    }
    return _webinarLinkLaterLine();
  }

  String _webinarLinkLaterIfMissing(Launch? launch) {
    if (launch?.hasWebinarUrl ?? false) {
      return '';
    }
    return _webinarLinkLaterLine();
  }

  String _joinSentences(String head, String tail) {
    final extra = tail.trim();
    if (extra.isEmpty) {
      return head.trim();
    }
    return '${head.trim()} $extra';
  }

  String _webinarScheduleBlock(Launch? launch) {
    final day = _formatHumanDate(launch?.webinarAt);
    final time = _formatClock(launch?.webinarAt);
    if (day == null && time == null) {
      return 'Дату и время пришлю, когда они появятся в карточке курса.';
    }
    final lines = <String>[
      if (day != null) '📅 Дата: $day' else '📅 Дата ещё уточняется',
      if (time != null) '⏰ Время: $time' else '⏰ Время уточню отдельно',
    ];
    return lines.join('\n');
  }

  String _warmupRsvpCta({
    required Launch? launch,
    required bool rsvp,
    String? listed,
    String? unlisted,
  }) {
    if (rsvp) {
      return (listed ?? 'Ты уже в списке. ${_webinarLinkFollowup(launch)}').trim();
    }
    final fallback = _joinSentences(
      'Мастер-класс бесплатный! Нажми на кнопку, чтобы попасть в список участников в 1 клик',
      _webinarLinkLaterIfMissing(launch),
    );
    return (unlisted ?? fallback).trim();
  }

  String _preSalesMasterClassCta({
    required Launch launch,
    required bool rsvp,
    required bool rsvpOpen,
    required bool webinarStarted,
  }) {
    if (rsvp) {
      if (webinarStarted && launch.hasWebinarUrl) {
        return 'Ты в списке. Мастер-класс уже идёт — кнопка со ссылкой ниже.';
      }
      return 'Ты уже в списке участников.';
    }
    if (!rsvpOpen) {
      return 'Запись в список уже закрыта.';
    }
    return 'Нажимай на кнопку внизу, чтобы попасть в список участников за 1 клик.';
  }

  String _dueDateLabel(DateTime? value, {required String fallback}) {
    return _formatDate(value) ?? fallback;
  }

  String _formatMoscowDateTime(DateTime value) {
    final moscow = MoscowTime.toMoscow(value);
    return _dateTime.format(moscow);
  }

  String payFullButtonLabel(SalesQuote quote) {
    if (quote.promoPriceApplies) {
      return MessageTemplates.buttonPayFullPromo;
    }
    return '${MessageTemplates.buttonPayFull} (${formatRubSpaced(quote.payableKopecks, unit: 'руб.')})';
  }

  String payDepositButtonLabel(int kopecks) {
    return '${MessageTemplates.buttonPayDeposit} (${formatRubSpaced(kopecks, unit: 'руб.')})';
  }

  String _regularEnrollCopy({
    required Launch launch,
    required SalesQuote quote,
    required String start,
    bool rsvpOpen = false,
  }) {
    final title = _quotedCourseTitle(launch);
    final price = formatRubSpaced(quote.payableKopecks);
    final was = _regularCompareAtRub(quote.payableKopecks);
    final priceLine = was == null ? price : '$price <s>$was</s>';
    final deposit = !quote.promoPriceApplies && launch.hasDepositOptionFor(quote.payableKopecks)
        ? formatRubSpaced(launch.depositKopecks, unit: 'руб.')
        : null;
    final depositLine = deposit == null
        ? ''
        : '\nМожно закрыть всю сумму или забронировать место предоплатой $deposit.';
    final rsvpHint = rsvpOpen && !quote.rsvp
        ? '\n\nЕщё можно попасть в список мастер-класса и взять специальную цену — кнопка ниже.'
        : '';
    return 'Запись на курс $title 🧡\n\n'
        '16 уроков + эфир. Уроки в телеграм, общий чат участников.\n\n'
        'Стоимость: $priceLine$depositLine\n'
        'Стартуем $start.\n'
        'Ссылка в канал курса придет в этот чат после полной оплаты.'
        '$rsvpHint';
  }

  String dozhimEnrollCta() {
    return 'Записаться на курс — по кнопке ниже.';
  }

  String _colorCoursePitchBody({required bool forWebinarAlumni}) {
    final who = forWebinarAlumni ? 'Курс для тех, кто:' : 'Для тех, кто:';
    return '$who\n'
        '- многократно проходил программы по колористике и только запутался\n'
        '- считает, что работать с цветом либо дано, либо нет\n'
        '- хочет работать с цветом осознанно и предсказуемо, без эффекта лотереи\n'
        '- хочет усилить свои проекты и выйти на новый уровень стоимости\n\n'
        '🧡 16 уроков, построенных на реальных инструментах именно интерьерной колористики, не на абстрактных примерах. Разборы объектов, которые уже получали премии и публиковались в журналах.\n\n'
        'По итогам курса вы научитесь:\n'
        '— Уверенно пользоваться цветом, как инструментом: регулировать стиль и настроение интерьера, а также его «дороговизну» и целевую аудиторию\n\n'
        '— Осознанно нарушать классические цветовые схемы, а не бояться от них отступить: собирать сочетания на пять и больше активных цветов там, где раньше выбрали бы один безопасный акцент\n\n'
        '— Защищать смелые цветовые решения перед заказчиком: знать, почему это сработает, до того как соберёте проект, и поднимать чек за счёт результата, который сразу виден';
  }
}
