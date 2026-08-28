import 'package:course_chatbot/src/domain/acquisition_link.dart';
import 'package:course_chatbot/src/domain/broadcast.dart';
import 'package:course_chatbot/src/domain/catalog.dart';
import 'package:course_chatbot/src/domain/channel_access.dart';
import 'package:course_chatbot/src/domain/conversation_log.dart';
import 'package:course_chatbot/src/domain/courses_sheet.dart';
import 'package:course_chatbot/src/domain/funnel.dart';
import 'package:course_chatbot/src/domain/links_sheet.dart';
import 'package:course_chatbot/src/domain/money.dart';
import 'package:course_chatbot/src/domain/order.dart';
import 'package:course_chatbot/src/domain/user_profile.dart';
import 'package:course_chatbot/src/messages/html_escaper.dart';
import 'package:course_chatbot/src/messages/keyboards/keyboard_builders.dart';
import 'package:intl/intl.dart';

part 'templates/message_templates_keyboards.part.dart';

/// User-facing copy and keyboards. Marketing tone lives here, not in handlers.
final class MessageTemplates {
  MessageTemplates({String? botUsername}) : _botUsername = botUsername;

  final String? _botUsername;
  final DateFormat _date = DateFormat('dd.MM.yyyy');
  final DateFormat _dateTime = DateFormat('dd.MM.yyyy HH:mm');
  static const int _moscowOffsetHours = 3;

  static const String buttonGuide = '📘 Получить гайд';
  static const String buttonEnroll = '✨ Записаться на курс';
  static const String buttonMenu = '📋 Меню';
  static const String buttonHelp = '❓ Помощь';
  static const String buttonOptOut = '⏸ Не писать';
  static const String buttonPayFull = '💳 Оплатить полностью';
  static const String buttonPayDeposit = '💳 Предоплата';
  static const String buttonPayInstallment = '💳 Рассрочка';
  static const String buttonPayRemainder = '💳 Доплатить';
  static const String buttonGoToPay = '💳 Перейти к оплате';
  static const String buttonContinuePay = '💳 Продолжить оплату';
  static const String buttonNewInvite = '🔗 Новая ссылка в канал';
  static const String buttonAcceptOffer = 'Принимаю условия Публичной оферты';
  static const String buttonAcceptPersonalData = 'Согласие на обработку персональных данных';
  static const String buttonAdminSearch = '🔍 Поиск человека';
  static const String buttonAdminAddUser = '➕ Добавить на курс';
  static const String buttonAdminBroadcast = '📣 Рассылка';
  static const String buttonAdminLinks = '🔗 Диплинки';
  static const String buttonAdminSheets = '📊 Обновить Sheets';
  static const String buttonAdminMenu = '🛠 Админка';
  static const String buttonAdminMarkPaid = '✅ Отметить оплаченным';
  static const String buttonAdminMarkDeposit = '💵 Предоплата';
  static const String buttonAdminCancel = '🚫 Убрать с курса';
  static const String buttonAdminReinvite = '🔗 Новый invite';
  static const String buttonAdminCreateUser = '➕ Создать карточку';
  static const String buttonAdminBroadcastSend = 'Отправить';
  static const String buttonAdminBroadcastOtherSegment = 'Другой сегмент';
  static const String buttonAdminBroadcastCancel = '✖️ Отмена';
  static const String buttonAdminGuideSave = '💾 Сохранить гайд';
  static const String buttonAdminGuideDiscard = '✖️ Не сохранять';
  static const String buttonAdminOpenCard = '👤 Карточка';

