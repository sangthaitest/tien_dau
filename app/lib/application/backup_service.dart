import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_info.dart';
import '../data/backup/backup_data_codec.dart';
import '../data/backup/backup_file_manager.dart';
import '../data/db/app_database.dart';
import '../domain/backup/backup_manifest.dart';
import '../domain/failures/app_failure.dart';
import '../domain/failures/result.dart';

class BackupService {
  BackupService({
    required AppDatabase database,
    BackupFileManager fileManager = const BackupFileManager(),
    BackupDataCodec codec = const BackupDataCodec(),
    String appVersion = AppInfo.version,
    String? platform,
    DateTime Function()? clock,
    Future<Directory> Function()? temporaryDirectory,
  }) : _database = database,
       _fileManager = fileManager,
       _codec = codec,
       _appVersion = appVersion,
       _platform = platform,
       _clock = clock ?? DateTime.now,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final AppDatabase _database;
  final BackupFileManager _fileManager;
  final BackupDataCodec _codec;
  final String _appVersion;
  final String? _platform;
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

      final document = await _codec.exportDocument(
        database: _database,
        appVersion: _appVersion,
        platform: _platform ?? _detectPlatform(),
        createdAt: now.toUtc(),
      );
      final packed = _fileManager.pack(document);
      final outPath = p.join(work.path, BackupFormat.fileNameFor(now));
      await File(outPath).writeAsBytes(packed, flush: true);
      // Stamp only after the user actually saves/shares the file.
      return Ok(outPath);
    } on AppFailure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(BackupFailure('Không thể tạo bản sao lưu.', cause: error));
    }
  }

  Future<Result<void>> markLastBackup({DateTime? at}) async {
    try {
      await _codec.writeLastBackupAt(_database, (at ?? _clock()).toUtc());
      return const Ok(null);
    } on AppFailure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(
        BackupFailure('Không thể ghi thời điểm sao lưu.', cause: error),
      );
    }
  }

  Future<DateTime?> lastBackupAt() => _codec.readLastBackupAt(_database);

  static String _detectPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }
}
