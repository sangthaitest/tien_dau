/// Maps ChiTieu Excel rows onto the existing transactions table shape.
/// Development tooling only. Not imported by the Flutter app.
library;

const excelErrors = {
  '#REF!',
  '#VALUE!',
  '#N/A',
  '#DIV/0!',
  '#NAME?',
  '#NULL!',
  '#NUM!',
};

const categoryByFold = {
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
  'gia dinh': 'other',
  'giai tri': 'other',
  'tien dien': 'other',
  'tien nuoc': 'other',
  'an uong': 'other',
};

class PaymentMap {
  const PaymentMap(this.id, this.method);
  final String id;
  final String method;
}

const paymentByFold = {
  'momo': PaymentMap('momo', 'eWallet'),
  'tien mat': PaymentMap('cash', 'cash'),
  'vcb': PaymentMap('vcb', 'bankAccount'),
  'vietcombank': PaymentMap('vcb', 'bankAccount'),
  'shb': PaymentMap('shb', 'debitCard'),
  'the shb': PaymentMap('shb', 'debitCard'),
  'kbank': PaymentMap('kbank', 'debitCard'),
  'the kbank': PaymentMap('kbank', 'debitCard'),
  'app vietlot': PaymentMap('vietlot', 'eWallet'),
  'vietlot': PaymentMap('vietlot', 'eWallet'),
  'vietlott': PaymentMap('vietlot', 'eWallet'),
  'chuyen khoan': PaymentMap('bank_transfer', 'bankAccount'),
  'the': PaymentMap('card', 'debitCard'),
};

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
    return isBlank(ngay) &&
        isBlank(nhom) &&
        isBlank(doiTuong) &&
        isBlank(khoanChi) &&
        isBlank(soTien) &&
        isBlank(thanhToan) &&
        isBlank(ghiChu) &&
        isBlank(tag);
  }
}

class MappedSeedRow {
  const MappedSeedRow({
    required this.excelRowNumber,
    required this.amount,
    required this.categoryId,
    required this.detail,
    required this.occurredDate,
    required this.paymentSourceId,
    required this.paymentSourceName,
    required this.paymentMethod,
    required this.note,
    required this.fingerprint,
  });

  final int excelRowNumber;
  final int amount;
  final String categoryId;
  final String? detail;
  final String occurredDate;
  final String paymentSourceId;
  final String paymentSourceName;
  final String paymentMethod;
  final String? note;
  final String fingerprint;
}

class SeedRowFailure {
  const SeedRowFailure({
    required this.excelRowNumber,
    required this.field,
    required this.reason,
  });

  final int excelRowNumber;
  final String field;
  final String reason;
}

class SeedReport {
  const SeedReport({
    required this.sourceName,
    required this.rowsFound,
    required this.imported,
    required this.duplicate,
    required this.invalid,
    required this.failed,
    required this.failures,
  });

  final String sourceName;
  final int rowsFound;
  final int imported;
  final int duplicate;
  final int invalid;
  final int failed;
  final List<SeedRowFailure> failures;

  String get summary {
    final buffer = StringBuffer()
      ..writeln('=== Tiền Đây Transaction Seed ===')
      ..writeln()
      ..writeln('Source: $sourceName')
      ..writeln('Sheet: ChiTieu')
      ..writeln()
      ..writeln('Rows found: $rowsFound')
      ..writeln('Imported: $imported')
      ..writeln('Duplicate: $duplicate')
      ..writeln('Invalid: $invalid')
      ..writeln('Failed: $failed')
      ..writeln()
      ..writeln('Seed completed.');
    for (final row in failures) {
      buffer
        ..writeln()
        ..writeln('Row: ${row.excelRowNumber}')
        ..writeln('Field: ${row.field}')
        ..writeln('Reason: ${row.reason}');
    }
    return buffer.toString().trimRight();
  }
}

bool isBlank(Object? value) {
  if (value == null) return true;
  return value.toString().trim().isEmpty;
}

