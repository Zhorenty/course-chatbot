import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/google_sheets_funnel_dashboard.dart';
import 'package:course_chatbot/src/data/google_sheets_writer.dart';
import 'package:l/l.dart';

final class GoogleSheetsFunnelExportJob {
  GoogleSheetsFunnelExportJob({
    required CourseRepository course,
    required GoogleSheetsWriter writer,
    this.sheetTitle = GoogleSheetsFunnelDashboard.defaultSheetTitle,
    DateTime Function()? nowProvider,
  })  : _course = course,
        _writer = writer,
        _nowProvider = nowProvider ?? DateTime.now;

  final CourseRepository _course;
  final GoogleSheetsWriter _writer;
  final String sheetTitle;
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    try {
      final analytics = _course.funnelAnalytics(now: _nowProvider());
      final dashboard = GoogleSheetsFunnelDashboard.build(analytics, sheetTitle: sheetTitle);
      await _writer.replaceDashboard(dashboard);
      l.i(
        'Google Sheets FUNNEL export completed. '
        'sheet=${dashboard.sheetTitle} charts=${dashboard.charts.length}',
      );
    } on Object catch (error, stackTrace) {
      l.w('Google Sheets export failed: $error', stackTrace);
    }
  }
}
