import 'package:sqflite/sqflite.dart' hide Transaction;

import '../../domain/entities/transaction.dart';
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

  Future<List<Transaction>> findAll() async {
    try {
      final rows = await _db.query(
        TransactionMapper.table,
        orderBy: 'occurred_date DESC, occurred_time DESC, created_at DESC',
      );
      return rows.map(TransactionMapper.fromMap).toList();
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to list transactions', cause: e),
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
}
