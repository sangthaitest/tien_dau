import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tien_day_excel_seed/seed_into_sqlite.dart';

/// One-time development seed. Not invoked by flutter run / app launch.
///
///   cd scripts/seed && dart run seed_transactions_from_excel.dart
///   ./scripts/seed_transactions_from_excel --xlsx FILE --db FILE
void main(List<String> args) {
  String? xlsxPath;
  String? dbPath;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--xlsx' && i + 1 < args.length) {
      xlsxPath = args[++i];
    } else if (arg == '--db' && i + 1 < args.length) {
      dbPath = args[++i];
    } else if (arg == '--help' || arg == '-h') {
      stdout.writeln(_usage);
      return;
    }
  }

  final seedDir = Directory.current.path;
  xlsxPath ??= _firstExisting([
    p.join(seedDir, 'Template_Chi_Tieu_Toi_Gian.xlsx'),
    p.join(p.dirname(Platform.script.toFilePath()), 'Template_Chi_Tieu_Toi_Gian.xlsx'),
    p.join(seedDir, '..', 'Template_Chi_Tieu_Toi_Gian.xlsx'),
    p.join(p.dirname(Platform.script.toFilePath()), '..', 'Template_Chi_Tieu_Toi_Gian.xlsx'),
  ]);
  dbPath ??= Platform.environment['TIEN_DAY_DB'];
  if (dbPath == null || dbPath.trim().isEmpty) {
    stderr.writeln(
      'Pass --db PATH/TO/tien_day.db (the same database file the Flutter app uses).',
    );
    exitCode = 64;
    return;
  }

  if (!File(xlsxPath).existsSync()) {
    stderr.writeln('Excel file not found: $xlsxPath');
    exitCode = 64;
    return;
  }

  final report = seedChiTieuIntoDatabase(xlsxPath: xlsxPath, dbPath: dbPath);
  stdout.writeln(report.summary);
  stdout.writeln();
  stdout.writeln('Database: $dbPath');
}

String _firstExisting(List<String> paths) {
  for (final path in paths) {
    if (File(path).existsSync()) return path;
  }
  return paths.first;
}

const _usage = '''
=== Tiền Đây Transaction Seed ===

One-time development tooling. Does not run during flutter run / app launch.

  cd scripts/seed && dart run seed_transactions_from_excel.dart --db PATH/TO/tien_day.db
  ./scripts/seed_transactions_from_excel --xlsx FILE --db FILE

Reads sheet ChiTieu and merges into the existing tien_day.db schema.
Re-runs skip duplicates and never delete current transactions.
''';
