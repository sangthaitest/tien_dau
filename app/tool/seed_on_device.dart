import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/data/datasources/transaction_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/dev/excel_transaction_seed.dart';
import 'package:tien_day/data/repositories/transaction_repository_impl.dart';
import 'package:uuid/uuid.dart';

import 'seed_payload.local.g.dart';

/// One-shot device seed. Not production UI and not an Import feature.
///
///   dart run tool/seed_transactions_from_excel.dart --xlsx FILE --write-payload
///   flutter run -t tool/seed_on_device.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final rows = _rowsFromPayload(seedPayloadJson);
  if (rows.isEmpty) {
    runApp(_SeedLog(
      'seed_payload.local.g.dart is empty.\n'
      'dart run tool/seed_transactions_from_excel.dart --xlsx FILE --write-payload',
    ));
    return;
  }

  final database = await AppDatabase.openFile();
  const uuid = Uuid();
  final service = TransactionService(
    TransactionRepositoryImpl(
      local: TransactionLocalDataSource(database),
      idFactory: uuid.v4,
      clock: DateTime.now,
    ),
  );
  final report = await seedChiTieuRows(service: service, rows: rows);
  await database.close();
  debugPrint(report.summary);
  runApp(_SeedLog(report.summary));
}

List<ExcelChiTieuRow> _rowsFromPayload(String json) {
  final decoded = jsonDecode(json) as List<dynamic>;
  return [
    for (final item in decoded)
      ExcelChiTieuRow(
        excelRowNumber: item['excelRowNumber'] as int,
        ngay: item['ngay'],
        nhom: item['nhom'],
        doiTuong: item['doiTuong'],
        khoanChi: item['khoanChi'],
        soTien: item['soTien'],
        thanhToan: item['thanhToan'],
        ghiChu: item['ghiChu'],
        tag: item['tag'],
      ),
  ];
}

class _SeedLog extends StatelessWidget {
  const _SeedLog(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF111111),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFEEEEEE),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