  static const String cbGuide = 'g';
  static const String cbEnroll = 'e';
  static const String cbPayFull = 'pf';
  static const String cbPayDeposit = 'pd';
  static const String cbPayInstallment = 'pi';
  static const String cbPayRemainder = 'pr';
  static const String cbToggleOffer = 'oo';
  static const String cbTogglePersonalData = 'op';
  static const String cbGoToPay = 'og';
  static const String cbOptOut = 'o';
  static const String cbContinuePay = 'cp:';
  static const String cbNewInvite = 'ni';
  static const String cbAdminPaid = 'ap:';
  static const String cbAdminDeposit = 'ad:';
  static const String cbAdminCancel = 'ac:';
  static const String cbAdminInvite = 'ai:';
  static const String cbAdminCreate = 'an:';
  static const String cbBroadcastSegment = 'bs:';
  static const String cbBroadcastSend = 'bp';
  static const String cbBroadcastOtherSegment = 'br';
  static const String cbBroadcastCancel = 'bx';
  static const String cbGuideSave = 'gs';
  static const String cbGuideDiscard = 'gx';
  static const String cbAdminCard = 'ak:';

  String botInDevelopment() {
    return '<b>Бот в разработке</b>\n\n'
        'Сейчас сценарий доступен только команде. '
        'Как откроем — напиши /start ещё раз.';
  }

  String startGuideOffer() {
    return '<b>Гайд «Язык цвета»</b>\n\n'
        'Какие оттенки тебе идут — и почему любимый цвет в зеркале вдруг «не работает». '
        'PDF пришлю сюда же: без имени, почты и телефона.\n\n'
        'Нажми кнопку — файл будет в этом чате.';
  }

  String startCourseCard({Launch? launch}) {
    final start = _formatDate(launch?.courseStartAt);
    final price = _formatPrice(launch?.priceFullKopecks);
    final headline = start == null ? 'Курс по колористике' : 'Поток с $start';
    final buf = StringBuffer()
      ..writeln('<b>$headline</b>')
      ..writeln()
      ..write('Собрать свой язык цвета и гардероб, который не спорит с тоном кожи.');
    if (price != null) {
      buf.write(' Полная стоимость — $price.');
    }
    if (start != null) {
      buf.write(' Старт $start.');
    }
    buf
      ..writeln()
      ..writeln()
      ..write('Можно сразу записаться или сначала забрать бесплатный гайд «Язык цвета».');
    return buf.toString();
  }

  String alreadyHasAccess() {
    return '<b>Ты уже в канале этого потока</b>\n\n'
        'Если ссылка потерялась — нажми «${MessageTemplates.buttonNewInvite}». '
        'Старая отключится, новая будет на одного человека.';
  }

  String menu(UserProfile user) {
    return '<b>Меню</b>\n\n'
        'Сейчас: ${escapeHtml(_phaseLabel(user.funnelPhase))}.\n\n'
        'Дальше — гайд, запись на курс или помощь.';
  }

  String help() {
    return '<b>Как это устроено</b>\n\n'
        'Гайд «Язык цвета» — бесплатно, в этот чат. Запись на поток — через оплату в боте.\n\n'
        'Если касса зависла или ссылка не открылась, напиши сюда. Сообщение увидит админ.';
  }

  String helpReceived() {
    return 'Передал админу. Напишет тебе в личные сообщения.';
  }

  String helpForwardFailed() {
    return 'Не смог передать админу. Напиши ещё раз чуть позже.';
  }

  String adminIncomingUserMessage({required UserProfile user, String? text}) {
    final handle = user.username == null || user.username!.trim().isEmpty
        ? ''
        : ' · @${escapeHtml(user.username!.trim())}';
    final body = (text == null || text.trim().isEmpty)
        ? 'без текста — фото или файл'
        : escapeHtml(text.trim());
    return '<b>Написал ${escapeHtml(user.displayName)}</b>\n'
        'id <code>${user.userId}</code>$handle\n'
        'сейчас: ${escapeHtml(_adminPhaseLabel(user.funnelPhase))}\n\n'
        '$body';
  }

  String guideReady() {
    return '📘 Лови гайд «Язык цвета» — файл выше.';
  }

  String guideAsUrl(String url) {
    return '📘 Гайд «Язык цвета» здесь: ${escapeHtml(url)}';
  }

  String guideMissing() {
    return '📘 Гайд ещё не загружен. Нажми «${MessageTemplates.buttonHelp}» — '
        'пришлю, как только файл будет на месте.';
  }

