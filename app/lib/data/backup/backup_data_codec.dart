import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/backup/backup_manifest.dart';
import '../../domain/failures/app_failure.dart';
import '../db/app_database.dart';

/// Reads portable rows from the live DB and materializes a document back into SQLite.
class BackupDataCodec {
  const BackupDataCodec();

  Future<BackupDocument> exportDocument({
    required AppDatabase database,
    required String appVersion,
    required String platform,
    required DateTime createdAt,
  }) async {
    final db = database.raw;
    final transactions = await db.query('transactions', orderBy: 'id ASC');
    final goals = await db.query('savings_goals', orderBy: 'id ASC');
    final recurring =
        await db.query('recurring_transactions', orderBy: 'id ASC');
    final prefRows = await db.query('app_prefs', orderBy: 'key ASC');

    final prefs = <String, String>{};
    for (final row in prefRows) {
      final key = row['key']?.toString();
      final value = row['value']?.toString();
      if (key == null || value == null) continue;
      if (BackupFormat.excludedPrefKeys.contains(key)) continue;
      prefs[key] = value;
    }

    final categories = _categoriesFromPrefs(prefs);
    final incomeCount =
        recurring.where((row) => row['kind']?.toString() == 'income').length;
    final recurringCount =
        recurring.where((row) => row['kind']?.toString() != 'income').length;

    return BackupDocument(
      backupVersion: BackupFormat.version,
      createdAt: createdAt.toUtc(),
      appVersion: appVersion,
      platform: platform,
      summary: BackupSummary(
        transactionCount: transactions.length,
        categoryCount: _categoryCount(categories),
        incomeCount: incomeCount,
        recurringCount: recurringCount,
        includesFinance: true,
      ),
      transactions: [
        for (final row in transactions) _stringifyRow(row),
      ],
      categories: categories,
      recurring: [
        for (final row in recurring) _stringifyRow(row),
      ],
      savingsGoals: [
        for (final row in goals) _stringifyRow(row),
      ],
      prefs: prefs,
    );
  }

  /// Builds a fresh schema DB at [sqlitePath] from [document]. Does not touch live DB.
  Future<void> materialize(BackupDocument document, String sqlitePath) async {
    final db = await AppDatabase.openPath(sqlitePath);
    try {
      await db.raw.transaction((txn) async {
        await txn.delete('transactions');
        await txn.delete('savings_goals');
        await txn.delete('recurring_transactions');
        await txn.delete('app_prefs');

        for (final row in document.transactions) {
          await txn.insert(
            'transactions',
            _transactionRow(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final row in document.savingsGoals) {
          await txn.insert(
            'savings_goals',
            _goalRow(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final row in document.recurring) {
          await txn.insert(
            'recurring_transactions',
            _recurringRow(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final entry in document.prefs.entries) {
          if (BackupFormat.excludedPrefKeys.contains(entry.key)) continue;
          await txn.insert(
            'app_prefs',
            {'key': entry.key, 'value': entry.value},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        if (!document.prefs.containsKey('transaction_catalog_v1')) {
          await txn.insert(
            'app_prefs',
            {
              'key': 'transaction_catalog_v1',
              'value': jsonEncode(document.categories),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      final integrity = await db.integrityCheck();
      if (integrity != 'ok') {
        throw BackupFailure('Không thể chuẩn bị dữ liệu khôi phục ($integrity).');
      }
    } finally {
      await db.close();
    }
  }

  Future<Map<String, String>> readPinPrefs(AppDatabase database) async {
    final rows = await database.raw.query(
      'app_prefs',
      where: 'key IN (?, ?)',
      whereArgs: const ['pin_hash', 'pin_salt'],
    );
    return {
      for (final row in rows)
        if (row['key'] is String && row['value'] is String)
          row['key'] as String: row['value'] as String,
    };
  }

  Future<void> writePinPrefs(
    AppDatabase database,
    Map<String, String> pinPrefs,
  ) async {
    await database.raw.transaction((txn) async {
      await txn.delete(
        'app_prefs',
        where: 'key IN (?, ?)',
        whereArgs: const ['pin_hash', 'pin_salt'],
      );
      for (final entry in pinPrefs.entries) {
        await txn.insert(
          'app_prefs',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> writeLastBackupAt(AppDatabase database, DateTime at) async {
    await database.raw.insert(
      'app_prefs',
      {
        'key': BackupFormat.lastBackupAtKey,
        'value': at.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> readLastBackupAt(AppDatabase database) async {
    final rows = await database.raw.query(
      'app_prefs',
      where: 'key = ?',
      whereArgs: [BackupFormat.lastBackupAtKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value']?.toString() ?? '');
  }

  Map<String, Object?> _categoriesFromPrefs(Map<String, String> prefs) {
    final raw = prefs['transaction_catalog_v1'];
    if (raw == null || raw.isEmpty) {
      return const {
        'version': 1,
        'categories': <Object?>[],
        'payments': <Object?>[],
      };
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return {
          for (final entry in decoded.entries)
            entry.key.toString(): entry.value as Object?,
        };
      }
    } catch (_) {}
    return const {
      'version': 1,
      'categories': <Object?>[],
      'payments': <Object?>[],
    };
  }

  int _categoryCount(Map<String, Object?> categories) {
    final list = categories['categories'];
    if (list is List) return list.length;
    return 0;
  }

  Map<String, Object?> _stringifyRow(Map<String, Object?> row) {
    return {
      for (final entry in row.entries) entry.key: entry.value,
    };
  }

  Map<String, Object?> _transactionRow(Map<String, Object?> row) {
    return {
      'id': row['id']?.toString(),
      'amount': _asInt(row['amount']) ?? 0,
      'type': row['type']?.toString(),
      'category_id': row['category_id']?.toString(),
      'detail': row['detail']?.toString(),
      'occurred_date': row['occurred_date']?.toString(),
      'occurred_time': row['occurred_time']?.toString(),
      'payment_source_id': row['payment_source_id']?.toString(),
      'payment_source_name': row['payment_source_name']?.toString(),
      'payment_method': row['payment_method']?.toString(),
      'note': row['note']?.toString(),
      'created_at': row['created_at']?.toString(),
      'updated_at': row['updated_at']?.toString(),
    };
  }

  Map<String, Object?> _goalRow(Map<String, Object?> row) {
    return {
      'id': row['id']?.toString(),
      'name': row['name']?.toString(),
      'target_amount': _asInt(row['target_amount']) ?? 0,
      'current_amount': _asInt(row['current_amount']) ?? 0,
      'created_at': row['created_at']?.toString(),
      'updated_at': row['updated_at']?.toString(),
    };
  }

  Map<String, Object?> _recurringRow(Map<String, Object?> row) {
    return {
      'id': row['id']?.toString(),
      'name': row['name']?.toString(),
      'kind': row['kind']?.toString(),
      'amount': _asInt(row['amount']) ?? 0,
      'frequency': row['frequency']?.toString(),
      'interval_count': _asInt(row['interval_count']) ?? 1,
      'direction': row['direction']?.toString(),
      'category_id': row['category_id']?.toString(),
      'detail': row['detail']?.toString(),
      'payment_source_id': row['payment_source_id']?.toString(),
      'note': row['note']?.toString(),
      'start_date': row['start_date']?.toString(),
      'end_date': row['end_date']?.toString(),
      'is_active': _asInt(row['is_active']) ?? 1,
      'created_at': row['created_at']?.toString(),
      'updated_at': row['updated_at']?.toString(),
    };
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
