import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/admin_payment_status.dart';
import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/enrollment.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/domain/moscow_time.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/messages/html_escaper.dart';
import 'package:course_chatbot/src/messages/keyboards/keyboard_builders.dart';
import 'package:intl/intl.dart';

part 'templates/message_templates_keyboards.part.dart';

/// User-facing copy and keyboards. Marketing tone lives here, not in handlers.
final class MessageTemplates {
  MessageTemplates({String? botUsername}) : _botUsername = botUsername;

  final String? _botUsername;
  final DateFormat _date = DateFormat('dd.MM.yyyy');
  final DateFormat _dateTime = DateFormat('dd.MM.yyyy HH:mm');

  static const String buttonGuide = '📘 Получить гайд';
  static const String buttonEnroll = '✨ Записаться на курс';
  static const String buttonCourseStatus = '📋 Мой курс';
  static const String buttonHelp = '❓ Помощь';
  static const String buttonOptOut = '⏸ Не писать';
  static const String buttonPayFull = '💳 Оплатить полностью';
  static const String buttonPayDeposit = '💳 Предоплата';
  static const String buttonPayInstallment = '💳 Рассрочка';
  static const String buttonPayRemainder = '💳 Доплатить';
  static const String buttonGoToPay = '💳 Перейти к оплате';
  static const String buttonContinuePay = '💳 Продолжить оплату';
  static const String buttonOpenInvite = '🔗 Открыть канал';
  static const String buttonAcceptConsent =
      'Принимаю оферту и соглашаюсь на обработку персональных данных';
  static const String buttonAdminSearch = '🔍 Поиск человека';
  static const String buttonAdminAddUser = '➕ Добавить на курс';
  static const String buttonAdminBroadcast = '📣 Рассылка';
  static const String buttonAdminLinks = '🔗 Диплинки';
  static const String buttonAdminSheets = '📊 Обновить Sheets';
  static const String buttonAdminMenu = '🛠 Админка';
  static const String buttonAdminChangeStatus = '✏️ Изменить статус';
  static const String buttonAdminStatusUnpaid = '⏳ Не оплачено';
  static const String buttonAdminStatusDeposit = '💵 Предоплата';
  static const String buttonAdminStatusPaid = '✅ Оплачено полностью';
  static const String buttonAdminCancel = '🚫 Убрать с курса';
  static const String buttonAdminStatusBack = '↩️ К карточке';
  static const String buttonAdminReinvite = '🔗 Выдать ссылку в канал';
  static const String buttonAdminDm = '✉️ Написать';
  static const String buttonAdminConfirmYes = 'Да';
  static const String buttonAdminConfirmNo = 'Нет';
  static const String buttonAdminCreateUser = '➕ Создать карточку';
  static const String buttonAdminBroadcastSend = 'Отправить';
  static const String buttonAdminBroadcastOtherSegment = 'Другой сегмент';
  static const String buttonAdminBroadcastCancel = '✖️ Отмена';
  static const String buttonAdminBroadcastSkipOptOut = 'Кроме «Не писать»';
  static const String buttonAdminBroadcastIncludeOptOut = 'Включая отписавшихся';
  static const String buttonAdminGuideSave = '💾 Сохранить гайд';
  static const String buttonAdminGuideDiscard = '✖️ Не сохранять';
  static const String buttonAdminOpenCard = '👤 Карточка';

  static const String cbGuide = 'g';
  static const String cbEnroll = 'e';
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
  static const String cbBroadcastOtherSegment = 'br';
  static const String cbBroadcastCancel = 'bx';
  static const String cbBroadcastToggleOptOut = 'bt';
  static const String cbGuideSave = 'gs';
  static const String cbGuideDiscard = 'gx';
  static const String cbAdminCard = 'ak:';

  String botInDevelopment() {
    return '<b>Бот в разработке</b>\n\n'
        'Сейчас сценарий доступен только команде. '
        'Как откроем — напиши /start ещё раз.';
  }

  String startGuideOffer() {
    return '<b>Гайд «Язык цвета»</b>\n\n'
        'Какие оттенки тебе идут — и почему любимый цвет в зеркале вдруг «не работает». '
        'PDF пришлю сюда же: без имени, почты и телефона.\n\n'
        'Нажми «${MessageTemplates.buttonGuide}» в меню внизу — файл будет в этом чате.';
  }

  String startCourseCard({Launch? launch}) {
    final start = _formatDate(launch?.courseStartAt);
    final price = _formatPrice(launch?.priceFullKopecks);
    final headline = start == null ? 'Курс по колористике' : 'Поток с $start';
    final buf = StringBuffer()
      ..writeln('<b>$headline</b>')
      ..writeln()
      ..write('Собрать свой язык цвета и гардероб, который не спорит с тоном кожи.');
    if (price != null) {
      buf.write(' Полная стоимость — $price.');
    }
    if (start != null) {
      buf.write(' Старт $start.');
    }
    buf
      ..writeln()
      ..writeln()
      ..write('Можно сразу записаться или сначала забрать бесплатный гайд «Язык цвета».');
    return buf.toString();
  }

