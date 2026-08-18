import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/data/mappers/transaction_mapper.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';

void main() {
  test('round-trips a transaction map', () {
    final original = Transaction(
      id: 'tx-1',
      amount: 45000,
      type: TransactionType.expense,
      categoryId: 'cafe',
      detail: 'Coffee',
      occurredOn: DateTime(2026, 8, 7),
      occurredTime: '08:15',
      paymentSourceId: 'momo',
      paymentSourceName: 'MoMo',
      paymentMethod: PaymentMethodKind.eWallet,
      note: 'optional',
      createdAt: DateTime.utc(2026, 8, 7, 1, 2, 3),
      updatedAt: DateTime.utc(2026, 8, 7, 1, 2, 3),
    );

    final restored = TransactionMapper.fromMap(TransactionMapper.toMap(original));

    expect(restored.id, original.id);
    expect(restored.amount, 45000);
    expect(restored.type, TransactionType.expense);
    expect(restored.categoryId, 'cafe');
    expect(restored.detail, 'Coffee');
    expect(restored.occurredOn, DateTime(2026, 8, 7));
    expect(restored.occurredTime, '08:15');
    expect(restored.paymentSourceId, 'momo');
    expect(restored.paymentSourceName, 'MoMo');
    expect(restored.paymentMethod, PaymentMethodKind.eWallet);
    expect(restored.note, 'optional');
  });

  test('fromStorage rejects unknown type', () {
    expect(
      () => TransactionType.fromStorage('unknown'),
      throwsA(isA<FormatException>()),
    );
  });
}