  String warmupStep(String stepKey, {Launch? launch}) {
    return switch (stepKey) {
      'warmup_0' => _warmupZero(launch),
      'warmup_d1' => _warmupDay1(),
      'warmup_d3' => _warmupDay3(launch),
      _ =>
        '<b>Ещё одно касание</b>\n\n'
            'Можно записаться на поток, когда будет удобно. Кнопка ниже.',
    };
  }

  String _warmupZero(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final startLine = start == null
        ? 'Можно записаться с кнопки ниже — когда будет удобно.'
        : 'Поток стартует $start. Можно записаться сейчас или почитать гайд и вернуться — кнопка никуда не денется.';
    return '<b>Гайд — это алфавит</b>\n\n'
        '«Язык цвета» помогает увидеть, какие оттенки тебе идут. '
        'Курс собирает это в систему: база гардероба и цвета, с которыми проще собираться.\n\n'
        '$startLine';
  }

  String _warmupDay1() {
    return '<b>Почему любимый цвет «не идёт»</b>\n\n'
        'Часто дело не во вкусе, а в подтоне: холодный розовый на тёплой коже выглядит грязновато, '
        'тёплый беж на холодной — желтит.\n\n'
        'Гайд это подсвечивает. На курсе разбираем, как собрать базу, которая не спорит с кожей. '
        'Когда будет момент — кнопка записи ниже.';
  }

  String _warmupDay3(Launch? launch) {
    final start = _formatDate(launch?.courseStartAt);
    final price = _formatPrice(launch?.priceFullKopecks);
    final deposit = launch != null && launch.hasDepositOption
        ? formatRubFromKopecks(launch.depositKopecks)
        : null;
    final due = _formatDate(launch?.depositDueAt);
    final buf = StringBuffer()
      ..writeln(start == null ? '<b>Если идёшь в поток</b>' : '<b>Поток $start</b>')
      ..writeln();
    if (price != null) {
      buf.write('Полная стоимость $price.');
      if (deposit != null && due != null) {
        buf.write(' Можно внести предоплату $deposit и закрыть остаток до $due.');
      }
      buf.write(' Рассрочка открывается на странице кассы — график ведёт касса, не бот.');
    } else {
      buf.write(
        'Можно закрыть полную сумму, внести предоплату или открыть рассрочку на странице кассы.',
      );
    }
    buf
      ..writeln()
      ..writeln()
      ..write(
        'В канал потока пускаю после полной суммы или после списания. Записаться — с кнопки ниже.',
      );
    return buf.toString();
  }

  String optOutConfirmed() {
    return '⏸ Ок, продающие сообщения больше не пришлю.\n\n'
        'Меню, гайд и запись остаются. Если оплата уже начата или есть доплата — про это напомню, это не реклама.';
  }

  String enrollOptions(Launch launch) {
    final price = launch.priceFullKopecks > 0
        ? formatRubFromKopecks(launch.priceFullKopecks)
        : 'цену уточнит админ';
    final buf = StringBuffer()
      ..writeln('<b>Запись на поток</b>')
      ..writeln()
      ..writeln('Стоимость: $price.');
    if (launch.hasDepositOption) {
      buf.write('Предоплата: ${formatRubFromKopecks(launch.depositKopecks)}.');
      final due = _formatDate(launch.depositDueAt);
      if (due != null) {
        buf.write(' Остаток — до $due');
        final start = _formatDate(launch.courseStartAt);
        if (start != null) {
          buf.write(', старт курса $start');
        }
        buf.write('.');
      }
      buf.writeln(' В канал пущу после полной суммы.');
    }
    buf.writeln(
      'Рассрочка откроется на странице кассы: график ведёт касса, не бот. '
      'Доступ — после списания, не после «заявка одобрена».',
    );
    buf.writeln();
    buf.write('Выбери, как удобнее закрыть оплату.');
    return buf.toString().trim();
  }