  String alreadyInFunnel() {
    return '<b>Ты уже здесь</b>\n\n'
        'Гайд можно запросить снова — «${MessageTemplates.buttonGuide}». '
        'Запись на поток — «${MessageTemplates.buttonEnroll}». '
        'Написать админу — «${MessageTemplates.buttonHelp}» или просто сообщение в этот чат.';
  }

  String menuPinned() {
    return 'Меню внизу всегда под рукой: гайд, запись или статус курса, помощь. '
        'Если что-то не получается — напиши сюда в чат, перешлю админу.';
  }

  String courseMenuPinned() {
    return 'В меню внизу вместо записи — «${MessageTemplates.buttonCourseStatus}»: '
        'оплата, старт потока и канал.';
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
      return 'Канал: оплата есть, канал ещё не привязан. Напиши сюда — админ выдаст доступ.';
    }
    if (access.revokedAt != null) {
      return 'Канал: доступ снят. Напиши сюда, если это ошибка.';
    }
    if (access.hasJoined) {
      return 'Канал: ты уже внутри.';
    }
    final link = access.inviteLink?.trim();
    if (link == null || link.isEmpty) {
      return 'Канал: ссылка ещё не выдана. Напиши сюда — админ выдаст из карточки.';
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
      return 'Открой канал с кнопки ниже. Если не сработает — напиши сюда, админ выдаст другую ссылку.';
    }
    if (access == null || access.revokedAt != null || access.inviteLink == null) {
      return null;
    }
    if (access.hasJoined) {
      return 'Если что-то не так — напиши сюда, перешлю админу.';
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
    return '<b>Как это устроено</b>\n\n'
        'Кнопки внизу: гайд, запись на поток и помощь. После оплаты вместо записи — '
        '«${MessageTemplates.buttonCourseStatus}»: сколько закрыто, старт потока и канал.\n\n'
        'Гайд потерялся или не пришёл — нажми «${MessageTemplates.buttonGuide}», пришлю ещё раз.\n'
        'Ссылка на кассу не открылась — «${MessageTemplates.buttonEnroll}», затем «Продолжить оплату».\n'
        'Ссылка в канал потерялась или не открылась — напиши сюда, админ выдаст другую.\n\n'
        'Если возникли проблемы — напиши сюда, перешлю админу.';
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
    return '📘 Лови гайд «Язык цвета» — файл выше.';
  }

  String guideAsUrl(String url) {
    return '📘 Гайд «Язык цвета» здесь: ${escapeHtml(url)}';
  }

  String guideMissing() {
    return '📘 Гайд ещё не загружен. Нажми «${MessageTemplates.buttonHelp}» — '
        'пришлю, как только файл будет на месте.';
  }

  String warmupStep(String stepKey, {Launch? launch}) {
    return switch (stepKey) {
      'warmup_0' => _warmupZero(launch),
      'warmup_d1' => _warmupDay1(),
      'warmup_d3' => _warmupDay3(launch),
      'warmup_d7' => _warmupDay7(launch),
      'enroll_d1' => _enrollNudge(launch),
      'enroll_d3' => _enrollNudge(launch),
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
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start == null
        ? 'Можно записаться, когда будет удобно — «${MessageTemplates.buttonEnroll}» в меню внизу.'
        : 'Поток стартует $start. Можно записаться сейчас или почитать гайд и вернуться — '
              'кнопки в меню внизу никуда не денутся.';
    return '<b>Гайд — это алфавит</b>\n\n'
        '«Язык цвета» помогает увидеть, какие оттенки тебе идут. '
        'Курс собирает это в систему: база гардероба и цвета, с которыми проще собираться.\n\n'
        '$startLine';
  }

  String _warmupDay1() {
    return '<b>Почему любимый цвет «не идёт»</b>\n\n'
        'Часто дело не во вкусе, а в подтоне: холодный розовый на тёплой коже выглядит грязновато, '
        'тёплый беж на холодной — желтит.\n\n'
        'Гайд это подсвечивает. На курсе разбираем, как собрать базу, которая не спорит с кожей. '
        'Когда будет момент — «${MessageTemplates.buttonEnroll}» в меню внизу.';
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
        'Записаться — «${MessageTemplates.buttonEnroll}» в меню внизу.',
      );
    return buf.toString();
  }

