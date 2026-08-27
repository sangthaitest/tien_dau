/// Keep in sync with `pubspec.yaml` version.
class AppInfo {
  static const version = '1.0.0+1';

  /// User-facing version label for Settings (build metadata stripped).
  static String get displayVersion {
    final core = version.split('+').first;
    return core.startsWith('v') ? core : 'v$core';
  }
}
