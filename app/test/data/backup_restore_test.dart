import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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

  test('export writes zip with manifest and sqlite snapshot', () async {
    final env = await _Env.create();
    await _insertTx(env.live.raw, id: 'keep-me', amount: 42000);
    final before = await env.live.raw.query('transactions', orderBy: 'id');

    final path = await env.exportBackup();
    expect(p.basename(path), 'tien-daune-2026-08-26-083045.tien-daune');

    final unpacked = const BackupFileManager().unpack(await File(path).readAsBytes());
    final manifest = BackupManifest.parse(
      jsonDecode(utf8.decode(unpacked.manifestBytes)),
      currentSchemaVersion: AppDatabase.schemaVersion,
    );
    expect(manifest.backupFormatVersion, 1);
    expect(manifest.databaseSchemaVersion, 5);
    expect(manifest.appVersion, '1.0.0+1');
    expect(manifest.createdAt.toUtc().toIso8601String(), '2026-08-26T08:30:45.000Z');
    expect(utf8.decode(unpacked.sqliteBytes.sublist(0, 15)), 'SQLite format 3');

    final after = await env.live.raw.query('transactions', orderBy: 'id');
    expect(after, before);
    await env.close();
  });

  test('valid v5 backup restores into a different live database', () async {
    final source = await _Env.create();
    await _insertTx(source.live.raw, id: 'from-backup', amount: 88000);
    final backup = await source.exportBackup();
    await source.close();

    final dest = await _Env.create();
    await _insertTx(dest.live.raw, id: 'live-only', amount: 1000);
    expect((await dest.restore.restore(backup)).isOk, isTrue);

    final rows = await dest.live.raw.query('transactions', orderBy: 'id');
    expect(rows.map((row) => row['id']), ['from-backup']);
    expect(rows.single['amount'], 88000);
    expect(await dest.live.userVersion(), 5);
    expect(await dest.live.integrityCheck(), 'ok');
    await dest.close();
  });

  test('v4 backup restores through existing onUpgrade into v5', () async {
    final dir = await Directory.systemTemp.createTemp('backup_v4');
    addTearDown(() => dir.delete(recursive: true));
    final v4Path = p.join(dir.path, 'legacy.db');
    final v4 = await _openV4(v4Path);
    await _insertTx(v4, id: 'old-expense', amount: 56000);
    await v4.insert('app_prefs', {'key': 'salary_amount', 'value': '18500000'});
    await v4.close();

    final backupPath = p.join(dir.path, 'from-v4.tien-daune');
    await File(backupPath).writeAsBytes(
      const BackupFileManager().pack(
        manifest: BackupManifest(
          backupFormatVersion: 1,
          databaseSchemaVersion: 4,
          appVersion: '0.9.0',
          createdAt: DateTime.utc(2026, 8, 1),
        ),
        sqliteBytes: await File(v4Path).readAsBytes(),
      ),
    );

    final dest = await _Env.create();
    await _insertTx(dest.live.raw, id: 'live-only', amount: 1);
    expect((await dest.restore.restore(backupPath)).isOk, isTrue);
    expect(await dest.live.userVersion(), 5);

    final rows = await dest.live.raw.query('transactions');
    expect(rows.single['id'], 'old-expense');
    expect(rows.single['amount'], 56000);
    final salary = await dest.live.raw.query(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: ['recurring_salary'],
    );
    expect(salary.single['amount'], 18500000);
    expect(
      await dest.live.raw.query(
        'app_prefs',
        where: 'key = ?',
        whereArgs: ['salary_amount'],
      ),
      isEmpty,
    );
    await dest.close();
  });

  test('newer schema backup is rejected and live data stays', () async {
    final env = await _Env.create();
    await _insertTx(env.live.raw, id: 'live-only', amount: 7000);
    final snapshot = p.join(env.dir.path, 'snap.sqlite');
    await env.live.snapshotTo(snapshot);
    final backup = p.join(env.dir.path, 'future.tien-daune');
    await File(backup).writeAsBytes(
      const BackupFileManager().pack(
        manifest: BackupManifest(
          backupFormatVersion: 1,
          databaseSchemaVersion: 99,
          appVersion: '9.0.0',
          createdAt: DateTime.utc(2026, 8, 26),
        ),
        sqliteBytes: await File(snapshot).readAsBytes(),
      ),
    );

    final result = await env.restore.restore(backup);
    expect(result.isErr, isTrue);
    expect(
      (result as Err).failure.message,
      contains('phiên bản ứng dụng mới hơn'),
    );
    final rows = await env.live.raw.query('transactions');
    expect(rows.single['id'], 'live-only');
    await env.close();
  });

  test('corrupted and incomplete backups are rejected', () async {
    final env = await _Env.create();
    await _insertTx(env.live.raw, id: 'live-only', amount: 9000);
    final sqlite = p.join(env.dir.path, 'ok.sqlite');
    await env.live.snapshotTo(sqlite);
    final sqliteBytes = await File(sqlite).readAsBytes();

    Future<void> expectReject(String path, String messagePart) async {
      final result = await env.restore.inspect(path);
      expect(result.isErr, isTrue, reason: path);
      expect((result as Err).failure, isA<BackupFailure>());
      expect((result as Err<BackupManifest>).failure.message, contains(messagePart));
      final rows = await env.live.raw.query('transactions');
      expect(rows.single['id'], 'live-only');
    }

    final corrupt = p.join(env.dir.path, 'bad.tien-daune');
    await File(corrupt).writeAsBytes(utf8.encode('not a zip'));
    await expectReject(corrupt, 'hỏng');

    final noManifest = p.join(env.dir.path, 'no-manifest.tien-daune');
    await File(noManifest).writeAsBytes(
      ZipEncoder().encode(
        Archive()..addFile(ArchiveFile.bytes('database.sqlite', sqliteBytes)),
      ),
    );
    await expectReject(noManifest, 'manifest.json');

    final noDb = p.join(env.dir.path, 'no-db.tien-daune');
    await File(noDb).writeAsBytes(
      const BackupFileManager().pack(
        manifest: BackupManifest(
          backupFormatVersion: 1,
          databaseSchemaVersion: 5,
          appVersion: '1.0.0',
          createdAt: DateTime.utc(2026, 8, 26),
        ),
        sqliteBytes: sqliteBytes,
      ).sublist(0, 0),
    );
    // empty file is corrupt zip; build a zip that only has manifest
    await File(noDb).writeAsBytes(
      ZipEncoder().encode(
        Archive()..addFile(
          ArchiveFile.string(
            'manifest.json',
            jsonEncode({
              'backup_format_version': 1,
              'database_schema_version': 5,
              'app_version': '1.0.0',
              'created_at': '2026-08-26T00:00:00.000Z',
            }),
          ),
        ),
      ),
    );
    await expectReject(noDb, 'database.sqlite');

    final invalidManifest = p.join(env.dir.path, 'invalid-manifest.tien-daune');
    await File(invalidManifest).writeAsBytes(
      ZipEncoder().encode(
        Archive()
          ..addFile(ArchiveFile.string('manifest.json', '{"nope":true}'))
          ..addFile(ArchiveFile.bytes('database.sqlite', sqliteBytes)),
      ),
    );
    await expectReject(invalidManifest, 'không hợp lệ');

    final unsupported = p.join(env.dir.path, 'format2.tien-daune');
    await File(unsupported).writeAsBytes(
      ZipEncoder().encode(
        Archive()
          ..addFile(
            ArchiveFile.string(
              'manifest.json',
              jsonEncode({
                'backup_format_version': 2,
                'database_schema_version': 5,
                'app_version': '1.0.0',
                'created_at': '2026-08-26T00:00:00.000Z',
              }),
            ),
          )
          ..addFile(ArchiveFile.bytes('database.sqlite', sqliteBytes)),
      ),
    );
    await expectReject(unsupported, 'không được hỗ trợ');

    final wrongExt = p.join(env.dir.path, 'backup.zip');
    await File(wrongExt).writeAsBytes(await File(await env.exportBackup()).readAsBytes());
    await expectReject(wrongExt, '.tien-daune');

    await env.close();
  });

  test('failed restore does not destroy existing data', () async {
    final env = await _Env.create();
    await _insertTx(env.live.raw, id: 'live-only', amount: 12345);
    final before = await env.live.raw.query('transactions');

    final fakeDb = p.join(env.dir.path, 'not-sqlite.tien-daune');
    await File(fakeDb).writeAsBytes(
      const BackupFileManager().pack(
        manifest: BackupManifest(
          backupFormatVersion: 1,
          databaseSchemaVersion: 5,
          appVersion: '1.0.0',
          createdAt: DateTime.utc(2026, 8, 26),
        ),
        sqliteBytes: utf8.encode('this is not sqlite'),
      ),
    );

    expect((await env.restore.restore(fakeDb)).isErr, isTrue);
    final after = await env.live.raw.query('transactions');
    expect(after, before);
    expect(await env.live.userVersion(), 5);
    await env.close();
  });

  test('manifest schema mismatch with sqlite user_version is rejected', () async {
    final env = await _Env.create();
    await _insertTx(env.live.raw, id: 'live-only', amount: 55);
    final snapshot = p.join(env.dir.path, 'snap.sqlite');
    await env.live.snapshotTo(snapshot);
    final backup = p.join(env.dir.path, 'mismatch.tien-daune');
    await File(backup).writeAsBytes(
      const BackupFileManager().pack(
        manifest: BackupManifest(
          backupFormatVersion: 1,
          databaseSchemaVersion: 4,
          appVersion: '1.0.0',
          createdAt: DateTime.utc(2026, 8, 26),
        ),
        sqliteBytes: await File(snapshot).readAsBytes(),
      ),
    );

    final result = await env.restore.inspect(backup);
    expect(result.isErr, isTrue);
    expect((result as Err).failure.message, contains('không khớp'));
    final rows = await env.live.raw.query('transactions');
    expect(rows.single['id'], 'live-only');
    await env.close();
  });
}

class _Env {
  _Env(this.dir, this.live)
      : backup = BackupService(
          database: live,
          appVersion: '1.0.0+1',
          clock: () => DateTime.utc(2026, 8, 26, 8, 30, 45),
          temporaryDirectory: () async => dir,
        ),
        restore = RestoreService(
          live: live,
          createWorkDir: () => Directory.systemTemp.createTempSync('restore_work'),
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

Future<Database> _openV4(String path) {
  return databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 4,
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
CREATE INDEX IF NOT EXISTS idx_transactions_type_date_time
ON transactions(type, occurred_date DESC, occurred_time DESC, created_at DESC)
''');
        await db.execute('''
CREATE INDEX IF NOT EXISTS idx_transactions_type_category_date
ON transactions(type, category_id, occurred_date DESC, occurred_time DESC)
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
      },
    ),
  );
}
