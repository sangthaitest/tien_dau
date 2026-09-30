import 'package:sqflite/sqflite.dart';

import '../../../domain/time/clock_format.dart';
import 'recurring_transactions.dart';

const recurringMonthEntriesTable = 'recurring_month_entries';

const createRecurringMonthEntriesSql = '''
CREATE TABLE recurring_month_entries (
  id TEXT PRIMARY KEY,
  template_id TEXT NOT NULL,
  month_key TEXT NOT NULL,
  name TEXT NOT NULL,
  kind TEXT NOT NULL,
  amount INTEGER NOT NULL,
  direction TEXT NOT NULL,
  category_id TEXT,
  detail TEXT,
  payment_source_id TEXT,
  note TEXT,
  day_of_month INTEGER NOT NULL,
  is_active INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(template_id, month_key)
)
''';

const createRecurringMonthEntriesMonthIndexSql = '''
CREATE INDEX idx_recurring_month_entries_month_key
ON recurring_month_entries(month_key)
''';

const createRecurringMonthEntriesTemplateIndexSql = '''
CREATE INDEX idx_recurring_month_entries_template_id
ON recurring_month_entries(template_id)
''';

class MonthEntriesMigrationAborted implements Exception {
  MonthEntriesMigrationAborted(this.message);
  final String message;

  @override
  String toString() => 'MonthEntriesMigrationAborted: $message';
}

Future<void> createRecurringMonthEntriesTable(DatabaseExecutor db) async {
  await db.execute(createRecurringMonthEntriesSql);
  await db.execute(createRecurringMonthEntriesMonthIndexSql);
  await db.execute(createRecurringMonthEntriesTemplateIndexSql);
}

/// Creates month snapshots for [recurring_salary] only, and only for months
/// the database already shows the user used.
///
/// Evidence is the distinct `transactions.occurred_date` month, `budget_month`,
/// and `view_month`. Other templates are not backfilled: this database never
/// stored their per-month history.
Future<void> migrateV5toV6(Database db) async {
  final transactionsBefore = await captureTransactionIntegrity(db);
  final prefsBefore = await _loadPrefs(db);
  final goalsBefore = await _loadGoals(db);

  await db.execute('SAVEPOINT v6_month_entries');
  try {
    await createRecurringMonthEntriesTable(db);
    await _materializeSalaryEvidence(db);

    final transactionsAfter = await captureTransactionIntegrity(db);
    _assertTransactionsUnchanged(transactionsBefore, transactionsAfter);
    _assertPrefsUnchanged(prefsBefore, await _loadPrefs(db));
    _assertGoalsUnchanged(goalsBefore, await _loadGoals(db));

    final integrity = await pragmaIntegrityCheck(db);
    if (integrity != 'ok') {
      throw MonthEntriesMigrationAborted('PRAGMA integrity_check: $integrity');
    }

    await db.execute('RELEASE SAVEPOINT v6_month_entries');
  } catch (error) {
    await db.execute('ROLLBACK TO SAVEPOINT v6_month_entries');
    await db.execute('RELEASE SAVEPOINT v6_month_entries');
    if (error is MonthEntriesMigrationAborted) rethrow;
    throw MonthEntriesMigrationAborted('$error');
  }
}