  String offerConsent(Launch launch) {
    final offerPhrase = _offerPhrase(launch);
    return 'Нажимая «${MessageTemplates.buttonGoToPay}», вы подтверждаете, '
        'что ознакомились и соглашаетесь с условиями $offerPhrase '
        'на оказание информационно-консультационных/образовательных услуг '
        'и даёте согласие на обработку персональных данных.';
  }

  String offerNeedBothChecks() {
    return 'Нужны обе галочки, чтобы открыть оплату.';
  }

  String _offerPhrase(Launch launch) {
    final url = launch.offerUrl?.trim();
    if (url == null || url.isEmpty) {
      return 'Публичной оферты';
    }
    return '<a href="${escapeHtml(url)}">Публичной оферты</a>';
  }

  String payButton(String url) {
    if (url.isEmpty) {
      return payManualFallback();
    }
    return '💳 Ссылка на оплату готова. После успешного платежа статус в боте обновится сам. '
        'Если это предоплата, в канал пущу после полной суммы.';
  }

  // TODO(launch): replace the hardcoded @zhorenty support username below with
  //  the real support contact once it's confirmed.
  String payManualFallback() {
    return '💳 Сейчас временные технические неполадки с онлайн-оплатой, '
        'запись временно оформляется через администратора.\n\n'
        'Напиши сюда: @zhorenty — зафиксируем твоё место.';
  }

  String adminPaymentGatewayDown({required int userId, required String provider, String? reason}) {
    final reasonLine = (reason == null || reason.trim().isEmpty)
        ? ''
        : '\n${escapeHtml(reason.trim())}';
    return '<b>Касса недоступна</b>\n\n'
        'Провайдер <code>${escapeHtml(provider)}</code> не отдал ссылку на оплату '
        'для id <code>$userId</code>.$reasonLine\n\n'
        'Если человек напишет сюда — отметь оплату вручную из карточки.';
  }

  String paymentSucceeded() {
    return '<b>Оплата прошла</b>\n\n'
        'Дальше — одноразовая ссылка в канал этого потока. На одного человека.';
  }

  String depositSucceeded(CourseOrder order) {
    final due = order.dueAt == null ? 'по договорённости' : _date.format(order.dueAt!.toLocal());
    return '<b>Предоплата дошла</b>\n\n'
        'Остаток ${formatRubFromKopecks(order.amountDueKopecks)} — до $due. '
        'В канал пущу, когда закроется полная сумма. Место никто не бронирует: лимита нет.';
  }

  String inviteMessage(String link) {
    return '🔗 Одноразовая ссылка в канал потока:\n${escapeHtml(link)}\n\n'
        'На одного человека. Если не открылась — запроси новую, эта отключится.';
  }

  String inviteUnavailable() {
    return 'Оплата есть, канал ещё не привязан. Напиши сюда — админ выдаст доступ вручную.';
  }

  String abandonedFirst() {
    return '💳 Оформление началось, оплата пока не закрылась. Можно продолжить с того же места.';
  }

  String abandonedSecond() {
    return '💳 Напоминаю про незакрытую оплату. Ссылка ещё действует — если поток всё ещё в планах.';
  }

  String remainderReminder(CourseOrder order) {
    final due = order.dueAt == null ? 'скоро' : _date.format(order.dueAt!.toLocal());
    return '💳 Доплата по курсу: остаток ${formatRubFromKopecks(order.amountDueKopecks)}, срок $due. '
        'После полной суммы открою канал потока.';
  }

  String adminMenu() {
    return '<b>Админка</b>\n\n'
        'Поиск и карточка человека, добавить на курс, ручной статус, рассылка сегменту. '
        'Диплинки — «${MessageTemplates.buttonAdminLinks}». '
        'Срез воронки и каталог COURSES — «${MessageTemplates.buttonAdminSheets}».';
  }

  String adminAskSearch() {
    return '<b>Поиск человека</b>\n\n'
        'Пришли сообщением id — цифры, как в карточке, или @username — ник в Telegram. '
        'Можно переслать сюда его сообщение — подставлю id сам.';
  }

