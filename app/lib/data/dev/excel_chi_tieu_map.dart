/// Development-only ChiTieu row mapping. Not used by production [main].
library;

import '../../domain/entities/new_transaction.dart';
import '../../domain/entities/payment_method_kind.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/validation/transaction_validator.dart';
import '../mappers/transaction_mapper.dart';

class ExcelChiTieuRow {
  const ExcelChiTieuRow({
    required this.excelRowNumber,
    required this.ngay,
    required this.nhom,
    required this.doiTuong,
    required this.khoanChi,
    required this.soTien,
    required this.thanhToan,
    required this.ghiChu,
    required this.tag,
  });

  final int excelRowNumber;
  final Object? ngay;
  final Object? nhom;
  final Object? doiTuong;
  final Object? khoanChi;
  final Object? soTien;
  final Object? thanhToan;
  final Object? ghiChu;
  final Object? tag;

  bool get isEmpty {
    return _isBlank(ngay) &&
        _isBlank(nhom) &&
        _isBlank(doiTuong) &&
        _isBlank(khoanChi) &&
        _isBlank(soTien) &&
        _isBlank(thanhToan) &&
        _isBlank(ghiChu) &&
        _isBlank(tag);
  }
}

class MappedSeedTransaction {
  const MappedSeedTransaction({
    required this.excelRowNumber,
    required this.input,
    required this.fingerprint,
  });

  final int excelRowNumber;
  final NewTransaction input;
  final String fingerprint;
}

class SeedRowFailure {
  const SeedRowFailure({required this.excelRowNumber, required this.reason});

  final int excelRowNumber;
  final String reason;
}

class ExcelSeedReport {
  const ExcelSeedReport({
    required this.excelRowsFound,
    required this.imported,
    required this.skippedDuplicate,
    required this.skippedInvalid,
    required this.failed,
    required this.invalidRows,
    required this.failedRows,
  });

  final int excelRowsFound;
  final int imported;
  final int skippedDuplicate;
  final int skippedInvalid;
  final int failed;
  final List<SeedRowFailure> invalidRows;
  final List<SeedRowFailure> failedRows;

  String get summary {
    final buffer = StringBuffer()
      ..writeln('Excel rows found: $excelRowsFound')
      ..writeln()
      ..writeln('Imported: $imported')
      ..writeln('Skipped duplicate: $skippedDuplicate')
      ..writeln('Skipped invalid: $skippedInvalid')
      ..writeln('Failed: $failed')
      ..writeln()
      ..writeln('Total transactions inserted: $imported');
    for (final row in [...invalidRows, ...failedRows]) {
      buffer
        ..writeln()
        ..writeln('Row ${row.excelRowNumber}')
        ..writeln('Reason: ${row.reason}');
    }
    return buffer.toString().trimRight();
  }
}

const _excelErrors = {
  '#REF!',
  '#VALUE!',
  '#N/A',
  '#DIV/0!',
  '#NAME?',
  '#NULL!',
  '#NUM!',
};

const _categoryByFold = {
  'an sang': 'breakfast',
  'an trua': 'lunch',
  'an toi': 'dinner',
  'cafe': 'cafe',
  'ca phe': 'cafe',
  'di cho': 'market',
  'di chuyen': 'transport',
  'do xang': 'transport',
  'mua sam': 'shopping',
  'khac': 'other',
  'may man': 'other',
  'do uong': 'other',
  'do an': 'other',
  'tien dien': 'other',
  'tien nuoc': 'other',
  'an uong': 'other',
};

class _PaymentMap {
  const _PaymentMap(this.id, this.name, this.method);
  final String id;
  final String name;
  final PaymentMethodKind method;
}

const _paymentByFold = {
  'momo': _PaymentMap('momo', 'MoMo', PaymentMethodKind.eWallet),
  'tien mat': _PaymentMap('cash', 'Tiền mặt', PaymentMethodKind.cash),
  'vcb': _PaymentMap('vcb', 'Vietcombank', PaymentMethodKind.bankAccount),
  'vietcombank': _PaymentMap(
    'vcb',
    'Vietcombank',
    PaymentMethodKind.bankAccount,
  ),
  'shb': _PaymentMap('shb', 'Thẻ SHB', PaymentMethodKind.debitCard),
  'the shb': _PaymentMap('shb', 'Thẻ SHB', PaymentMethodKind.debitCard),
  'kbank': _PaymentMap('kbank', 'KBank', PaymentMethodKind.debitCard),
  'the kbank': _PaymentMap('kbank', 'KBank', PaymentMethodKind.debitCard),
  'app vietlot': _PaymentMap(
    'vietlot',
    'App Vietlot',
    PaymentMethodKind.eWallet,
  ),
  'vietlot': _PaymentMap('vietlot', 'App Vietlot', PaymentMethodKind.eWallet),
  'vietlott': _PaymentMap('vietlot', 'App Vietlot', PaymentMethodKind.eWallet),
};

bool _isBlank(Object? value) {
  if (value == null) return true;
  return value.toString().trim().isEmpty;
}

bool isExcelErrorValue(Object? value) {
  if (value == null) return false;
  final text = value.toString().trim().toUpperCase();
  return _excelErrors.contains(text);
}