bool isExcelErrorValue(Object? value) {
  if (value == null) return false;
  return excelErrors.contains(value.toString().trim().toUpperCase());
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

String? asTrimmed(Object? value) {
  if (isBlank(value) || isExcelErrorValue(value)) return null;
  return value.toString().trim();
}

String formatIsoDate(int year, int month, int day) {
  final y = year.toString().padLeft(4, '0');
  final m = month.toString().padLeft(2, '0');
  final d = day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String? parseExcelDate(Object? value) {
  if (value == null || isExcelErrorValue(value)) return null;
  if (value is DateTime) {
    return formatIsoDate(value.year, value.month, value.day);
  }
  if (value is num) {
    final utc = DateTime.utc(1899, 12, 30).add(Duration(days: value.floor()));
    return formatIsoDate(utc.year, utc.month, utc.day);
  }
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return formatIsoDate(parsed.year, parsed.month, parsed.day);
  final slash = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(text);
  if (slash != null) {
    return formatIsoDate(
      int.parse(slash.group(3)!),
      int.parse(slash.group(2)!),
      int.parse(slash.group(1)!),
    );
  }
  return null;
}

int? parseVndAmount(Object? value) {
  if (value == null || isExcelErrorValue(value)) return null;
  if (value is int) return value > 0 ? value : null;
  if (value is num) {
    if (value <= 0) return null;
    if (value != value.truncateToDouble()) return null;
    return value.toInt();
  }
  final text = value.toString().trim().replaceAll(RegExp(r'[^\d-]'), '');
  if (text.isEmpty) return null;
  final parsed = int.tryParse(text);
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

({MappedSeedRow? mapped, SeedRowFailure? invalid}) mapChiTieuRow(
  ExcelChiTieuRow row,
) {
  if (row.isEmpty) return (mapped: null, invalid: null);

  for (final entry in {
    'Ngày': row.ngay,
    'Nhóm': row.nhom,
    'Đối tượng': row.doiTuong,
    'Khoản chi': row.khoanChi,
    'Số tiền': row.soTien,
    'Thanh toán': row.thanhToan,
    'Ghi chú': row.ghiChu,
    'Tag': row.tag,
  }.entries) {
    if (isExcelErrorValue(entry.value)) {
      return (
        mapped: null,
        invalid: SeedRowFailure(
          excelRowNumber: row.excelRowNumber,
          field: entry.key,
          reason: 'Excel error value ${entry.value.toString().trim()}',
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
        field: 'Ngày',
        reason: 'Missing or invalid Ngày',
      ),
    );
  }

  final amount = parseVndAmount(row.soTien);
  if (amount == null) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        field: 'Số tiền',
        reason: 'Missing or invalid Số tiền',
      ),
    );
  }

  final group = asTrimmed(row.nhom);
  if (group == null) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        field: 'Nhóm',
        reason: 'Missing Nhóm',
      ),
    );
  }
  final categoryId = categoryByFold[foldKey(group)] ?? 'other';

  final paymentRaw = asTrimmed(row.thanhToan);
  if (paymentRaw == null) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        field: 'Thanh toán',
        reason: 'Missing Thanh toán',
      ),
    );
  }
  final payment = paymentByFold[foldKey(paymentRaw)];
  if (payment == null) {
    return (
      mapped: null,
      invalid: SeedRowFailure(
        excelRowNumber: row.excelRowNumber,
        field: 'Thanh toán',
        reason: 'Unknown Thanh toán "$paymentRaw"',
      ),
    );
  }

  final detail = asTrimmed(row.khoanChi);
  final note = asTrimmed(row.ghiChu);
  final fingerprint = [
    date,
    '$amount',
    foldKey(detail ?? ''),
    foldKey(paymentRaw),
    foldKey(note ?? ''),
    categoryId,
  ].join('|');

  return (
    mapped: MappedSeedRow(
      excelRowNumber: row.excelRowNumber,
      amount: amount,
      categoryId: categoryId,
      detail: detail,
      occurredDate: date,
      paymentSourceId: payment.id,
      paymentSourceName: paymentRaw,
      paymentMethod: payment.method,
      note: note,
      fingerprint: fingerprint,
    ),
    invalid: null,
  );
}

String fingerprintFromDb({
  required String occurredDate,
  required int amount,
  required String? detail,
  required String paymentSourceName,
  required String? note,
  required String categoryId,
}) {
  return [
    occurredDate,
    '$amount',
    foldKey(detail ?? ''),
    foldKey(paymentSourceName),
    foldKey(note ?? ''),
    categoryId,
  ].join('|');
}
