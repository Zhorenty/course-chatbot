part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplatesAdminCatalog on MessageTemplates {
  String adminCatalogOpened() {
    return '<b>Управление курсами</b>\n\n'
        'Список ниже. «${MessageTemplates.buttonAdminBroadcastCancel}» — выход в админку.';
  }

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
      ..writeln('цена: ${formatRubFromKopecks(launch.priceFullKopecks)}');
    if (launch.depositKopecks > 0) {
      buf.writeln('предоплата: ${formatRubFromKopecks(launch.depositKopecks)}');
      final due = _formatDate(launch.depositDueAt);
      if (due != null) {
        buf.writeln('доплата до: $due');
      }
    } else {
      buf.writeln('предоплата: нет');
    }
    buf.writeln('старт: ${_formatDate(launch.courseStartAt) ?? 'не указан'}');
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
    return 'Полная цена в рублях. Число, как 18000 или 18 000.';
  }

  String adminCatalogAskDeposit() {
    return 'Предоплата в рублях. Пусто или 0 — сразу полная оплата.';
  }

  String adminCatalogAskDepositDue() {
    return 'Дата доплаты, как 19.08.2026.';
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
      ..writeln('цена: ${formatRubFromKopecks(draft.priceFullKopecks)}');
    if (draft.depositKopecks > 0) {
      buf.writeln('предоплата: ${formatRubFromKopecks(draft.depositKopecks)}');
      final due = _formatDate(draft.depositDueAt);
      if (due != null) {
        buf.writeln('доплата до: $due');
      }
    } else {
      buf.writeln('предоплата: нет');
    }
    buf.writeln('старт: ${_formatDate(draft.courseStartAt) ?? 'не указан'}');
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
      CatalogLaunchField.price => 'Новая полная цена в рублях. Число, как 18000 или 18 000.',
      CatalogLaunchField.deposit => 'Новая предоплата в рублях. Пусто или 0 — без предоплаты.',
      CatalogLaunchField.depositDue => 'Новая дата доплаты, как 19.08.2026.',
      CatalogLaunchField.start => 'Новая дата старта, как 19.08.2026.',
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
      CatalogFieldError.needDueDate => 'Для предоплаты нужна дата доплаты, как 19.08.2026.',
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
    CatalogLaunchField.deposit => '💵 Предоплата',
    CatalogLaunchField.depositDue => '📅 Доплата до',
    CatalogLaunchField.start => '🚀 Старт',
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
