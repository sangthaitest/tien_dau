abstract class BackupSharePort {
  /// Delivers the `.tdn` to the user (Save As / share).
  /// Returns `true` if the user completed a save or share action.
  Future<bool> deliver(String path);
}

abstract class BackupPickPort {
  Future<String?> pickBackup();
}