  String adminAskAddUser() {
    return '<b>Добавить на курс</b>\n\n'
        'Пришли числовой Telegram id человека (как в @userinfobot). '
        'Можно переслать сюда его сообщение — подставлю id сам.\n\n'
        'Карточку создам, если её ещё нет. Дальше из карточки: оплата, invite или убрать с курса.';
  }

  String adminNeedNumericId() {
    return 'Нужен числовой Telegram id или пересланное сообщение. '
        'По нику без карточки id не подставлю.';
  }

  String adminNotFound(String query, {bool canCreate = false}) {
    final buf = StringBuffer('Никого не нашёл по «${escapeHtml(query)}».');
    if (canCreate) {
      buf.write('\n\nЕсли это Telegram id — создай карточку кнопкой ниже.');
    }
    return buf.toString();
  }

  String adminCard({
    required UserProfile user,
    CourseOrder? order,
    ChannelAccess? access,
    List<ConversationLogEntry> dialog = const <ConversationLogEntry>[],
  }) {
    final buf = StringBuffer()
      ..writeln(_adminCardTitle(user))
      ..writeln('id <code>${user.userId}</code>')
      ..writeln(_adminSourceLine(user.source))
      ..writeln('сейчас: ${escapeHtml(_adminPhaseLabel(user.funnelPhase))}');
    for (final line in _adminOrderLines(order)) {
      buf.writeln(line);
    }
    buf
      ..writeln(_adminChannelLine(access))
      ..writeln(_adminWarmupLine(user.warmupOptOut))
      ..writeln(_adminBotLine(user.botBlocked));
    if (dialog.isNotEmpty) {
      buf.writeln('\nПоследние сообщения:');
      for (final entry in dialog.take(8)) {
        final dir = entry.direction == ConversationDirection.outbound ? '→' : '←';
        buf.writeln('$dir ${_dialogPreview(entry)}');
      }
    }
    return buf.toString();
  }

  String adminAskBroadcastContent() {
    return 'Пришли одним сообщением текст, фото, файл, видео или голосовое. Можно с подписью.';
  }

  String adminBroadcastPickSegment(Map<BroadcastSegment, int> counts) {
    final buf = StringBuffer()
      ..writeln('<b>Рассылка</b>')
      ..writeln()
      ..writeln('Кому отправить?')
      ..writeln();
    for (final segment in BroadcastSegment.values) {
      buf.writeln('${broadcastSegmentLabel(segment)} — ${counts[segment] ?? 0}');
    }
    return buf.toString().trim();
  }

  String adminBroadcastDraftSavedPickSegment() {
    return 'Сохранил черновик. Выбери сегмент.';
  }

  String adminBroadcastPreview({
    required BroadcastSegment segment,
    required int recipientCount,
    required BroadcastContentKind kind,
    String? previewText,
  }) {
    final buf = StringBuffer()
      ..writeln('<b>Превью</b>')
      ..writeln()
      ..writeln('Сегмент: ${escapeHtml(broadcastSegmentLabel(segment))}')
      ..writeln('Получателей: $recipientCount')
      ..write('Содержимое: ${escapeHtml(broadcastContentKindLabel(kind))}');
    final preview = previewText?.trim();
    if (preview != null && preview.isNotEmpty) {
      buf
        ..writeln()
        ..writeln()
        ..write(escapeHtml(_clipBroadcastPreview(preview)));
    }
    return buf.toString();
  }

  String adminBroadcastAlbumRejected() {
    return 'Пришли одно фото или файл, не альбом.';
  }

  String adminBroadcastEmptyRejected() {
    return 'Пришли текст или файл.';
  }

  String adminBroadcastCopyFailed() {
    return 'Не получилось показать превью. Пришли сообщение ещё раз.';
  }

  String adminBroadcastNeedDraft() {
    return 'Сначала пришли текст, фото, файл, видео или голосовое.';
  }

  String adminBroadcastDone({required int sent, required int failed, required int total}) {
    return '📣 Рассылка: отправлено $sent, ошибок $failed, в сегменте $total.';
  }

