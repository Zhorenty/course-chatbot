import 'dart:io';

import 'package:args/args.dart';

enum PaymentProvider { leadpay, yookassa, manual }

final class AppConfig {
  /// Secrets and Telegram ids come from CLI / env / `.env`.
  /// Quiet hours, backups, and offline test fallbacks are constructor defaults.
  /// Live launch price/dates come from Google Sheets `COURSES` (gid=0).
  const AppConfig({
    required this.botToken,
    this.pollTimeoutSeconds = 25,
    this.sqlitePath = 'data/course.sqlite',
    required this.adminUserIds,
    required this.adminChatId,
    this.logLevel = 'info',
    this.timezoneOffsetHours = 3,
    this.quietHoursFrom = 10,
    this.quietHoursTo = 21,
    this.warmupEnabled = true,
    this.courseChannelId,
    this.leadMagnetFileId,
    this.leadMagnetUrl,
    this.leadMagnetPath = 'assets/guide.pdf',
    this.leadMagnetFilename = 'Гайд Язык цвета.pdf',
    this.paymentProvider = PaymentProvider.leadpay,
    this.leadpayToken,
    this.yookassaShopId,
    this.yookassaSecretKey,
    this.paymentWebhookBind = '127.0.0.1:8080',
    this.offerUrl,
    this.productCode = 'course',
    this.launchCode = 'launch-1',
    this.priceFullRub = 18000,
    this.depositAmountRub = 5000,
    this.depositDueDays = 7,
    this.depositDueDate = '2026-10-05',
    this.courseStartDate = '2026-10-12',
    this.abandonFirstDelayHours = 6,
    this.abandonSecondDelayHours = 24,
    this.yookassaReturnUrl,
    this.googleSheetsWriteEnabled = false,
    this.googleSheetsCredentialsPath,
    this.googleSheetsCredentialsJson,
    this.googleSheetsSpreadsheetId,
    this.googleSheetsWriteSheetTitle = 'ВОРОНКА',
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
  final String? leadMagnetPath;
  final String leadMagnetFilename;
  final String? offerUrl;
  final String productCode;
  final String launchCode;
  final int priceFullRub;
  final int depositAmountRub;
  final int depositDueDays;
  final String? depositDueDate;
  final String? courseStartDate;
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

  DateTime? get depositDueAt =>
      parseIsoDateEndOfDay(depositDueDate, timezoneOffsetHours: timezoneOffsetHours);

  DateTime? get courseStartAt => parseIsoDate(courseStartDate);

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
      ..addOption('admin-user-ids', help: 'Comma-separated Telegram user ids')
      ..addOption('admin-chat-id', help: 'Telegram chat id for admin notifications')
      ..addOption('course-channel-id', help: 'Closed channel id for this launch')
      ..addOption('lead-magnet-file-id', help: 'Telegram file_id of the guide PDF')
      ..addOption('offer-url', help: 'Offer / terms URL shown before checkout')
      ..addOption('yookassa-return-url', help: 'Redirect after YooKassa checkout')
      ..addOption('payment-provider', help: 'leadpay | yookassa | manual')
      ..addOption('leadpay-token', help: 'LeadPay token for external systems')
      ..addOption('yookassa-shop-id', help: 'YooKassa shop id')
      ..addOption('yookassa-secret-key', help: 'YooKassa secret key')
      ..addOption('payment-webhook-bind', help: 'Local bind for payment callbacks')
      ..addOption('payment-webhook-secret', help: 'Shared secret for kassa callbacks')
      ..addOption('google-sheets-write-enabled', help: 'Export funnel slice (default: false)')
      ..addOption('google-sheets-credentials-path', help: 'Service-account JSON path')
      ..addOption('google-sheets-credentials-json', help: 'Inline service-account JSON')
      ..addOption('google-sheets-spreadsheet-id', help: 'Spreadsheet id')
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
      stderr.writeln('Unknown PAYMENT_PROVIDER="$providerRaw". Use leadpay, yookassa, or manual.');
      exit(2);
    }

    return AppConfig(
      botToken: token,
      adminUserIds: _parseIntSet(resolve('ADMIN_USER_IDS', 'admin-user-ids')),
      adminChatId: int.tryParse(resolve('ADMIN_CHAT_ID', 'admin-chat-id') ?? ''),
      logLevel: resolve('LOG_LEVEL', 'log-level') ?? 'info',
      courseChannelId: int.tryParse(resolve('COURSE_CHANNEL_ID', 'course-channel-id') ?? ''),
      leadMagnetFileId: resolve('LEAD_MAGNET_FILE_ID', 'lead-magnet-file-id'),
      offerUrl: resolve('OFFER_URL', 'offer-url'),
      yookassaReturnUrl: resolve('YOOKASSA_RETURN_URL', 'yookassa-return-url'),
      paymentProvider: paymentProvider,
      leadpayToken: resolve('LEADPAY_TOKEN', 'leadpay-token'),
      yookassaShopId: resolve('YOOKASSA_SHOP_ID', 'yookassa-shop-id'),
      yookassaSecretKey: resolve('YOOKASSA_SECRET_KEY', 'yookassa-secret-key'),
      paymentWebhookBind:
          resolve('PAYMENT_WEBHOOK_BIND', 'payment-webhook-bind') ?? '127.0.0.1:8080',
      googleSheetsWriteEnabled: _toBool(
        resolve('GOOGLE_SHEETS_WRITE_ENABLED', 'google-sheets-write-enabled'),
        defaultValue: false,
      ),
      googleSheetsCredentialsPath: resolve(
        'GOOGLE_SHEETS_CREDENTIALS_PATH',
        'google-sheets-credentials-path',
      ),
      googleSheetsCredentialsJson: resolve(
        'GOOGLE_SHEETS_CREDENTIALS_JSON',
        'google-sheets-credentials-json',
      ),
      googleSheetsSpreadsheetId: resolve(
        'GOOGLE_SHEETS_SPREADSHEET_ID',
        'google-sheets-spreadsheet-id',
      ),
      paymentWebhookSecret: resolve('PAYMENT_WEBHOOK_SECRET', 'payment-webhook-secret'),
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

final _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

DateTime? parseIsoDate(String? raw) {
  final match = _isoDate.firstMatch(raw?.trim() ?? '');
  if (match == null) {
    return null;
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  return DateTime.utc(year, month, day);
}

/// End of the calendar day in the business timezone, stored as UTC.
DateTime? parseIsoDateEndOfDay(String? raw, {required int timezoneOffsetHours}) {
  final date = parseIsoDate(raw);
  if (date == null) {
    return null;
  }
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    23,
    59,
    59,
  ).subtract(Duration(hours: timezoneOffsetHours));
}
