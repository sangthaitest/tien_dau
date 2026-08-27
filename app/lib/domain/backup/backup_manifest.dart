import '../failures/app_failure.dart';

class BackupFormat {
  static const version = 1;
  static const fileExtension = 'tien-daune';
  static const manifestName = 'manifest.json';
  static const databaseName = 'database.sqlite';

  static bool hasValidExtension(String path) {
    return path.toLowerCase().endsWith('.$fileExtension');
  }

  static String fileNameFor(DateTime local) {
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    return 'tien-daune-$y-$m-$d-$hh$mm$ss.$fileExtension';
  }
}

class BackupManifest {
  const BackupManifest({
    required this.backupFormatVersion,
    required this.databaseSchemaVersion,
    required this.appVersion,
    required this.createdAt,
  });

  final int backupFormatVersion;
  final int databaseSchemaVersion;
  final String appVersion;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'backup_format_version': backupFormatVersion,
        'database_schema_version': databaseSchemaVersion,
        'app_version': appVersion,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  static BackupManifest parse(
    Object? raw, {
    required int currentSchemaVersion,
  }) {
    if (raw is! Map) {
      throw const BackupFailure('Manifest sao lưu không hợp lệ.');
    }
    final map = Map<String, dynamic>.from(raw);
    final format = _asInt(map['backup_format_version']);
    final schema = _asInt(map['database_schema_version']);
    final appVersion = map['app_version'];
    final createdAtRaw = map['created_at'];
    if (format == null ||
        schema == null ||
        appVersion is! String ||
        appVersion.isEmpty ||
        createdAtRaw is! String) {
      throw const BackupFailure('Manifest sao lưu không hợp lệ.');
    }
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      throw const BackupFailure('Manifest sao lưu không hợp lệ.');
    }
    if (format != BackupFormat.version) {
      throw const BackupFailure(
        'Định dạng sao lưu không được hỗ trợ. Hãy cập nhật ứng dụng.',
      );
    }
    if (schema > currentSchemaVersion) {
      throw const BackupFailure(
        'Bản sao lưu đến từ phiên bản ứng dụng mới hơn. Hãy cập nhật ứng dụng rồi thử lại.',
      );
    }
    if (schema < 1) {
      throw const BackupFailure('Manifest sao lưu không hợp lệ.');
    }
    return BackupManifest(
      backupFormatVersion: format,
      databaseSchemaVersion: schema,
      appVersion: appVersion,
      createdAt: createdAt.toUtc(),
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
