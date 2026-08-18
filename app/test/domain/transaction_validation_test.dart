import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/validation/transaction_validator.dart';
import 'package:flutter_test/flutter_test.dart';

NewTransaction _valid({int amount = 100000, String category = 'cafe'}) {
  return NewTransaction(
    amount: amount,
    type: TransactionType.expense,
    categoryId: category,
    occurredOn: DateTime(2026, 8, 18),
    occurredTime: '08:15',
    paymentSourceId: 'momo',
    paymentSourceName: 'MoMo',
    paymentMethod: PaymentMethodKind.eWallet,
  );
}

void main() {
  test('accepts a valid expense', () {
    expect(validateNewTransaction(_valid()), isNull);
  });

  test('rejects zero and negative amount', () {
    expect(validateNewTransaction(_valid(amount: 0)), isA<ValidationFailure>());
    expect(validateNewTransaction(_valid(amount: -1)), isA<ValidationFailure>());
  });

  test('rejects empty category', () {
    expect(validateNewTransaction(_valid(category: '  ')), isA<ValidationFailure>());
  });

  test('rejects invalid time', () {
    final input = NewTransaction(
      amount: 10000,
      type: TransactionType.expense,
      categoryId: 'cafe',
      occurredOn: DateTime(2026, 8, 18),
      occurredTime: '25:99',
      paymentSourceId: 'momo',
      paymentSourceName: 'MoMo',
      paymentMethod: PaymentMethodKind.eWallet,
    );
    expect(validateNewTransaction(input), isA<ValidationFailure>());
  });
}
