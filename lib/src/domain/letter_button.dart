import 'package:course_chatbot/src/domain/copy_sheet.dart';
import 'package:course_chatbot/src/domain/launch_copy.dart';

/// What the button under a student letter does.
enum LetterButtonAction {
  payFull,
  payDeposit,
  payRemainder,
  enroll,
  rsvp,
  webinar,
  promo,
  channel,
  optOut,
  url,
  none,

  /// Built-in pair on the regular price card: full payment and deposit.
  payChoice;

  String get code => switch (this) {
    LetterButtonAction.payFull => 'f',
    LetterButtonAction.payDeposit => 'd',
    LetterButtonAction.payRemainder => 'r',
    LetterButtonAction.enroll => 'e',
    LetterButtonAction.rsvp => 's',
    LetterButtonAction.webinar => 'w',
    LetterButtonAction.promo => 'p',
    LetterButtonAction.channel => 'c',
    LetterButtonAction.optOut => 'o',
    LetterButtonAction.url => 'u',
    LetterButtonAction.none => 'n',
    LetterButtonAction.payChoice => 'x',
  };

  static LetterButtonAction? fromCode(String? raw) {
    final code = raw?.trim();
    if (code == null || code.isEmpty) {
      return null;
    }
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }

  /// Actions an admin can hang on a letter. [payChoice] stays the built-in pair.
  static const List<LetterButtonAction> editable = <LetterButtonAction>[
    payFull,
    payDeposit,
    payRemainder,
    enroll,
    rsvp,
    webinar,
    promo,
    channel,
    optOut,
    url,
    none,
  ];
}

/// One button stored for a letter. [url] is set only for [LetterButtonAction.url].
final class LetterButton {
  const LetterButton({required this.action, required this.label, this.url});

  final LetterButtonAction action;
  final String label;
  final String? url;

  bool get hidesButton => action == LetterButtonAction.none;

  /// Same action as the scenario default: do not replace the built-in keyboard.
  bool get keepsBuiltinKeyboard => action == LetterButtonAction.payChoice;
}

/// How a ТЕКСТЫ row's button cells were read.
enum LetterCellKind { empty, unknown, button }

final class LetterCellRead {
  const LetterCellRead._(this.kind, this.button);

  const LetterCellRead.empty() : this._(LetterCellKind.empty, null);

  const LetterCellRead.unknown() : this._(LetterCellKind.unknown, null);

  const LetterCellRead.button(LetterButton button) : this._(LetterCellKind.button, button);

  final LetterCellKind kind;
  final LetterButton? button;
}

/// Button under one student letter: the sheet row, the admin slot, and the default.
final class LetterSpec {
  const LetterSpec({
    required this.key,
    required this.stage,
    required this.action,
    required this.label,
    this.slot,
  });

  final String key;
  final String stage;
  final LetterButtonAction action;
  final String label;
  final LaunchCopySlotKey? slot;

  LetterButton get button => LetterButton(action: action, label: label);
}

abstract final class LetterButtons {
  static const String payChoiceLabel =
      '2 кнопки:\n'
      '- Оплатить курс целиком ({обычная цена})\n'
      '- Бронь места, предоплата ({предоплата})';

