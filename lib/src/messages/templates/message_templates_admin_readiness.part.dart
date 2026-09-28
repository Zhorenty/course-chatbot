part of 'package:course_chatbot/src/messages/message_templates.dart';

typedef _ReadinessRow = ({String label, String valueHtml});

typedef _ReadinessSection = ({String title, List<_ReadinessRow> rows});

extension MessageTemplatesAdminReadiness on MessageTemplates {
  String adminCourseReadinessEmpty({String? notice}) {
    final buf = StringBuffer();
    if (notice != null && notice.isNotEmpty) {
      buf
        ..writeln(notice)
        ..writeln();
    }
    buf
      ..writeln('<b>Готовность курса</b>')
      ..writeln()
      ..write('В таблице пока нет потоков.');
    return buf.toString();
  }

  String adminCourseReadinessEmptyRich({String? notice}) {
    return '${notice == null || notice.isEmpty ? '' : richP(notice)}'
        '${richH2('Готовность курса')}'
        '${richP('В таблице пока нет потоков.')}';
  }

  String adminCourseReadiness(Launch launch, {required int dozhimCount, String? notice}) {
    final buf = StringBuffer();
    if (notice != null && notice.isNotEmpty) {
      buf
        ..writeln(notice)
        ..writeln();
    }
    buf
      ..writeln('<b>Готовность · ${escapeHtml(launch.title)}</b>')
      ..writeln()
      ..writeln(_readinessSummary(launch, dozhimCount: dozhimCount));
    for (final section in _readinessSections(launch, dozhimCount: dozhimCount)) {
      buf
        ..writeln()
        ..writeln('<b>${escapeHtml(section.title)}</b>');
      for (final row in section.rows) {
        buf.writeln('${escapeHtml(row.label)}: ${row.valueHtml}');
      }
    }
    buf
      ..writeln()
      ..write(
        'Шаблон — письмо по умолчанию. Своё — задано в карточке курса. '
        'Ссылку на эфир можно дописать позже.',
      );
    return buf.toString().trimRight();
  }

  String adminCourseReadinessRich(Launch launch, {required int dozhimCount, String? notice}) {
    final buf = StringBuffer()
      ..write(notice == null || notice.isEmpty ? '' : richP(notice))
      ..write(richH2('Готовность · ${launch.title}'))
      ..write(richP(escapeHtml(_readinessSummary(launch, dozhimCount: dozhimCount))));
    for (final section in _readinessSections(launch, dozhimCount: dozhimCount)) {
      buf
        ..write(richH3(section.title))
        ..write(
          richTable(<(String, String)>[for (final row in section.rows) (row.label, row.valueHtml)]),
        );
    }
    buf.write(
      richFooter(
        'Шаблон — письмо по умолчанию. Своё — задано в карточке курса. '
        'Ссылку на эфир можно дописать позже.',
      ),
    );
    return buf.toString();
  }

  String _readinessSummary(Launch launch, {required int dozhimCount}) {
    final missing = _readinessMissing(launch);
    final letters = _readinessLetterLine(launch);
    final dozhim = _readinessDozhimValue(dozhimCount);
    final gaps = missing.isEmpty ? 'Пустых полей нет.' : 'Не указано: ${missing.join(', ')}.';
    final active = launch.isActive ? 'Текущий набор.' : 'Не активен.';
    return '$active $gaps $letters Дожим: $dozhim.';
  }

  List<String> _readinessMissing(Launch launch) {
    return <String>[
      if (!launch.hasWebinarUrl) 'ссылка на эфир',
      if (!_readinessHasGuide(launch)) 'гайд',
    ];
  }

  String _readinessLetterLine(Launch launch) {
    final slots = <LaunchCopySlotKey>[
      for (final slot in LaunchCopySlotKey.values)
        if (slot.storesInCopyTable) slot,
    ];
    final custom = slots.where((slot) => _readinessSlotCustom(launch, slot)).length;
    if (custom == 0) {
      return 'Письма: все шаблон.';
    }
    if (custom == slots.length) {
      return 'Письма: все свои.';
    }
    return 'Письма: свои $custom из ${slots.length}, остальные шаблон.';
  }