  String adminMarkedPaid() => '✅ Оплата проставлена вручную.';

  String adminCancelled() =>
      '🚫 Убрал с курса. Статус снят, invite отозван, из канала выкинул, если был.';

  String adminGuideSaved(String fileId) {
    return '📘 Гайд сохранён. file_id: <code>${escapeHtml(fileId)}</code>';
  }

  String adminGuideConfirm(String fileId) {
    return '💾 Сохранить этот файл как гайд запуска?\n'
        'file_id: <code>${escapeHtml(fileId)}</code>';
  }

  String adminGuideDiscarded() => 'Файл не сохранён как гайд.';

  String adminInviteReissued() => '🔗 Invite перевыдан.';

  String adminSheetsUpdated({Launch? launch}) {
    return adminSheetsRefreshResult(
      catalogAttempted: true,
      catalogOk: true,
      funnelAttempted: true,
      funnelOk: true,
      launch: launch,
    );
  }

  String adminSheetsRefreshResult({
    required bool catalogAttempted,
    required bool catalogOk,
    String? catalogError,
    required bool funnelAttempted,
    required bool funnelOk,
    String? funnelError,
    Launch? launch,
  }) {
    final buf = StringBuffer()
      ..writeln('<b>Таблица</b>')
      ..writeln();
    if (catalogAttempted) {
      if (catalogOk && launch != null) {
        buf.writeln('Набор в боте');
        final title = launch.title.trim();
        if (title.isNotEmpty) {
          buf.writeln('поток: ${escapeHtml(title)}');
        }
        buf.writeln('цена: ${formatRubFromKopecks(launch.priceFullKopecks)}');
        final start = _formatDate(launch.courseStartAt);
        if (start != null) {
          buf.writeln('старт: $start');
        }
      } else if (catalogOk) {
        buf.writeln('Набор в боте');
        buf.writeln('без изменений');
      } else {
        buf.writeln('Набор в боте');
        buf.writeln(
          'лист ${escapeHtml(CoursesSheet.tabTitle)}: не прочитался — '
          '${escapeHtml(catalogError ?? 'ошибка')}',
        );
      }
      buf.writeln();
    }
    if (funnelAttempted) {
      if (funnelOk) {
        buf.writeln('Воронка');
        buf.writeln('лист ВОРОНКА: цифры перезаписаны');
      } else {
        buf.writeln('Воронка');
        buf.writeln('лист ВОРОНКА: не обновился — ${escapeHtml(funnelError ?? 'ошибка')}');
      }
    }
    return buf.toString().trim();
  }

  String adminDeepLinks(List<AcquisitionLink> links) {
    final buf = StringBuffer()
      ..writeln('<b>Диплинки</b>')
      ..writeln();
    final bot = _botUsername?.trim() ?? '';
    if (bot.isEmpty) {
      buf.writeln('Username бота неизвестен — готовые t.me-ссылки не собрались. Метки:');
      buf.writeln();
    }
    for (final link in links) {
      buf.writeln('${escapeHtml(link.origin)} → ${escapeHtml(link.destinationLabel)}');
      if (bot.isEmpty) {
        buf.writeln('<code>${escapeHtml(link.payload)}</code>');
      } else {
        buf.writeln('<code>${escapeHtml(deepLink(link.payload))}</code>');
      }
      buf.writeln();
    }
    buf.write(
      'Те же ссылки на листе ${escapeHtml(LinksSheet.tabTitle)}. '
      'Новая метка (Stories, таргет) — строка на листе, затем '
      '«${MessageTemplates.buttonAdminSheets}» или снова «${MessageTemplates.buttonAdminLinks}».',
    );
    return buf.toString().trim();
  }

  String adminSheetsDisabled() {
    return '📊 Google Sheets не подключён. Проверь ключ, id таблицы и GOOGLE_SHEETS_WRITE_ENABLED.';
  }