String foldKey(String raw) {
  const marks = {
    'à': 'a',
    'á': 'a',
    'ả': 'a',
    'ã': 'a',
    'ạ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'ặ': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ậ': 'a',
    'è': 'e',
    'é': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ẹ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ệ': 'e',
    'ì': 'i',
    'í': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ị': 'i',
    'ò': 'o',
    'ó': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ọ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ộ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ợ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ụ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ự': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'ỵ': 'y',
    'đ': 'd',
  };
  final buffer = StringBuffer();
  for (final rune in raw.trim().toLowerCase().runes) {
    if (rune >= 0x300 && rune <= 0x36F) continue;
    final ch = String.fromCharCode(rune);
    buffer.write(marks[ch] ?? ch);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? _asTrimmed(Object? value) {
  if (_isBlank(value) || isExcelErrorValue(value)) return null;
  return value.toString().trim();
}

DateTime? parseExcelDate(Object? value) {
  if (value == null || isExcelErrorValue(value)) return null;
  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }
  if (value is num) {
    final epoch = DateTime(1899, 12, 30);
    return DateTime(
      epoch.year,
      epoch.month,
      epoch.day,
    ).add(Duration(days: value.floor()));
  }
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
  final slash = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(text);
  if (slash != null) {
    return DateTime(
      int.parse(slash.group(3)!),
      int.parse(slash.group(2)!),
      int.parse(slash.group(1)!),
    );
  }
  return null;
}

int? parseVndAmount(Object? value) {
  if (value == null || isExcelErrorValue(value)) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  final text = value.toString().trim().replaceAll(RegExp(r'[^\d-]'), '');
  if (text.isEmpty) return null;
  return int.tryParse(text);
}

({MappedSeedTransaction? mapped, SeedRowFailure? invalid}) mapChiTieuRow(
  ExcelChiTieuRow row,
) {
  if (row.isEmpty) {
    return (mapped: null, invalid: null);
  }

  for (final field in [
    row.ngay,
    row.nhom,
    row.doiTuong,
    row.khoanChi,
    row.soTien,
    row.thanhToan,
    row.ghiChu,
    row.tag,
  ]) {
    if (isExcelErrorValue(field)) {
      return (
        mapped: null,
        invalid: SeedRowFailure(
          excelRowNumber: row.excelRowNumber,
          reason: 'Excel error value ${field.toString().trim()}',
        ),
      );
    }
  }

  final date = parseExcelDate(row.ngay);
  if (date == null) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        reason: 'Missing or invalid Ngày',
      ),
    );
  }

  final amount = parseVndAmount(row.soTien);
  if (amount == null || amount <= 0) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        reason: 'Missing or invalid Số tiền',
      ),
    );
  }

  final group = _asTrimmed(row.nhom);
  if (group == null) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        reason: 'Missing Nhóm',
      ),
    );
  }
  final categoryId = _categoryByFold[foldKey(group)] ?? 'other';

  final paymentRaw = _asTrimmed(row.thanhToan);
  if (paymentRaw == null) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        reason: 'Missing Thanh toán',
      ),
    );
  }
  final payment = _paymentByFold[foldKey(paymentRaw)];
  if (payment == null) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        reason: 'Unknown Thanh toán "$paymentRaw"',
      ),
    );
  }

  final detail = _asTrimmed(row.khoanChi);
  final ghiChu = _asTrimmed(row.ghiChu);
  final participant = _asTrimmed(row.doiTuong);
  final noteParts = <String>[
    ?ghiChu,
    if (participant != null && foldKey(participant) != 'ban than') participant,
  ];
  final note = noteParts.isEmpty ? null : noteParts.join(' · ');

  final input = NewTransaction(
    amount: amount,
    type: TransactionType.expense,
    categoryId: categoryId,
    detail: detail,
    occurredOn: date,
    paymentSourceId: payment.id,
    paymentSourceName: payment.name,
    paymentMethod: payment.method,
    note: note,
  );
  final invalid = validateNewTransaction(input);
  if (invalid != null) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        reason: invalid.message,
      ),
    );
  }

  return (
    mapped: MappedSeedTransaction(
      excelRowNumber: row.excelRowNumber,
      input: input,
      fingerprint: fingerprintFor(
        date: date,
        detail: detail,
        categoryId: categoryId,
        amount: amount,
        paymentSourceId: payment.id,
        note: note,
      ),
    ),
    invalid: null,
  );
}

String fingerprintFor({
  required DateTime date,
  required String? detail,
  required String categoryId,
  required int amount,
  required String paymentSourceId,
  required String? note,
}) {
  return [
    TransactionMapper.dateToStorage(date),
    foldKey(detail ?? ''),
    categoryId,
    '$amount',
    paymentSourceId,
    foldKey(note ?? ''),
  ].join('|');
}

String fingerprintOfTransaction(Transaction tx) {
  return fingerprintFor(
    date: tx.occurredOn,
    detail: tx.detail,
    categoryId: tx.categoryId,
    amount: tx.amount,
    paymentSourceId: tx.paymentSourceId,
    note: tx.note,
  );
}