  List<_ReadinessSection> _readinessSections(Launch launch, {required int dozhimCount}) {
    return <_ReadinessSection>[
      (title: 'Параметры', rows: _readinessParamRows(launch)),
      for (final segment in LaunchCopySegment.values)
        if (segment != LaunchCopySegment.params && segment != LaunchCopySegment.dozhim)
          (
            title: _readinessSegmentTitle(segment),
            rows: <_ReadinessRow>[
              for (final slot in LaunchCopySlotKey.slotsOf(segment))
                if (slot != LaunchCopySlotKey.guideFile)
                  (
                    label: slot.adminLabel,
                    valueHtml: escapeHtml(_readinessSlotCustom(launch, slot) ? 'своё' : 'шаблон'),
                  ),
            ],
          ),
      (
        title: 'Дожим',
        rows: <_ReadinessRow>[
          (label: 'Сообщения', valueHtml: escapeHtml(_readinessDozhimValue(dozhimCount))),
        ],
      ),
    ];
  }

  List<_ReadinessRow> _readinessParamRows(Launch launch) {
    final due = _formatDate(launch.depositDueAt ?? launch.impliedDepositDueAt);
    final deposit = launch.depositKopecks > 0
        ? 'указано, ${formatRubFromKopecks(launch.depositKopecks)}'
              '${due == null ? '' : ' · доплата до $due'}'
        : 'нет, сразу полная оплата';
    final promoRaw = launch.promoCheckoutUrl?.trim();
    final promoCustom = promoRaw != null && promoRaw.isNotEmpty;
    return <_ReadinessRow>[
      (label: 'Название', valueHtml: escapeHtml(launch.title)),
      (label: 'Код', valueHtml: '<code>${escapeHtml(launch.code)}</code>'),
      (label: 'Активен', valueHtml: escapeHtml(launch.isActive ? 'да, текущий набор' : 'нет')),
      (label: 'Цена', valueHtml: escapeHtml(formatRubFromKopecks(launch.priceFullKopecks))),
      (label: 'Спеццена', valueHtml: escapeHtml(formatRubFromKopecks(launch.pricePromoKopecks))),
      (
        label: 'Ссылка на спеццену',
        valueHtml: escapeHtml(_readinessPromoValue(promoRaw, custom: promoCustom)),
      ),
      (label: 'Предоплата', valueHtml: escapeHtml(deposit)),
      (label: 'Старт курса', valueHtml: escapeHtml(_formatDate(launch.courseStartAt) ?? '')),
      (label: 'Эфир', valueHtml: escapeHtml(_formatDateTime(launch.webinarAt) ?? '')),
      (
        label: 'Ссылка на эфир',
        valueHtml: escapeHtml(launch.hasWebinarUrl ? 'указано' : 'не указано'),
      ),
      (label: 'Старт продаж', valueHtml: escapeHtml(_formatDateTime(launch.salesStartAt) ?? '')),
      (label: 'Конец продаж', valueHtml: escapeHtml(_formatDate(launch.salesEndAt) ?? '')),
      (label: 'Канал', valueHtml: '<code>${launch.channelId}</code>'),
      (label: 'Гайд', valueHtml: escapeHtml(_readinessGuideValue(launch))),
    ];
  }

  String _readinessPromoValue(String? url, {required bool custom}) {
    if (!custom || url == null || url.isEmpty) {
      return 'не указана, LeadPay';
    }
    if (url == LaunchPrices.defaultPromoCheckoutUrl) {
      return 'указана, LeadPay';
    }
    return 'указана своя';
  }

  bool _readinessHasGuide(Launch launch) {
    final fileId = launch.leadMagnetFileId?.trim();
    if (fileId != null && fileId.isNotEmpty) {
      return true;
    }
    final url = launch.leadMagnetUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  String _readinessGuideValue(Launch launch) {
    final fileId = launch.leadMagnetFileId?.trim();
    if (fileId != null && fileId.isNotEmpty) {
      return 'указан файл';
    }
    final url = launch.leadMagnetUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return 'указана ссылка';
    }
    return 'не указано';
  }

  bool _readinessSlotCustom(Launch launch, LaunchCopySlotKey slot) {
    if (slot == LaunchCopySlotKey.description) {
      return launch.hasCustomDescription;
    }
    return launch.copy.has(slot);
  }

  String _readinessDozhimValue(int count) {
    if (count <= 0) {
      return 'не указаны, уйдёт встроенный';
    }
    return 'указаны, $count ${_dayWord(count)}';
  }

  String _readinessSegmentTitle(LaunchCopySegment segment) {
    return switch (segment) {
      LaunchCopySegment.params => 'Параметры',
      LaunchCopySegment.welcome => 'Приветствие',
      LaunchCopySegment.masterclass => 'Мастер-класс',
      LaunchCopySegment.card => 'Карточка курса',
      LaunchCopySegment.warmup => 'Прогрев',
      LaunchCopySegment.dozhim => 'Дожим',
    };
  }
}
