import 'package:course_chatbot/src/domain/stored_telegram_message.dart';

/// Admin editing groups on a launch card. Student copy lives in slots, not here.
enum LaunchCopySegment {
  params,
  welcome,
  masterclass,
  card,
  warmup,
  dozhim;

  String get token => switch (this) {
    LaunchCopySegment.params => 'p',
    LaunchCopySegment.welcome => 'w',
    LaunchCopySegment.masterclass => 'm',
    LaunchCopySegment.card => 'c',
    LaunchCopySegment.warmup => 'u',
    LaunchCopySegment.dozhim => 'd',
  };

  String get adminLabel => switch (this) {
    LaunchCopySegment.params => '⚙️ Параметры',
    LaunchCopySegment.welcome => '👋 Приветствие',
    LaunchCopySegment.masterclass => '🎙 Мастер-класс',
    LaunchCopySegment.card => '✨ Карточка курса',
    LaunchCopySegment.warmup => '🔥 Прогрев',
    LaunchCopySegment.dozhim => '📣 Дожим',
  };

  static LaunchCopySegment? fromToken(String raw) {
    return switch (raw) {
      'p' => LaunchCopySegment.params,
      'w' => LaunchCopySegment.welcome,
      'm' => LaunchCopySegment.masterclass,
      'c' => LaunchCopySegment.card,
      'u' => LaunchCopySegment.warmup,
      'd' => LaunchCopySegment.dozhim,
      _ => null,
    };
  }
}

/// Per-launch student copy slot. [guideFile] is stored on `launches.lead_magnet_file_id`.
enum LaunchCopySlotKey {
  startOffer,
  guideTitle,
  guideReady,
  guideFile,
  masterClassTitle,
  rsvpCta,
  warmupImmediate,
  warmupTomorrow,
  warmupTenMinutes,
  warmupStarted,
  rsvpConfirmed,
  courseButton,
  description,
  enrollPromo,
  enrollRegular,
  coursePitch,
  afterWebinar,
  salesOpen,
  salesRegular,
  paymentSucceeded;

  String get token => switch (this) {
    LaunchCopySlotKey.startOffer => 'so',
    LaunchCopySlotKey.guideTitle => 'gt',
    LaunchCopySlotKey.guideReady => 'gr',
    LaunchCopySlotKey.guideFile => 'gf',
    LaunchCopySlotKey.masterClassTitle => 'mt',
    LaunchCopySlotKey.rsvpCta => 'rc',
    LaunchCopySlotKey.warmupImmediate => 'w0',
    LaunchCopySlotKey.warmupTomorrow => 'w1',
    LaunchCopySlotKey.warmupTenMinutes => 'w2',
    LaunchCopySlotKey.warmupStarted => 'w3',
    LaunchCopySlotKey.rsvpConfirmed => 'rv',
    LaunchCopySlotKey.courseButton => 'cb',
    LaunchCopySlotKey.description => 'ds',
    LaunchCopySlotKey.enrollPromo => 'ep',
    LaunchCopySlotKey.enrollRegular => 'er',
    LaunchCopySlotKey.coursePitch => 'cp',
    LaunchCopySlotKey.afterWebinar => 'aw',
    LaunchCopySlotKey.salesOpen => 'op',
    LaunchCopySlotKey.salesRegular => 'sr',
    LaunchCopySlotKey.paymentSucceeded => 'ps',
  };

  String get canonical => switch (this) {
    LaunchCopySlotKey.startOffer => 'start_offer',
    LaunchCopySlotKey.guideTitle => 'guide_title',
    LaunchCopySlotKey.guideReady => 'guide_ready',
    LaunchCopySlotKey.guideFile => 'guide_file',
    LaunchCopySlotKey.masterClassTitle => 'master_class_title',
    LaunchCopySlotKey.rsvpCta => 'rsvp_cta',
    LaunchCopySlotKey.warmupImmediate => 'warmup_0',
    LaunchCopySlotKey.warmupTomorrow => 'webinar_24h',
    LaunchCopySlotKey.warmupTenMinutes => 'webinar_10m',
    LaunchCopySlotKey.warmupStarted => 'webinar_live',
    LaunchCopySlotKey.rsvpConfirmed => 'rsvp_confirmed',
    LaunchCopySlotKey.courseButton => 'course_button',
    LaunchCopySlotKey.description => 'description',
    LaunchCopySlotKey.enrollPromo => 'enroll_promo',
    LaunchCopySlotKey.enrollRegular => 'enroll_regular',
    LaunchCopySlotKey.coursePitch => 'course_pitch',
    LaunchCopySlotKey.afterWebinar => 'after_webinar',
    LaunchCopySlotKey.salesOpen => 'sales_open',
    LaunchCopySlotKey.salesRegular => 'sales_regular',
    LaunchCopySlotKey.paymentSucceeded => 'payment_succeeded',
  };

