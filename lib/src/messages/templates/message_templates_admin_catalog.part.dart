part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplatesAdminCatalog on MessageTemplates {
  String adminCatalogList(List<Launch> launches, {String? notice}) {
    final buf = StringBuffer();
    if (notice != null && notice.isNotEmpty) {
      buf.writeln(notice);
      buf.writeln();
    }
    buf
      ..writeln('<b>Курсы</b>')
      ..writeln();
    if (launches.isEmpty) {
      buf.writeln('В таблице пока нет потоков. Добавь новый.');
    } else {
      for (final launch in launches) {
        buf.writeln(_catalogListLine(launch));
      }
    }
    buf
      ..writeln()
      ..write('Открой карточку или создай курс.');
    return buf.toString();
  }

  String _catalogListLine(Launch launch) {
    final title = escapeHtml(launch.title);
    final code = escapeHtml(launch.code);
    final price = formatRubFromKopecks(launch.priceFullKopecks);
    final start = _formatDate(launch.courseStartAt) ?? 'без даты старта';
    final active = launch.isActive ? ' · активен' : '';
    return '$title ($code) · $price · $start$active';
  }

  String adminCatalogCard(Launch launch) {
    final buf = StringBuffer()
      ..writeln('<b>${escapeHtml(launch.title)}</b>')
      ..writeln()
      ..writeln('код: <code>${escapeHtml(launch.code)}</code>')
      ..writeln('цена: ${formatRubFromKopecks(launch.priceFullKopecks)}')
      ..writeln('спеццена: ${formatRubFromKopecks(launch.resolvedPricePromoKopecks)}');
    if (launch.depositKopecks > 0) {
      buf.writeln('предоплата: ${formatRubFromKopecks(launch.depositKopecks)}');
      final due = _formatDate(launch.depositDueAt ?? launch.impliedDepositDueAt);
      if (due != null) {
        buf.writeln('доплата до: $due');
      }
    } else {
      buf.writeln('предоплата: нет');
    }
    buf.writeln('старт: ${_formatDate(launch.courseStartAt) ?? 'не указан'}');
    buf.writeln('эфир: ${_formatDateTime(launch.webinarAt) ?? 'не указан'}');
    final webinarUrl = launch.webinarUrl?.trim();
    buf.writeln(
      webinarUrl == null || webinarUrl.isEmpty ? 'ссылка эфира: нет' : 'ссылка эфира: есть',
    );
    buf.writeln('старт продаж: ${_formatDateTime(launch.salesStartAt) ?? 'как дата эфира'}');
    buf.writeln('конец продаж: ${_formatDate(launch.salesEndAt) ?? 'не указан'}');
    final channel = launch.channelId;
    buf.writeln(channel == null ? 'канал: не указан' : 'канал: <code>$channel</code>');
    buf.writeln(_catalogGuideLine(launch));
    buf.write(launch.isActive ? 'активен: да' : 'активен: нет');
    return buf.toString();
  }

  String adminCatalogAskTitle() {
    return '<b>Новый курс</b>\n\nНазвание запуска — как увидят в боте.';
  }

  String adminCatalogAskCode(String suggested) {
    return '<b>Код запуска</b>\n\n'
        'Это служебный id потока в таблице и диплинках, не название для учеников. '
        'Только латиница, цифры, _ и - — <b>не на русском</b>. '
        'Без кода строка в бота не попадёт.\n\n'
        'Предлагаю <code>${escapeHtml(suggested)}</code>. '
        'Кнопка ниже оставит его, или пришли другой.';
  }

  String adminCatalogAskPrice() {
    return 'Обычная цена в рублях. Число, как 19000 или 19 000.';
  }

  String adminCatalogAskPromo() {
    return 'Спеццена эфира в рублях. Число, как 15000. Пусто или «-» — 15000.';
  }

  String adminCatalogAskWebinar() {
    return 'Дата и время эфира по Москве, как 05.10.2026 19:00. '
        'Пусто или «-» — заполнить позже.';
  }

  String adminCatalogAskWebinarUrl() {
    return 'Ссылка на эфир. Пусто или «-» — без ссылки, можно дописать позже.';
  }

  String adminCatalogAskSalesStart() {
    return 'Когда открывается касса и продающий прогрев. Дата и время по Москве, '
        'как 05.10.2026 19:00. Пусто или «-» — как дата эфира. '
        'Без эфира и без этой даты продажи закрыты.';
  }

  String adminCatalogAskSalesEnd() {
    return 'Последний день продаж, как 11.10.2026. Пусто или «-» — не закрывать по календарю.';
  }

  String adminCatalogAskDeposit() {
    return 'Предоплата в рублях. Пусто или 0 — сразу полная оплата. '
        'Срок доплаты бот поставит сам: за неделю до старта курса.';
  }

  String adminCatalogAskStart() {
    return 'Дата старта курса, как 19.08.2026.';
  }

  String adminCatalogAskChannel() {
    return 'ID канала этого потока (число вида −100…).\n\n'
        'Своего канала нет — кнопка «${MessageTemplates.buttonAdminCatalogSkipChannel}» '
        'или напиши «-». При синке возьмётся запасной.';
  }

  String adminCatalogAskActive() {
    return 'Сделать этот поток активным? «Да» снимет метку с остальных.';
  }

  String adminCatalogPreview(CatalogLaunchDraft draft) {
    final buf = StringBuffer()
      ..writeln('<b>Проверь</b>')
      ..writeln()
      ..writeln('название: ${escapeHtml(draft.launchTitle)}')
      ..writeln('код: <code>${escapeHtml(draft.launchCode)}</code>')
      ..writeln('цена: ${formatRubFromKopecks(draft.priceFullKopecks)}')
      ..writeln(
        'спеццена: ${formatRubFromKopecks(draft.pricePromoKopecks > 0 ? draft.pricePromoKopecks : LaunchPrices.promoKopecks)}',
      );
    if (draft.depositKopecks > 0) {
      buf.writeln('предоплата: ${formatRubFromKopecks(draft.depositKopecks)}');
      final due = _formatDate(
        draft.depositDueAt ??
            MoscowTime.daysBeforeCourseStart(draft.courseStartAt, days: draft.depositDueDays),
      );
      if (due != null) {
        buf.writeln('доплата до: $due');
      }
    } else {
      buf.writeln('предоплата: нет');
    }
    buf.writeln('старт: ${_formatDate(draft.courseStartAt) ?? 'не указан'}');
    buf.writeln('эфир: ${_formatDateTime(draft.webinarAt) ?? 'не указан'}');
    final previewUrl = draft.webinarUrl?.trim();
    buf.writeln(
      previewUrl == null || previewUrl.isEmpty ? 'ссылка эфира: нет' : 'ссылка эфира: есть',
    );
    buf.writeln('старт продаж: ${_formatDateTime(draft.salesStartAt) ?? 'как дата эфира'}');
    buf.writeln('конец продаж: ${_formatDate(draft.salesEndAt) ?? 'не указан'}');
    final channel = draft.channelId;
    buf.writeln(channel == null ? 'канал: не указан' : 'канал: <code>$channel</code>');
    buf
      ..writeln(draft.isActive ? 'активен: да' : 'активен: нет')
      ..writeln()
      ..write('Запишу строку в COURSES и обновлю бота.');
    return buf.toString();
  }

  String adminCatalogSaved(Launch launch) {
    final buf = StringBuffer()
      ..writeln('<b>Записано</b>')
      ..writeln()
      ..writeln('поток: ${escapeHtml(launch.title)}')
      ..writeln('код: <code>${escapeHtml(launch.code)}</code>')
      ..write('цена: ${formatRubFromKopecks(launch.priceFullKopecks)}');
    if (launch.isActive) {
      buf.write('\nэто текущий набор');
    }
    return buf.toString();
  }

  String adminCatalogDeleted(String title, String code) {
    return '<b>Удалено</b>\n\n'
        '${escapeHtml(title)} (<code>${escapeHtml(code)}</code>) убрал из COURSES.';
  }

  String adminCatalogAskField(CatalogLaunchField field) {
    return switch (field) {
      CatalogLaunchField.title => 'Новое название запуска.',
      CatalogLaunchField.code =>
        'Новый код запуска: латиница, цифры, _ и -.\n\n'
            'Если сменишь код, диплинки на листе ССЫЛКИ с этим кодом поправь руками.',
      CatalogLaunchField.price => 'Новая обычная цена в рублях. Число, как 19000.',
      CatalogLaunchField.promo => 'Спеццена эфира в рублях. Число, как 15000. Пусто — 15000.',
      CatalogLaunchField.deposit => 'Новая предоплата в рублях. Пусто или 0 — без предоплаты.',
      CatalogLaunchField.start => 'Новая дата старта, как 19.08.2026.',
      CatalogLaunchField.webinar =>
        'Дата и время эфира по Москве, как 05.10.2026 19:00. Пусто или «-» — сбросить.',
      CatalogLaunchField.webinarUrl => 'Ссылка на эфир. Пусто — убрать ссылку.',
      CatalogLaunchField.salesStart =>
        'Когда открывается касса. Дата и время по Москве, как 05.10.2026 19:00. '
            'Пусто или «-» — как дата эфира.',
      CatalogLaunchField.salesEnd =>
        'Последний день продаж, как 11.10.2026. Пусто или «-» — не закрывать по календарю.',
      CatalogLaunchField.channel =>
        'Новый ID канала (число вида −100…).\n\n'
            'Сбросить свой канал — кнопка «${MessageTemplates.buttonAdminCatalogSkipChannel}» '
            'или напиши «-».',
      CatalogLaunchField.guide => 'Пришли PDF гайда в этот чат. Старый файл этого потока заменю.',
    };
  }

  String adminCatalogPickField() {
    return 'Какое поле меняем?';
  }

  String adminCatalogConfirmDelete(Launch launch) {
    return 'Удалить «${escapeHtml(launch.title)}» (<code>${escapeHtml(launch.code)}</code>) из COURSES?';
  }

  String adminCatalogFieldError(CatalogFieldError error) {
    return switch (error) {
      CatalogFieldError.emptyTitle => 'Название пустое. Пришли, как поток назовут в боте.',
      CatalogFieldError.badCode =>
        'Код не подойдёт. Латиница, цифры, _ и - — не кириллица, без пробелов, до 64 символов.',
      CatalogFieldError.codeTaken => 'Такой код уже есть. Пришли другой.',
      CatalogFieldError.badPrice => 'Это не цена. Пришли число, как 18000 или 18 000.',
      CatalogFieldError.badDeposit =>
        'Предоплата — число меньше полной цены. Пусто или 0, если предоплаты нет.',
      CatalogFieldError.badDate => 'Дата не разобралась. Формат 19.08.2026.',
      CatalogFieldError.badChannel =>
        'ID канала — отрицательное число вида −100…. '
            'Или «-» / «${MessageTemplates.buttonAdminCatalogSkipChannel}», чтобы без своего канала.',
      CatalogFieldError.needGuideFile => 'Нужен файл. Пришли PDF гайда, не текст.',
    };
  }

  String adminCatalogFailure(CatalogAdminFailure failure, {String? detail}) {
    return switch (failure) {
      CatalogAdminFailure.sheetsUnavailable => adminSheetsDisabled(),
      CatalogAdminFailure.lastLaunch => 'Это единственный поток в таблице. Сначала добавь другой.',
      CatalogAdminFailure.lastLink => 'Это единственная метка на листе. Сначала добавь другую.',
      CatalogAdminFailure.activeLaunch =>
        'Сначала сделай активным другой поток — текущий без замены не удаляю.',
      CatalogAdminFailure.hasPeople =>
        'Есть ученики или оплаты. Сначала разбери карточки — из таблицы не удаляю.',
      CatalogAdminFailure.codeTaken => 'Такой код уже есть.',
      CatalogAdminFailure.notFound => 'Этот поток в таблице не нашёл.',
      CatalogAdminFailure.writeFailed =>
        'Не получилось записать в таблицу${detail == null || detail.isEmpty ? '.' : ': ${escapeHtml(detail)}'}',
    };
  }

  String adminCatalogWriting() {
    return 'Пишу строку в COURSES и обновляю бота. Подожди несколько секунд.';
  }

  String adminCatalogRefreshing() {
    return 'Читаю COURSES. Подожди несколько секунд.';
  }

  String adminCatalogRefreshFailed(String? detail) {
    return 'Не получилось прочитать COURSES'
        '${detail == null || detail.isEmpty ? '.' : ': ${escapeHtml(detail)}'}';
  }

  String adminCatalogAskWithError(CatalogFieldError error, String ask) {
    return '${adminCatalogFieldError(error)}\n\n$ask';
  }

  String adminCatalogFieldLabel(CatalogLaunchField field) => switch (field) {
    CatalogLaunchField.title => '📝 Название',
    CatalogLaunchField.code => '🔖 Код',
    CatalogLaunchField.price => '💰 Цена',
    CatalogLaunchField.promo => '🎁 Спеццена',
    CatalogLaunchField.deposit => '💵 Предоплата',
    CatalogLaunchField.start => '🚀 Старт',
    CatalogLaunchField.webinar => '📺 Эфир',
    CatalogLaunchField.webinarUrl => '🔗 Ссылка эфира',
    CatalogLaunchField.salesStart => '🛒 Старт продаж',
    CatalogLaunchField.salesEnd => '🚪 Конец продаж',
    CatalogLaunchField.channel => '📣 Канал',
    CatalogLaunchField.guide => '📘 Гайд',
  };

  String adminCatalogGuideButton(Launch launch) {
    return _catalogHasGuide(launch)
        ? MessageTemplates.buttonAdminCatalogReplaceGuide
        : MessageTemplates.buttonAdminCatalogAttachGuide;
  }

  String _catalogGuideLine(Launch launch) {
    return _catalogHasGuide(launch) ? 'гайд: есть' : 'гайд: нет';
  }

  bool _catalogHasGuide(Launch launch) {
    final fileId = launch.leadMagnetFileId?.trim();
    return fileId != null && fileId.isNotEmpty;
  }

  String adminCatalogListButton(Launch launch) {
    final mark = launch.isActive ? '🟢 ' : '⚪️ ';
    final label = '$mark${launch.title} (${launch.code})';
    if (label.length <= 64) {
      return label;
    }
    return '${label.substring(0, 63)}…';
  }
}
