import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/transaction_display.dart';

Transaction _tx({String? detail, String? note}) {
  final now = DateTime.utc(2026, 8, 18);
  return Transaction(
    id: '1',
    amount: 45000,
    type: TransactionType.expense,
    categoryId: 'cafe',
    detail: detail,
    note: note,
    occurredOn: DateTime(2026, 8, 18),
    paymentSourceId: 'momo',
    paymentSourceName: 'MoMo',
    paymentMethod: PaymentMethodKind.eWallet,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('title is the note when one is set', () {
    expect(
      transactionTitle(
        _tx(detail: 'Highlands', note: 'đi làm'),
        categoryName: 'Cafe',
      ),
      'đi làm',
    );
  });

  test('title falls back to detail when there is no note', () {
    expect(
      transactionTitle(_tx(detail: 'Highlands'), categoryName: 'Cafe'),
      'Highlands',
    );
  });

  test('list meta keeps category and payment when detail is the title', () {
    expect(
      transactionListMeta(_tx(detail: 'Highlands'), categoryName: 'Cafe'),
      'Cafe · MoMo',
    );
  });

  test('list meta shows detail when the note is the title', () {
    expect(
      transactionListMeta(
        _tx(detail: 'Highlands', note: 'đi làm'),
        categoryName: 'Cafe',
      ),
      'Highlands · Cafe · MoMo',
    );
  });

  test('list meta does not invent a detail when the note is the title', () {
    expect(
      transactionListMeta(_tx(note: 'Flash sale'), categoryName: 'Mua sắm'),
      'Mua sắm · MoMo',
    );
  });
}
