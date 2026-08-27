import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/application/backup_service.dart';
import 'package:tien_day/application/restore_service.dart';
import 'package:tien_day/data/backup/backup_file_manager.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/domain/backup/backup_manifest.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('export writes portable .tdn without sqlite or pin', () async {
    final env = await _Env.create();
    await _insertTx(env.live.raw, id: 'keep-me', amount: 42000);
    await env.live.raw.insert('app_prefs', {
      'key': 'pin_hash',
      'value': 'secret-hash',
    });
    await env.live.raw.insert('app_prefs', {
      'key': 'pin_salt',
      'value': 'secret-salt',
    });
    await env.live.raw.insert('app_prefs', {
      'key': 'settings_dark_mode',
      'value': '1',
    });
    await env.live.raw.insert('recurring_transactions', _salaryRow());
    await env.live.raw.insert('savings_goals', {
      'id': 'goal-1',
      'name': 'Du lịch',
      'target_amount': 5000000,
      'current_amount': 1000000,
      'created_at': '2026-08-01T00:00:00.000Z',
      'updated_at': '2026-08-01T00:00:00.000Z',
    });

    final path = await env.exportBackup();
    expect(p.basename(path), 'TienDauNe_Backup_2026-08-26_1435.tdn');

    final document = const BackupFileManager().unpack(await File(path).readAsBytes());
    expect(document.backupVersion, 1);
    expect(document.appVersion, '1.0.0+1');
    expect(document.platform, 'test');
    expect(document.summary.transactionCount, 1);
    expect(document.summary.incomeCount, 1);
    expect(document.summary.includesFinance, isTrue);
    expect(document.prefs.containsKey('pin_hash'), isFalse);
    expect(document.prefs.containsKey('pin_salt'), isFalse);
    expect(document.prefs['settings_dark_mode'], '1');
    expect(utf8.decode(await File(path).readAsBytes()).contains('SQLite format 3'), isFalse);

    final last = await env.backup.lastBackupAt();
    expect(last, DateTime(2026, 8, 26, 14, 35).toUtc());
    await env.close();
  });

  test('valid .tdn restores replace-all including finance and keeps device pin', () async {
    final source = await _Env.create();
    await _insertTx(source.live.raw, id: 'from-backup', amount: 88000);
    await source.live.raw.insert('recurring_transactions', _salaryRow(amount: 20000000));
    await source.live.raw.insert('app_prefs', {
      'key': 'budget_limit',
      'value': '10000000',
    });
    final backup = await source.exportBackup();
    await source.close();

    final dest = await _Env.create();
    await _insertTx(dest.live.raw, id: 'live-only', amount: 1000);
    await dest.live.raw.insert('app_prefs', {
      'key': 'pin_hash',
      'value': 'device-hash',
    });
    await dest.live.raw.insert('app_prefs', {
      'key': 'pin_salt',
      'value': 'device-salt',
    });

    final preview = await dest.restore.inspect(backup);
    expect(preview.isOk, isTrue);
    final shown = (preview as Ok<BackupPreview>).value;
    expect(shown.summary.transactionCount, 1);
    expect(shown.summary.incomeCount, 1);
    expect(shown.summary.includesFinance, isTrue);

    expect((await dest.restore.restore(backup)).isOk, isTrue);

    final rows = await dest.live.raw.query('transactions', orderBy: 'id');
    expect(rows.map((row) => row['id']), ['from-backup']);
    expect(rows.single['amount'], 88000);

    final salary = await dest.live.raw.query(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: ['recurring_salary'],
    );
    expect(salary.single['amount'], 20000000);

    final budget = await dest.live.raw.query(
      'app_prefs',
      where: 'key = ?',
      whereArgs: ['budget_limit'],
    );
    expect(budget.single['value'], '10000000');

    final pin = await dest.live.raw.query(
      'app_prefs',
      where: 'key IN (?, ?)',
      whereArgs: ['pin_hash', 'pin_salt'],
    );
    expect(
      {for (final row in pin) row['key']: row['value']},
      {'pin_hash': 'device-hash', 'pin_salt': 'device-salt'},
    );
    await dest.close();
  });

  test('corrupt and unsupported backups are rejected without changing live data', () async {
    final env = await _Env.create();
    await _insertTx(env.live.raw, id: 'live-only', amount: 9000);

    Future<void> expectReject(String path, String messagePart) async {
      final result = await env.restore.inspect(path);
      expect(result.isErr, isTrue, reason: path);
      expect((result as Err).failure, isA<BackupFailure>());
      expect((result as Err<BackupPreview>).failure.message, contains(messagePart));
      final rows = await env.live.raw.query('transactions');
      expect(rows.single['id'], 'live-only');
    }

    final corrupt = p.join(env.dir.path, 'bad.tdn');
    await File(corrupt).writeAsBytes(utf8.encode('not-json'));
    await expectReject(corrupt, 'bản sao lưu hợp lệ');

    final wrongFormat = p.join(env.dir.path, 'wrong.tdn');
    await File(wrongFormat).writeAsString(jsonEncode({
      'format': 'OtherBackup',
      'backupVersion': 1,
      'createdAt': '2026-08-26T00:00:00.000Z',
      'appVersion': '1.0.0',
      'platform': 'test',
      'summary': {
        'transactionCount': 0,
        'categoryCount': 0,
        'incomeCount': 0,
        'recurringCount': 0,
        'includesFinance': true,
      },
      'financial': {'savingsGoals': [], 'recurring': []},
      'transactions': [],
      'categories': {'version': 1, 'categories': [], 'payments': []},
      'settings': {},
    }));
    await expectReject(wrongFormat, 'bản sao lưu hợp lệ');

    final unsupported = p.join(env.dir.path, 'v99.tdn');
    await File(unsupported).writeAsString(jsonEncode({
      'format': BackupFormat.name,
      'backupVersion': 99,
      'createdAt': '2026-08-26T00:00:00.000Z',
      'appVersion': '9.0.0',
      'platform': 'test',
      'summary': {
        'transactionCount': 0,
        'categoryCount': 0,
        'incomeCount': 0,
        'recurringCount': 0,
        'includesFinance': true,
      },
      'financial': {'savingsGoals': [], 'recurring': []},
      'transactions': [],
      'categories': {'version': 1, 'categories': [], 'payments': []},
      'settings': {},
    }));
    await expectReject(unsupported, 'không được hỗ trợ');

    final wrongExt = p.join(env.dir.path, 'backup.json');
    await File(wrongExt).writeAsBytes(await File(await env.exportBackup()).readAsBytes());
    await expectReject(wrongExt, 'không phải bản sao lưu hợp lệ');

    await env.close();
  });

  test('empty database export and restore round-trip', () async {
    final source = await _Env.create();
    final backup = await source.exportBackup();
    final document = const BackupFileManager().unpack(await File(backup).readAsBytes());
    expect(document.summary.transactionCount, 0);
    expect(document.summary.includesFinance, isTrue);
    await source.close();

    final dest = await _Env.create();
    await _insertTx(dest.live.raw, id: 'wipe-me', amount: 1);
    expect((await dest.restore.restore(backup)).isOk, isTrue);
    expect(await dest.live.raw.query('transactions'), isEmpty);
    await dest.close();
  });
}

