import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import 'migrations/normalize_categories.dart';

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  Database get raw => _db;

  static const _fileName = 'tien_day.db';
  static const _version = 4;

  static Future<AppDatabase> openFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _fileName);
    return openPath(path);
  }

  static Future<AppDatabase> openPath(String path) async {
    final db = await openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await _createTransactions(db);
        await _createTransactionIndexes(db);
        await _createFinance(db);
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
      },
    );
    return AppDatabase._(db);
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

  Future<void> close() => _db.close();
}
