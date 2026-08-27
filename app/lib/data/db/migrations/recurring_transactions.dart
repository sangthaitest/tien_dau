import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../../../domain/time/clock_format.dart';

const recurringTransactionsTable = 'recurring_transactions';
const recurringSalaryId = 'recurring_salary';
const recurringSalaryName = 'Lương';
const salaryAmountPrefKey = 'salary_amount';

const protectedPrefKeys = <String>[
  'budget_month',
  'budget_limit',
  'transaction_catalog_v1',
  'view_month',
  'pin_hash',
  'pin_salt',
  'settings_dark_mode',
  'settings_balance_hidden',
  'settings_notifications',
  'profile_display_name',
  'profile_email',
  'profile_avatar_path',
];

const createRecurringTransactionsSql = '''
CREATE TABLE recurring_transactions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    kind TEXT NOT NULL,
    amount INTEGER NOT NULL,
    frequency TEXT NOT NULL,
    interval_count INTEGER NOT NULL DEFAULT 1,
    direction TEXT NOT NULL,
    category_id TEXT,
    detail TEXT,
    payment_source_id TEXT,
    note TEXT,
    start_date TEXT NOT NULL,
    end_date TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
)
''';

class RecurringMigrationAborted implements Exception {
  RecurringMigrationAborted(this.message);
  final String message;

  @override
  String toString() => 'RecurringMigrationAborted: $message';
}

class TransactionIntegritySnapshot {
  const TransactionIntegritySnapshot({
    required this.count,
    required this.sum,
    required this.checksum,
    required this.ids,
  });

  final int count;
  final int sum;
  final String checksum;
  final List<String> ids;
}

class RecurringMigrationReport {
  const RecurringMigrationReport({
    required this.salaryMigrated,
    required this.salaryAmount,
    required this.before,
    required this.after,
    required this.integrityCheck,
  });

  final bool salaryMigrated;
  final int? salaryAmount;
  final TransactionIntegritySnapshot before;
  final TransactionIntegritySnapshot after;
  final String integrityCheck;
}

Future<void> createRecurringTransactionsTable(DatabaseExecutor db) {
  return db.execute(createRecurringTransactionsSql);
}

Future<TransactionIntegritySnapshot> captureTransactionIntegrity(
  DatabaseExecutor db,
) async {
  final countRows = await db.rawQuery(
    'SELECT COUNT(*) AS total FROM transactions',
  );
  final sumRows = await db.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions',
  );
  final rows = await db.query('transactions', orderBy: 'id ASC');
  return TransactionIntegritySnapshot(
    count: (countRows.first['total'] as num?)?.toInt() ?? 0,
    sum: (sumRows.first['total'] as num?)?.toInt() ?? 0,
    checksum: transactionChecksum(rows),
    ids: [for (final row in rows) row['id']! as String],
  );
}

String transactionChecksum(List<Map<String, Object?>> rows) {
  final payload = rows.map(_checksumLine).join('\n');
  return sha256.convert(utf8.encode(payload)).toString();
}

String _checksumLine(Map<String, Object?> row) {
  return [
    row['id'],
    row['amount'],
    row['type'],
    row['category_id'],
    row['detail'] ?? '',
    row['occurred_date'],
    row['occurred_time'] ?? '',
    row['payment_source_id'],
    row['payment_source_name'],
    row['payment_method'],
    row['note'] ?? '',
    row['created_at'],
    row['updated_at'],
  ].join('|');
}

Future<String> pragmaIntegrityCheck(DatabaseExecutor db) async {
  final rows = await db.rawQuery('PRAGMA integrity_check');
  if (rows.isEmpty) return 'empty';
  return rows.first.values.first.toString();
}

