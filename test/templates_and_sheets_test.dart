import 'package:course_chatbot/src/data/google_sheets_funnel_dashboard.dart';
import 'package:course_chatbot/src/domain/funnel_analytics.dart';
import 'package:course_chatbot/src/messages/message_templates.dart';
import 'package:test/test.dart';

void main() {
  test('enroll CTA stays in templates until access is granted', () {
    final templates = MessageTemplates();
    expect(templates.warmupStep('warmup_0'), contains('записаться'));
    expect(MessageTemplates.buttonEnroll, contains('Записаться'));
  });

  test('FUNNEL dashboard has course steps not club quiz', () {
    final dashboard = GoogleSheetsFunnelDashboard.build(
      FunnelAnalytics(
        generatedAt: DateTime.utc(2026, 8, 26, 12),
        startedUsersTotal: 10,
        funnelUsers: 9,
        guideTaken: 8,
        checkoutStarted: 3,
        paidUsers: 1,
        startedLast7Days: 4,
        startedLast30Days: 10,
        paidLast7Days: 1,
        paidLast30Days: 1,
        phaseCounts: const <String, int>{'warming': 5, 'paid': 1},
        sourceCounts: const <String, int>{'ig_reels_guide': 6, 'direct_course': 4},
      ),
    );
    final flat = dashboard.rows.map((row) => row.join(' ')).join('\n');
    expect(flat, contains('Взяли гайд'));
    expect(flat, contains('Instagram Reels'));
    expect(flat, isNot(contains('квиз')));
    expect(dashboard.charts, isNotEmpty);
  });
}