  String _warmupDay7(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start == null ? 'Поток ещё можно успеть.' : 'Старт потока $start.';
    return '<b>Неделя с гайдом</b>\n\n'
        '$startLine Если хочешь собрать гардероб в систему — '
        '«${MessageTemplates.buttonEnroll}» в меню внизу.';
  }

  String _enrollNudge(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start == null ? '' : ' Старт потока $start.';
    return '<b>Гайд и запись ещё здесь</b>\n\n'
        'Можно забрать «Язык цвета» или записаться на поток.$startLine '
        'Кнопки в меню внизу.';
  }

  String _startNudge(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start == null ? 'Поток близко.' : 'Поток $start.';
    return '<b>$startLine</b>\n\n'
        'Записаться ещё можно из меню внизу. Ссылку в канал пришлю после полной оплаты или после списания.';
  }

  String optOutConfirmed() {
    return '⏸ Ок, продающие сообщения больше не пришлю.\n\n'
        'Гайд и запись остаются в меню внизу. Если оплата уже начата или есть доплата — про это напомню, это не реклама.';
  }

  String enrollOptions(Launch launch) {
    final price = launch.priceFullKopecks > 0
        ? formatRubFromKopecks(launch.priceFullKopecks)
        : 'цену уточнит админ';
    final buf = StringBuffer()
      ..writeln('<b>Запись на поток</b>')
      ..writeln()
      ..writeln('Стоимость: $price.');
    if (launch.hasDepositOption) {
      buf.write('Можно начать с предоплаты ${formatRubFromKopecks(launch.depositKopecks)}.');
      final due = _formatDate(launch.depositDueAt);
      if (due != null) {
        buf.write(' Остаток — до $due');
        final start = _formatDate(launch.courseStartAt);
        if (start != null) {
          buf.write(', старт курса $start');
        }
        buf.write('.');
      }
      buf.writeln(' Ссылку в канал пришлю после полной оплаты.');
    }
    buf.writeln('Рассрочка откроется на странице кассы: график ведёт касса, не бот.');
    buf.writeln();
    buf.write('Выбери удобный способ оплаты.');
    return buf.toString().trim();
  }

  String offerConsent(Launch launch) {
    final offerPhrase = _offerPhrase(launch);
    return 'Чтобы открыть оплату, сначала нажми галочку ниже. '
        'Без этого кнопка «${MessageTemplates.buttonGoToPay}» не сработает.\n\n'
        'Нажимая «${MessageTemplates.buttonGoToPay}», ты подтверждаешь, '
        'что принимаешь условия $offerPhrase '
        'на оказание информационно-консультационных/образовательных услуг '
        'и даёшь согласие на обработку персональных данных.';
  }

  String offerNeedCheck() {
    return 'Сначала нажми галочку ниже — без этого оплата не откроется.';
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
    return '💳 Ссылка на оплату готова. После успешного платежа статус в этом чате обновится сам. '
        'Если страница кассы не вернула сюда — всё равно жди сообщение здесь. '
        'Если это предоплата, ссылку в канал пришлю после полной оплаты.';
  }

  // TODO(launch): replace the hardcoded @zhorenty support username below with
  //  the real support contact once it's confirmed.
  String payManualFallback() {
    return '💳 Сейчас временные технические неполадки с онлайн-оплатой, '
        'запись временно оформляется через администратора.\n\n'
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
    return '🔗 Одноразовая ссылка в канал потока:\n${escapeHtml(link)}\n\n'
        'На одного человека. Если не открылась — напиши сюда, админ выдаст другую.';
  }

  String inviteUnavailable() {
    return 'Оплата есть, канал ещё не привязан. Напиши сюда — админ выдаст доступ вручную.';
  }

  String abandonedFirst() {
    return '💳 Оформление началось, оплата пока не закрылась. Можно продолжить с того же места.';
  }

  String abandonedSecond() {
    return '💳 Напоминаю про незакрытую оплату. Ссылка ещё действует — если поток всё ещё в планах.';
  }

  String abandonedPrestart() {
    return '💳 Поток близко, а оплата ещё не закрылась. Можно продолжить с того же места.';
  }

  String remainderBeforeDue(CourseOrder order) {
    final due = _dueDateLabel(order.dueAt, fallback: 'скоро');
    return '💳 Напоминаю про доплату: остаток ${formatRubFromKopecks(order.amountDueKopecks)}, срок $due. '
        'После полной суммы открою канал потока.';
  }

  String remainderReminder(CourseOrder order) {
    final due = _dueDateLabel(order.dueAt, fallback: 'скоро');
    return '💳 Доплата по курсу: остаток ${formatRubFromKopecks(order.amountDueKopecks)}, срок $due. '
        'После полной суммы открою канал потока.';
  }

  String unjoinedInviteReminder(String link) {
    return '🔗 Ссылка в канал потока ещё не использована:\n${escapeHtml(link)}\n\n'
        'Открой её с кнопки ниже. Если не сработает — напиши сюда, админ выдаст другую.';
  }

