import 'dart:convert';
import 'dart:typed_data';

import '../../domain/backup/backup_manifest.dart';
import '../../domain/failures/app_failure.dart';

class BackupFileManager {
  const BackupFileManager();

  Uint8List pack(BackupDocument document) {
    return Uint8List.fromList(utf8.encode(document.encode()));
  }

  BackupDocument unpack(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const BackupFailure(
        'File không phải bản sao lưu hợp lệ của Tiền đâu nè hoặc file đã bị hỏng.',
      );
    }
    return BackupDocument.parseBytes(bytes);
  }
}
