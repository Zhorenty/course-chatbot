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

  String adminCatalogAskProductCode(String suggested) {
    return _catalogWizardStep(
      1,
      'Код продукта',
      'Служебный код продукта в таблице. Только латиница, цифры, _ и -.\n\n'
          'Предлагаю <code>${escapeHtml(suggested)}</code>. Кнопка ниже оставит его, или пришли другой.',
    );
  }

  String adminCatalogAskProductTitle(String suggested) {
    return _catalogWizardStep(
      2,
      'Продукт',
      'Как называется продукт. Это не название потока.\n\n'
          'Предлагаю <code>${escapeHtml(suggested)}</code>. Кнопка ниже оставит его, или пришли другой.',
    );
  }

  String adminCatalogAskTitle() {
    return _catalogWizardStep(
      3,
      'Название',
      'Как поток назовут в боте.',
      example: 'Колористика · октябрь',
    );
  }

  String adminCatalogAskCode(String suggested) {
    return _catalogWizardStep(
      4,
      'Код запуска',
      'Служебный id потока в таблице и диплинках, не название для учеников. '
          'Только латиница, цифры, _ и - — не на русском. Без кода строка в бота не попадёт.\n\n'
          'Предлагаю <code>${escapeHtml(suggested)}</code>. Кнопка ниже оставит его, или пришли другой.',
    );
  }

  String adminCatalogAskPrice() {
    return _catalogWizardStep(5, 'Цена', 'Обычная цена в рублях.', example: '19000');
  }

  String adminCatalogAskPromo() {
    return _catalogWizardStep(
      6,
      'Спеццена',
      'Спеццена эфира в рублях.',
      example: '15000',
      skipHint: '«Пропустить» — спеццена по умолчанию.',
    );
  }

  String adminCatalogAskWebinar() {
    return _catalogWizardStep(
      9,
      'Эфир',
      'Дата и время эфира по Москве.',
      example: '05.10.2026 19:00',
      skipHint: '«Пропустить» — заполнить позже.',
    );
  }

  String adminCatalogAskWebinarUrl() {
    return _catalogWizardStep(
      10,
      'Ссылка на эфир',
      'URL эфира.',
      example: 'https://',
      skipHint: '«Пропустить» — без ссылки, можно дописать позже.',
    );
  }

  String adminCatalogAskSalesStart() {
    return _catalogWizardStep(
      11,
      'Старт продаж',
      'Когда открывается касса и продающий прогрев. Дата и время по Москве. '
          'Без эфира и без этой даты продажи закрыты.',
      example: '05.10.2026 19:00',
      skipHint: '«Пропустить» — как дата эфира.',
    );
  }

  String adminCatalogAskSalesEnd() {
    return _catalogWizardStep(
      12,
      'Конец продаж',
      'Последний день продаж.',
      example: '11.10.2026',
      skipHint: '«Пропустить» — не закрывать по календарю.',
    );
  }

  String adminCatalogAskDeposit() {
    return _catalogWizardStep(
      7,
      'Предоплата',
      'Предоплата в рублях. Срок доплаты бот поставит сам: за неделю до старта курса.',
      example: '5000',
      skipHint: '«Пропустить» или 0 — сразу полная оплата.',
    );
  }

  String adminCatalogAskStart() {
    return _catalogWizardStep(8, 'Старт курса', 'Дата старта курса.', example: '19.08.2026');
  }

  String adminCatalogAskChannel() {
    return _catalogWizardStep(
      13,
      'Канал',
      'ID канала этого потока (число вида −100…).',
      skipHint:
          '«${MessageTemplates.buttonAdminCatalogSkipChannel}» — возьмётся запасной при синке.',
    );
  }

  String adminCatalogAskGuide() {
    return _catalogWizardStep(
      14,
      'Гайд',
      'Пришли PDF гайда этого потока в чат.',
      skipHint: '«Пропустить» — без файла, можно прикрепить позже в карточке курса.',
    );
  }

  String adminCatalogAskActive() {
    return _catalogWizardStep(
      15,
      'Активный поток',
      'Сделать этот поток активным? «Да» снимет метку с остальных.',
    );
  }

  String _catalogWizardStep(
    int step,
    String title,
    String body, {
    String? example,
    String? skipHint,
  }) {
    const total = 15;
    final buf = StringBuffer()
      ..writeln('<b>Шаг $step из $total · $title</b>')
      ..writeln()
      ..write(body);
    if (example != null) {
      buf
        ..writeln()
        ..writeln()
        ..write('Пример: <code>${escapeHtml(example)}</code>');
    }
    if (skipHint != null) {
      buf
        ..writeln()
        ..writeln()
        ..write(skipHint);
    }
    return buf.toString();
  }

  String adminCatalogPreview(CatalogLaunchDraft draft) {
    final buf = StringBuffer()
      ..writeln('<b>Проверь</b>')
      ..writeln()
      ..writeln('код продукта: <code>${escapeHtml(draft.productCode)}</code>')
      ..writeln('продукт: ${escapeHtml(draft.productTitle)}')
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
    final guideId = draft.leadMagnetFileId?.trim();
    buf.writeln(guideId == null || guideId.isEmpty ? 'гайд: нет' : 'гайд: есть');
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
            'Сбросить свой канал — кнопка «${MessageTemplates.buttonAdminCatalogSkipChannel}».',
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