  String inviteAskAdmin() {
    return 'Новую ссылку в канал выдаёт админ. Напиши сюда — передам.';
  }

  String adminMenu() {
    return '<b>Админка</b>\n\n'
        'Поиск и карточка человека, добавить на курс, ручной статус, рассылка сегменту. '
        'Диплинки — «${MessageTemplates.buttonAdminLinks}». '
        'Срез воронки и каталог COURSES — «${MessageTemplates.buttonAdminSheets}».';
  }

  String adminAskSearch() {
    return '<b>Поиск человека</b>\n\n'
        'Пришли сообщением id — цифры, как в карточке, или @username — ник в Telegram. '
        'Можно переслать сюда его сообщение — подставлю id сам.';
  }

  String adminAskAddUser() {
    return '<b>Добавить на курс</b>\n\n'
        'Пришли числовой Telegram id человека (как в @userinfobot). '
        'Можно переслать сюда его сообщение — подставлю id сам.\n\n'
        'Карточку создам, если её ещё нет. Дальше из карточки: оплата, ссылка в канал или убрать с курса.';
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

  String adminBroadcastPickSegment(Map<BroadcastSegment, int> counts) {
    final buf = StringBuffer()
      ..writeln('<b>Рассылка</b>')
      ..writeln()
      ..writeln('Кому отправить?')
      ..writeln();
    for (final segment in BroadcastSegment.values) {
      buf.writeln('${broadcastSegmentLabel(segment)} — ${counts[segment] ?? 0}');
    }
    return buf.toString().trim();
  }

  String adminBroadcastDraftSavedPickSegment() {
    return 'Сохранил черновик. Выбери сегмент.';
  }

  String adminBroadcastPreview({
    required BroadcastSegment segment,
    required int recipientCount,
    required BroadcastContentKind kind,
    String? previewText,
    int optOutCount = 0,
    bool excludeOptOut = false,
  }) {
    final buf = StringBuffer()
      ..writeln('<b>Превью</b>')
      ..writeln()
      ..writeln('Сегмент: ${escapeHtml(broadcastSegmentLabel(segment))}')
      ..writeln('Получателей: $recipientCount');
    if (optOutCount > 0) {
      buf.writeln(
        excludeOptOut
            ? '«Не писать» в сегменте: $optOutCount — не включены'
            : '«Не писать» в сегменте: $optOutCount — будут включены',
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
    return '📣 Рассылка: отправлено $sent, ошибок $failed, в сегменте $total.';
  }

  String adminMarkedPaid() => '✅ Оплата проставлена вручную.';

  String adminMarkedDeposit() => '💵 Предоплата проставлена вручную.';

  String adminMarkedUnpaid() => 'Статус: не оплачено. Invite отозван, если был.';

  String adminStatusFailed() => 'Не получилось сменить статус. Попробуй ещё раз.';

  String adminStatusChanged(AdminPaymentStatus status) => switch (status) {
    AdminPaymentStatus.unpaid => adminMarkedUnpaid(),
    AdminPaymentStatus.deposit => adminMarkedDeposit(),
    AdminPaymentStatus.paid => adminMarkedPaid(),
    AdminPaymentStatus.cancelled => adminCancelled(),
  };

  String adminCancelled() =>
      '🚫 Убрал с курса. Статус снят, invite отозван, из канала выкинул, если был.';

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

  String adminConfirmCancel(int userId) {
    return 'Убрать id <code>$userId</code> с курса? Invite отзову, из канала выкину.';
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

  String adminInviteReissued() {
    return '🔗 Ссылку в канал отправил человеку. Предыдущая больше не действует.';
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
      'Новая метка (Stories, таргет) — строка на листе, затем '
      '«${MessageTemplates.buttonAdminSheets}» или снова «${MessageTemplates.buttonAdminLinks}».',
    );
    return buf.toString().trim();
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
    BroadcastSegment.allStarted => 'Все, кроме купивших и отмен',
    BroadcastSegment.leadNoGuide => 'Гайд-вход, без гайда',
    BroadcastSegment.guideNotPaid => 'Гайд, без записи',
    BroadcastSegment.courseLeadNoCheckout => 'Курс, без записи',
    BroadcastSegment.checkoutOpen => 'Начали оплату',
    BroadcastSegment.depositPaid => 'Предоплата',
    BroadcastSegment.paidAccess => 'Оплатили / доступ',
    BroadcastSegment.paidNotJoined => 'Оплатили, не вошли',
    BroadcastSegment.cancelled => 'Отмена / возврат',
  };

  String broadcastSegmentButton(BroadcastSegment segment, int count) {
    return '${broadcastSegmentLabel(segment)} ($count)';
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
}
