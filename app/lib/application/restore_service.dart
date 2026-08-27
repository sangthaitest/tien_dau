import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/backup/backup_file_manager.dart';
import '../data/db/app_database.dart';
import '../domain/backup/backup_manifest.dart';
import '../domain/failures/app_failure.dart';
import '../domain/failures/result.dart';

class RestoreService {
  RestoreService({
    required AppDatabase live,
    BackupFileManager fileManager = const BackupFileManager(),
    Directory Function()? createWorkDir,
  }) : _live = live,
       _fileManager = fileManager,
       _tempDir = createWorkDir ??
           (() => Directory.systemTemp.createTempSync('tien_day_restore'));

  final AppDatabase _live;
  final BackupFileManager _fileManager;
  final Directory Function() _tempDir;

  static const _sqliteHeader = 'SQLite format 3';

  Future<Result<BackupManifest>> inspect(String path) async {
    Directory? work;
    try {
      work = await _extractToTemp(path);
      final prepared = await _validateExtracted(work);
      await prepared.migrated.close();
      return Ok(prepared.manifest);
    } on AppFailure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(BackupFailure('Không thể đọc bản sao lưu.', cause: error));
    } finally {
      await _deleteDir(work);
    }
  }

  Future<Result<void>> restore(String path) async {
    Directory? work;
    try {
      work = await _extractToTemp(path);
      final prepared = await _validateExtracted(work);
      await prepared.migrated.close();

      final safetyPath = p.join(work.path, 'safety.sqlite');
      await _live.snapshotTo(safetyPath);
      try {
        await _live.replaceLiveDatabase(prepared.migratedSqlitePath);
      } catch (error) {
        await _live.replaceLiveDatabase(safetyPath);
        throw BackupFailure(
          'Không thể khôi phục dữ liệu. Dữ liệu hiện tại được giữ nguyên.',
          cause: error,
        );
      }
      return const Ok(null);
    } on AppFailure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(
        BackupFailure(
          'Không thể khôi phục dữ liệu. Dữ liệu hiện tại được giữ nguyên.',
          cause: error,
        ),
      );
    } finally {
      await _deleteDir(work);
    }
  }

  Future<Directory> _extractToTemp(String path) async {
    if (!BackupFormat.hasValidExtension(path)) {
      throw const BackupFailure(
        'Chỉ hỗ trợ tệp .tien-daune.',
      );
    }
    final file = File(path);
    if (!await file.exists()) {
      throw const BackupFailure('Không tìm thấy tệp sao lưu.');
    }
    final unpacked = _fileManager.unpack(await file.readAsBytes());
    final work = _tempDir();
    await work.create(recursive: true);
    await File(p.join(work.path, BackupFormat.manifestName))
        .writeAsBytes(unpacked.manifestBytes, flush: true);
    await File(p.join(work.path, BackupFormat.databaseName))
        .writeAsBytes(unpacked.sqliteBytes, flush: true);
    return work;
  }

  Future<_PreparedRestore> _validateExtracted(Directory work) async {
    final manifestFile = File(p.join(work.path, BackupFormat.manifestName));
    final sqliteFile = File(p.join(work.path, BackupFormat.databaseName));
    Object? manifestJson;
    try {
      manifestJson = jsonDecode(utf8.decode(await manifestFile.readAsBytes()));
    } catch (error) {
      throw BackupFailure('Manifest sao lưu không hợp lệ.', cause: error);
    }
    final manifest = BackupManifest.parse(
      manifestJson,
      currentSchemaVersion: AppDatabase.schemaVersion,
    );

    final sqliteBytes = await sqliteFile.readAsBytes();
    _assertSqliteHeader(sqliteBytes);

    final packedVersion = await _readUserVersion(sqliteFile.path);
    if (packedVersion != manifest.databaseSchemaVersion) {
      throw const BackupFailure('Phiên bản cơ sở dữ liệu trong bản sao lưu không khớp.');
    }
    if (packedVersion > AppDatabase.schemaVersion) {
      throw const BackupFailure(
        'Bản sao lưu đến từ phiên bản ứng dụng mới hơn. Hãy cập nhật ứng dụng rồi thử lại.',
      );
    }

    final workSqlite = p.join(work.path, 'migrated.sqlite');
    await sqliteFile.copy(workSqlite);
    final migrated = await AppDatabase.openPath(workSqlite);
    try {
      final integrity = await migrated.integrityCheck();
      if (integrity != 'ok') {
        throw BackupFailure('Cơ sở dữ liệu trong bản sao lưu bị hỏng ($integrity).');
      }
      if (await migrated.userVersion() != AppDatabase.schemaVersion) {
        throw const BackupFailure('Không thể nâng cấp bản sao lưu lên phiên bản hiện tại.');
      }
      await _assertRequiredTables(migrated.raw);
    } catch (error) {
      await migrated.close();
      if (error is AppFailure) rethrow;
      throw BackupFailure('Bản sao lưu không phải cơ sở dữ liệu hợp lệ.', cause: error);
    }
    return _PreparedRestore(
      manifest: manifest,
      migrated: migrated,
      migratedSqlitePath: workSqlite,
    );
  }

  void _assertSqliteHeader(Uint8List bytes) {
    if (bytes.length < 16) {
      throw const BackupFailure('Bản sao lưu không phải cơ sở dữ liệu hợp lệ.');
    }
    final header = utf8.decode(bytes.sublist(0, 15), allowMalformed: true);
    if (header != _sqliteHeader) {
      throw const BackupFailure('Bản sao lưu không phải cơ sở dữ liệu hợp lệ.');
    }
  }

  Future<int> _readUserVersion(String sqlitePath) async {
    final probe = await openDatabase(
      sqlitePath,
      readOnly: true,
      singleInstance: false,
    );
    try {
      final rows = await probe.rawQuery('PRAGMA user_version');
      return (rows.first['user_version'] as num).toInt();
    } finally {
      await probe.close();
    }
  }

  Future<void> _assertRequiredTables(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = {for (final row in rows) row['name'] as String};
    const required = {
      'transactions',
      'app_prefs',
      'savings_goals',
      'recurring_transactions',
    };
    final missing = required.difference(names);
    if (missing.isNotEmpty) {
      throw BackupFailure(
        'Bản sao lưu thiếu bảng dữ liệu: ${missing.join(', ')}.',
      );
    }
  }

  Future<void> _deleteDir(Directory? dir) async {
    if (dir == null) return;
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}

class _PreparedRestore {
  const _PreparedRestore({
    required this.manifest,
    required this.migrated,
    required this.migratedSqlitePath,
  });

  final BackupManifest manifest;
  final AppDatabase migrated;
  final String migratedSqlitePath;
}