  String get coursesHeader => switch (this) {
    LaunchCopySlotKey.guideFile => 'Гайд',
    LaunchCopySlotKey.startOffer => 'Приветствие',
    LaunchCopySlotKey.guideTitle => 'Название гайда',
    LaunchCopySlotKey.guideReady => 'Подпись гайда',
    LaunchCopySlotKey.masterClassTitle => 'Название МК',
    LaunchCopySlotKey.rsvpCta => 'RSVP',
    LaunchCopySlotKey.warmupImmediate => 'Сразу после гайда',
    LaunchCopySlotKey.warmupTomorrow => 'МК завтра',
    LaunchCopySlotKey.warmupTenMinutes => 'МК 10 минут',
    LaunchCopySlotKey.warmupStarted => 'МК начали',
    LaunchCopySlotKey.rsvpConfirmed => 'Подтверждение RSVP',
    LaunchCopySlotKey.courseButton => 'Кнопка курса',
    LaunchCopySlotKey.description => 'Описание',
    LaunchCopySlotKey.enrollPromo => 'Спеццена',
    LaunchCopySlotKey.enrollRegular => 'Обычная цена',
    LaunchCopySlotKey.coursePitch => 'Pitch',
    LaunchCopySlotKey.afterWebinar => 'После МК',
    LaunchCopySlotKey.salesOpen => 'Открытие продаж',
    LaunchCopySlotKey.salesRegular => 'Обычные продажи',
    LaunchCopySlotKey.paymentSucceeded => 'После оплаты',
  };

  String get adminLabel => coursesHeader;

  LaunchCopySegment get segment => switch (this) {
    LaunchCopySlotKey.startOffer ||
    LaunchCopySlotKey.guideTitle ||
    LaunchCopySlotKey.guideReady ||
    LaunchCopySlotKey.guideFile => LaunchCopySegment.welcome,
    LaunchCopySlotKey.masterClassTitle ||
    LaunchCopySlotKey.rsvpCta ||
    LaunchCopySlotKey.rsvpConfirmed => LaunchCopySegment.masterclass,
    LaunchCopySlotKey.courseButton ||
    LaunchCopySlotKey.description ||
    LaunchCopySlotKey.enrollPromo ||
    LaunchCopySlotKey.enrollRegular ||
    LaunchCopySlotKey.coursePitch => LaunchCopySegment.card,
    LaunchCopySlotKey.warmupImmediate ||
    LaunchCopySlotKey.warmupTomorrow ||
    LaunchCopySlotKey.warmupTenMinutes ||
    LaunchCopySlotKey.warmupStarted ||
    LaunchCopySlotKey.afterWebinar ||
    LaunchCopySlotKey.salesOpen ||
    LaunchCopySlotKey.salesRegular ||
    LaunchCopySlotKey.paymentSucceeded => LaunchCopySegment.warmup,
  };

  bool get storesInCopyTable => this != LaunchCopySlotKey.guideFile;

  bool get allowsMedia => switch (this) {
    LaunchCopySlotKey.startOffer ||
    LaunchCopySlotKey.guideReady ||
    LaunchCopySlotKey.warmupImmediate ||
    LaunchCopySlotKey.warmupTomorrow ||
    LaunchCopySlotKey.warmupTenMinutes ||
    LaunchCopySlotKey.warmupStarted ||
    LaunchCopySlotKey.afterWebinar ||
    LaunchCopySlotKey.salesOpen ||
    LaunchCopySlotKey.salesRegular ||
    LaunchCopySlotKey.paymentSucceeded => true,
    _ => false,
  };

  String? get funnelMediaKey => switch (this) {
    LaunchCopySlotKey.startOffer => 'start',
    LaunchCopySlotKey.warmupImmediate || LaunchCopySlotKey.warmupTomorrow => 'warmup_0',
    LaunchCopySlotKey.afterWebinar => 'webinar_next',
    LaunchCopySlotKey.salesOpen => 'sales_open',
    LaunchCopySlotKey.paymentSucceeded => 'paid',
    _ => null,
  };

  static LaunchCopySlotKey? fromToken(String raw) {
    for (final value in values) {
      if (value.token == raw) {
        return value;
      }
    }
    return null;
  }

  static LaunchCopySlotKey? fromCanonical(String raw) {
    for (final value in values) {
      if (value.canonical == raw) {
        return value;
      }
    }
    return null;
  }

  static List<LaunchCopySlotKey> slotsOf(LaunchCopySegment segment) {
    return <LaunchCopySlotKey>[
      for (final slot in values)
        if (slot.segment == segment) slot,
    ];
  }
}

final class LaunchCopy {
  const LaunchCopy(this._slots);

  const LaunchCopy.empty() : _slots = const <LaunchCopySlotKey, StoredTelegramMessage>{};

  final Map<LaunchCopySlotKey, StoredTelegramMessage> _slots;

  bool has(LaunchCopySlotKey slot) => _slots.containsKey(slot);

  StoredTelegramMessage? operator [](LaunchCopySlotKey slot) => _slots[slot];

  String? htmlOf(LaunchCopySlotKey slot) {
    final message = _slots[slot];
    final html = message?.html?.trim();
    if (html != null && html.isNotEmpty) {
      return html;
    }
    return message?.captionHtml;
  }

  Map<LaunchCopySlotKey, StoredTelegramMessage> get asMap =>
      Map<LaunchCopySlotKey, StoredTelegramMessage>.unmodifiable(_slots);
}
