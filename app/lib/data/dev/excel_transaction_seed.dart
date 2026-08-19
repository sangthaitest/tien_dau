/// Development-only Excel merge seed.
/// Not imported from production [main]. Never a user-facing Import feature.
library;

import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/failures/result.dart';
import 'excel_chi_tieu_map.dart';

export 'excel_chi_tieu_map.dart';

Future<List<Transaction>> loadAllTransactions(TransactionService service) async {
  const pageSize = 200;
  final all = <Transaction>[];
  var offset = 0;
  while (true) {
    final result = await service.query(
      TransactionQuerySpec(
        limit: pageSize,
        offset: offset,
        includeExpenseSum: false,
      ),
    );
    switch (result) {
      case Err(:final failure):
        throw StateError(failure.message);
      case Ok(:final value):
        all.addAll(value.items);
        if (!value.hasMore) return all;
        offset += value.items.length;
    }
  }
}

Future<ExcelSeedReport> seedChiTieuRows({
  required TransactionService service,
  required List<ExcelChiTieuRow> rows,
}) async {
  final dataRows = rows.where((row) => !row.isEmpty).toList(growable: false);
  final existing = {
    for (final tx in await loadAllTransactions(service))
      fingerprintOfTransaction(tx),
  };
  final seenThisRun = <String>{};

  var imported = 0;
  var skippedDuplicate = 0;
  var skippedInvalid = 0;
  var failed = 0;
  final invalidRows = <SeedRowFailure>[];
  final failedRows = <SeedRowFailure>[];

  for (final row in dataRows) {
    final mapped = mapChiTieuRow(row);
    if (mapped.invalid != null) {
      skippedInvalid += 1;
      invalidRows.add(mapped.invalid!);
      continue;
    }
    final item = mapped.mapped!;
    if (existing.contains(item.fingerprint) ||
        seenThisRun.contains(item.fingerprint)) {
      skippedDuplicate += 1;
      continue;
    }
    final created = await service.add(item.input);
    switch (created) {
      case Err(:final failure):
        failed += 1;
        failedRows.add(
          SeedRowFailure(
            excelRowNumber: item.excelRowNumber,
            reason: failure.message,
          ),
        );
      case Ok():
        imported += 1;
        seenThisRun.add(item.fingerprint);
        existing.add(item.fingerprint);
    }
  }

  return ExcelSeedReport(
    excelRowsFound: dataRows.length,
    imported: imported,
    skippedDuplicate: skippedDuplicate,
    skippedInvalid: skippedInvalid,
    failed: failed,
    invalidRows: invalidRows,
    failedRows: failedRows,
  );
}
