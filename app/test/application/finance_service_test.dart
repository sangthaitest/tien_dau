import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/finance_service.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';

import '../support/memory_finance_repository.dart';
import '../support/memory_transaction_repository.dart';

void main() {
  final now = DateTime(2026, 8, 18, 10);

  FinanceService service({MemoryTransactionRepository? txs}) {
    return FinanceService(
      MemoryFinanceRepository(),
      TransactionService(txs ?? MemoryTransactionRepository()),
      idFactory: () => 'goal-1',
      clock: () => now,
    );
  }

  test('fresh finance data is empty and unused budget is zero', () async {
    final snap = ((await service().load()) as Ok).value;
    expect(snap.salary, 0);
    expect(snap.budgetLimit, 0);
    expect(snap.used, 0);
    expect(snap.goals, isEmpty);
  });

  test('salary and budget persist and budget used comes from expenses', () async {
    final txs = MemoryTransactionRepository();
    final finance = service(txs: txs);
    expect((await finance.saveSalary(18500000)).isOk, isTrue);
    expect((await finance.saveBudget(10000000)).isOk, isTrue);
    await TransactionService(txs).add(
      NewTransaction(
        amount: 45000,
        type: TransactionType.expense,
        categoryId: 'cafe',
        occurredOn: DateTime(2026, 8, 7),
        paymentSourceId: 'momo',
        paymentSourceName: 'MoMo',
        paymentMethod: PaymentMethodKind.eWallet,
      ),
    );
    final snap = ((await finance.load()) as Ok).value;
    expect(snap.salary, 18500000);
    expect(snap.budgetLimit, 10000000);
    expect(snap.used, 45000);
    expect(snap.remaining, 10000000 - 45000);
  });

  test('monthly budget excludes income and other months and reports overspend', () async {
    final txs = MemoryTransactionRepository();
    final finance = service(txs: txs);
    final transactions = TransactionService(txs);
    expect((await finance.saveBudget(100000)).isOk, isTrue);

    for (final input in [
      NewTransaction(
        amount: 120000,
        type: TransactionType.expense,
        categoryId: 'market',
        occurredOn: DateTime(2026, 8, 18),
        paymentSourceId: 'cash',
        paymentSourceName: 'Tiền mặt',
        paymentMethod: PaymentMethodKind.cash,
      ),
      NewTransaction(
        amount: 900000,
        type: TransactionType.income,
        categoryId: 'other',
        occurredOn: DateTime(2026, 8, 18),
        paymentSourceId: 'bank',
        paymentSourceName: 'Ngân hàng',
        paymentMethod: PaymentMethodKind.bankAccount,
      ),
      NewTransaction(
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'cafe',
        occurredOn: DateTime(2026, 7, 31),
        paymentSourceId: 'cash',
        paymentSourceName: 'Tiền mặt',
        paymentMethod: PaymentMethodKind.cash,
      ),
    ]) {
      expect((await transactions.add(input)).isOk, isTrue);
    }

    final snap = ((await finance.load()) as Ok).value;
    expect(snap.budgetLimit, 100000);
    expect(snap.used, 120000);
    expect(snap.remaining, -20000);
    expect(snap.percentUsed, 100);
  });

  test('rejects invalid salary and budget', () async {
    final finance = service();
    expect(((await finance.saveSalary(0)) as Err).failure, isA<ValidationFailure>());
    expect(((await finance.saveBudget(0)) as Err).failure, isA<ValidationFailure>());
  });

  test('goal create add-money and delete', () async {
    final finance = service();
    expect((await finance.createGoal(name: 'Quỹ khẩn cấp', targetAmount: 1000000)).isOk, isTrue);
    var snap = ((await finance.load()) as Ok).value;
    expect(snap.goals.single.name, 'Quỹ khẩn cấp');
    expect((await finance.addToGoal(snap.goals.single, 200000)).isOk, isTrue);
    snap = ((await finance.load()) as Ok).value;
    expect(snap.goals.single.currentAmount, 200000);
    expect((await finance.deleteGoal(snap.goals.single.id)).isOk, isTrue);
    snap = ((await finance.load()) as Ok).value;
    expect(snap.goals, isEmpty);
  });
}
