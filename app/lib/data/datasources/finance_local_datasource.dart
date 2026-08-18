import 'package:sqflite/sqflite.dart';

import '../../domain/entities/finance.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/repositories/pin_repository.dart';
import '../db/app_database.dart';

class PrefsLocalDataSource {
  PrefsLocalDataSource(this._database);

  final AppDatabase _database;
  Database get _db => _database.raw;

  Future<String?> get(String key) async {
    try {
      final rows = await _db.query(
        'app_prefs',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['value'] as String?;
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to read preference', cause: e),
        st,
      );
    }
  }

  Future<void> set(String key, String value) async {
    try {
      await _db.insert(
        'app_prefs',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to save preference', cause: e),
        st,
      );
    }
  }
}

class GoalsLocalDataSource {
  GoalsLocalDataSource(this._database);

  final AppDatabase _database;
  Database get _db => _database.raw;

  Future<List<SavingsGoal>> findAll() async {
    try {
      final rows = await _db.query('savings_goals', orderBy: 'created_at ASC');
      return rows.map(_fromMap).toList();
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to list goals', cause: e),
        st,
      );
    }
  }

  Future<void> insert(SavingsGoal goal) async {
    try {
      await _db.insert('savings_goals', _toMap(goal));
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to save goal', cause: e),
        st,
      );
    }
  }

  Future<int> update(SavingsGoal goal) async {
    try {
      return _db.update(
        'savings_goals',
        _toMap(goal),
        where: 'id = ?',
        whereArgs: [goal.id],
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to update goal', cause: e),
        st,
      );
    }
  }

  Future<int> delete(String id) async {
    try {
      return _db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
    } catch (e, st) {
      Error.throwWithStackTrace(
        PersistenceFailure('Failed to delete goal', cause: e),
        st,
      );
    }
  }

  Map<String, Object?> _toMap(SavingsGoal goal) => {
        'id': goal.id,
        'name': goal.name,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'created_at': goal.createdAt.toUtc().toIso8601String(),
        'updated_at': goal.updatedAt.toUtc().toIso8601String(),
      };

  SavingsGoal _fromMap(Map<String, Object?> row) {
    return SavingsGoal(
      id: row['id']! as String,
      name: row['name']! as String,
      targetAmount: row['target_amount']! as int,
      currentAmount: row['current_amount']! as int,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }
}

class PinRepositoryImpl implements PinRepository {
  PinRepositoryImpl(this._prefs);

  static const hashKey = 'pin_hash';
  static const saltKey = 'pin_salt';

  final PrefsLocalDataSource _prefs;

  @override
  Future<Result<PinRecord?>> load() async {
    try {
      final hash = await _prefs.get(hashKey);
      final salt = await _prefs.get(saltKey);
      if (hash == null || salt == null) return const Ok(null);
      return Ok(PinRecord(hash: hash, salt: salt));
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<void>> save(PinRecord record) async {
    try {
      await _prefs.set(hashKey, record.hash);
      await _prefs.set(saltKey, record.salt);
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }
}