  String adminSheetsFailed(String error) {
    return '📊 Не получилось обновить таблицу: ${escapeHtml(error)}';
  }

  static int? idFromCallback(String data, String prefix) {
    if (!data.startsWith(prefix)) {
      return null;
    }
    return int.tryParse(data.substring(prefix.length));
  }

  static BroadcastSegment? segmentFromCallback(String data) {
    if (!data.startsWith(cbBroadcastSegment)) {
      return null;
    }
    return BroadcastSegment.fromCode(data.substring(cbBroadcastSegment.length));
  }

  String broadcastSegmentLabel(BroadcastSegment segment) => switch (segment) {
    BroadcastSegment.allStarted => 'Все',
    BroadcastSegment.leadNoGuide => 'Зашли, без гайда',
    BroadcastSegment.guideNotPaid => 'Гайд, не купили',
    BroadcastSegment.checkoutOpen => 'Начали оплату',
    BroadcastSegment.depositPaid => 'Предоплата',
    BroadcastSegment.paidAccess => 'Оплатили / доступ',
    BroadcastSegment.cancelled => 'Отмена / возврат',
  };

  String broadcastSegmentButton(BroadcastSegment segment, int count) {
    return '${broadcastSegmentLabel(segment)} ($count)';
  }

  String broadcastContentKindLabel(BroadcastContentKind kind) => switch (kind) {
    BroadcastContentKind.text => 'текст',
    BroadcastContentKind.photo => 'фото',
    BroadcastContentKind.document => 'файл',
    BroadcastContentKind.video => 'видео',
    BroadcastContentKind.voice => 'голосовое',
    BroadcastContentKind.audio => 'аудио',
    BroadcastContentKind.animation => 'gif',
    BroadcastContentKind.sticker => 'стикер',
    BroadcastContentKind.videoNote => 'видеосообщение',
  };

  String _clipBroadcastPreview(String text) {
    if (text.length <= 200) {
      return text;
    }
    return '${text.substring(0, 200)}…';
  }

  String deepLink(String payload) {
    final bot = _botUsername;
    if (bot == null || bot.isEmpty) {
      return payload;
    }
    return 'https://t.me/$bot?start=$payload';
  }

  String _phaseLabel(FunnelPhase phase) => switch (phase) {
    FunnelPhase.lead => 'только зашёл',
    FunnelPhase.magnetIssued => 'гайд выдан',
    FunnelPhase.warming => 'в прогреве',
    FunnelPhase.checkout => 'оформление оплаты',
    FunnelPhase.depositPaid => 'есть предоплата',
    FunnelPhase.paid => 'оплачено',
    FunnelPhase.accessGranted => 'доступ в канал есть',
    FunnelPhase.cancelled => 'оплата отменена',
  };

  String _adminPhaseLabel(FunnelPhase phase) => switch (phase) {
    FunnelPhase.lead => 'пришёл, без гайда',
    FunnelPhase.magnetIssued => 'гайд выдан',
    FunnelPhase.warming => 'в прогреве',
    FunnelPhase.checkout => 'оформляет оплату',
    FunnelPhase.depositPaid => 'внесена предоплата',
    FunnelPhase.paid => 'оплачено полностью',
    FunnelPhase.accessGranted => 'доступ в канал выдан',
    FunnelPhase.cancelled => 'оплата отменена',
  };

  String _adminCardTitle(UserProfile user) {
    final name = user.firstName?.trim();
    final handle = user.username?.trim();
    final parts = <String>[];
    if (name != null && name.isNotEmpty) {
      parts.add(escapeHtml(name));
    }
    if (handle != null && handle.isNotEmpty) {
      parts.add('@${escapeHtml(handle)}');
    }
    if (parts.isEmpty) {
      return '<b>Карточка</b>';
    }
    return '<b>Карточка</b> ${parts.join(' · ')}';
  }

  String _adminSourceLine(String? source) {
    final raw = source?.trim();
    if (raw == null || raw.isEmpty) {
      return 'источник: без метки';
    }
    final label = _adminSourceLabel(raw);
    if (label == raw) {
      return 'источник: <code>${escapeHtml(raw)}</code>';
    }
    return 'источник: $label · <code>${escapeHtml(raw)}</code>';
  }

