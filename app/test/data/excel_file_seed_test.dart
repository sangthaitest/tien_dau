import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/data/datasources/transaction_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/dev/excel_chi_tieu_map.dart';
import 'package:tien_day/data/dev/excel_transaction_seed.dart';
import 'package:tien_day/data/repositories/transaction_repository_impl.dart';
import 'package:uuid/uuid.dart';

List<ExcelChiTieuRow> _read(String path) {
  final table = SpreadsheetDecoder.decodeBytes(
    File(path).readAsBytesSync(),
  ).tables['ChiTieu'];
  if (table == null) {
    throw StateError('missing ChiTieu');
  }
  final header = [
    for (final cell in table.rows.first) (cell?.toString() ?? '').trim(),
  ];
  int col(String name) => header.indexOf(name);
  Object? at(List<dynamic> raw, int index) =>
      index >= 0 && index < raw.length ? raw[index] : null;
  return [
    for (var i = 1; i < table.rows.length; i++)
      ExcelChiTieuRow(
        excelRowNumber: i + 1,
        ngay: at(table.rows[i], col('Ngày')),
        nhom: at(table.rows[i], col('Nhóm')),
        doiTuong: at(table.rows[i], col('Đối tượng')),
        khoanChi: at(table.rows[i], col('Khoản chi')),
        soTien: at(table.rows[i], col('Số tiền')),
        thanhToan: at(table.rows[i], col('Thanh toán')),
        ghiChu: at(table.rows[i], col('Ghi chú')),
        tag: at(table.rows[i], col('Tag')),
      ),
  ];
}

void main() {
  final repoXlsx = p.normalize(
    p.join(Directory.current.path, '..', 'scripts', 'Template_Chi_Tieu_Toi_Gian.xlsx'),
  );
  final downloads = p.join(
    Platform.environment['HOME'] ?? '',
    'Downloads',
    'Template_Chi_Tieu_Toi_Gian.xlsx',
  );
  final xlsx = File(repoXlsx).existsSync()
      ? repoXlsx
      : downloads;
  final exists = File(xlsx).existsSync();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('seeds ChiTieu from the local Excel template without wiping data', () async {
    if (!exists) {
      return;
    }
    final dir = await Directory.systemTemp.createTemp('excel_file_seed');
    final db = await AppDatabase.openPath(p.join(dir.path, 'tien_day.db'));
    var ids = 0;
    final service = TransactionService(
      TransactionRepositoryImpl(
        local: TransactionLocalDataSource(db),
        idFactory: () => 'seed-${++ids}-${const Uuid().v4()}',
        clock: () => DateTime.utc(2026, 8, 19),
      ),
    );
    final rows = _read(xlsx);
    final first = await seedChiTieuRows(service: service, rows: rows);
    // ignore: avoid_print
    print(first.summary);
    expect(first.excelRowsFound, greaterThanOrEqualTo(15));
    expect(first.imported, first.excelRowsFound - first.skippedInvalid - first.skippedDuplicate);
    expect(first.failed, 0);

    final second = await seedChiTieuRows(service: service, rows: rows);
    expect(second.imported, 0);
    expect(second.skippedDuplicate, first.imported);
    await db.close();
  }, skip: exists ? false : 'Excel template is not on this machine');
}
