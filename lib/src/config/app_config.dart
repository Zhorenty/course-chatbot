import 'dart:io';

import 'package:args/args.dart';

enum PaymentProvider { leadpay, yookassa, manual }

final class AppConfig {
  const AppConfig({
    required this.botToken,
    required this.pollTimeoutSeconds,
    this.sqlitePath = 'data/course.sqlite',
    required this.adminUserIds,
    required this.adminChatId,
    required this.logLevel,
    this.timezoneOffsetHours = 3,
    this.quietHoursFrom = 10,
    this.quietHoursTo = 21,
    this.warmupEnabled = true,
    this.courseChannelId,
    this.leadMagnetFileId,
    this.paymentProvider = PaymentProvider.leadpay,
    this.leadpayToken,
    this.yookassaShopId,
    this.yookassaSecretKey,
    this.paymentWebhookBind = '127.0.0.1:8080',
    this.leadMagnetUrl,
    this.offerUrl,
    this.productCode = 'course',
    this.launchCode = 'launch-1',
    this.priceFullRub = 0,
    this.depositAmountRub = 0,
    this.depositDueDays = 7,
    this.abandonFirstDelayHours = 6,
    this.abandonSecondDelayHours = 24,
    this.yookassaReturnUrl,
    this.googleSheetsWriteEnabled = false,
    this.googleSheetsCredentialsPath,
    this.googleSheetsCredentialsJson,
    this.googleSheetsSpreadsheetId,
    this.googleSheetsWriteSheetTitle = 'FUNNEL',
    this.googleSheetsWriteIntervalSeconds = 300,
    this.paymentWebhookSecret,
    this.paymentWebhookPath = '/payments/callback',
    this.sqliteBackupEnabled = true,
    this.sqliteBackupDir = 'data/backups',
    this.sqliteBackupKeep = 7,
    this.sqliteBackupIntervalHours = 24,
  });

  final String botToken;
  final int pollTimeoutSeconds;
  final String sqlitePath;
  final Set<int> adminUserIds;
  final int? adminChatId;
  final String logLevel;
  final int timezoneOffsetHours;
  final int quietHoursFrom;
  final int quietHoursTo;
  final bool warmupEnabled;
  final int? courseChannelId;
  final String? leadMagnetFileId;
  final String? leadMagnetUrl;
  final String? offerUrl;
  final String productCode;
  final String launchCode;
  final int priceFullRub;
  final int depositAmountRub;
  final int depositDueDays;
  final int abandonFirstDelayHours;
  final int abandonSecondDelayHours;
  final String? yookassaReturnUrl;
  final PaymentProvider paymentProvider;
  final String? leadpayToken;
  final String? yookassaShopId;
  final String? yookassaSecretKey;
  final String paymentWebhookBind;
  final bool googleSheetsWriteEnabled;
  final String? googleSheetsCredentialsPath;
  final String? googleSheetsCredentialsJson;
  final String? googleSheetsSpreadsheetId;
  final String googleSheetsWriteSheetTitle;
  final int googleSheetsWriteIntervalSeconds;
  final String? paymentWebhookSecret;
  final String paymentWebhookPath;
  final bool sqliteBackupEnabled;
  final String sqliteBackupDir;
  final int sqliteBackupKeep;
  final int sqliteBackupIntervalHours;

  bool get usesLiveKassa {
    switch (paymentProvider) {
      case PaymentProvider.leadpay:
        return leadpayToken != null && leadpayToken!.trim().isNotEmpty;
      case PaymentProvider.yookassa:
        return (yookassaShopId?.trim().isNotEmpty ?? false) &&
            (yookassaSecretKey?.trim().isNotEmpty ?? false);
      case PaymentProvider.manual:
        return false;
    }
  }

  List<String> validationErrors() {
    final errors = <String>[];
    if (adminUserIds.isEmpty) {
      errors.add('ADMIN_USER_IDS is required (comma-separated Telegram user ids).');
    }
    if (usesLiveKassa && (paymentWebhookSecret == null || paymentWebhookSecret!.trim().isEmpty)) {
      errors.add(
        'PAYMENT_WEBHOOK_SECRET is required when a kassa is configured. '
        'Put the secret in the callback URL or X-Webhook-Secret header.',
      );
    }
    return errors;
  }

