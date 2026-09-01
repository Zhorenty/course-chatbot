part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplatesAdminLinks on MessageTemplates {
  String adminSheetsHubOpened() {
    return '<b>Google Sheets</b>\n\n'
        'Курсы, диплинки и срез воронки. «${MessageTemplates.buttonAdminBack}» — выход в админку.';
  }

  String adminSheetsHub() {
    return '<b>Google Sheets</b>\n\n'
        '«${MessageTemplates.buttonAdminCatalog}» — потоки на листе ${escapeHtml(CoursesSheet.tabTitle)}. '
        '«${MessageTemplates.buttonAdminLinks}» — метки на листе ${escapeHtml(LinksSheet.tabTitle)}. '
        '«${MessageTemplates.buttonAdminSheets}» — перечитать таблицу и пересобрать воронку.';
  }

  String adminLinksList(List<AcquisitionLink> links, {String? notice}) {
    final buf = StringBuffer();
    if (notice != null && notice.isNotEmpty) {
      buf.writeln(notice);
      buf.writeln();
    }
    buf
      ..writeln('<b>Диплинки</b>')
      ..writeln();
    if (links.isEmpty) {
      buf.writeln('На листе пока нет меток. Добавь новую.');
    } else {
      for (final link in links) {
        buf.writeln(_linksListLine(link));
      }
    }
    buf
      ..writeln()
      ..write('Открой карточку или создай диплинк.');
    return buf.toString();
  }

  String _linksListLine(AcquisitionLink link) {
    final origin = escapeHtml(link.origin);
    final dest = escapeHtml(link.destinationLabel);
    final payload = escapeHtml(link.payload);
    final launch = link.launchCode?.trim();
    final launchSuffix = launch == null || launch.isEmpty ? '' : ' · ${escapeHtml(launch)}';
    return '$origin → $dest$launchSuffix · <code>$payload</code>';
  }

  String adminLinksCard(AcquisitionLink link) {
    final buf = StringBuffer()
      ..writeln('<b>${escapeHtml(link.origin)}</b>')
      ..writeln()
      ..writeln('куда: ${escapeHtml(link.destinationLabel)}')
      ..writeln('метка: <code>${escapeHtml(link.payload)}</code>');
    final launch = link.launchCode?.trim();
    buf.writeln(
      launch == null || launch.isEmpty ? 'поток: текущий набор' : 'поток: ${escapeHtml(launch)}',
    );
    final bot = _botUsername?.trim() ?? '';
    if (bot.isEmpty) {
      buf.write('ссылка: username бота неизвестен — t.me не собрался');
    } else {
      buf.write('ссылка:\n<code>${escapeHtml(deepLink(link.payload))}</code>');
    }
    return buf.toString();
  }

  String adminLinksAskOrigin() {
    return '<b>Новый диплинк</b>\n\nОткуда человек пришёл. Пример: Instagram Reels.';
  }

  String adminLinksAskDestination() {
    return 'Что открыть при первом /start: гайд или карточку курса.';
  }

  String adminLinksAskPayload() {
    return 'Метка в ссылке t.me/бот?start=метка.\n\n'
        'Латиница, цифры и подчёркивание, до 64 символов. Без пробелов и кириллицы.';
  }

  String adminLinksAskLaunch() {
    return 'Поток для этой метки. Пусто или «${MessageTemplates.buttonAdminLinksSkipLaunch}» — '
        'текущий набор.';
  }

  String adminLinksPreview(AcquisitionLink link) {
    final buf = StringBuffer()
      ..writeln('<b>Проверь</b>')
      ..writeln()
      ..writeln('откуда: ${escapeHtml(link.origin)}')
      ..writeln('куда: ${escapeHtml(link.destinationLabel)}')
      ..writeln('метка: <code>${escapeHtml(link.payload)}</code>');
    final launch = link.launchCode?.trim();
    buf.writeln(
      launch == null || launch.isEmpty ? 'поток: текущий набор' : 'поток: ${escapeHtml(launch)}',
    );
    buf
      ..writeln()
      ..write('Запишу строку в ${escapeHtml(LinksSheet.tabTitle)} и обновлю бота.');
    return buf.toString();
  }

  String adminLinksDeleted(String origin, String payload) {
    return '<b>Удалено</b>\n\n'
        '${escapeHtml(origin)} (<code>${escapeHtml(payload)}</code>) убрал из ${escapeHtml(LinksSheet.tabTitle)}.';
  }

  String adminLinksAskField(CatalogLinkField field) {
    return switch (field) {
      CatalogLinkField.origin => 'Новое «откуда». Пример: Instagram Reels.',
      CatalogLinkField.destination => 'Что открыть при первом /start: гайд или карточку курса.',
      CatalogLinkField.payload => 'Новая метка: латиница, цифры и подчёркивание, до 64 символов.',
      CatalogLinkField.launch =>
        'Новый поток. «${MessageTemplates.buttonAdminLinksSkipLaunch}» — текущий набор.',
    };
  }

  String adminLinksPickField() {
    return 'Какое поле меняем?';
  }

  String adminLinksConfirmDelete(AcquisitionLink link) {
    return 'Удалить «${escapeHtml(link.origin)}» (<code>${escapeHtml(link.payload)}</code>) '
        'из ${escapeHtml(LinksSheet.tabTitle)}?';
  }

  String adminLinksFieldError(CatalogLinkFieldError error) {
    return switch (error) {
      CatalogLinkFieldError.emptyOrigin => 'Откуда пусто. Пришли источник, как Instagram Reels.',
      CatalogLinkFieldError.badPayload =>
        'Метка не подойдёт. Латиница, цифры и _ — не кириллица, без пробелов, до 64 символов.',
      CatalogLinkFieldError.payloadTaken => 'Такая метка уже есть. Пришли другую.',
      CatalogLinkFieldError.badLaunch =>
        'Такого потока нет. Выбери из списка или «${MessageTemplates.buttonAdminLinksSkipLaunch}».',
    };
  }

  String adminLinksFailure(CatalogAdminFailure failure, {String? detail}) {
    return switch (failure) {
      CatalogAdminFailure.sheetsUnavailable => adminSheetsDisabled(),
      CatalogAdminFailure.lastLink => 'Это единственная метка на листе. Сначала добавь другую.',
      CatalogAdminFailure.lastLaunch ||
      CatalogAdminFailure.activeLaunch ||
      CatalogAdminFailure.hasPeople ||
      CatalogAdminFailure.codeTaken => adminCatalogFailure(failure, detail: detail),
      CatalogAdminFailure.notFound => 'Эту метку на листе не нашёл.',
      CatalogAdminFailure.writeFailed =>
        'Не получилось записать в таблицу${detail == null || detail.isEmpty ? '.' : ': ${escapeHtml(detail)}'}',
    };
  }

  String adminLinksWriting() {
    return 'Пишу строку в ${escapeHtml(LinksSheet.tabTitle)} и обновляю бота. Подожди несколько секунд.';
  }

  String adminLinksRefreshing() {
    return 'Читаю ${escapeHtml(LinksSheet.tabTitle)}. Подожди несколько секунд.';
  }

  String adminLinksRefreshFailed(String? detail) {
    return 'Не получилось прочитать ${escapeHtml(LinksSheet.tabTitle)}'
        '${detail == null || detail.isEmpty ? '.' : ': ${escapeHtml(detail)}'}';
  }

  String adminLinksAskWithError(CatalogLinkFieldError error, String ask) {
    return '${adminLinksFieldError(error)}\n\n$ask';
  }

  String adminLinksFieldLabel(CatalogLinkField field) => switch (field) {
    CatalogLinkField.origin => '📝 Откуда',
    CatalogLinkField.destination => '🎯 Куда',
    CatalogLinkField.payload => '🔖 Метка',
    CatalogLinkField.launch => '🚀 Поток',
  };

  String adminLinksListButton(AcquisitionLink link) {
    final label = '${link.origin} → ${link.destinationLabel}';
    if (label.length <= 64) {
      return label;
    }
    return '${label.substring(0, 63)}…';
  }

  String adminLinksLaunchButton(Launch launch) {
    final mark = launch.isActive ? '🟢 ' : '⚪️ ';
    final label = '$mark${launch.title}';
    if (label.length <= 64) {
      return label;
    }
    return '${label.substring(0, 63)}…';
  }
}
