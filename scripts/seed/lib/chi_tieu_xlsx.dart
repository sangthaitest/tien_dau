import 'dart:io';

import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import 'chi_tieu_map.dart';

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

  return [
    for (var i = 1; i < table.rows.length; i++)
      ExcelChiTieuRow(
        excelRowNumber: i + 1,
        ngay: _at(table.rows[i], ngay),
        nhom: _at(table.rows[i], nhom),
        doiTuong: _at(table.rows[i], doiTuong),
        khoanChi: _at(table.rows[i], khoanChi),
        soTien: _at(table.rows[i], soTien),
        thanhToan: _at(table.rows[i], thanhToan),
        ghiChu: _at(table.rows[i], ghiChu),
        tag: _at(table.rows[i], tag),
      ),
  ];
}

List<ExcelChiTieuRow> readChiTieuFile(String path) {
  return readChiTieuSheet(File(path).readAsBytesSync());
}

Object? _at(List<dynamic> raw, int index) {
  return index < raw.length ? raw[index] : null;
}
