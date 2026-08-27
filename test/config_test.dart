import 'package:course_chatbot/src/config/app_config.dart';
import 'package:test/test.dart';

void main() {
  test('live kassa without webhook secret fails validation', () {
    const config = AppConfig(
      botToken: 't',
      pollTimeoutSeconds: 25,
      adminUserIds: {1},
      adminChatId: null,
      logLevel: 'info',
      leadpayToken: 'token',
    );
    expect(
      config.validationErrors().any((error) => error.contains('PAYMENT_WEBHOOK_SECRET')),
      isTrue,
    );
  });

  test('empty admin list fails validation', () {
    const config = AppConfig(
      botToken: 't',
      pollTimeoutSeconds: 25,
      adminUserIds: {},
      adminChatId: null,
      logLevel: 'info',
    );
    expect(
      config.validationErrors().any((error) => error.contains('ADMIN_USER_IDS')),
      isTrue,
    );
  });

  test('manual provider without secret is valid when admins are set', () {
    const config = AppConfig(
      botToken: 't',
      pollTimeoutSeconds: 25,
      adminUserIds: {1},
      adminChatId: null,
      logLevel: 'info',
      paymentProvider: PaymentProvider.manual,
    );
    expect(config.validationErrors(), isEmpty);
  });

  test('defaults are 18000 / 5000 and remainder due 5 Oct 2026 MSK', () {
    const config = AppConfig(
      botToken: 't',
      pollTimeoutSeconds: 25,
      adminUserIds: {1},
      adminChatId: null,
      logLevel: 'info',
    );
    expect(config.priceFullRub, 18000);
    expect(config.depositAmountRub, 5000);
    expect(config.depositDueAt, DateTime.utc(2026, 10, 5, 20, 59, 59));
    expect(config.courseStartAt, DateTime.utc(2026, 10, 12));
  });
}