Future<RecurringMigrationReport> migrateV4toV5(Database db) async {
  final before = await captureTransactionIntegrity(db);
  final prefsBefore = await _loadPrefs(db);
  final salaryAmount = _parsePositiveInt(prefsBefore[salaryAmountPrefKey]);

  await db.execute('SAVEPOINT v5_recurring');
  try {
    await createRecurringTransactionsTable(db);
    if (salaryAmount != null) {
      await _insertSalaryRule(db, salaryAmount);
    }

    final afterCreate = await captureTransactionIntegrity(db);
    _assertTransactionsUnchanged(before, afterCreate);
    _assertProtectedPrefsUnchanged(prefsBefore, await _loadPrefs(db));
    if (salaryAmount != null) {
      await _assertSalaryRule(db, salaryAmount);
    }

    final integrity = await pragmaIntegrityCheck(db);
    if (integrity != 'ok') {
      throw RecurringMigrationAborted('PRAGMA integrity_check: $integrity');
    }

    if (salaryAmount != null) {
      final deleted = await db.delete(
        'app_prefs',
        where: 'key = ?',
        whereArgs: [salaryAmountPrefKey],
      );
      if (deleted != 1) {
        throw RecurringMigrationAborted(
          'Expected to delete one salary_amount pref, deleted $deleted',
        );
      }
    }

    final prefsAfter = await _loadPrefs(db);
    if (salaryAmount != null && prefsAfter.containsKey(salaryAmountPrefKey)) {
      throw RecurringMigrationAborted('salary_amount still present after delete');
    }
    if (salaryAmount == null &&
        prefsBefore.containsKey(salaryAmountPrefKey) &&
        !prefsAfter.containsKey(salaryAmountPrefKey)) {
      throw RecurringMigrationAborted('invalid salary_amount was deleted');
    }
    _assertProtectedPrefsUnchanged(prefsBefore, prefsAfter);

    final after = await captureTransactionIntegrity(db);
    _assertTransactionsUnchanged(before, after);

    await db.execute('RELEASE SAVEPOINT v5_recurring');
    return RecurringMigrationReport(
      salaryMigrated: salaryAmount != null,
      salaryAmount: salaryAmount,
      before: before,
      after: after,
      integrityCheck: integrity,
    );
  } catch (error) {
    await db.execute('ROLLBACK TO SAVEPOINT v5_recurring');
    await db.execute('RELEASE SAVEPOINT v5_recurring');
    if (error is RecurringMigrationAborted) rethrow;
    throw RecurringMigrationAborted('$error');
  }
}

void _assertTransactionsUnchanged(
  TransactionIntegritySnapshot before,
  TransactionIntegritySnapshot after,
) {
  if (before.count != after.count) {
    throw RecurringMigrationAborted(
      'transaction count changed: ${before.count} → ${after.count}',
    );
  }
  if (before.sum != after.sum) {
    throw RecurringMigrationAborted(
      'transaction sum changed: ${before.sum} → ${after.sum}',
    );
  }
  if (before.checksum != after.checksum) {
    throw RecurringMigrationAborted('transaction checksum changed');
  }
  if (!_sameIds(before.ids, after.ids)) {
    throw RecurringMigrationAborted('transaction ids changed');
  }
}

void _assertProtectedPrefsUnchanged(
  Map<String, String> before,
  Map<String, String> after,
) {
  for (final key in protectedPrefKeys) {
    if (before[key] != after[key]) {
      throw RecurringMigrationAborted('protected pref changed: $key');
    }
  }
}

bool _sameIds(List<String> before, List<String> after) {
  if (before.length != after.length) return false;
  for (var i = 0; i < before.length; i++) {
    if (before[i] != after[i]) return false;
  }
  return true;
}

Future<void> _insertSalaryRule(DatabaseExecutor db, int amount) async {
  final now = DateTime.now().toUtc();
  await db.insert(recurringTransactionsTable, {
    'id': recurringSalaryId,
    'name': recurringSalaryName,
    'kind': 'income',
    'amount': amount,
    'frequency': 'monthly',
    'interval_count': 1,
    'direction': 'add',
    'category_id': null,
    'detail': null,
    'payment_source_id': null,
    'note': null,
    'start_date': formatIsoDate(now),
    'end_date': null,
    'is_active': 1,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });
}

Future<void> _assertSalaryRule(DatabaseExecutor db, int amount) async {
  final rows = await db.query(
    recurringTransactionsTable,
    where: 'id = ?',
    whereArgs: [recurringSalaryId],
    limit: 1,
  );
  if (rows.length != 1) {
    throw RecurringMigrationAborted(
      'expected recurring_salary row, found ${rows.length}',
    );
  }
  final row = rows.single;
  void expectField(String column, Object? expected) {
    if (row[column] != expected) {
      throw RecurringMigrationAborted(
        'recurring_salary.$column=${row[column]}, expected $expected',
      );
    }
  }

  expectField('name', recurringSalaryName);
  expectField('kind', 'income');
  expectField('amount', amount);
  expectField('frequency', 'monthly');
  expectField('interval_count', 1);
  expectField('direction', 'add');
  expectField('is_active', 1);
}

Future<Map<String, String>> _loadPrefs(DatabaseExecutor db) async {
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'app_prefs'",
  );
  if (tables.isEmpty) return {};
  final rows = await db.query('app_prefs');
  return {
    for (final row in rows) row['key']! as String: row['value']! as String,
  };
}

int? _parsePositiveInt(String? raw) {
  if (raw == null) return null;
  final amount = int.tryParse(raw.trim());
  if (amount == null || amount <= 0) return null;
  return amount;
}
