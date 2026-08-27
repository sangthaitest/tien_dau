import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/backup/backup_data_codec.dart';
import '../data/backup/backup_file_manager.dart';
import '../data/db/app_database.dart';
import '../domain/backup/backup_manifest.dart';
import '../domain/failures/app_failure.dart';
import '../domain/failures/result.dart';

class RestoreService {
  RestoreService({
    required AppDatabase live,
    BackupFileManager fileManager = const BackupFileManager(),
    BackupDataCodec codec = const BackupDataCodec(),
    Directory Function()? createWorkDir,
  }) : _live = live,
       _fileManager = fileManager,
       _codec = codec,
       _tempDir = createWorkDir ??
           (() => Directory.systemTemp.createTempSync('tien_day_restore'));

  final AppDatabase _live;
  final BackupFileManager _fileManager;
  final BackupDataCodec _codec;
  final Directory Function() _tempDir;

  Future<Result<BackupPreview>> inspect(String path) async {
    try {
      final document = await _readAndValidate(path);
      return Ok(BackupPreview(document: document, path: path));
    } on AppFailure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(
        BackupFailure(
          'File không phải bản sao lưu hợp lệ của Tiền đâu nè hoặc file đã bị hỏng.',
          cause: error,
        ),
      );
    }
  }

  Future<Result<void>> restore(String path) async {
    Directory? work;
    try {
      final document = await _readAndValidate(path);
      work = _tempDir();
      await work.create(recursive: true);

      final materialPath = p.join(work.path, 'restored.sqlite');
      await _codec.materialize(document, materialPath);

      final pinPrefs = await _codec.readPinPrefs(_live);
      final safetyPath = p.join(work.path, 'safety.sqlite');
      await _live.snapshotTo(safetyPath);

      try {
        await _live.replaceLiveDatabase(materialPath);
        await _codec.writePinPrefs(_live, pinPrefs);
      } catch (error) {
        try {
          await _live.replaceLiveDatabase(safetyPath);
          await _codec.writePinPrefs(_live, pinPrefs);
        } catch (_) {}
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

  Future<BackupDocument> _readAndValidate(String path) async {
    if (!BackupFormat.hasValidExtension(path)) {
      throw const BackupFailure(
        'File không phải bản sao lưu hợp lệ của Tiền đâu nè hoặc file đã bị hỏng.',
      );
    }
    final file = File(path);
    if (!await file.exists()) {
      throw const BackupFailure('Không tìm thấy tệp sao lưu.');
    }
    return _fileManager.unpack(await file.readAsBytes());
  }

  Future<void> _deleteDir(Directory? dir) async {
    if (dir == null) return;
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
