import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import 'migrations/normalize_categories.dart';
import 'migrations/recurring_transactions.dart';

class AppDatabase {
  AppDatabase._(this._db, this.path);

  Database _db;
  final String path;

  Database get raw => _db;

  static const fileName = 'tien_day.db';
  static const schemaVersion = 5;

  static Future<String> documentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, fileName);
  }

  static Future<AppDatabase> openFile() async {
    return openPath(await documentsPath());
  }

  static Future<AppDatabase> openPath(String path) async {
    final db = await _openRaw(path);
    return AppDatabase._(db, path);
  }

  static Future<Database> _openRaw(String path) {
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: (db, version) async {
        await _createTransactions(db);
        await _createTransactionIndexes(db);
        await _createFinance(db);
        await createRecurringTransactionsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createFinance(db);
        }
        if (oldVersion < 3) {
          await _createTransactionIndexes(db);
        }
        if (oldVersion < 4) {
          await normalizeCategories(db);
        }
        if (oldVersion < 5) {
          await migrateV4toV5(db);
        }
      },
    );
  }

  static Future<void> _createTransactions(Database db) async {
    await db.execute('''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL,
  category_id TEXT NOT NULL,
  detail TEXT,
  occurred_date TEXT NOT NULL,
  occurred_time TEXT,
  payment_source_id TEXT NOT NULL,
  payment_source_name TEXT NOT NULL,
  payment_method TEXT NOT NULL,
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
  }

  static Future<void> _createTransactionIndexes(Database db) async {
    await db.execute('''
CREATE INDEX IF NOT EXISTS idx_transactions_type_date_time
ON transactions(type, occurred_date DESC, occurred_time DESC, created_at DESC)
''');
    await db.execute('''
CREATE INDEX IF NOT EXISTS idx_transactions_type_category_date
ON transactions(type, category_id, occurred_date DESC, occurred_time DESC)
''');
  }

  static Future<void> _createFinance(Database db) async {
    await db.execute('''
CREATE TABLE app_prefs (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE savings_goals (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  target_amount INTEGER NOT NULL,
  current_amount INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
  }

  Future<int> userVersion() async {
    final rows = await _db.rawQuery('PRAGMA user_version');
    return (rows.first['user_version'] as num).toInt();
  }

  Future<String> integrityCheck() async {
    final rows = await _db.rawQuery('PRAGMA integrity_check');
    if (rows.isEmpty) return 'empty';
    return rows.first.values.first.toString();
  }

  /// Consistent standalone copy. Does not replace the live file.
  Future<void> snapshotTo(String destPath) async {
    final dest = File(destPath);
    if (await dest.exists()) await dest.delete();
    await dest.parent.create(recursive: true);
    // Prefer checkpoint + copy: reliable on Android/iOS/desktop and avoids
    // platform hangs seen with VACUUM INTO under sqflite_common_ffi.
    try {
      await _db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {}
    await File(path).copy(destPath);
  }

  Future<void> replaceLiveDatabase(String sourceSqlitePath) async {
    try {
      await _db.close();
    } catch (_) {}
    try {
      await deleteSqliteSidecars(path);
      await File(sourceSqlitePath).copy(path);
      await deleteSqliteSidecars(path);
      _db = await _openRaw(path);
    } catch (error, stack) {
      try {
        _db = await _openRaw(path);
      } catch (_) {}
      Error.throwWithStackTrace(error, stack);
    }
  }

  static Future<void> deleteSqliteSidecars(String dbPath) async {
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final file = File('$dbPath$suffix');
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> close() => _db.close();
}
