import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/data/db/app_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v2 to v3 adds transaction indexes without losing rows', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_migration');
    final path = p.join(dir.path, 'legacy.db');
    final legacy = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
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
      ),
    );
    await legacy.insert('transactions', {
      'id': 'keep-me',
      'amount': 42000,
      'type': 'expense',
      'category_id': 'cafe',
      'detail': 'Migration',
      'occurred_date': '2026-08-19',
      'occurred_time': '09:30',
      'payment_source_id': 'cash',
      'payment_source_name': 'Tiền mặt',
      'payment_method': 'cash',
      'note': null,
      'created_at': DateTime.utc(2026, 8, 19).toIso8601String(),
      'updated_at': DateTime.utc(2026, 8, 19).toIso8601String(),
    });
    await legacy.close();

    final upgraded = await AppDatabase.openPath(path);
    final rows = await upgraded.raw.query('transactions');
    expect(rows, hasLength(1));
    expect(rows.single['id'], 'keep-me');
    expect(rows.single['amount'], 42000);

    final indexes = await upgraded.raw.rawQuery(
      "PRAGMA index_list('transactions')",
    );
    final names = indexes.map((row) => row['name']).toSet();
    expect(names, contains('idx_transactions_type_date_time'));
    expect(names, contains('idx_transactions_type_category_date'));

    await upgraded.close();
    await dir.delete(recursive: true);
  });
}
