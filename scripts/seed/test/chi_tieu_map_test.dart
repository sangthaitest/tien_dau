import 'package:test/test.dart';
import 'package:tien_day_excel_seed/chi_tieu_map.dart';

ExcelChiTieuRow row({
  int n = 2,
  Object? ngay = '2026-07-23',
  Object? nhom = 'Cafe',
  Object? doiTuong = 'Bản thân',
  Object? khoanChi = 'Cà phê sữa',
  Object? soTien = 29000,
  Object? thanhToan = 'Momo',
  Object? ghiChu = 'Hightlands',
  Object? tag = 'Bản thân',
}) {
  return ExcelChiTieuRow(
    excelRowNumber: n,
    ngay: ngay,
    nhom: nhom,
    doiTuong: doiTuong,
    khoanChi: khoanChi,
    soTien: soTien,
    thanhToan: thanhToan,
    ghiChu: ghiChu,
    tag: tag,
  );
}

void main() {
  test('keeps original payment name, note, and exact amount', () {
    final mapped = mapChiTieuRow(row(soTien: 145000.0, thanhToan: 'Thẻ SHB')).mapped!;
    expect(mapped.amount, 145000);
    expect(mapped.paymentSourceName, 'Thẻ SHB');
    expect(mapped.note, 'Hightlands');
    expect(mapped.detail, 'Cà phê sữa');
  });

  test('does not round whole VND amounts', () {
    expect(parseVndAmount(780000.0), 780000);
    expect(parseVndAmount(145000), 145000);
    expect(parseVndAmount(30000.4), isNull);
  });

  test('stores calendar dates without timezone shift', () {
    expect(parseExcelDate(DateTime(2026, 7, 23)), '2026-07-23');
    expect(parseExcelDate(DateTime.utc(2026, 7, 23)), '2026-07-23');
  });

  test('skips Excel error values in seed columns', () {
    final result = mapChiTieuRow(row(khoanChi: '#REF!'));
    expect(result.mapped, isNull);
    expect(result.invalid!.field, 'Khoản chi');
    expect(result.invalid!.reason, contains('#REF!'));
  });

  test('maps Tiền mặt even with extra combining marks', () {
    final mapped = mapChiTieuRow(row(thanhToan: 'Tiề̀n mặt')).mapped!;
    expect(mapped.paymentSourceId, 'cash');
    expect(mapped.paymentSourceName, 'Tiề̀n mặt');
  });

  test('does not treat blank template rows as data', () {
    expect(
      const ExcelChiTieuRow(
        excelRowNumber: 20,
        ngay: null,
        nhom: null,
        doiTuong: null,
        khoanChi: null,
        soTien: null,
        thanhToan: null,
        ghiChu: null,
        tag: null,
      ).isEmpty,
      isTrue,
    );
  });
}
