import 'package:sqflite/sqflite.dart';

import '../../domain/entities/recurring_transaction.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/time/clock_format.dart';
import '../db/app_database.dart';
import '../db/migrations/recurring_transactions.dart';
import '../mappers/recurring_transaction_mapper.dart';

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
      return RecurringTransactionMapper.fromMap(rows.first);
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to read recurring transaction', cause: e),
        st,
      );
    }
  }

  Future<List<RecurringTransaction>> findAll() async {
    try {
      final rows = await _db.query(
        recurringTransactionsTable,
        orderBy: 'start_date ASC, created_at ASC',
      );
      return [for (final row in rows) RecurringTransactionMapper.fromMap(row)];
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to list recurring transactions', cause: e),
        st,
      );
    }
  }

  Future<void> insert(RecurringTransaction rule) async {
    try {
      await _db.insert(
        recurringTransactionsTable,
        RecurringTransactionMapper.toMap(rule),
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to save recurring transaction', cause: e),
        st,
      );
    }
  }

  Future<int> update(RecurringTransaction rule) async {
    try {
      return await _db.update(
        recurringTransactionsTable,
        RecurringTransactionMapper.toMap(rule),
        where: 'id = ?',
        whereArgs: [rule.id],
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to update recurring transaction', cause: e),
        st,
      );
    }
  }

  Future<int> delete(String id) async {
    try {
      return await _db.delete(
        recurringTransactionsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to delete recurring transaction', cause: e),
        st,
      );
    }
  }

  Future<void> replaceSalary(RecurringTransaction row) async {
    if (row.id != recurringSalaryId) {
      throw const PersistenceFailure('Invalid salary id.');
    }
    final existing = await findById(recurringSalaryId);
    if (existing == null) {
      await insert(row);
      return;
    }
    await update(row);
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
          'name': recurringSalaryName,
          'kind': RecurringKind.income.storageValue,
          'frequency': RecurringFrequency.monthly.storageValue,
          'interval_count': 1,
          'direction': RecurringDirection.add.storageValue,
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
}
