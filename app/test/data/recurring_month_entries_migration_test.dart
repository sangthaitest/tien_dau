import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/db/migrations/recurring_month_entries.dart';
import 'package:tien_day/data/db/migrations/recurring_transactions.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v5 to v6 snapshots salary only for evidenced months', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_v6');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    final legacy = await _openV5(path);
    await legacy.insert('transactions', {
      'id': 'tx-july',
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
    });
    await legacy.insert('app_prefs', {
      'key': 'budget_month',
      'value': '2026-08',
    });
    await legacy.insert('app_prefs', {
      'key': 'budget_limit',
      'value': '10000000',
    });
    await legacy.insert('app_prefs', {'key': 'view_month', 'value': '2026-10'});
    await legacy.insert('savings_goals', {
      'id': 'goal-1',
      'name': 'Du lịch',
      'target_amount': 5000000,
      'current_amount': 1000000,
      'created_at': '2026-08-01T00:00:00.000Z',
      'updated_at': '2026-08-01T00:00:00.000Z',
    });
    await legacy.insert(recurringTransactionsTable, {
      'id': recurringSalaryId,
      'name': 'Lương',
      'kind': 'income',
      'amount': 20000000,
      'frequency': 'monthly',
      'interval_count': 1,
      'direction': 'add',
      'category_id': null,
      'detail': null,
      'payment_source_id': null,
      'note': null,
      'start_date': '2026-09-30',
      'end_date': null,
      'is_active': 1,
      'created_at': '2026-09-30T00:00:00.000Z',
      'updated_at': '2026-09-30T00:00:00.000Z',
    });
    await legacy.insert(recurringTransactionsTable, {
      'id': 'rent',
      'name': 'Tiền nhà',
      'kind': 'expense',
      'amount': 5000000,
      'frequency': 'monthly',
      'interval_count': 1,
      'direction': 'subtract',
      'category_id': 'bills',
      'detail': null,
      'payment_source_id': null,
      'note': null,
      'start_date': '2026-07-01',
      'end_date': null,
      'is_active': 1,
      'created_at': '2026-07-01T00:00:00.000Z',
      'updated_at': '2026-07-01T00:00:00.000Z',
    });
    final before = await captureTransactionIntegrity(legacy);
    await legacy.close();

    final upgraded = await AppDatabase.openPath(path);
    addTearDown(upgraded.close);
    final version = await upgraded.userVersion();
    final entries = await upgraded.raw.query(
      recurringMonthEntriesTable,
      orderBy: 'month_key ASC, template_id ASC',
    );
    final after = await captureTransactionIntegrity(upgraded.raw);
    final salaryTemplate = await upgraded.raw.query(
      recurringTransactionsTable,
      where: 'id = ?',
      whereArgs: [recurringSalaryId],
    );
    final rentTemplate = await upgraded.raw.query(
      recurringTransactionsTable,
      where: 'id = ?',
      whereArgs: ['rent'],
    );
    final goals = await upgraded.raw.query('savings_goals');
    final budget = await upgraded.raw.query(
      'app_prefs',
      where: 'key = ?',
      whereArgs: ['budget_month'],
    );
    final sql = await upgraded.raw.rawQuery(
      "SELECT sql FROM sqlite_master WHERE name = ?",
      [recurringMonthEntriesTable],
    );
    final foreignKeys = await upgraded.raw.rawQuery(
      'PRAGMA foreign_key_list(recurring_month_entries)',
    );
    final indexes = await upgraded.raw.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = ?",
      [recurringMonthEntriesTable],
    );

    expect(version, 6);
    expect(after.checksum, before.checksum);
    expect(after.count, before.count);
    expect(after.sum, before.sum);
    expect(entries.map((row) => row['month_key']), [
      '2026-07',
      '2026-08',
      '2026-10',
    ]);
    expect(
      entries.map((row) => row['template_id']),
      everyElement(recurringSalaryId),
    );
    expect(entries.map((row) => row['amount']), everyElement(20000000));
    expect(entries.map((row) => row['day_of_month']), everyElement(30));
    expect(salaryTemplate.single['amount'], 20000000);
    expect(rentTemplate.single['amount'], 5000000);
    expect(goals.single['current_amount'], 1000000);
    expect(budget.single['value'], '2026-08');
    expect(
      sql.single['sql'].toString(),
      contains('UNIQUE(template_id, month_key)'),
    );
    expect(
      sql.single['sql'].toString().toUpperCase(),
      isNot(contains('CASCADE')),
    );
    expect(foreignKeys, isEmpty);
    expect(
      indexes.map((row) => row['name']),
      containsAll([
        'idx_recurring_month_entries_month_key',
        'idx_recurring_month_entries_template_id',
      ]),
    );

    await upgraded.raw.delete(
      recurringTransactionsTable,
      where: 'id = ?',
      whereArgs: [recurringSalaryId],
    );
    final kept = await upgraded.raw.query(recurringMonthEntriesTable);
    expect(kept, hasLength(3));
  });

  test('v6 failure rolls back and leaves the previous version', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_v6_rollback');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    final legacy = await _openV5(path);
    await legacy.insert('transactions', {
      'id': 'tx-keep',
      'amount': 45000,
      'type': 'expense',
      'category_id': 'cafe',
      'detail': null,
      'occurred_date': '2026-08-03',
      'occurred_time': null,
      'payment_source_id': 'cash',
      'payment_source_name': 'Tiền mặt',
      'payment_method': 'cash',
      'note': null,
      'created_at': '2026-08-03T00:00:00.000Z',
      'updated_at': '2026-08-03T00:00:00.000Z',
    });
    await legacy.insert(recurringTransactionsTable, {
      'id': recurringSalaryId,
      'name': 'Lương',
      'kind': 'income',
      'amount': 20000000,
      'frequency': 'monthly',
      'interval_count': 1,
      'direction': 'add',
      'start_date': '2026-08-01',
      'end_date': null,
      'is_active': 1,
      'created_at': '2026-08-01T00:00:00.000Z',
      'updated_at': '2026-08-01T00:00:00.000Z',
    });
    await legacy.execute(
      'CREATE TABLE recurring_month_entries (id TEXT PRIMARY KEY)',
    );
    final before = await captureTransactionIntegrity(legacy);
    await legacy.close();

    await expectLater(
      AppDatabase.openPath(path),
      throwsA(isA<MonthEntriesMigrationAborted>()),
    );

    final inspect = await databaseFactory.openDatabase(path);
    final version = (await inspect.rawQuery(
      'PRAGMA user_version',
    )).first['user_version'];
    final after = await captureTransactionIntegrity(inspect);
    final salary = await inspect.query(
      recurringTransactionsTable,
      where: 'id = ?',
      whereArgs: [recurringSalaryId],
    );
    final entries = await inspect.query('recurring_month_entries');

    expect(version, 5);
    expect(after.checksum, before.checksum);
    expect(salary.single['amount'], 20000000);
    expect(entries, isEmpty);
    await inspect.close();
  });

  test('fresh install creates an empty month-entry table', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_v6_fresh');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    final db = await AppDatabase.openPath(path);
    addTearDown(db.close);

    expect(await db.userVersion(), 6);
    expect(await db.raw.query(recurringMonthEntriesTable), isEmpty);
    expect(await db.raw.query('transactions'), isEmpty);
    expect(await db.integrityCheck(), 'ok');
  });
}

Future<Database> _openV5(String path) {
  return databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 5,
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
        await db.execute(createRecurringTransactionsSql);
      },
    ),
  );
}
