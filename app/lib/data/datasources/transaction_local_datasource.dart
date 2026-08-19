import 'package:sqflite/sqflite.dart' hide Transaction;

import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/failures/app_failure.dart';
import '../db/app_database.dart';
import '../mappers/transaction_mapper.dart';

class TransactionLocalDataSource {
  TransactionLocalDataSource(this._database);

  final AppDatabase _database;

  Database get _db => _database.raw;

  Future<void> insert(Transaction tx) async {
    try {
      await _db.insert(
        TransactionMapper.table,
        TransactionMapper.toMap(tx),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to save transaction', cause: e),
        st,
      );
    }
  }

  Future<Transaction?> findById(String id) async {
    try {
      final rows = await _db.query(
        TransactionMapper.table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return TransactionMapper.fromMap(rows.first);
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to read transaction', cause: e),
        st,
      );
    }
  }

  Future<TransactionPage> findPage(TransactionQuerySpec spec) async {
    try {
      final filter = _buildFilter(spec);
      final rows = await _db.query(
        TransactionMapper.table,
        where: filter.clause,
        whereArgs: filter.args,
        orderBy: 'occurred_date DESC, occurred_time DESC, created_at DESC',
        limit: spec.limit + 1,
        offset: spec.offset,
      );
      final hasMore = rows.length > spec.limit;
      final pageRows = hasMore ? rows.take(spec.limit) : rows;

      var expenseSum = 0;
      if (spec.includeExpenseSum) {
        final expenseFilter = _buildFilter(
          TransactionQuerySpec(
            fromInclusive: spec.fromInclusive,
            toExclusive: spec.toExclusive,
            type: TransactionType.expense,
            categoryId: spec.categoryId,
          ),
        );
        final sumRows = await _db.rawQuery('''
SELECT COALESCE(SUM(amount), 0) AS total
FROM ${TransactionMapper.table}
WHERE ${expenseFilter.clause}
''', expenseFilter.args);
        expenseSum = (sumRows.first['total'] as num?)?.toInt() ?? 0;
      }

      return TransactionPage(
        items: pageRows.map(TransactionMapper.fromMap).toList(growable: false),
        expenseSum: expenseSum,
        hasMore: hasMore,
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to query transactions', cause: e),
        st,
      );
    }
  }

  Future<ExpenseSummary> summarizeExpenses({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    try {
      final filter = _buildFilter(
        TransactionQuerySpec(
          fromInclusive: fromInclusive,
          toExclusive: toExclusive,
          type: TransactionType.expense,
        ),
      );
      final rows = await _db.rawQuery('''
SELECT category_id, COALESCE(SUM(amount), 0) AS total
FROM ${TransactionMapper.table}
WHERE ${filter.clause}
GROUP BY category_id
''', filter.args);
      final byCategory = <String, int>{
        for (final row in rows)
          row['category_id']! as String: (row['total']! as num).toInt(),
      };
      return ExpenseSummary(
        total: byCategory.values.fold(0, (sum, amount) => sum + amount),
        byCategory: byCategory,
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to summarize expenses', cause: e),
        st,
      );
    }
  }

  Future<int> update(Transaction tx) async {
    try {
      return await _db.update(
        TransactionMapper.table,
        TransactionMapper.toMap(tx),
        where: 'id = ?',
        whereArgs: [tx.id],
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to update transaction', cause: e),
        st,
      );
    }
  }

  Future<int> delete(String id) async {
    try {
      return await _db.delete(
        TransactionMapper.table,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to delete transaction', cause: e),
        st,
      );
    }
  }

  _SqlFilter _buildFilter(TransactionQuerySpec spec) {
    final clauses = <String>[];
    final args = <Object?>[];
    if (spec.fromInclusive != null) {
      clauses.add('occurred_date >= ?');
      args.add(TransactionMapper.dateToStorage(spec.fromInclusive!));
    }
    if (spec.toExclusive != null) {
      clauses.add('occurred_date < ?');
      args.add(TransactionMapper.dateToStorage(spec.toExclusive!));
    }
    if (spec.type != null) {
      clauses.add('type = ?');
      args.add(spec.type!.storageValue);
    }
    if (spec.categoryId != null) {
      clauses.add('category_id = ?');
      args.add(spec.categoryId);
    }
    return _SqlFilter(
      clause: clauses.isEmpty ? '1 = 1' : clauses.join(' AND '),
      args: args,
    );
  }
}

class _SqlFilter {
  const _SqlFilter({required this.clause, required this.args});

  final String clause;
  final List<Object?> args;
}
