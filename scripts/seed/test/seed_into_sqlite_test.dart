import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:tien_day_excel_seed/seed_into_sqlite.dart';

void main() {
  final xlsx = p.normalize(
    p.join(
      Directory.current.path,
      'Template_Chi_Tieu_Toi_Gian.xlsx',
    ),
  );

  test('seeds all valid ChiTieu rows and is idempotent', () {
    if (!File(xlsx).existsSync()) {
      fail('Missing $xlsx');
    }
    final dir = Directory.systemTemp.createTempSync('tien_day_seed');
    final dbPath = p.join(dir.path, 'tien_day.db');
    addTearDown(() => dir.deleteSync(recursive: true));

    final first = seedChiTieuIntoDatabase(xlsxPath: xlsx, dbPath: dbPath);
    expect(first.rowsFound, 150);
    expect(first.imported, 148);
    expect(first.duplicate, 0);
    expect(first.invalid, 2);
    expect(first.failed, 0);
    expect(
      first.failures.map((row) => row.excelRowNumber).toList(),
      [80, 117],
    );

    final second = seedChiTieuIntoDatabase(xlsxPath: xlsx, dbPath: dbPath);
    expect(second.rowsFound, 150);
    expect(second.imported, 0);
    expect(second.duplicate, 148);
    expect(second.invalid, 2);

    final db = sqlite3.open(dbPath);
    addTearDown(db.dispose);
    final count = db.select('SELECT COUNT(*) AS c FROM transactions').first['c'];
    expect(count, 148);
    final amounts = db
        .select(
          "SELECT amount FROM transactions WHERE amount IN (30000, 145000) GROUP BY amount ORDER BY amount",
        )
        .map((row) => row['amount'])
        .toList();
    expect(amounts, [30000, 145000]);
  });
}
