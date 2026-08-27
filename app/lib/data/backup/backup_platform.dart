import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../domain/backup/backup_manifest.dart';
import 'backup_ports.dart';

/// Prefers an explicit "Save as" dialog so the user chooses where `.tdn` goes.
/// Falls back to the system share sheet if save is unavailable.
class SharePlusBackupShare implements BackupSharePort {
  const SharePlusBackupShare();

  @override
  Future<bool> deliver(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final bytes = Uint8List.fromList(await file.readAsBytes());
    final name = p.basename(path);

    try {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Lưu bản sao lưu Tiền đâu nè',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: [BackupFormat.fileExtension],
        bytes: bytes,
        mimeType: 'application/x-tien-daune-backup',
      );
      return savedUri != null;
    } catch (_) {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
      return true;
    }
  }
}

class FilePickerBackupPick implements BackupPickPort {
  const FilePickerBackupPick();

  @override
  Future<String?> pickBackup() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [BackupFormat.fileExtension],
    );
    return file?.path;
  }
}
