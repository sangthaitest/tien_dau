import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/db/migrations/recurring_transactions.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v4 to v5 realistic upgrade preserves transactions and migrates salary', () async {
    final path = await _v4FixturePath();
    final beforeDb = await databaseFactory.openDatabase(path);
    final before = await captureTransactionIntegrity(beforeDb);
    final prefsBefore = await _prefs(beforeDb);
    final transactionRowsBefore = await beforeDb.query(
      'transactions',
      orderBy: 'id ASC',
    );
    await beforeDb.close();

    expect(before.count, 6);
    expect(before.sum, 1586195);
    expect(
      before.checksum,
      '8bc2bc445d729fc8d4b6762ddd42175d36375831cc88d0146b4fa44fa75b2030',
    );
    expect(prefsBefore[salaryAmountPrefKey], '20000000');

    final upgraded = await AppDatabase.openPath(path);
    final version = await _userVersion(upgraded.raw);
    final after = await captureTransactionIntegrity(upgraded.raw);
    final prefsAfter = await _prefs(upgraded.raw);
    final integrity = await pragmaIntegrityCheck(upgraded.raw);
    final salary = await upgraded.raw.query(
      recurringTransactionsTable,
      where: 'id = ?',
      whereArgs: [recurringSalaryId],
    );
    final transactionRowsAfter = await upgraded.raw.query(
      'transactions',
      orderBy: 'id ASC',
    );
    final incomeInTransactions = await upgraded.raw.query(
      'transactions',
      where: 'type = ?',
      whereArgs: ['income'],
    );

    expect(version, 5);
    expect(after.count, before.count);
    expect(after.sum, before.sum);
    expect(after.checksum, before.checksum);
    expect(after.ids, before.ids);
    expect(transactionRowsAfter, transactionRowsBefore);
    expect(incomeInTransactions, isEmpty);
    expect(integrity, 'ok');
    expect(salary, hasLength(1));
    expect(salary.single['name'], recurringSalaryName);
    expect(salary.single['kind'], 'income');
    expect(salary.single['amount'], 20000000);
    expect(salary.single['frequency'], 'monthly');
    expect(salary.single['interval_count'], 1);
    expect(salary.single['direction'], 'add');
    expect(salary.single['is_active'], 1);
    expect(prefsAfter.containsKey(salaryAmountPrefKey), isFalse);
    for (final key in protectedPrefKeys) {
      expect(prefsAfter[key], prefsBefore[key], reason: key);
    }

    await upgraded.close();
  });

  test('v5 second open does not remigrate or duplicate salary', () async {
    final path = await _v4FixturePath();
    final first = await AppDatabase.openPath(path);
    final firstSnap = await captureTransactionIntegrity(first.raw);
    final firstSalary = await first.raw.query(recurringTransactionsTable);
    await first.close();

    final second = await AppDatabase.openPath(path);
    final secondSnap = await captureTransactionIntegrity(second.raw);
    final secondSalary = await second.raw.query(recurringTransactionsTable);
    final version = await _userVersion(second.raw);

    expect(version, 5);
    expect(secondSnap.count, firstSnap.count);
    expect(secondSnap.checksum, firstSnap.checksum);
    expect(secondSalary, hasLength(1));
    expect(secondSalary.single['id'], recurringSalaryId);
    expect(firstSalary, hasLength(1));

    await second.close();
  });

  test('fresh v5 install has recurring table and no seeded money data', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_v5_fresh');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');

    final db = await AppDatabase.openPath(path);
    final version = await _userVersion(db.raw);
    final tables = await db.raw.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [recurringTransactionsTable],
    );
    final transactions = await db.raw.query('transactions');
    final recurring = await db.raw.query(recurringTransactionsTable);
    final prefs = await _prefs(db.raw);
    final income = await db.raw.query(
      'transactions',
      where: 'type = ?',
      whereArgs: ['income'],
    );

    expect(version, 5);
    expect(tables, isNotEmpty);
    expect(transactions, isEmpty);
    expect(recurring, isEmpty);
    expect(income, isEmpty);
    expect(prefs, isEmpty);
    expect(
      await pragmaIntegrityCheck(db.raw),
      'ok',
    );

    await db.close();
  });

  test('v4 to v5 rolls back when salary cleanup fails', () async {
    final path = await _v4FixturePath();
    final prepared = await databaseFactory.openDatabase(path);
    final before = await captureTransactionIntegrity(prepared);
    await prepared.execute('''
CREATE TRIGGER prevent_salary_delete
BEFORE DELETE ON app_prefs
FOR EACH ROW
WHEN OLD.key = 'salary_amount'
BEGIN
  SELECT RAISE(ABORT, 'test: block salary_amount delete');
END
''');
    await prepared.close();

    await expectLater(
      AppDatabase.openPath(path),
      throwsA(isA<RecurringMigrationAborted>()),
    );

    final inspect = await databaseFactory.openDatabase(path);
    final version = (await inspect.rawQuery(
      'PRAGMA user_version',
    )).first['user_version'];
    final after = await captureTransactionIntegrity(inspect);
    final prefs = await _prefs(inspect);
    final tables = await inspect.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [recurringTransactionsTable],
    );

    expect(version, 4);
    expect(after.count, before.count);
    expect(after.sum, before.sum);
    expect(after.checksum, before.checksum);
    expect(prefs[salaryAmountPrefKey], '20000000');
    expect(prefs['budget_month'], '2026-08');
    expect(tables, isEmpty);

    await inspect.close();
  });

  test('v4 without valid salary still upgrades and does not invent a salary row', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_v5_nosalary');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'legacy.db');
    final legacy = await _openV4(path);
    await _insertPref(legacy, 'budget_month', '2026-08');
    await _insertPref(legacy, 'budget_limit', '10000000');
    await _insertPref(legacy, salaryAmountPrefKey, '0');
    await legacy.close();

    final upgraded = await AppDatabase.openPath(path);
    final prefs = await _prefs(upgraded.raw);
    final salary = await upgraded.raw.query(recurringTransactionsTable);

    expect(await _userVersion(upgraded.raw), 5);
    expect(salary, isEmpty);
    expect(prefs[salaryAmountPrefKey], '0');
    expect(prefs['budget_month'], '2026-08');
    expect(prefs['budget_limit'], '10000000');

    await upgraded.close();
  });
}