  String _adminSourceLabel(String raw) => switch (raw) {
    'ig_reels_guide' => 'Instagram Reels',
    'threads_guide' => 'Threads',
    'tg_announce' => 'Telegram, анонс',
    'direct_course' => 'прямая ссылка',
    'ig_stories_guide' => 'Stories',
    'email_guide' => 'рассылка',
    AcquisitionSource.adminManual => 'админ',
    _ => raw,
  };

  Iterable<String> _adminOrderLines(CourseOrder? order) {
    if (order == null) {
      return const <String>['заказ: нет'];
    }
    final lines = <String>[
      'заказ: #${order.id} · ${_adminPaymentKindLabel(order.kind)} · '
          '${_adminOrderStatusLabel(order.status)}',
      'оплачено ${formatRubFromKopecks(order.amountPaidKopecks)} '
          'из ${formatRubFromKopecks(order.priceFullKopecks)}',
    ];
    if (order.hasRemainder) {
      final due = _formatDate(order.dueAt) ?? 'срок не указан';
      lines.add('остаток ${formatRubFromKopecks(order.amountDueKopecks)} · до $due');
    }
    return lines;
  }

  String _adminPaymentKindLabel(PaymentKind kind) => switch (kind) {
    PaymentKind.full => 'полная оплата',
    PaymentKind.deposit => 'предоплата',
    PaymentKind.remainder => 'доплата',
    PaymentKind.installment => 'рассрочка',
  };

  String _adminOrderStatusLabel(OrderStatus status) => switch (status) {
    OrderStatus.checkoutStarted => 'оформление начато',
    OrderStatus.awaitingPayment => 'ждёт оплату',
    OrderStatus.depositPaid => 'внесена предоплата',
    OrderStatus.paid => 'оплачено',
    OrderStatus.cancelled => 'отменён',
  };

  String _adminChannelLine(ChannelAccess? access) {
    if (access == null) {
      return 'канал: нет доступа';
    }
    if (access.revokedAt != null) {
      if (access.joinedAt != null) {
        return 'канал: был вход ${_formatMoscowDateTime(access.joinedAt!)}, invite отозван';
      }
      return 'канал: invite отозван, входа не было';
    }
    if (access.hasJoined) {
      return 'канал: вошёл ${_formatMoscowDateTime(access.joinedAt!)}';
    }
    final link = access.inviteLink?.trim();
    if (link == null || link.isEmpty) {
      return 'канал: ссылка не выдана';
    }
    return 'канал: ссылка выдана, входа нет';
  }

  String _adminWarmupLine(bool optOut) {
    return optOut ? 'прогрев: не шлём («Не писать»)' : 'прогрев: идёт';
  }

  String _adminBotLine(bool blocked) {
    return blocked ? 'бот: заблокирован' : 'бот: на связи';
  }

  String _dialogPreview(ConversationLogEntry entry) {
    final preview = entry.textPreview?.trim();
    if (preview != null && preview.isNotEmpty) {
      return escapeHtml(preview);
    }
    return _conversationContentLabel(entry.contentType);
  }

  String _conversationContentLabel(ConversationContentType type) => switch (type) {
    ConversationContentType.text => 'текст',
    ConversationContentType.photo => 'фото',
    ConversationContentType.document => 'файл',
    ConversationContentType.video => 'видео',
    ConversationContentType.other => 'сообщение',
    ConversationContentType.copy => 'копия',
  };

  String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _date.format(value.toUtc());
  }

  String _formatMoscowDateTime(DateTime value) {
    final moscow = value.toUtc().add(const Duration(hours: _moscowOffsetHours));
    return _dateTime.format(moscow);
  }

  String? _formatPrice(int? kopecks) {
    if (kopecks == null || kopecks <= 0) {
      return null;
    }
    return formatRubFromKopecks(kopecks);
  }
}
