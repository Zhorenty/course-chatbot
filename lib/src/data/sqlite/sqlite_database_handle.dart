import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

bool _linuxSqliteOverrideApplied = false;

/// Ubuntu runtime images ship `libsqlite3.so.0`, while `package:sqlite3`
/// dlopens `libsqlite3.so` (the unversioned symlink from `-dev`).
void _ensureSqliteNativeLibrary() {
  if (_linuxSqliteOverrideApplied || !Platform.isLinux) {
    return;
  }
  _linuxSqliteOverrideApplied = true;
  open.overrideFor(OperatingSystem.linux, () {
    try {
      return DynamicLibrary.open('libsqlite3.so');
    } on ArgumentError {
      return DynamicLibrary.open('libsqlite3.so.0');
    }
  });
}

/// Shared SQLite connection for funnel/order/payment repositories.
final class SqliteDatabaseHandle {
  SqliteDatabaseHandle._(this._db, {required this.path, required this.ownsConnection});

  factory SqliteDatabaseHandle.open(String path, {int busyTimeoutMs = 5000}) {
    _ensureSqliteNativeLibrary();
    final file = File(path);
    file.parent.createSync(recursive: true);
    final db = sqlite3.open(path);
    db.execute('PRAGMA busy_timeout=$busyTimeoutMs;');
    try {
      db.execute('PRAGMA journal_mode=WAL;');
    } on Object {
      // Concurrent openers may briefly lock while WAL is enabled.
    }
    db.execute('PRAGMA foreign_keys=ON;');
    return SqliteDatabaseHandle._(db, path: path, ownsConnection: true);
  }

  factory SqliteDatabaseHandle.fromDatabase(Database db, {required String path}) {
    return SqliteDatabaseHandle._(db, path: path, ownsConnection: false);
  }

  final Database _db;
  final String path;
  final bool ownsConnection;
  bool _closed = false;

  Database get database {
    if (_closed) {
      throw StateError('SqliteDatabaseHandle is closed.');
    }
    return _db;
  }

  void ensureJobDedupeSchema() {
    database.execute('''
      CREATE TABLE IF NOT EXISTS job_dedupe_log (
        dedupe_key TEXT PRIMARY KEY,
        sent_at TEXT NOT NULL
      );
    ''');
  }

  void ensureCourseSchema() {
    ensureJobDedupeSchema();
    final db = database;
    db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS launches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL REFERENCES products(id),
        code TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        channel_id INTEGER,
        price_full_kopecks INTEGER NOT NULL DEFAULT 0,
        deposit_kopecks INTEGER NOT NULL DEFAULT 0,
        deposit_due_days INTEGER NOT NULL DEFAULT 7,
        deposit_due_at TEXT,
        course_start_at TEXT,
        offer_url TEXT,
        lead_magnet_file_id TEXT,
        lead_magnet_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 0
      );
    ''');
    _ensureColumn(db, 'launches', 'is_active', 'INTEGER NOT NULL DEFAULT 0');
    _ensureColumn(db, 'launches', 'deposit_due_at', 'TEXT');
    _ensureColumn(db, 'launches', 'course_start_at', 'TEXT');
    db.execute('''
      CREATE TABLE IF NOT EXISTS telegram_users (
        user_id INTEGER PRIMARY KEY,
        username TEXT,
        first_name TEXT,
        source TEXT,
        funnel_phase TEXT NOT NULL DEFAULT 'lead',
        warmup_opt_out INTEGER NOT NULL DEFAULT 0,
        bot_blocked INTEGER NOT NULL DEFAULT 0,
        magnet_issued_at TEXT,
        first_started_at TEXT NOT NULL,
        last_seen_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_telegram_users_username
      ON telegram_users (username COLLATE NOCASE);
    ''');
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_telegram_users_phase
      ON telegram_users (funnel_phase);
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES telegram_users(user_id),
        launch_id INTEGER NOT NULL REFERENCES launches(id),
        status TEXT NOT NULL,
        kind TEXT NOT NULL,
        price_full_kopecks INTEGER NOT NULL,
        amount_paid_kopecks INTEGER NOT NULL DEFAULT 0,
        amount_due_kopecks INTEGER NOT NULL,
        due_at TEXT,
        checkout_started_at TEXT NOT NULL,
        paid_at TEXT,
        cancelled_at TEXT,
        access_granted INTEGER NOT NULL DEFAULT 0
      );
    ''');
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders (user_id, id DESC);
    ''');
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status);
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL REFERENCES orders(id),
        provider TEXT NOT NULL,
        provider_payment_id TEXT,
        kind TEXT NOT NULL,
        amount_kopecks INTEGER NOT NULL,
        status TEXT NOT NULL,
        confirmation_url TEXT,
        created_at TEXT NOT NULL,
        succeeded_at TEXT
      );
    ''');
    db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_provider_id
      ON payments (provider, provider_payment_id)
      WHERE provider_payment_id IS NOT NULL;
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS channel_access (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        launch_id INTEGER NOT NULL,
        order_id INTEGER NOT NULL,
        invite_link TEXT,
        invite_created_at TEXT,
        joined_at TEXT,
        revoked_at TEXT,
        UNIQUE(user_id, launch_id)
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS warmup_steps (
        step_key TEXT PRIMARY KEY,
        delay_seconds INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS warmup_sent (
        user_id INTEGER NOT NULL,
        step_key TEXT NOT NULL,
        sent_at TEXT NOT NULL,
        PRIMARY KEY (user_id, step_key)
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS conversation_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        occurred_at TEXT NOT NULL,
        direction TEXT NOT NULL,
        peer_user_id INTEGER NOT NULL,
        peer_username TEXT,
        chat_id INTEGER NOT NULL,
        telegram_message_id INTEGER,
        content_type TEXT NOT NULL,
        text_preview TEXT
      );
    ''');
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_conversation_log_occurred_at
      ON conversation_log (occurred_at DESC);
    ''');
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_conversation_log_peer
      ON conversation_log (peer_user_id, occurred_at DESC);
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS bot_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
  }

  void _ensureColumn(Database db, String table, String column, String spec) {
    final info = db.select('PRAGMA table_info($table);');
    final exists = info.any((row) => row['name'] == column);
    if (exists) {
      return;
    }
    db.execute('ALTER TABLE $table ADD COLUMN $column $spec;');
  }

  T transaction<T>(T Function() action) {
    database.execute('BEGIN IMMEDIATE;');
    try {
      final result = action();
      database.execute('COMMIT;');
      return result;
    } on Object {
      try {
        database.execute('ROLLBACK;');
      } on Object {
        // ignore rollback failures
      }
      rethrow;
    }
  }

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    if (ownsConnection) {
      _db.dispose();
    }
  }
}