  static AppConfig fromArgs(List<String> args) {
    final parser = ArgParser()
      ..addFlag('help', abbr: 'h', negatable: false)
      ..addOption('token', abbr: 't', help: 'Telegram bot token')
      ..addOption('poll-timeout-seconds', help: 'Long polling timeout in seconds')
      ..addOption('admin-user-ids', help: 'Comma-separated Telegram user ids')
      ..addOption('admin-chat-id', help: 'Telegram chat id for admin notifications')
      ..addOption('bookings-db-path', help: 'SQLite path')
      ..addOption('timezone-offset-hours', help: 'Business timezone offset (default: 3)')
      ..addOption('quiet-hours-from', help: 'Outgoing jobs silent before this hour (default: 10)')
      ..addOption('quiet-hours-to', help: 'Outgoing jobs silent from this hour (default: 21)')
      ..addOption('warmup-enabled', help: 'Enable drip after lead magnet (default: true)')
      ..addOption('course-channel-id', help: 'Closed channel id for this launch')
      ..addOption('lead-magnet-file-id', help: 'Telegram file_id of the guide PDF')
      ..addOption('lead-magnet-url', help: 'Fallback URL if PDF file_id is empty')
      ..addOption('offer-url', help: 'Offer / terms URL shown before checkout')
      ..addOption('product-code', help: 'Product code in SQLite (default: course)')
      ..addOption('launch-code', help: 'Launch code in SQLite (default: launch-1)')
      ..addOption('price-full-rub', help: 'Full course price in RUB')
      ..addOption('deposit-amount-rub', help: 'Deposit amount in RUB (0 = no deposit)')
      ..addOption('deposit-due-days', help: 'Days until remainder is due (default: 7)')
      ..addOption('abandon-first-delay-hours', help: 'First abandoned-payment nudge hours')
      ..addOption('abandon-second-delay-hours', help: 'Second abandoned-payment nudge hours')
      ..addOption('yookassa-return-url', help: 'Redirect after YooKassa checkout')
      ..addOption('payment-provider', help: 'leadpay | yookassa | manual')
      ..addOption('leadpay-token', help: 'LeadPay token for external systems')
      ..addOption('yookassa-shop-id', help: 'YooKassa shop id')
      ..addOption('yookassa-secret-key', help: 'YooKassa secret key')
      ..addOption('payment-webhook-bind', help: 'Local bind for payment callbacks')
      ..addOption('payment-webhook-secret', help: 'Shared secret for kassa callbacks')
      ..addOption('payment-webhook-path', help: 'Callback path (default: /payments/callback)')
      ..addOption('sqlite-backup-enabled', help: 'Periodic VACUUM INTO backups (default: true)')
      ..addOption('sqlite-backup-dir', help: 'Directory for SQLite backups')
      ..addOption('sqlite-backup-keep', help: 'How many backup files to keep (default: 7)')
      ..addOption(
        'sqlite-backup-interval-hours',
        help: 'Hours between SQLite backups (default: 24)',
      )
      ..addOption('google-sheets-write-enabled', help: 'Export funnel slice (default: false)')
      ..addOption('google-sheets-credentials-path', help: 'Service-account JSON path')
      ..addOption('google-sheets-credentials-json', help: 'Inline service-account JSON')
      ..addOption('google-sheets-spreadsheet-id', help: 'Spreadsheet id')
      ..addOption('google-sheets-write-sheet-title', help: 'Dashboard tab (default: FUNNEL)')
      ..addOption('google-sheets-write-interval-seconds', help: 'Export interval (default: 300)')
      ..addOption('log-level', help: 'debug/info/warn/error');

    final result = parser.parse(args);
    if (result['help'] == true) {
      stdout
        ..writeln('Course launch Telegram bot')
        ..writeln()
        ..writeln(parser.usage);
      exit(0);
    }

    final dotenv = _readDotEnv();
    final env = Platform.environment;

    String? resolve(String key, String cliName) {
      if (result.wasParsed(cliName)) {
        return result[cliName]?.toString();
      }
      if (env[key] case final String value when value.isNotEmpty) {
        return value;
      }
      if (dotenv[key] case final String value when value.isNotEmpty) {
        return value;
      }
      return null;
    }

    final token = resolve('BOT_TOKEN', 'token');
    if (token == null || token.isEmpty) {
      stderr.writeln('Missing bot token. Use --token or BOT_TOKEN.');
      exit(2);
    }

    final providerRaw = resolve('PAYMENT_PROVIDER', 'payment-provider');
    final paymentProvider = _parsePaymentProvider(providerRaw);
    if (paymentProvider == null) {
      stderr.writeln(
        'Unknown PAYMENT_PROVIDER="$providerRaw". Use leadpay, yookassa, or manual.',
      );
      exit(2);
    }

    return AppConfig(
      botToken: token,
      pollTimeoutSeconds:
          int.tryParse(resolve('POLL_TIMEOUT_SECONDS', 'poll-timeout-seconds') ?? '')
                  ?.clamp(5, 60) ??
              25,
      sqlitePath: resolve('BOOKINGS_DB_PATH', 'bookings-db-path') ?? 'data/course.sqlite',
      adminUserIds: _parseIntSet(resolve('ADMIN_USER_IDS', 'admin-user-ids')),
      adminChatId: int.tryParse(resolve('ADMIN_CHAT_ID', 'admin-chat-id') ?? ''),
      logLevel: resolve('LOG_LEVEL', 'log-level') ?? 'info',
      timezoneOffsetHours:
          int.tryParse(resolve('TIMEZONE_OFFSET_HOURS', 'timezone-offset-hours') ?? '')
                  ?.clamp(-12, 14) ??
              3,
      quietHoursFrom:
          int.tryParse(resolve('QUIET_HOURS_FROM', 'quiet-hours-from') ?? '')?.clamp(0, 23) ?? 10,
      quietHoursTo:
          int.tryParse(resolve('QUIET_HOURS_TO', 'quiet-hours-to') ?? '')?.clamp(0, 23) ?? 21,
      warmupEnabled: _toBool(resolve('WARMUP_ENABLED', 'warmup-enabled'), defaultValue: true),
      courseChannelId: int.tryParse(resolve('COURSE_CHANNEL_ID', 'course-channel-id') ?? ''),
      leadMagnetFileId: resolve('LEAD_MAGNET_FILE_ID', 'lead-magnet-file-id'),
      leadMagnetUrl: resolve('LEAD_MAGNET_URL', 'lead-magnet-url'),
      offerUrl: resolve('OFFER_URL', 'offer-url'),
      productCode: resolve('PRODUCT_CODE', 'product-code') ?? 'course',
      launchCode: resolve('LAUNCH_CODE', 'launch-code') ?? 'launch-1',
      priceFullRub:
          int.tryParse(resolve('PRICE_FULL_RUB', 'price-full-rub') ?? '')?.clamp(0, 100000000) ?? 0,
      depositAmountRub: int.tryParse(resolve('DEPOSIT_AMOUNT_RUB', 'deposit-amount-rub') ?? '')
              ?.clamp(0, 100000000) ??
          0,
      depositDueDays:
          int.tryParse(resolve('DEPOSIT_DUE_DAYS', 'deposit-due-days') ?? '')?.clamp(1, 365) ?? 7,
      abandonFirstDelayHours:
          int.tryParse(resolve('ABANDON_FIRST_DELAY_HOURS', 'abandon-first-delay-hours') ?? '')
                  ?.clamp(1, 72) ??
              6,
      abandonSecondDelayHours:
          int.tryParse(resolve('ABANDON_SECOND_DELAY_HOURS', 'abandon-second-delay-hours') ?? '')
                  ?.clamp(2, 168) ??
              24,
      yookassaReturnUrl: resolve('YOOKASSA_RETURN_URL', 'yookassa-return-url'),
      paymentProvider: paymentProvider,
      leadpayToken: resolve('LEADPAY_TOKEN', 'leadpay-token'),
      yookassaShopId: resolve('YOOKASSA_SHOP_ID', 'yookassa-shop-id'),
      yookassaSecretKey: resolve('YOOKASSA_SECRET_KEY', 'yookassa-secret-key'),
      paymentWebhookBind:
          resolve('PAYMENT_WEBHOOK_BIND', 'payment-webhook-bind') ?? '127.0.0.1:8080',
      googleSheetsWriteEnabled: _toBool(
          resolve('GOOGLE_SHEETS_WRITE_ENABLED', 'google-sheets-write-enabled'),
          defaultValue: false),
      googleSheetsCredentialsPath:
          resolve('GOOGLE_SHEETS_CREDENTIALS_PATH', 'google-sheets-credentials-path'),
      googleSheetsCredentialsJson:
          resolve('GOOGLE_SHEETS_CREDENTIALS_JSON', 'google-sheets-credentials-json'),
      googleSheetsSpreadsheetId:
          resolve('GOOGLE_SHEETS_SPREADSHEET_ID', 'google-sheets-spreadsheet-id'),
      googleSheetsWriteSheetTitle:
          resolve('GOOGLE_SHEETS_WRITE_SHEET_TITLE', 'google-sheets-write-sheet-title') ?? 'FUNNEL',
      googleSheetsWriteIntervalSeconds: int.tryParse(
            resolve('GOOGLE_SHEETS_WRITE_INTERVAL_SECONDS',
                    'google-sheets-write-interval-seconds') ??
                '',
          )?.clamp(30, 86400) ??
          300,
      paymentWebhookSecret: resolve('PAYMENT_WEBHOOK_SECRET', 'payment-webhook-secret'),
      paymentWebhookPath:
          resolve('PAYMENT_WEBHOOK_PATH', 'payment-webhook-path') ?? '/payments/callback',
      sqliteBackupEnabled: _toBool(
        resolve('SQLITE_BACKUP_ENABLED', 'sqlite-backup-enabled'),
        defaultValue: true,
      ),
      sqliteBackupDir: resolve('SQLITE_BACKUP_DIR', 'sqlite-backup-dir') ?? 'data/backups',
      sqliteBackupKeep:
          int.tryParse(resolve('SQLITE_BACKUP_KEEP', 'sqlite-backup-keep') ?? '')?.clamp(1, 30) ??
              7,
      sqliteBackupIntervalHours: int.tryParse(
            resolve('SQLITE_BACKUP_INTERVAL_HOURS', 'sqlite-backup-interval-hours') ?? '',
          )?.clamp(1, 168) ??
          24,
    );
  }
}