  static final List<LetterSpec> specs = <LetterSpec>[
    const LetterSpec(
      key: 'pre_sales',
      stage: 'нажал на кнопку курса ДО эфира / до старта продаж',
      action: LetterButtonAction.rsvp,
      label: 'Хочу на мастер-класс',
    ),
    const LetterSpec(
      key: 'rsvp_live',
      stage: 'нажал "Хочу на мастер-класс", эфир уже идёт и ссылка есть',
      action: LetterButtonAction.webinar,
      label: 'Присоединиться',
    ),
    const LetterSpec(
      key: 'warmup_0',
      stage: 'Нажал "Получить гайд", сразу после выдачи гайда',
      action: LetterButtonAction.rsvp,
      label: 'Хочу на мастер-класс',
      slot: LaunchCopySlotKey.warmupImmediate,
    ),
    const LetterSpec(
      key: 'webinar_24h',
      stage: 'Не отметился, не нажимал "хочу на мастер-класс". За сутки до эфира',
      action: LetterButtonAction.rsvp,
      label: 'Хочу на мастер-класс',
      slot: LaunchCopySlotKey.warmupTomorrow,
    ),
    const LetterSpec(
      key: 'webinar_10m',
      stage: 'Не отметился. За 10 минут до эфира',
      action: LetterButtonAction.rsvp,
      label: 'Хочу на мастер-класс',
      slot: LaunchCopySlotKey.warmupTenMinutes,
    ),
    const LetterSpec(
      key: 'webinar_live',
      stage: 'эфир начинается, только те, кто в списке отмечался',
      action: LetterButtonAction.webinar,
      label: 'Присоединиться',
      slot: LaunchCopySlotKey.warmupStarted,
    ),
    const LetterSpec(
      key: 'webinar_next',
      stage: 'на следующий день после эфира, только кто отмечался в списке',
      action: LetterButtonAction.enroll,
      label: 'Записаться на курс',
      slot: LaunchCopySlotKey.afterWebinar,
    ),
    const LetterSpec(
      key: 'enroll_promo',
      stage: 'сегмент тех, кто получил спец.предложение и нажал "записаться на курс"',
      action: LetterButtonAction.promo,
      label: 'Оплатить курс по специальной цене',
      slot: LaunchCopySlotKey.enrollPromo,
    ),
    const LetterSpec(
      key: 'sales_regular',
      stage: 'спеццена истекла, кто был в списке МК и не записался за 3 дня',
      action: LetterButtonAction.enroll,
      label: 'Записаться на курс',
      slot: LaunchCopySlotKey.salesRegular,
    ),
    LetterSpec(
      key: 'enroll_regular',
      stage: 'нажал на Записаться на курс, обычная цена',
      action: LetterButtonAction.payChoice,
      label: payChoiceLabel,
      slot: LaunchCopySlotKey.enrollRegular,
    ),
    const LetterSpec(
      key: 'sales_open',
      stage: 'продажи открыты, кто забирал гайд или нажимал курс и не был на эфире',
      action: LetterButtonAction.enroll,
      label: 'Записаться на курс',
      slot: LaunchCopySlotKey.salesOpen,
    ),
    const LetterSpec(
      key: 'dozhim_d1',
      stage: 'дожим 1 (кейс)',
      action: LetterButtonAction.enroll,
      label: 'Записаться на курс',
    ),
    const LetterSpec(
      key: 'dozhim_d2',
      stage: 'дожим 2 (возражение 1)',
      action: LetterButtonAction.enroll,
      label: 'Записаться на курс',
    ),
    const LetterSpec(
      key: 'dozhim_d3',
      stage: 'дожим 3 (до-после)',
      action: LetterButtonAction.enroll,
      label: 'Записаться на курс',
    ),
    const LetterSpec(
      key: 'dozhim_d4',
      stage: 'дожим 4 (возражение 2)',
      action: LetterButtonAction.enroll,
      label: 'Записаться на курс',
    ),
    const LetterSpec(
      key: 'help',
      stage: 'Помощь',
      action: LetterButtonAction.optOut,
      label: 'Отписаться от рассылки',
    ),
    const LetterSpec(
      key: 'paid',
      stage: 'касса ответила, полная оплата',
      action: LetterButtonAction.channel,
      label: 'Открыть канал курса',
      slot: LaunchCopySlotKey.paymentSucceeded,
    ),
    const LetterSpec(
      key: 'deposit_paid',
      stage: 'касса ответила, предоплата',
      action: LetterButtonAction.payRemainder,
      label: 'Внести остаток сейчас',
    ),
    const LetterSpec(
      key: 'remainder_due',
      stage: 'предоплата внесена, остаток не внесен',
      action: LetterButtonAction.payRemainder,
      label: 'Внести остаток сейчас',
    ),
    const LetterSpec(
      key: 'unjoined',
      stage: 'оплатил, но не открывал канал курса',
      action: LetterButtonAction.channel,
      label: 'Открыть канал курса',
    ),
    const LetterSpec(
      key: 'late_full',
      stage: CopySheet.lateFullStage,
      action: LetterButtonAction.payFull,
      label: 'присоединиться к курсу',
    ),
    const LetterSpec(
      key: 'sales_closed',
      stage: 'продажи этого потока закончились',
      action: LetterButtonAction.none,
      label: '',
    ),
  ];

  static LetterSpec? specByKey(String key) {
    for (final spec in specs) {
      if (spec.key == key) {
        return spec;
      }
    }
    return null;
  }

  static LetterSpec? specByStage(String stage) {
    final text = stage.trim();
    for (final spec in specs) {
      if (spec.stage == text) {
        return spec;
      }
    }
    return null;
  }

  static LetterSpec? specBySlot(LaunchCopySlotKey slot) {
    for (final spec in specs) {
      if (spec.slot == slot) {
        return spec;
      }
    }
    return null;
  }

