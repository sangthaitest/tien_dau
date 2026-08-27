import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../domain/backup/backup_manifest.dart';
import '../../domain/failures/app_failure.dart';

class UnpackedBackup {
  const UnpackedBackup({
    required this.manifestBytes,
    required this.sqliteBytes,
  });

  final Uint8List manifestBytes;
  final Uint8List sqliteBytes;
}

class BackupFileManager {
  const BackupFileManager();

  Uint8List pack({
    required BackupManifest manifest,
    required List<int> sqliteBytes,
  }) {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          BackupFormat.manifestName,
          const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
        ),
      )
      ..addFile(ArchiveFile.bytes(BackupFormat.databaseName, sqliteBytes));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  UnpackedBackup unpack(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const BackupFailure('Bản sao lưu bị hỏng.');
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (error) {
      throw BackupFailure('Bản sao lưu bị hỏng.', cause: error);
    }
    final files = <String, ArchiveFile>{};
    for (final file in archive) {
      if (!file.isFile) continue;
      files[_baseName(file.name)] = file;
    }
    if (files.isEmpty) {
      throw const BackupFailure('Bản sao lưu bị hỏng.');
    }
    final manifest = files[BackupFormat.manifestName];
    final database = files[BackupFormat.databaseName];
    if (manifest == null) {
      throw const BackupFailure('Thiếu manifest.json trong bản sao lưu.');
    }
    if (database == null) {
      throw const BackupFailure('Thiếu database.sqlite trong bản sao lưu.');
    }
    return UnpackedBackup(
      manifestBytes: Uint8List.fromList(manifest.content),
      sqliteBytes: Uint8List.fromList(database.content),
    );
  }

  String _baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? normalized : parts.last;
  }
}