class _Env {
  _Env(this.dir, this.live)
      : backup = BackupService(
          database: live,
          appVersion: '1.0.0+1',
          platform: 'test',
          clock: () => DateTime(2026, 8, 26, 14, 35),
          temporaryDirectory: () async => dir,
        ),
        restore = RestoreService(
          live: live,
          createWorkDir: () =>
              Directory.systemTemp.createTempSync('restore_work'),
        );

  final Directory dir;
  final AppDatabase live;
  final BackupService backup;
  final RestoreService restore;

  static Future<_Env> create() async {
    final dir = await Directory.systemTemp.createTemp('tien_day_backup');
    addTearDown(() async {
      try {
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (_) {}
    });
    final live = await AppDatabase.openPath(p.join(dir.path, 'live.db'));
    return _Env(dir, live);
  }

  Future<String> exportBackup() async {
    final result = await backup.export();
    expect(result.isOk, isTrue);
    return (result as Ok<String>).value;
  }

  Future<void> close() async {
    await live.close();
  }
}

Future<void> _insertTx(Database db, {required String id, required int amount}) {
  return db.insert('transactions', {
    'id': id,
    'amount': amount,
    'type': 'expense',
    'category_id': 'cafe',
    'detail': null,
    'occurred_date': '2026-08-18',
    'occurred_time': '09:00',
    'payment_source_id': 'cash',
    'payment_source_name': 'Tiền mặt',
    'payment_method': 'cash',
    'note': null,
    'created_at': '2026-08-18T02:00:00.000Z',
    'updated_at': '2026-08-18T02:00:00.000Z',
  });
}

Map<String, Object?> _salaryRow({int amount = 18500000}) => {
      'id': 'recurring_salary',
      'name': 'Lương',
      'kind': 'income',
      'amount': amount,
      'frequency': 'monthly',
      'interval_count': 1,
      'direction': 'add',
      'category_id': null,
      'detail': null,
      'payment_source_id': null,
      'note': null,
      'start_date': '2026-01-01',
      'end_date': null,
      'is_active': 1,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    };