  static String leadsToPhrase(LetterButtonAction action, {String? url}) {
    return switch (action) {
      LetterButtonAction.payFull => 'полная оплата',
      LetterButtonAction.payDeposit => 'предоплата',
      LetterButtonAction.payRemainder => 'оплата остатка',
      LetterButtonAction.enroll => 'карточка курса',
      LetterButtonAction.rsvp => 'запись на мастер-класс',
      LetterButtonAction.webinar => 'ссылка на эфир',
      LetterButtonAction.promo => 'оплата спеццены',
      LetterButtonAction.channel => 'канал курса',
      LetterButtonAction.optOut => 'отписка от рассылки',
      LetterButtonAction.url => url == null || url.isEmpty ? 'своя ссылка' : url,
      LetterButtonAction.none => 'без кнопки',
      LetterButtonAction.payChoice => 'полная оплата и предоплата',
    };
  }

  static String defaultLabel(LetterButtonAction action) {
    return switch (action) {
      LetterButtonAction.payFull => 'Оплатить курс целиком',
      LetterButtonAction.payDeposit => 'Бронь места, предоплата',
      LetterButtonAction.payRemainder => 'Внести остаток сейчас',
      LetterButtonAction.enroll => 'Записаться на курс',
      LetterButtonAction.rsvp => 'Хочу на мастер-класс',
      LetterButtonAction.webinar => 'Присоединиться',
      LetterButtonAction.promo => 'Оплатить курс по специальной цене',
      LetterButtonAction.channel => 'Открыть канал курса',
      LetterButtonAction.optOut => 'Отписаться от рассылки',
      LetterButtonAction.url => 'Открыть',
      LetterButtonAction.none => '',
      LetterButtonAction.payChoice => payChoiceLabel,
    };
  }

  static LetterCellRead readCells({String? label, String? leadsTo}) {
    final buttonText = label?.trim() ?? '';
    final actionText = leadsTo?.trim() ?? '';
    if (buttonText.isEmpty && actionText.isEmpty) {
      return const LetterCellRead.empty();
    }
    final fromButton = _actionOf(buttonText);
    final fromLeads = _actionOf(actionText);
    final action = fromButton == LetterButtonAction.payChoice
        ? fromButton
        : (fromLeads ?? fromButton);
    if (action == null) {
      return const LetterCellRead.unknown();
    }
    if (action == LetterButtonAction.payChoice) {
      return LetterCellRead.button(
        const LetterButton(action: LetterButtonAction.payChoice, label: payChoiceLabel),
      );
    }
    if (action == LetterButtonAction.none) {
      return const LetterCellRead.button(LetterButton(action: LetterButtonAction.none, label: ''));
    }
    final url = action == LetterButtonAction.url ? _urlOf(actionText) ?? _urlOf(buttonText) : null;
    if (action == LetterButtonAction.url && (url == null || url.isEmpty)) {
      return const LetterCellRead.unknown();
    }
    final shown = buttonText.isEmpty || _actionOf(buttonText) != null
        ? defaultLabel(action)
        : buttonText;
    return LetterCellRead.button(LetterButton(action: action, label: shown, url: url));
  }

  static LetterButtonAction? _actionOf(String raw) {
    final text = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) {
      return null;
    }
    final url = _urlOf(raw);
    if (url != null && (text == url.toLowerCase() || text.startsWith('http'))) {
      return LetterButtonAction.url;
    }
    if (text.contains('без кнопки')) {
      return LetterButtonAction.none;
    }
    if (text.contains('полная оплата и предоплата') ||
        text.contains('2 кнопки') ||
        (text.contains('оплатить курс целиком') && text.contains('предоплат'))) {
      return LetterButtonAction.payChoice;
    }
    if (text.contains('предоплат')) {
      return LetterButtonAction.payDeposit;
    }
    if (text.contains('остат') || text.contains('доплат')) {
      return LetterButtonAction.payRemainder;
    }
    if (text.contains('карточк') || text.contains('записаться на курс')) {
      return LetterButtonAction.enroll;
    }
    if (text.contains('спеццен') || text.contains('leadpay')) {
      return LetterButtonAction.promo;
    }
    if (text.contains('отпис')) {
      return LetterButtonAction.optOut;
    }
    if (text.contains('мастер-класс') || text.contains('записавшихся')) {
      return LetterButtonAction.rsvp;
    }
    if (text.contains('эфир')) {
      return LetterButtonAction.webinar;
    }
    if (text.contains('канал')) {
      return LetterButtonAction.channel;
    }
    if (text.contains('полная оплата') ||
        text.contains('юkassa') ||
        text.contains('юкасса') ||
        text.contains('касса')) {
      return LetterButtonAction.payFull;
    }
    return null;
  }

  static String? _urlOf(String raw) {
    final match = RegExp(r'https?://\S+').firstMatch(raw.trim());
    final url = match?.group(0);
    if (url == null || url.contains(' ')) {
      return null;
    }
    return url;
  }
}