Future<String> _v4FixturePath() async {
  final dir = await Directory.systemTemp.createTemp('tien_day_v4_fixture');
  addTearDown(() => dir.delete(recursive: true));
  final path = p.join(dir.path, 'tien_day.db');
  final db = await _openV4(path);

  for (final row in _fixtureTransactions) {
    await db.insert('transactions', row);
  }

  await _insertPref(db, salaryAmountPrefKey, '20000000');
  await _insertPref(db, 'budget_month', '2026-08');
  await _insertPref(db, 'budget_limit', '12000000');
  await _insertPref(db, 'transaction_catalog_v1', _catalogJson);
  await _insertPref(db, 'view_month', '2026-08');
  await _insertPref(db, 'pin_hash', 'hash-v4');
  await _insertPref(db, 'pin_salt', 'salt-v4');
  await _insertPref(db, 'settings_dark_mode', '0');
  await _insertPref(db, 'settings_balance_hidden', '1');
  await _insertPref(db, 'settings_notifications', '1');
  await db.close();
  return path;
}

Future<Database> _openV4(String path) {
  return databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 4,
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
        await db.execute('''
CREATE INDEX IF NOT EXISTS idx_transactions_type_date_time
ON transactions(type, occurred_date DESC, occurred_time DESC, created_at DESC)
''');
        await db.execute('''
CREATE INDEX IF NOT EXISTS idx_transactions_type_category_date
ON transactions(type, category_id, occurred_date DESC, occurred_time DESC)
''');
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
      },
    ),
  );
}

