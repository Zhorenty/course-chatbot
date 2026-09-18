part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplatesRich on MessageTemplates {
  String startGuideOfferRich() {
    return richParagraphsFromTelegramHtml(startGuideOffer());
  }

  String guideReadyRich() {
    return '${richH2('Гайд «${MessageTemplates.guideTitle}»')}'
        '${richDocument(mediaId: MessageTemplates.guideDocumentMediaId)}';
  }

  String startCourseCardRich({Launch? launch, String? cta}) {
    return richParagraphsFromTelegramHtml(_preSalesCourseCopy(launch, cta: cta));
  }

  String alreadyInFunnelRich() {
    return '${richH2('Продолжаем с того же места')}'
        '${richP('В меню внизу: гайд, курс и помощь.')}';
  }

  String helpRich() {
    return '${richH2('Помощь')}'
        '${richP('Если что-то сломалось или не пришло, напиши сюда: перешлю человеку на связи.')}';
  }

  String courseStatusRich({
    Launch? launch,
    CourseOrder? order,
    ChannelAccess? access,
    required DateTime now,
  }) {
    final next = _courseStatusNextStep(order: order, access: access);
    return '${richH2('Курс ${_quotedCourseTitle(launch, escape: false)}')}'
        '${richTable(<(String, String)>[('Оплата', _coursePaymentLine(order)), ('Старт', _courseStartLine(launch, now)), ('Канал', _courseChannelLine(order: order, access: access).split('\n').first)])}'
        '${next == null ? '' : richP(next)}';
  }

  String enrollOptionsRich(
    Launch launch, {
    required SalesQuote quote,
    bool rsvpOpen = true,
    bool webinarStarted = false,
    bool hasOpenCheckout = false,
  }) {
    if (quote.phase == SalesPhase.preSales) {
      return startCourseCardRich(
        launch: launch,
        cta: _preSalesMasterClassCta(
          launch: launch,
          rsvp: quote.rsvp,
          rsvpOpen: rsvpOpen,
          webinarStarted: webinarStarted,
        ),
      );
    }
    return richParagraphsFromTelegramHtml(
      enrollOptions(
        launch,
        quote: quote,
        rsvpOpen: rsvpOpen,
        webinarStarted: webinarStarted,
        hasOpenCheckout: hasOpenCheckout,
      ),
    );
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

  String adminCatalogCardRich(Launch launch, {int dozhimCount = 0}) {
    final webinarUrl = launch.webinarUrl?.trim();
    final channel = launch.channelId;
    return '${richH2(launch.title)}'
        '${richTable(<(String, String)>[('код', '<code>${escapeHtml(launch.code)}</code>'), ('цена', formatRubFromKopecks(launch.priceFullKopecks)), ('спеццена', formatRubFromKopecks(launch.pricePromoKopecks)), ('предоплата', launch.depositKopecks > 0 ? formatRubFromKopecks(launch.depositKopecks) : 'нет'), ('старт', _formatDate(launch.courseStartAt) ?? ''), ('эфир', _formatDateTime(launch.webinarAt) ?? ''), ('ссылка эфира', webinarUrl == null || webinarUrl.isEmpty ? 'нет' : 'есть'), ('старт продаж', _formatDateTime(launch.salesStartAt) ?? ''), ('конец продаж', _formatDate(launch.salesEndAt) ?? ''), ('канал', '<code>$channel</code>'), ('гайд', _catalogHasGuide(launch) ? 'есть' : 'нет'), ('описание', launch.hasCustomDescription ? 'своё' : 'шаблон'), ('дожим', dozhimCount <= 0 ? 'нет' : '$dozhimCount ${_dayWord(dozhimCount)}'), ('активен', launch.isActive ? 'да' : 'нет')])}';
  }

  String adminCatalogDozhimListRich(Launch launch, List<LaunchDozhimMessage> messages) {
    final items = messages.isEmpty
        ? <String>[
            'Пока пусто. Добавь день — текст, фото, альбом или файл.',
            'Без своих сообщений уйдёт встроенный дожим.',
          ]
        : <String>[
            'Свои сообщения заменяют встроенный дожим. День 1 — через сутки после обычной цены.',
            for (final message in messages) escapeHtml(_catalogDozhimListLine(message)),
          ];
    return '${richH2('Дожим')}'
        '${richP(escapeHtml(launch.title))}'
        '${richUl(items)}'
        '${richFooter('Сохраняем копию у бота. Исходное сообщение в этом чате можно удалить.')}';
  }

  String adminCatalogDozhimItemRich(LaunchDozhimMessage message) {
    final kind = broadcastContentKindLabel(message.contentKind);
    final preview = message.previewText?.trim();
    return '${richH2('Дожим · день ${message.dayIndex}')}'
        '${richP('содержимое: $kind')}'
        '${preview == null || preview.isEmpty ? '' : richQuote(escapeHtml(_clipBroadcastPreview(preview)))}';
  }

  String adminPeopleHubRich({Launch? launch, required Map<ParticipantListSegment, int> counts}) {
    if (launch == null) {
      return '${richH2('Список участников')}'
          '${richP('Нет активного потока. Сначала заведи курс в «${escapeHtml(MessageTemplates.buttonAdminSheetsHub)}».')}';
    }
    final items = <String>[
      for (final segment in ParticipantListSegment.values)
        '${escapeHtml(participantListLabel(segment))} — ${counts[segment] ?? 0}',
    ];
    return '${richH2('Список участников')}'
        '${richP('Поток: ${escapeHtml(launch.title)}')}'
        '${richP('Нажми группу — открою имена. Из списка можно открыть карточку.')}'
        '${richUl(items)}';
  }

  String adminPeopleListRich({
    required ParticipantListSegment segment,
    required List<UserProfile> people,
    required int total,
    required int page,
    Launch? launch,
  }) {
    final title = participantListLabel(segment);
    final launchLine = launch == null ? '' : richP('Поток: ${escapeHtml(launch.title)}');
    if (people.isEmpty) {
      return '${richH2(title)}'
          '$launchLine'
          '${richP(escapeHtml(_adminPeopleCountLine(total)))}'
          '${richP('Пока никого.')}';
    }
    final items = <String>[for (final user in people) _adminPeopleLine(user)];
    final from = page * MessageTemplates.adminPeoplePageSize + 1;
    final to = from + people.length - 1;
    final range = total > MessageTemplates.adminPeoplePageSize
        ? richP('Показаны $from–$to из $total.')
        : '';
    return '${richH2(title)}'
        '$launchLine'
        '${richP(escapeHtml(_adminPeopleCountLine(total)))}'
        '${richUl(items)}'
        '$range';
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
        'Письма ученика — лист ${escapeHtml(CopySheet.tabTitle)}, бот выгружает его один раз. '
        '«${escapeHtml(MessageTemplates.buttonAdminSheets)}» — перечитать таблицу и пересобрать воронку.')}';
  }

  String adminSheetsHubOpenedRich() {
    return '${richH2('Google Sheets')}'
        '${richP('Курсы, диплинки, тексты и срез воронки. «${escapeHtml(MessageTemplates.buttonAdminBack)}» — выход в админку.')}';
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

  String adminGuideIssuedRich({required UserProfile user, Launch? launch}) {
    return '${richH2('Получил гайд')}'
        '${richTable(_adminFunnelAlertRows(user: user, launch: launch, extra: <(String, String)>[('источник', _adminSourceValue(user.source))]))}';
  }

  String adminWebinarRsvpRich({required UserProfile user, required Launch launch}) {
    final when = _formatDateTime(launch.webinarAt)!;
    return '${richH2('Записался на эфир')}'
        '${richTable(_adminFunnelAlertRows(user: user, launch: launch, extra: <(String, String)>[('эфир', when)]))}';
  }

  String adminPaidWithInviteRich({
    required UserProfile user,
    required CourseOrder order,
    Launch? launch,
  }) {
    return '${richH2('Оплатил — ссылка в канал выдана')}'
        '${richTable(_adminFunnelAlertRows(user: user, launch: launch, extra: <(String, String)>[('заказ', '#${order.id} · ${_adminPaymentKindLabel(order.kind)}'), ('сумма', '${formatRubFromKopecks(order.amountPaidKopecks)} из ${formatRubFromKopecks(order.priceFullKopecks)}')]))}';
  }

  List<(String, String)> _adminFunnelAlertRows({
    required UserProfile user,
    Launch? launch,
    List<(String, String)> extra = const <(String, String)>[],
  }) {
    return <(String, String)>[
      ('Кто', _adminWhoLineFor(user).replaceFirst('Кто: ', '')),
      ('поток', _adminLaunchValue(launch)),
      ...extra,
    ];
  }

  String _adminLaunchValue(Launch? launch) {
    final title = launch?.title.trim();
    if (title == null || title.isEmpty) {
      return 'не выбран';
    }
    return escapeHtml(title);
  }

  String _adminSourceValue(String? source) {
    final raw = source?.trim();
    if (raw == null || raw.isEmpty) {
      return 'без метки';
    }
    final label = _adminSourceLabel(raw);
    if (label == raw) {
      return '<code>${escapeHtml(raw)}</code>';
    }
    return '$label · <code>${escapeHtml(raw)}</code>';
  }
}
