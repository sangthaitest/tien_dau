import 'dart:io';

import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:tien_day/data/dev/excel_chi_tieu_map.dart';

const chiTieuSheetName = 'ChiTieu';

List<ExcelChiTieuRow> readChiTieuSheet(List<int> bytes) {
  final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
  final table = decoder.tables[chiTieuSheetName];
  if (table == null) {
    throw StateError('Sheet $chiTieuSheetName not found');
  }
  if (table.rows.isEmpty) return const [];

  final header = [
    for (final cell in table.rows.first) (cell?.toString() ?? '').trim(),
  ];
  int col(String name) {
    final index = header.indexOf(name);
    if (index < 0) {
      throw StateError('Missing column "$name" on $chiTieuSheetName');
    }
    return index;
  }

  final ngay = col('Ngày');
  final nhom = col('Nhóm');
  final doiTuong = col('Đối tượng');
  final khoanChi = col('Khoản chi');
  final soTien = col('Số tiền');
  final thanhToan = col('Thanh toán');
  final ghiChu = col('Ghi chú');
  final tag = col('Tag');

  final rows = <ExcelChiTieuRow>[];
  for (var i = 1; i < table.rows.length; i++) {
    final raw = table.rows[i];
    Object? at(int index) => index < raw.length ? raw[index] : null;
    rows.add(
      ExcelChiTieuRow(
        excelRowNumber: i + 1,
        ngay: at(ngay),
        nhom: at(nhom),
        doiTuong: at(doiTuong),
        khoanChi: at(khoanChi),
        soTien: at(soTien),
        thanhToan: at(thanhToan),
        ghiChu: at(ghiChu),
        tag: at(tag),
      ),
    );
  }
  return rows;
}

List<ExcelChiTieuRow> readChiTieuFile(String path) {
  return readChiTieuSheet(File(path).readAsBytesSync());
}
