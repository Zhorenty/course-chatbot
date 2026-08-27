import 'dart:io';

import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:intl/intl.dart';
import 'package:l/l.dart';

final class SqliteMaintenanceJob {
  SqliteMaintenanceJob({
    required SqliteDatabaseHandle databaseHandle,
    required CourseRepository course,
    required JobDedupeRepository dedupe,
    required String sqlitePath,
    required String backupDir,
    this.keep = 7,
    this.interval = const Duration(hours: 24),
    this.backupEnabled = true,
    DateTime Function()? nowProvider,
  }) : _handle = databaseHandle,
       _course = course,
       _dedupe = dedupe,
       _sqlitePath = sqlitePath,
       _backupDir = backupDir,
       _nowProvider = nowProvider ?? DateTime.now;

  final SqliteDatabaseHandle _handle;
  final CourseRepository _course;
  final JobDedupeRepository _dedupe;
  final String _sqlitePath;
  final String _backupDir;
  final int keep;
  final Duration interval;
  final bool backupEnabled;
  final DateTime Function() _nowProvider;

  Future<void> run() async {
    final now = _nowProvider();
    _dedupe.cleanupOlderThan(const Duration(days: 30));
    _course.pruneConversationLog(olderThan: now.subtract(const Duration(days: 90)));
    if (!backupEnabled || _sqlitePath == ':memory:') {
      return;
    }
    if (!_backupDue(now)) {
      return;
    }
    await _backup(now);
    _pruneOldBackups();
  }

  bool _backupDue(DateTime now) {
    final dir = Directory(_backupDir);
    if (!dir.existsSync()) {
      return true;
    }
    final files =
        dir.listSync().whereType<File>().where((file) => file.path.endsWith('.sqlite')).toList()
          ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    if (files.isEmpty) {
      return true;
    }
    return now.difference(files.first.lastModifiedSync()) >= interval;
  }

  Future<void> _backup(DateTime now) async {
    final dir = Directory(_backupDir);
    dir.createSync(recursive: true);
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(now.toUtc());
    final target = File('${dir.path}/course-$stamp.sqlite');
    if (target.existsSync()) {
      target.deleteSync();
    }
    final escaped = target.path.replaceAll("'", "''");
    try {
      _handle.database.execute('PRAGMA wal_checkpoint(TRUNCATE);');
    } on Object catch (error, stackTrace) {
      l.w('WAL checkpoint before backup failed: $error', stackTrace);
    }
    _handle.database.execute("VACUUM INTO '$escaped';");
    l.i('SQLite backup written to ${target.path}');
  }

  void _pruneOldBackups() {
    final dir = Directory(_backupDir);
    if (!dir.existsSync()) {
      return;
    }
    final files =
        dir.listSync().whereType<File>().where((file) => file.path.endsWith('.sqlite')).toList()
          ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (final extra in files.skip(keep)) {
      extra.deleteSync();
    }
  }
}
