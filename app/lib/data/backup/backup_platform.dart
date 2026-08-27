import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/backup/backup_manifest.dart';
import 'backup_ports.dart';

class SharePlusBackupShare implements BackupSharePort {
  const SharePlusBackupShare();

  @override
  Future<void> share(String path) {
    return SharePlus.instance.share(ShareParams(files: [XFile(path)]));
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
