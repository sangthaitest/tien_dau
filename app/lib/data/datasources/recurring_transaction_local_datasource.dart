import 'package:sqflite/sqflite.dart';

import '../../domain/entities/recurring_transaction.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/time/clock_format.dart';
import '../db/app_database.dart';
import '../db/migrations/recurring_transactions.dart';

class RecurringTransactionsLocalDataSource {
  RecurringTransactionsLocalDataSource(this._database);

  final AppDatabase _database;
  Database get _db => _database.raw;

  Future<RecurringTransaction?> findById(String id) async {
    try {
      final rows = await _db.query(
        recurringTransactionsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _fromMap(rows.first);
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to read recurring transaction', cause: e),
        st,
      );
    }
  }

  Future<void> upsertSalary(int amount) async {
    try {
      final now = DateTime.now().toUtc();
      final existing = await findById(recurringSalaryId);
      if (existing == null) {
        await _db.insert(recurringTransactionsTable, {
          'id': recurringSalaryId,
          'name': recurringSalaryName,
          'kind': RecurringKind.income.storageValue,
          'amount': amount,
          'frequency': RecurringFrequency.monthly.storageValue,
          'interval_count': 1,
          'direction': RecurringDirection.add.storageValue,
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
        return;
      }
      await _db.update(
        recurringTransactionsTable,
        {
          'amount': amount,
          'is_active': 1,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [recurringSalaryId],
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to save salary', cause: e),
        st,
      );
    }
  }

  RecurringTransaction _fromMap(Map<String, Object?> row) {
    return RecurringTransaction(
      id: row['id']! as String,
      name: row['name']! as String,
      kind: RecurringKind.fromStorage(row['kind']! as String),
      amount: row['amount']! as int,
      frequency: RecurringFrequency.fromStorage(row['frequency']! as String),
      intervalCount: row['interval_count']! as int,
      direction: RecurringDirection.fromStorage(row['direction']! as String),
      categoryId: row['category_id'] as String?,
      detail: row['detail'] as String?,
      paymentSourceId: row['payment_source_id'] as String?,
      note: row['note'] as String?,
      startDate: DateTime.parse(row['start_date']! as String),
      endDate: row['end_date'] == null
          ? null
          : DateTime.parse(row['end_date']! as String),
      isActive: (row['is_active']! as int) == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }
}
