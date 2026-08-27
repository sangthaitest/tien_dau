import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_info.dart';
import '../data/backup/backup_file_manager.dart';
import '../data/db/app_database.dart';
import '../domain/backup/backup_manifest.dart';
import '../domain/failures/app_failure.dart';
import '../domain/failures/result.dart';

class BackupService {
  BackupService({
    required AppDatabase database,
    BackupFileManager fileManager = const BackupFileManager(),
    String appVersion = AppInfo.version,
    DateTime Function()? clock,
    Future<Directory> Function()? temporaryDirectory,
  }) : _database = database,
       _fileManager = fileManager,
       _appVersion = appVersion,
       _clock = clock ?? DateTime.now,
       _temporaryDirectory =
           temporaryDirectory ?? getTemporaryDirectory;

  final AppDatabase _database;
  final BackupFileManager _fileManager;
  final String _appVersion;
  final DateTime Function() _clock;
  final Future<Directory> Function() _temporaryDirectory;

  Future<Result<String>> export() async {
    Directory? work;
    try {
      final now = _clock();
      final root = await _temporaryDirectory();
      work = Directory(
        p.join(root.path, 'tien_day_backup_${now.microsecondsSinceEpoch}'),
      );
      await work.create(recursive: true);
      final snapshotPath = p.join(work.path, BackupFormat.databaseName);
      await _database.snapshotTo(snapshotPath);
      final sqliteBytes = await File(snapshotPath).readAsBytes();
      final schemaVersion = await _database.userVersion();
      final manifest = BackupManifest(
        backupFormatVersion: BackupFormat.version,
        databaseSchemaVersion: schemaVersion,
        appVersion: _appVersion,
        createdAt: now.toUtc(),
      );
      final packed = _fileManager.pack(
        manifest: manifest,
        sqliteBytes: sqliteBytes,
      );
      final outPath = p.join(work.path, BackupFormat.fileNameFor(now));
      await File(outPath).writeAsBytes(packed, flush: true);
      return Ok(outPath);
    } on AppFailure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(BackupFailure('Không thể tạo bản sao lưu.', cause: error));
    }
  }
}
