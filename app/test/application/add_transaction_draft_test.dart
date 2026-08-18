import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/add_transaction_draft.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/failures/app_failure.dart';

void main() {
  late AddTransactionDraft draft;

  setUp(() {
    draft = AddTransactionDraft(now: DateTime(2026, 8, 18, 9, 15));
  });

  test('defaults to now, cafe, and MoMo', () {
    expect(draft.occurredOn, DateTime(2026, 8, 18));
    expect(draft.occurredTime, '09:15');
    expect(draft.categoryId, 'cafe');
    expect(draft.paymentSourceId, 'momo');
    expect(draft.detail, isNull);
    expect(draft.note, isEmpty);
  });

  test('rejects zero amount', () {
    expect(draft.validate(), isA<ValidationFailure>());
    draft.setAmount(0);
    expect(draft.validate(), isA<ValidationFailure>());
  });

  test('shortcut sets amount and marks the matching chip', () {
    draft.applyShortcut(50000);
    expect(draft.amount, 50000);
    expect(draft.activeShortcut, 50000);
  });

  test('manual amount entry can differ from shortcuts', () {
    draft.applyShortcut(10000);
    draft.setAmountFromRaw('25.000');
    expect(draft.amount, 25000);
    expect(draft.activeShortcut, isNull);
  });

  test('category selection maps to production id and clears detail', () {
    draft.toggleDetail('Highlands');
    expect(draft.detail, 'Highlands');
    draft.selectCategory('transport');
    expect(draft.categoryId, 'transport');
    expect(draft.detail, isNull);
    expect(draft.toNewTransaction().categoryId, 'transport');
  });

  test('detail is optional and togglable', () {
    expect(draft.toNewTransaction().detail, isNull);
    draft.toggleDetail('Highlands');
    expect(draft.toNewTransaction().detail, 'Highlands');
    draft.toggleDetail('Highlands');
    expect(draft.toNewTransaction().detail, isNull);
  });

  test('payment picker snapshots source name and method', () {
    draft.selectPayment('cash');
    draft.setAmount(10000);
    final mapped = draft.toNewTransaction();
    expect(mapped.paymentSourceId, 'cash');
    expect(mapped.paymentSourceName, 'Tiền mặt');
    expect(mapped.paymentMethod, PaymentMethodKind.cash);

    draft.selectPayment('vcb');
    final bank = draft.toNewTransaction();
    expect(bank.paymentSourceId, 'vcb');
    expect(bank.paymentSourceName, 'Vietcombank');
    expect(bank.paymentMethod, PaymentMethodKind.bankAccount);
    expect(draft.payment.pickerLabel, contains('Vietcombank'));
  });

  test('date and time are persisted on the input', () {
    draft.setAmount(10000);
    draft.setOccurredOn(DateTime(2026, 7, 3, 22));
    draft.setOccurredTime('14:30');
    final input = draft.toNewTransaction();
    expect(input.occurredOn, DateTime(2026, 7, 3));
    expect(input.occurredTime, '14:30');
  });

  test('note is omitted when empty and stored when provided', () {
    draft.setAmount(10000);
    expect(draft.toNewTransaction().note, isNull);
    draft.setNote('  cafe sáng  ');
    expect(draft.toNewTransaction().note, 'cafe sáng');
  });
}
