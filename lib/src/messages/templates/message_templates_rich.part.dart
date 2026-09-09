part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplatesRich on MessageTemplates {
  String startGuideOfferRich() {
    return '${richH2('Гайд «Язык цвета»')}'
        '${richP('Какие оттенки тебе идут — и почему любимый цвет в зеркале вдруг «не работает».')}'
        '${richP('PDF пришлю сюда: без имени, почты и телефона.')}'
        '${richFooter('Гайд — кнопка в меню внизу.')}';
  }

  String guideReadyRich() {
    return '${richH2('Гайд «Язык цвета»')}'
        '${richDocument(mediaId: MessageTemplates.guideDocumentMediaId)}'
        '${richP('Без имени, почты и телефона. PDF в этом сообщении.')}'
        '${richFooter('Дальше — эфир. Напомню следующим сообщением.')}';
  }

  String startCourseCardRich({Launch? launch}) {
    final start = _formatDate(launch?.courseStartAt);
    final price = _formatPrice(launch?.priceFullKopecks);
    final rawTitle = launch?.title.trim();
    final headline = rawTitle == null || rawTitle.isEmpty ? 'Курс по колористике' : rawTitle;
    final rows = <(String, String)>[
      if (start != null) ('Старт', start),
      if (price != null) ('Стоимость', price),
    ];
    return '${richH2(headline)}'
        '${richP('Собрать свой язык цвета и гардероб, который не спорит с тоном кожи.')}'
        '${rows.isEmpty ? '' : richTable(rows)}'
        '${richP('Дальше — записаться на поток или сначала забрать гайд «Язык цвета». Оба в меню внизу.')}';
  }

  String alreadyInFunnelRich() {
    return '${richH2('Продолжаем с того же места')}'
        '${richP('В меню внизу: гайд, запись на поток и помощь.')}';
  }

  String helpRich() {
    return '${richH2('Помощь')}'
        '${richP('Гайд, запись и статус — в меню внизу. Если что-то сломалось, напиши сюда: перешлю человеку на связи.')}'
        '${richUl(<String>['Гайд не пришёл — «${escapeHtml(MessageTemplates.buttonGuide)}» в меню, пришлю ещё раз.', 'Касса не открылась — «${escapeHtml(MessageTemplates.buttonEnroll)}», затем «Продолжить оплату».', 'Ссылка в канал не сработала — напиши сюда, новую выдаст админ.', 'Продающие сообщения не нужны — «${escapeHtml(MessageTemplates.buttonOptOut)}» ниже. Гайд, запись и напоминания про оплату останутся.'])}';
  }

  String courseStatusRich({
    Launch? launch,
    CourseOrder? order,
    ChannelAccess? access,
    required DateTime now,
  }) {
    final next = _courseStatusNextStep(order: order, access: access);
    return '${richH2('Мой курс')}'
        '${richTable(<(String, String)>[('Оплата', _coursePaymentLine(order).replaceFirst('Оплата: ', '')), ('Старт', _courseStartLine(launch, now).replaceFirst('Курс: ', '')), ('Канал', _courseChannelLine(order: order, access: access).replaceFirst('Канал: ', '').split('\n').first)])}'
        '${next == null ? '' : richP(next)}'
        '${_courseStatusInviteFooter(access: access, order: order)}';
  }

  String _courseStatusInviteFooter({CourseOrder? order, ChannelAccess? access}) {
    if (order != null && order.hasRemainder) {
      return '';
    }
    final link = access?.inviteLink?.trim();
    if (access == null ||
        access.revokedAt != null ||
        access.hasJoined ||
        link == null ||
        link.isEmpty) {
      return '';
    }
    return richP('🔗 ${escapeHtml(link)}');
  }

  String enrollOptionsRich(Launch launch, {required SalesQuote quote}) {
    return '${richH2(_enrollHeadline(quote))}${richP(enrollOptions(launch, quote: quote).replaceFirst(RegExp(r'^<b>.*?</b>\n\n'), ''))}';
  }

  String _enrollHeadline(SalesQuote quote) {
    return switch (quote.phase) {
      SalesPhase.preSales => 'Курс',
      SalesPhase.closed => 'Запись закрыта',
      SalesPhase.promo when quote.rsvp => 'Запись · спеццена',
      SalesPhase.promo => 'Курс',
      SalesPhase.regular => 'Запись на поток',
    };
  }

  String adminCardRich({
    required UserProfile user,
    UserEnrollment? enrollment,
    CourseOrder? order,
    ChannelAccess? access,
    List<ConversationLogEntry> dialog = const <ConversationLogEntry>[],
  }) {
    final phase = enrollment?.funnelPhase ?? user.funnelPhase;
    final optOut = enrollment?.warmupOptOut ?? user.warmupOptOut;
    final who = _adminPersonLabel(user);
    final money = _adminOrderLines(order).toList();
    final dialogHtml = dialog.isEmpty
        ? ''
        : richDetails('Последние сообщения', _adminDialogHtml(dialog));
    return '${richH2(who.isEmpty ? 'Карточка' : 'Карточка · $who')}'
        '${richTable(<(String, String)>[('id', '<code>${user.userId}</code>'), ('источник', _adminSourceLine(user.source).replaceFirst('источник: ', '')), ('воронка', escapeHtml(_headline(_adminPhaseLabel(phase))))])}'
        '${richH3('Деньги')}'
        '${richP(money.map(escapeHtml).join('<br>'))}'
        '${richH3('Канал')}'
        '${richP(escapeHtml(_adminChannelLine(access)))}'
        '${richH3('Связь')}'
        '${richUl(<String>[escapeHtml(_adminWarmupLine(optOut)), escapeHtml(_adminWebinarLine(enrollment)), escapeHtml(_adminBotLine(user.botBlocked))])}'
        '$dialogHtml';
  }

  String _adminDialogHtml(List<ConversationLogEntry> dialog) {
    final buf = StringBuffer('<ul>');
    for (final entry in _recentDialog(dialog)) {
      final dir = entry.direction == ConversationDirection.outbound ? '→' : '←';
      buf.write('<li>$dir ${_dialogPreview(entry)}</li>');
    }
    buf.write('</ul>');
    return buf.toString();
  }

  String adminCatalogCardRich(Launch launch) {
    final webinarUrl = launch.webinarUrl?.trim();
    final channel = launch.channelId;
    return '${richH2(launch.title)}'
        '${richTable(<(String, String)>[('код', '<code>${escapeHtml(launch.code)}</code>'), ('цена', formatRubFromKopecks(launch.priceFullKopecks)), ('спеццена', formatRubFromKopecks(launch.resolvedPricePromoKopecks)), ('предоплата', launch.depositKopecks > 0 ? formatRubFromKopecks(launch.depositKopecks) : 'нет'), ('старт', _formatDate(launch.courseStartAt) ?? 'не указан'), ('эфир', _formatDateTime(launch.webinarAt) ?? 'не указан'), ('ссылка эфира', webinarUrl == null || webinarUrl.isEmpty ? 'нет' : 'есть'), ('старт продаж', _formatDateTime(launch.salesStartAt) ?? 'как дата эфира'), ('конец продаж', _formatDate(launch.salesEndAt) ?? 'не указан'), ('канал', channel == null ? 'не указан' : '<code>$channel</code>'), ('гайд', _catalogHasGuide(launch) ? 'есть' : 'нет'), ('активен', launch.isActive ? 'да' : 'нет')])}';
  }

  String adminFunnelLogicRich({Launch? launch}) {
    final start = _formatDate(launch?.courseStartAt) ?? 'дата старта из карточки курса';
    return '${richH2('Как устроена воронка')}'
        '${richP('Человек заходит в бота → может забрать гайд и/или записаться на поток → бот сам напоминает, пока нет оплаты или отписки.')}'
        '${richDetails('Кто не получает прогрев', richP('Аккаунты админов. Карточка может появиться (админ тоже пишет боту), но продающие сообщения админу не шлём.'))}'
        '${richDetails('Вход', '${richP('Ссылка с меткой (Reels, Threads, пост и т.д.). Первый переход запоминаем. Повторный /start уже идущий сценарий не ломает.')}${richUl(<String>['ссылка на гайд — экран про «Язык цвета»;', 'ссылка на курс — карточка потока.', 'Дальше гайд и запись всегда в меню внизу.'])}')}'
        '${richDetails('Гайд', richP('Без имени, почты и телефона. Сразу после файла — первое сообщение прогрева.'))}'
        '${richDetails('Прогрев после гайда', richP('Сразу приглашение на эфир и кнопка «Буду на эфире». Напоминания за сутки и за 10 минут, ссылка в день эфира тем, кто отметился. Спеццена — 3 дня с эфира, только у отметившихся.'))}'
        '${richDetails('Продажи', richP('До старта продаж «Записаться» — карточка курса и «ждём кассу», без оплаты. Старт продаж — поле в карточке курса (пусто — как дата эфира). После окна спеццены — обычная цена и дожим. В последний день продаж — «последний вагон». Старт потока $start.'))}'
        '${richDetails('Если гайд не забрали', richP('Напоминания на 1-й и на 3-й день после первого /start, пока не нажали «Записаться» и пока касса уже открыта для этого человека. После записи до старта продаж молчим про оплату. В день обычной цены и дожим до конца продаж — тоже, даже без гайда.'))}'
        '${richDetails('Запись и оплата', '${richP('«${escapeHtml(MessageTemplates.buttonEnroll)}» — пока нет успешной оплаты. Потом в меню «Мой курс».')}${richUl(<String>['полная оплата или списание по рассрочке — ссылка в канал этого потока;', 'предоплата — канала нет, пока не доплатят;', 'рассрочка считается только после реального списания, не после заявки.'])}')}'
        '${richDetails('Открыли оплату и не закончили', richP('Напоминание через ~6 часов и через сутки. За 3 дня до старта — одно касание вместо двух.'))}'
        '${richDetails('Внесли предоплату', richP('Напоминание за 1–3 дня до срока, в день срока и один раз после просрочки. Отписка от рассылки это не глушит.'))}'
        '${richDetails('Отписка', richP('«${escapeHtml(MessageTemplates.buttonOptOut)}» в «${escapeHtml(MessageTemplates.buttonHelp)}». Гайд и запись остаются. Напоминания про начатую оплату и доплату тоже.'))}'
        '${richDetails('Ночью не пишем', richP('Автосообщения только с 10:00 до 21:00 по Москве. Напоминание за 10 минут до эфира уходит и ночью.'))}'
        '${richDetails('Канал', richP('Одноразовая ссылка после полной оплаты. Новую выдаёшь только ты из карточки человека.'))}';
  }

  String adminBroadcastPickSegmentRich(
    Map<BroadcastSegment, int> counts, {
    Set<BroadcastSegment> selected = const <BroadcastSegment>{},
    int recipientCount = 0,
    bool draftSaved = false,
  }) {
    final items = <String>[
      for (final segment in BroadcastSegment.values)
        '${selected.contains(segment) ? '✓ ' : ''}${escapeHtml(broadcastSegmentLabel(segment))} — ${counts[segment] ?? 0}',
    ];
    final selectedBlock = selected.isEmpty
        ? ''
        : '${richP('Выбрано: ${escapeHtml(broadcastSegmentsLabel(selected))}')}${richP('<b>Получателей: $recipientCount</b>')}';
    return '${draftSaved ? richP('Сохранил черновик.') : ''}'
        '${richH2('Рассылка')}'
        '${richP('Кому отправить? Можно несколько сегментов.')}'
        '${richUl(items)}'
        '$selectedBlock';
  }

  String adminBroadcastPreviewRich({
    required Iterable<BroadcastSegment> segments,
    required int recipientCount,
    required BroadcastContentKind kind,
    String? previewText,
    int optOutCount = 0,
    bool excludeOptOut = false,
  }) {
    final segmentWord = BroadcastSegment.ordered(segments).length == 1 ? 'Сегмент' : 'Сегменты';
    final optOutLine = optOutCount <= 0
        ? null
        : excludeOptOut
        ? '«Не писать» в выборке: $optOutCount — не включены'
        : '«Не писать» в выборке: $optOutCount — будут включены';
    final preview = previewText?.trim();
    return '${richH2('Превью')}'
        '${richTable(<(String, String)>[(segmentWord, escapeHtml(broadcastSegmentsLabel(segments))), ('Получателей', '<b>$recipientCount</b>'), if (optOutLine != null) ('Отписка', optOutLine), ('Содержимое', escapeHtml(broadcastContentKindLabel(kind)))])}'
        '${preview == null || preview.isEmpty ? '' : richQuote(escapeHtml(_clipBroadcastPreview(preview)))}';
  }

  String adminIncomingUserMessageRich({
    required UserProfile user,
    String? text,
    FunnelPhase? phase,
  }) {
    final handle = user.username?.trim();
    final body = (text == null || text.trim().isEmpty)
        ? 'без текста — фото или файл'
        : escapeHtml(text.trim());
    return '${richH2('Написал ${user.displayName}')}'
        '${richTable(<(String, String)>[('id', '<code>${user.userId}</code>'), if (handle != null && handle.isNotEmpty) ('username', '@${escapeHtml(handle)}'), ('воронка', escapeHtml(_adminPhaseLabel(phase ?? user.funnelPhase)))])}'
        '${richQuote(body)}';
  }

  String adminSheetsHubRich() {
    return '${richH2('Google Sheets')}'
        '${richP('«${escapeHtml(MessageTemplates.buttonAdminCatalog)}» — потоки на листе ${escapeHtml(CoursesSheet.tabTitle)}. '
        '«${escapeHtml(MessageTemplates.buttonAdminLinks)}» — метки на листе ${escapeHtml(LinksSheet.tabTitle)}. '
        '«${escapeHtml(MessageTemplates.buttonAdminSheets)}» — перечитать таблицу и пересобрать воронку.')}';
  }

  String adminSheetsHubOpenedRich() {
    return '${richH2('Google Sheets')}'
        '${richP('Курсы, диплинки и срез воронки. «${escapeHtml(MessageTemplates.buttonAdminBack)}» — выход в админку.')}';
  }

  String adminCatalogListRich(List<Launch> launches, {String? notice}) {
    final items = launches.isEmpty
        ? <String>[]
        : <String>[for (final launch in launches) _catalogListLine(launch)];
    return '${notice == null || notice.isEmpty ? '' : richP(notice)}'
        '${richH2('Курсы')}'
        '${items.isEmpty ? richP('В таблице пока нет потоков. Добавь новый.') : richUl(items)}'
        '${richP('Открой карточку или создай курс.')}';
  }

  String adminLinksListRich(List<AcquisitionLink> links, {String? notice}) {
    final items = links.isEmpty
        ? <String>[]
        : <String>[for (final link in links) _linksListLine(link)];
    return '${notice == null || notice.isEmpty ? '' : richP(notice)}'
        '${richH2('Диплинки')}'
        '${items.isEmpty ? richP('На листе пока нет меток. Добавь новую.') : richUl(items)}'
        '${richP('Открой карточку или создай диплинк.')}';
  }

  String adminLinksCardRich(AcquisitionLink link) {
    final launch = link.launchCode?.trim();
    final bot = _botUsername?.trim() ?? '';
    final url = bot.isEmpty
        ? 'username бота неизвестен — t.me не собрался'
        : '<code>${escapeHtml(deepLink(link.payload))}</code>';
    return '${richH2(link.origin)}'
        '${richTable(<(String, String)>[('куда', escapeHtml(link.destinationLabel)), ('метка', '<code>${escapeHtml(link.payload)}</code>'), ('поток', launch == null || launch.isEmpty ? 'текущий набор' : escapeHtml(launch)), ('ссылка', url)])}';
  }

  String adminSheetsRefreshResultRich({
    required bool catalogAttempted,
    required bool catalogOk,
    String? catalogError,
    required bool funnelAttempted,
    required bool funnelOk,
    String? funnelError,
    Launch? launch,
  }) {
    final rows = <(String, String)>[];
    if (catalogAttempted) {
      if (catalogOk && launch != null) {
        rows.add(('Набор в боте', 'обновлён'));
        final title = launch.title.trim();
        if (title.isNotEmpty) {
          rows.add(('поток', escapeHtml(title)));
        }
        rows.add(('цена', formatRubFromKopecks(launch.priceFullKopecks)));
        final start = _formatDate(launch.courseStartAt);
        if (start != null) {
          rows.add(('старт', start));
        }
      } else if (catalogOk) {
        rows.add(('Набор в боте', 'без изменений'));
      } else {
        rows.add((
          'Набор в боте',
          'лист ${escapeHtml(CoursesSheet.tabTitle)}: не прочитался — ${escapeHtml(catalogError ?? 'ошибка')}',
        ));
      }
    }
    if (funnelAttempted) {
      rows.add((
        'Воронка',
        funnelOk
            ? 'лист ВОРОНКА: цифры перезаписаны'
            : 'лист ВОРОНКА: не обновился — ${escapeHtml(funnelError ?? 'ошибка')}',
      ));
    }
    return '${richH2('Таблица')}${rows.isEmpty ? '' : richTable(rows)}';
  }

  String adminPaymentGatewayDownRich({
    required int userId,
    required String provider,
    required PaymentKind kind,
    String? reason,
    String? username,
    String? firstName,
  }) {
    final reasonText = reason?.trim();
    return '${richH2('Ошибка онлайн-оплаты')}'
        '${richP('Не получилось открыть ссылку на кассу.')}'
        '${richTable(<(String, String)>[('Кто', _adminWhoLine(userId: userId, username: username, firstName: firstName).replaceFirst('Кто: ', '')), ('Способ', _payKindLabel(kind)), ('Провайдер', '<code>${escapeHtml(provider)}</code>'), if (reasonText != null && reasonText.isNotEmpty) ('Причина', escapeHtml(reasonText))])}'
        '${richP('Человеку показан запасной путь через администратора. Можно отметить оплату вручную из карточки.')}';
  }
}
