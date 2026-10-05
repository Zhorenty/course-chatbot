part of 'package:course_chatbot/src/messages/message_templates.dart';

extension MessageTemplatesCourse on MessageTemplates {
  String courseReplyButton(Launch? launch) {
    final stored = launch?.copy.htmlOf(LaunchCopySlotKey.courseButton)?.trim();
    if (stored != null && stored.isNotEmpty) {
      final rendered = _applyCopyPlaceholders(stored, launch);
      if (rendered.trim().isNotEmpty) {
        return rendered.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      }
    }
    final title = launch?.title.trim();
    if (title == null || title.isEmpty) {
      return MessageTemplates.buttonEnroll;
    }
    return 'Курс "$title"';
  }

  String guideTitleOf(Launch? launch) {
    return _slotOrDefault(launch, LaunchCopySlotKey.guideTitle, LaunchCopyDefaults.guideTitle);
  }

  String masterClassTitleOf(Launch? launch) {
    return _slotOrDefault(
      launch,
      LaunchCopySlotKey.masterClassTitle,
      LaunchCopyDefaults.masterClassTitle,
    );
  }

  List<InputRichMessageMedia> copyMedia(Launch? launch, LaunchCopySlotKey slot) {
    if (launch != null && launch.copy.has(slot)) {
      return storedCopyToRichMedia(launch.copy[slot]);
    }
    final key = slot.funnelMediaKey;
    if (key == null) {
      return const <InputRichMessageMedia>[];
    }
    return FunnelMedia.richMedia(key);
  }

  List<String> regularEnrollPhotos() => FunnelMedia.pathsFor('enroll_regular');

  List<InputRichMessageMedia> warmupMedia(String stepKey, {Launch? launch}) {
    final slot = _warmupSlot(stepKey);
    if (slot != null) {
      return copyMedia(launch, slot);
    }
    return FunnelMedia.richMedia(stepKey);
  }

  String _slotOrDefault(Launch? launch, LaunchCopySlotKey slot, String fallback) {
    return _renderCopySlot(launch, slot, fallback);
  }

  String _renderCopySlot(Launch? launch, LaunchCopySlotKey slot, String fallback) {
    final stored = launch?.copy.htmlOf(slot)?.trim();
    final raw = (stored != null && stored.isNotEmpty) ? stored : fallback;
    return _applyCopyPlaceholders(raw, launch);
  }

  LaunchCopySlotKey? _warmupSlot(String stepKey) {
    return switch (stepKey) {
      'warmup_0' => LaunchCopySlotKey.warmupImmediate,
      'webinar_24h' => LaunchCopySlotKey.warmupTomorrow,
      'webinar_10m' => LaunchCopySlotKey.warmupTenMinutes,
      'webinar_live' => LaunchCopySlotKey.warmupStarted,
      'webinar_next' => LaunchCopySlotKey.afterWebinar,
      'sales_open' => LaunchCopySlotKey.salesOpen,
      'sales_regular' => LaunchCopySlotKey.salesRegular,
      _ => null,
    };
  }

  StoredTelegramMessage renderStoredCopy(
    StoredTelegramMessage payload,
    Launch? launch, {
    Map<String, String>? extra,
  }) {
    return payload.mapHtml((html) => _applyCopyPlaceholders(html, launch, extra));
  }

  StoredTelegramMessage renderDozhimCopy(StoredTelegramMessage payload, Launch? launch) {
    return renderStoredCopy(
      payload,
      launch,
      extra: <String, String>{'course_start_join': _dozhimStartJoin(launch)},
    );
  }

  String _rawCopySlot(Launch? launch, LaunchCopySlotKey slot, String fallback) {
    final stored = launch?.copy.htmlOf(slot)?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return fallback;
  }

  String _applyCopyPlaceholders(String raw, Launch? launch, [Map<String, String>? extra]) {
    var text = raw;
    final values = <String, String>{
      'title': _quotedCourseTitle(launch),
      'short_title': escapeHtml(_courseTitle(launch)),
      'launch_title': launch?.title.trim() ?? '',
      'course_start': _formatHumanDate(launch?.courseStartAt) ?? '',
      'webinar_at': _formatHumanDate(launch?.webinarAt) ?? '',
      'webinar_time': _formatClock(launch?.webinarAt) ?? '',
      'webinar_schedule': _webinarScheduleBlock(launch),
      'webinar_link': launch?.resolvedWebinarUrl ?? '',
      'price_full': launch == null ? '' : formatRubSpaced(launch.priceFullKopecks, unit: 'руб.'),
      'price_promo': launch == null ? '' : formatRubSpaced(launch.pricePromoKopecks, unit: 'руб.'),
      'price_was': _compareAtRub(launch),
      'price_was_regular': formatRubSpaced(LaunchPrices.wasRegularKopecks),
      'deposit': launch == null || !launch.hasDepositOption
          ? ''
          : formatRubSpaced(launch.depositKopecks, unit: 'руб.'),
      'guide_title': escapeHtml(
        _rawCopySlot(launch, LaunchCopySlotKey.guideTitle, LaunchCopyDefaults.guideTitle),
      ),
      'master_class_title': escapeHtml(
        _rawCopySlot(
          launch,
          LaunchCopySlotKey.masterClassTitle,
          LaunchCopyDefaults.masterClassTitle,
        ),
      ),
      'rsvp_cta': _rawCopySlot(launch, LaunchCopySlotKey.rsvpCta, LaunchCopyDefaults.rsvpCta),
      ...?extra,
    };
    values.forEach((key, value) {
      text = text.replaceAll('{$key}', value);
    });
    return text;
  }
}
