import 'package:course_chatbot/src/data/job_dedupe_repository.dart';
import 'package:course_chatbot/src/data/sqlite/sqlite_database_handle.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('tryClaim is idempotent for the same key', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.dispose);
    final handle = SqliteDatabaseHandle.fromDatabase(db, path: ':memory:');
    final repo = JobDedupeRepository(databaseHandle: handle)..initSchema();

    expect(repo.tryClaim('warmup:1:0'), isTrue);
    expect(repo.tryClaim('warmup:1:0'), isFalse);
  });
}