Map<String, String> _readDotEnv() {
  final file = File('.env');
  if (!file.existsSync()) {
    return const <String, String>{};
  }

  final map = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final idx = trimmed.indexOf('=');
    if (idx <= 0) {
      continue;
    }
    final key = trimmed.substring(0, idx).trim();
    final value = _stripOptionalQuotes(trimmed.substring(idx + 1).trim());
    map[key] = value;
  }
  return map;
}

String _stripOptionalQuotes(String value) {
  if (value.length < 2) {
    return value;
  }
  final startsAndEndsWithSingle = value.startsWith("'") && value.endsWith("'");
  final startsAndEndsWithDouble = value.startsWith('"') && value.endsWith('"');
  if (startsAndEndsWithSingle || startsAndEndsWithDouble) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

bool _toBool(String? value, {required bool defaultValue}) {
  if (value == null) {
    return defaultValue;
  }
  switch (value.trim().toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
    case 'on':
      return true;
    case '0':
    case 'false':
    case 'no':
    case 'off':
      return false;
    default:
      return defaultValue;
  }
}

PaymentProvider? _parsePaymentProvider(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'yookassa':
    case 'yoo_kassa':
      return PaymentProvider.yookassa;
    case 'manual':
      return PaymentProvider.manual;
    case 'leadpay':
    case null:
    case '':
      return PaymentProvider.leadpay;
    default:
      return null;
  }
}

Set<int> _parseIntSet(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const <int>{};
  }
  return raw.split(',').map((item) => int.tryParse(item.trim())).whereType<int>().toSet();
}