Future<void> _materializeSalaryEvidence(DatabaseExecutor db) async {
  final rows = await db.query(
    recurringTransactionsTable,
    where: 'id = ?',
    whereArgs: [recurringSalaryId],
    limit: 1,
  );
  if (rows.isEmpty) return;

  final salary = rows.single;
  final months = await _evidenceMonths(db);
  if (months.isEmpty) return;

  final startDate = salary['start_date']?.toString();
  if (startDate == null || startDate.length < 10) {
    throw MonthEntriesMigrationAborted(
      'recurring_salary.start_date is missing',
    );
  }
  final day = int.tryParse(startDate.substring(8, 10));
  if (day == null || day < 1 || day > 31) {
    throw MonthEntriesMigrationAborted(
      'recurring_salary.start_date day is invalid: $startDate',
    );
  }

  final name = salary['name']?.toString();
  final kind = salary['kind']?.toString();
  final direction = salary['direction']?.toString();
  final amount = (salary['amount'] as num?)?.toInt();
  final createdAt = salary['created_at']?.toString();
  final updatedAt = salary['updated_at']?.toString();
  final isActive = (salary['is_active'] as num?)?.toInt();
  if (name == null ||
      name.isEmpty ||
      kind == null ||
      kind.isEmpty ||
      direction == null ||
      direction.isEmpty ||
      amount == null ||
      createdAt == null ||
      createdAt.isEmpty ||
      updatedAt == null ||
      updatedAt.isEmpty ||
      isActive == null) {
    throw MonthEntriesMigrationAborted('recurring_salary row is incomplete');
  }

  final sorted = months.toList()..sort();
  for (final monthKey in sorted) {
    await db.insert(recurringMonthEntriesTable, {
      'id': '$recurringSalaryId@$monthKey',
      'template_id': recurringSalaryId,
      'month_key': monthKey,
      'name': name,
      'kind': kind,
      'amount': amount,
      'direction': direction,
      'category_id': salary['category_id'],
      'detail': salary['detail'],
      'payment_source_id': salary['payment_source_id'],
      'note': salary['note'],
      'day_of_month': day,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }
}

Future<Set<String>> _evidenceMonths(DatabaseExecutor db) async {
  final months = <String>{};
  final transactionMonths = await db.rawQuery('''
SELECT DISTINCT substr(occurred_date, 1, 7) AS month_key
FROM transactions
WHERE length(occurred_date) >= 7
''');
  for (final row in transactionMonths) {
    _addMonth(months, row['month_key']?.toString());
  }

  final prefs = await _loadPrefs(db);
  _addMonth(months, prefs['budget_month']);
  _addMonth(months, prefs['view_month']);
  return months;
}

void _addMonth(Set<String> months, String? raw) {
  final parsed = parseMonthKey(raw);
  if (parsed == null) return;
  months.add(monthKey(parsed));
}

Future<Map<String, String>> _loadPrefs(DatabaseExecutor db) async {
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'app_prefs'",
  );
  if (tables.isEmpty) return {};
  final rows = await db.query('app_prefs', orderBy: 'key ASC');
  return {
    for (final row in rows) row['key']! as String: row['value']! as String,
  };
}

Future<List<Map<String, Object?>>> _loadGoals(DatabaseExecutor db) async {
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'savings_goals'",
  );
  if (tables.isEmpty) return const [];
  return db.query('savings_goals', orderBy: 'id ASC');
}

void _assertTransactionsUnchanged(
  TransactionIntegritySnapshot before,
  TransactionIntegritySnapshot after,
) {
  if (before.count != after.count ||
      before.sum != after.sum ||
      before.checksum != after.checksum ||
      before.ids.length != after.ids.length) {
    throw MonthEntriesMigrationAborted('transactions changed during v6');
  }
  for (var i = 0; i < before.ids.length; i++) {
    if (before.ids[i] != after.ids[i]) {
      throw MonthEntriesMigrationAborted('transaction ids changed during v6');
    }
  }
}

void _assertPrefsUnchanged(
  Map<String, String> before,
  Map<String, String> after,
) {
  if (before.length != after.length) {
    throw MonthEntriesMigrationAborted('app_prefs changed during v6');
  }
  for (final entry in before.entries) {
    if (after[entry.key] != entry.value) {
      throw MonthEntriesMigrationAborted(
        'app_prefs changed during v6: ${entry.key}',
      );
    }
  }
}

void _assertGoalsUnchanged(
  List<Map<String, Object?>> before,
  List<Map<String, Object?>> after,
) {
  if (before.length != after.length) {
    throw MonthEntriesMigrationAborted('savings_goals changed during v6');
  }
  for (var i = 0; i < before.length; i++) {
    final left = before[i];
    final right = after[i];
    for (final column in [
      'id',
      'name',
      'target_amount',
      'current_amount',
      'created_at',
      'updated_at',
    ]) {
      if (left[column] != right[column]) {
        throw MonthEntriesMigrationAborted(
          'savings_goals.$column changed during v6',
        );
      }
    }
  }
}