Future<void> _insertPref(Database db, String key, String value) {
  return db.insert('app_prefs', {'key': key, 'value': value});
}

Future<Map<String, String>> _prefs(Database db) async {
  final rows = await db.query('app_prefs');
  return {
    for (final row in rows) row['key']! as String: row['value']! as String,
  };
}

Future<int> _userVersion(Database db) async {
  final rows = await db.rawQuery('PRAGMA user_version');
  return (rows.first['user_version'] as num).toInt();
}

const _catalogJson =
    '{"version":1,"categories":[{"id":"cafe","name":"Cafe","details":["Highlands","Ô Bầu"],"visualKey":"cafe","archived":false}],"payments":[{"id":"momo","name":"MoMo","method":"eWallet","typeLabel":"Ví điện tử","archived":false}]}';

const _fixtureTransactions = <Map<String, Object?>>[
  {
    'id': 'tx-cafe-1',
    'amount': 45000,
    'type': 'expense',
    'category_id': 'cafe',
    'detail': 'Highlands',
    'occurred_date': '2026-08-03',
    'occurred_time': '08:15',
    'payment_source_id': 'momo',
    'payment_source_name': 'MoMo',
    'payment_method': 'eWallet',
    'note': 'Sáng',
    'created_at': '2026-08-03T01:15:00.000Z',
    'updated_at': '2026-08-03T01:15:00.000Z',
  },
  {
    'id': 'tx-lunch-1',
    'amount': 65000,
    'type': 'expense',
    'category_id': 'lunch',
    'detail': 'Cơm',
    'occurred_date': '2026-08-07',
    'occurred_time': '11:40',
    'payment_source_id': 'cash',
    'payment_source_name': 'Tiền mặt',
    'payment_method': 'cash',
    'note': null,
    'created_at': '2026-08-07T04:40:00.000Z',
    'updated_at': '2026-08-07T04:40:00.000Z',
  },
  {
    'id': 'tx-market-1',
    'amount': 128000,
    'type': 'expense',
    'category_id': 'market',
    'detail': null,
    'occurred_date': '2026-08-12',
    'occurred_time': '17:05',
    'payment_source_id': 'vcb',
    'payment_source_name': 'Vietcombank',
    'payment_method': 'bankAccount',
    'note': 'Rau + thịt',
    'created_at': '2026-08-12T10:05:00.000Z',
    'updated_at': '2026-08-12T10:05:00.000Z',
  },
  {
    'id': 'tx-transport-1',
    'amount': 32000,
    'type': 'expense',
    'category_id': 'transport',
    'detail': 'Grab',
    'occurred_date': '2026-07-29',
    'occurred_time': null,
    'payment_source_id': 'momo',
    'payment_source_name': 'MoMo',
    'payment_method': 'eWallet',
    'note': null,
    'created_at': '2026-07-29T12:00:00.000Z',
    'updated_at': '2026-07-29T12:00:00.000Z',
  },
  {
    'id': 'tx-bills-1',
    'amount': 1306195,
    'type': 'expense',
    'category_id': 'bills',
    'detail': 'Điện',
    'occurred_date': '2026-08-01',
    'occurred_time': '09:00',
    'payment_source_id': 'vcb',
    'payment_source_name': 'Vietcombank',
    'payment_method': 'bankAccount',
    'note': 'EVN',
    'created_at': '2026-08-01T02:00:00.000Z',
    'updated_at': '2026-08-01T02:00:00.000Z',
  },
  {
    'id': 'tx-snacks-1',
    'amount': 10000,
    'type': 'expense',
    'category_id': 'snacks',
    'detail': 'Nước cam',
    'occurred_date': '2026-08-18',
    'occurred_time': '15:22',
    'payment_source_id': 'cash',
    'payment_source_name': 'Tiền mặt',
    'payment_method': 'cash',
    'note': null,
    'created_at': '2026-08-18T08:22:00.000Z',
    'updated_at': '2026-08-18T08:22:00.000Z',
  },
];
