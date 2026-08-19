import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'chi_tieu_map.dart';
import 'chi_tieu_xlsx.dart';

const _createTransactions = '''
CREATE TABLE IF NOT EXISTS transactions (
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
''';

const _createIndexes = [
  '''
CREATE INDEX IF NOT EXISTS idx_transactions_type_date_time
ON transactions(type, occurred_date DESC, occurred_time DESC, created_at DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS idx_transactions_type_category_date
ON transactions(type, category_id, occurred_date DESC, occurred_time DESC)
''',
];

const _createFinance = [
  '''
CREATE TABLE IF NOT EXISTS app_prefs (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''',
  '''
CREATE TABLE IF NOT EXISTS savings_goals (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  target_amount INTEGER NOT NULL,
  current_amount INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''',
];

SeedReport seedChiTieuIntoDatabase({
  required String xlsxPath,
  required String dbPath,
  DateTime Function()? clock,
}) {
  final now = (clock ?? DateTime.now)().toUtc().toIso8601String();
  final sourceName = xlsxPath.split(RegExp(r'[/\\]')).last;
  final rows = readChiTieuFile(xlsxPath);
  final dataRows = rows.where((row) => !row.isEmpty).toList(growable: false);

  final dbFile = File(dbPath);
  dbFile.parent.createSync(recursive: true);
  final isNew = !dbFile.existsSync();
  final db = sqlite3.open(dbPath);
  try {
    db.execute(_createTransactions);
    for (final sql in [..._createIndexes, ..._createFinance]) {
      db.execute(sql);
    }
    if (isNew) {
      db.execute('PRAGMA user_version = 3');
    }

    final existing = <String>{};
    final existingRows = db.select(
      'SELECT occurred_date, amount, detail, payment_source_name, note, category_id FROM transactions',
    );
    for (final row in existingRows) {
      existing.add(
        fingerprintFromDb(
          occurredDate: row['occurred_date'] as String,
          amount: (row['amount'] as num).toInt(),
          detail: row['detail'] as String?,
          paymentSourceName: row['payment_source_name'] as String,
          note: row['note'] as String?,
          categoryId: row['category_id'] as String,
        ),
      );
    }

    var imported = 0;
    var duplicate = 0;
    var invalid = 0;
    var failed = 0;
    final failures = <SeedRowFailure>[];
    final seen = <String>{};
    const uuid = Uuid();

    final insert = db.prepare('''
INSERT INTO transactions (
  id, amount, type, category_id, detail, occurred_date, occurred_time,
  payment_source_id, payment_source_name, payment_method, note,
  created_at, updated_at
) VALUES (?, ?, 'expense', ?, ?, ?, NULL, ?, ?, ?, ?, ?, ?)
''');
    try {
      for (final row in dataRows) {
        final mapped = mapChiTieuRow(row);
        if (mapped.invalid != null) {
          invalid += 1;
          failures.add(mapped.invalid!);
          continue;
        }
        final item = mapped.mapped!;
        if (existing.contains(item.fingerprint) || seen.contains(item.fingerprint)) {
          duplicate += 1;
          continue;
        }
        try {
          insert.execute([
            uuid.v4(),
            item.amount,
            item.categoryId,
            item.detail,
            item.occurredDate,
            item.paymentSourceId,
            item.paymentSourceName,
            item.paymentMethod,
            item.note,
            now,
            now,
          ]);
          imported += 1;
          seen.add(item.fingerprint);
          existing.add(item.fingerprint);
        } catch (error) {
          failed += 1;
          failures.add(
            SeedRowFailure(
              excelRowNumber: item.excelRowNumber,
              field: 'database',
              reason: error.toString(),
            ),
          );
        }
      }
    } finally {
      insert.dispose();
    }

    return SeedReport(
      sourceName: sourceName,
      rowsFound: dataRows.length,
      imported: imported,
      duplicate: duplicate,
      invalid: invalid,
      failed: failed,
      failures: failures,
    );
  } finally {
    db.dispose();
  }
}
