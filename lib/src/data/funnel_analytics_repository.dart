import 'package:course_chatbot/src/domain/funnel_analytics.dart';

abstract interface class FunnelAnalyticsRepository {
  FunnelAnalytics funnelAnalytics({required DateTime now, int? launchId});

  FunnelDaySlice funnelDaySlice({required DateTime fromUtc, required DateTime toExclusiveUtc});
}
