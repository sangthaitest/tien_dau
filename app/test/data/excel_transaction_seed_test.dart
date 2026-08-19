import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/data/datasources/transaction_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/dev/excel_transaction_seed.dart';
import 'package:tien_day/data/repositories/transaction_repository_impl.dart';
import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction_query.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/result.dart';

ExcelChiTieuRow _row({
  int n = 2,
  Object? ngay = '2026-07-23',
  Object? nhom = 'Cafe',
  Object? doiTuong = 'Bản thân',
  Object? khoanChi = 'Cà phê sữa',
  Object? soTien = 29000,
  Object? thanhToan = 'Momo',
  Object? ghiChu = 'Highlands',
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
  test('maps ChiTieu columns onto the existing transaction model', () {
    final mapped = mapChiTieuRow(_row()).mapped!;
    expect(mapped.input.amount, 29000);
    expect(mapped.input.type, TransactionType.expense);
    expect(mapped.input.categoryId, 'cafe');
    expect(mapped.input.detail, 'Cà phê sữa');
    expect(mapped.input.occurredOn, DateTime(2026, 7, 23));
    expect(mapped.input.paymentSourceId, 'momo');
    expect(mapped.input.paymentSourceName, 'MoMo');
    expect(mapped.input.paymentMethod, PaymentMethodKind.eWallet);
    expect(mapped.input.note, 'Highlands');
  });

  test('does not map Tiền tháng chọn / Hạng tiền error values', () {
    final mapped = mapChiTieuRow(
      _row(nhom: 'Ăn sáng', khoanChi: 'Mì Quảng', soTien: 30000),
    ).mapped!;
    expect(mapped.input.note, isNot(contains('#REF!')));
    expect(mapped.input.detail, isNot(contains('#REF!')));
  });

  test('skips Excel error values in seed columns', () {
    final result = mapChiTieuRow(_row(khoanChi: '#REF!'));
    expect(result.mapped, isNull);
    expect(result.invalid!.reason, contains('#REF!'));
  });

  test('folds decomposed Vietnamese category names', () {
    final mapped = mapChiTieuRow(_row(nhom: 'Ăn tối ')).mapped!;
    expect(mapped.input.categoryId, 'dinner');
  });

  test('does not treat blank template rows as Excel rows', () {
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

  group('sqlite merge seed', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    Future<({AppDatabase db, TransactionService service})> open() async {
      final dir = await Directory.systemTemp.createTemp('excel_seed');
      final db = await AppDatabase.openPath(p.join(dir.path, 'tien_day.db'));
      var ids = 0;
      final service = TransactionService(
        TransactionRepositoryImpl(
          local: TransactionLocalDataSource(db),
          idFactory: () => 'id-${++ids}',
          clock: () => DateTime.utc(2026, 8, 19),
        ),
      );
      return (db: db, service: service);
    }

    test('merges into existing rows and skips duplicates on rerun', () async {
      final opened = await open();
      final existing = await opened.service.add(
        NewTransaction(
          amount: 12000,
          type: TransactionType.expense,
          categoryId: 'other',
          occurredOn: DateTime(2026, 7, 1),
          paymentSourceId: 'cash',
          paymentSourceName: 'Tiền mặt',
          paymentMethod: PaymentMethodKind.cash,
          detail: 'Keep me',
        ),
      );
      expect(existing, isA<Ok>());

      final rows = [_row(), _row(n: 3, khoanChi: '#VALUE!')];
      final first = await seedChiTieuRows(service: opened.service, rows: rows);
      expect(first.excelRowsFound, 2);
      expect(first.imported, 1);
      expect(first.skippedInvalid, 1);
      expect(first.skippedDuplicate, 0);

      final second = await seedChiTieuRows(service: opened.service, rows: rows);
      expect(second.imported, 0);
      expect(second.skippedDuplicate, 1);
      expect(second.skippedInvalid, 1);

      final page = await opened.service.query(
        const TransactionQuerySpec(limit: 50, includeExpenseSum: false),
      );
      final items = (page as Ok).value.items;
      expect(items, hasLength(2));
      expect(items.map((item) => item.detail), containsAll(['Keep me', 'Cà phê sữa']));
      expect(
        items.every((item) => !(item.note ?? '').contains('#REF!')),
        isTrue,
      );

      await opened.db.close();
    });
  });
}
