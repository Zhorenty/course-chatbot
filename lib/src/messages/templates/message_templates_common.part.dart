part of 'package:course_chatbot/src/messages/message_templates.dart';

/// Common funnel phrases (help, pay, invite, status). Not launch slots.
extension MessageTemplatesCommon on MessageTemplates {
  String alreadyInFunnel() {
    return '<b>Продолжаем с того же места</b>\n\n'
        'В меню внизу: гайд, курс и помощь.';
  }

  String webinarRsvpClosedToast() => 'Регистрация на эфир уже закрыта.';

  String webinarRsvpListedToast() => 'Ты в списке участников!';

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
    if (launch == null) {
      return 'Дата старта пока не указана.';
    }
    final start = _formatDate(launch.courseStartAt)!;
    if (_courseHasStarted(launch.courseStartAt, now)) {
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

  String guideMissing() {
    return 'Гайд ещё не загружен. Напиши сюда — пришлю, как только файл будет на месте.';
  }

  String optOutConfirmed() {
    return '<b>Вы отписались от сообщений бота</b>\n\n'
        'Жаль, что ты уходишь! Ты в любой момент можешь возобновить чат, чтобы получить полезные материалы и анонсы.';
  }

  String payButton(String url) {
    if (url.isEmpty) {
      return payManualFallback();
    }
    return 'Ссылка на оплату готова. После успешного платежа статус в этом чате обновится сам. '
        'Если ты вносишь предоплату, то ссылка в канал курса придет тебе после внесения остатка.';
  }

  String payManualFallback() {
    return 'Сейчас онлайн-оплата недоступна, запись временно оформляется через администратора.\n\n'
        '<a href="tg://user?id=${MessageTemplates.supportContactUserId}">Напиши сюда</a> — подскажем, как закрыть оплату.';
  }

  String payFullButtonLabel(SalesQuote quote) {
    return '${MessageTemplates.buttonPayFull} (${formatRubSpaced(quote.payableKopecks, unit: 'руб.')})';
  }

  String payDepositButtonLabel(int kopecks) {
    return '${MessageTemplates.buttonPayDeposit} (${formatRubSpaced(kopecks, unit: 'руб.')})';
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

  String paymentResetToUnpaid({Launch? launch}) {
    return '<b>Статус оплаты сброшен</b>\n\n'
        'Доступ в канал снят, если был. Записаться снова — '
        '«${courseReplyButton(launch)}» в меню внизу.\n\n'
        'Если это ошибка — напиши сюда.';
  }

  String dozhimEnrollCta() {
    return 'Записаться на курс — по кнопке ниже.';
  }
}
