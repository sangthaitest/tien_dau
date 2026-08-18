import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  Database get raw => _db;

  static const _fileName = 'tien_day.db';
  static const _version = 1;

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
      },
    );
    return AppDatabase._(db);
  }

  Future<void> close() => _db.close();
}
