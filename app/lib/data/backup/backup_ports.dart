abstract class BackupSharePort {
  Future<void> share(String path);
}

abstract class BackupPickPort {
  Future<String?> pickBackup();
}
