import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/finance_service.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/data/db/migrations/recurring_transactions.dart';
import 'package:tien_day/domain/entities/finance.dart';
import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/recurring_transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';

import '../support/memory_finance_repository.dart';
import '../support/memory_recurring_transaction_repository.dart';
import '../support/memory_transaction_repository.dart';

void main() {
  final now = DateTime(2026, 8, 18, 10);

  FinanceService service({
    MemoryTransactionRepository? txs,
    MemoryRecurringTransactionRepository? recurring,
  }) {
    return FinanceService(
      MemoryFinanceRepository(),
      TransactionService(txs ?? MemoryTransactionRepository()),
      recurring ?? MemoryRecurringTransactionRepository(),
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

  test(
    'salary and budget persist and budget used comes from expenses',
    () async {
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
    },
  );

  test(
    'monthly budget excludes income and other months and reports overspend',
    () async {
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
    },
  );

  test(
    'load can summarize a selected month instead of the clock month',
    () async {
      final txs = MemoryTransactionRepository();
      final finance = service(txs: txs);
      final transactions = TransactionService(txs);
      expect((await finance.saveBudget(100000)).isOk, isTrue);
      expect(
        (await transactions.add(
          NewTransaction(
            amount: 45000,
            type: TransactionType.expense,
            categoryId: 'cafe',
            occurredOn: DateTime(2026, 7, 20),
            paymentSourceId: 'momo',
            paymentSourceName: 'MoMo',
            paymentMethod: PaymentMethodKind.eWallet,
          ),
        )).isOk,
        isTrue,
      );
      expect(
        (await transactions.add(
          NewTransaction(
            amount: 12000,
            type: TransactionType.expense,
            categoryId: 'cafe',
            occurredOn: DateTime(2026, 8, 2),
            paymentSourceId: 'momo',
            paymentSourceName: 'MoMo',
            paymentMethod: PaymentMethodKind.eWallet,
          ),
        )).isOk,
        isTrue,
      );

      final july = ((await finance.load(month: DateTime(2026, 7))) as Ok).value;
      expect(july.month, DateTime(2026, 7));
      expect(july.used, 45000);
    },
  );

  test('rejects invalid salary and budget', () async {
    final finance = service();
    expect(
      ((await finance.saveSalary(0)) as Err).failure,
      isA<ValidationFailure>(),
    );
    expect(
      ((await finance.saveBudget(0)) as Err).failure,
      isA<ValidationFailure>(),
    );
  });

  test('goal create add-money and delete', () async {
    final finance = service();
    expect(
      (await finance.createGoal(
        name: 'Quỹ khẩn cấp',
        targetAmount: 1000000,
      )).isOk,
      isTrue,
    );
    var snap = ((await finance.load()) as Ok).value;
    expect(snap.goals.single.name, 'Quỹ khẩn cấp');
    expect((await finance.addToGoal(snap.goals.single, 200000)).isOk, isTrue);
    snap = ((await finance.load()) as Ok).value;
    expect(snap.goals.single.currentAmount, 200000);
    expect((await finance.deleteGoal(snap.goals.single.id)).isOk, isTrue);
    snap = ((await finance.load()) as Ok).value;
    expect(snap.goals, isEmpty);
  });

  RecurringTransaction rule({
    required String id,
    String name = 'Tiền nhà',
    RecurringKind kind = RecurringKind.expense,
    int amount = 5000000,
    int day = 25,
    bool isActive = true,
  }) {
    final at = DateTime.utc(2026, 8, 1);
    return RecurringTransaction(
      id: id,
      name: name,
      kind: kind,
      amount: amount,
      frequency: RecurringFrequency.monthly,
      intervalCount: 1,
      direction: kind.derivedDirection,
      categoryId: kind == RecurringKind.expense ? 'bills' : null,
      startDate: DateTime(2026, 8, day),
      isActive: isActive,
      createdAt: at,
      updatedAt: at,
    );
  }

  test(
    'actual expenses come from transactions and recurring from rules',
    () async {
      final txs = MemoryTransactionRepository();
      final recurring = MemoryRecurringTransactionRepository();
      var nextId = 0;
      final finance = FinanceService(
        MemoryFinanceRepository(),
        TransactionService(txs),
        recurring,
        idFactory: () => 'rule-${nextId++}',
        clock: () => now,
      );
      expect((await finance.saveSalary(20000000)).isOk, isTrue);
      expect((await finance.saveBudget(10000000)).isOk, isTrue);
      await TransactionService(txs).add(
        NewTransaction(
          amount: 6569557,
          type: TransactionType.expense,
          categoryId: 'cafe',
          occurredOn: DateTime(2026, 8, 7),
          paymentSourceId: 'momo',
          paymentSourceName: 'MoMo',
          paymentMethod: PaymentMethodKind.eWallet,
        ),
      );
      expect(
        (await recurring.create(
          rule(id: 'card', name: 'Thẻ tín dụng', amount: 5000000, day: 25),
        )).isOk,
        isTrue,
      );
      expect(
        (await recurring.create(
          rule(
            id: 'transfer',
            name: 'Chuyển cho Minh',
            amount: 2000000,
            day: 28,
          ),
        )).isOk,
        isTrue,
      );
      expect(
        (await recurring.create(
          rule(id: 'utility', name: 'Điện nước', amount: 500000, day: 30),
        )).isOk,
        isTrue,
      );
      expect(
        (await recurring.create(
          rule(
            id: 'bonus',
            name: 'Thưởng',
            kind: RecurringKind.income,
            amount: 1000000,
            day: 10,
          ),
        )).isOk,
        isTrue,
      );
      expect(
        (await recurring.create(
          rule(id: 'off', name: 'Gym', amount: 800000, day: 1, isActive: false),
        )).isOk,
        isTrue,
      );

      final snap = ((await finance.load()) as Ok).value;
      expect(snap.used, 6569557);
      expect(snap.salary, 20000000);
      expect(snap.recurringExpenseTotal, 7500000);
      expect(snap.recurringIncomeTotal, 21000000);
      expect(snap.spendableAmount, 21000000 - 7500000);
      expect(snap.projectedRemaining, 20000000 + 1000000 - 6569557 - 7500000);
      expect(
        snap.recurringItems.map((item) => item.id),
        isNot(contains('off')),
      );
      expect(
        snap.recurringItems.map((item) => item.id),
        isNot(contains('bonus')),
      );
      expect(
        snap.recurringItems.map((item) => item.id),
        isNot(contains(recurringSalaryId)),
      );
      expect(snap.managedRecurring.map((item) => item.id), contains('off'));
      expect(
        snap.managedRecurring.map((item) => item.kind),
        everyElement(RecurringKind.expense),
      );
      expect(snap.managedIncome.map((item) => item.id), contains('bonus'));
      expect(
        snap.managedIncome.map((item) => item.kind),
        everyElement(RecurringKind.income),
      );
      expect(
        snap.managedIncome.map((item) => item.id),
        isNot(contains('card')),
      );
    },
  );

  test('inactive recurring items are ignored in monthly totals', () async {
    final recurring = MemoryRecurringTransactionRepository();
    final finance = service(recurring: recurring);
    expect((await finance.saveSalary(10000000)).isOk, isTrue);
    expect(
      (await recurring.create(
        rule(id: 'rent', amount: 3000000, isActive: false),
      )).isOk,
      isTrue,
    );
    final snap = ((await finance.load()) as Ok).value;
    expect(snap.recurringExpenseTotal, 0);
    expect(snap.spendableAmount, 10000000);
    expect(snap.projectedRemaining, 10000000);
    expect(snap.recurringItems, isEmpty);
  });

  RecurringDraft draft({
    String name = 'Tiền nhà',
    RecurringKind kind = RecurringKind.expense,
    int amount = 5000000,
    int dayOfMonth = 25,
    String? categoryId,
    String? paymentSourceId,
    String? note,
  }) {
    return RecurringDraft(
      name: name,
      kind: kind,
      amount: amount,
      dayOfMonth: dayOfMonth,
      categoryId: categoryId,
      paymentSourceId: paymentSourceId,
      note: note,
    );
  }

  test(
    'create expense recurring maps monthly frequency and subtract',
    () async {
      final recurring = MemoryRecurringTransactionRepository();
      final finance = FinanceService(
        MemoryFinanceRepository(),
        TransactionService(MemoryTransactionRepository()),
        recurring,
        idFactory: () => 'rent',
        clock: () => now,
      );

      final created = ((await finance.createRecurring(draft())) as Ok).value;
      expect(created.id, 'rent');
      expect(created.name, 'Tiền nhà');
      expect(created.kind, RecurringKind.expense);
      expect(created.direction, RecurringDirection.subtract);
      expect(created.amount, 5000000);
      expect(created.frequency, RecurringFrequency.monthly);
      expect(created.intervalCount, 1);
      expect(created.dayOfMonth, 25);
      expect(created.categoryId, isNull);
      expect(created.isActive, isTrue);

      final snap = ((await finance.load()) as Ok).value;
      expect(snap.recurringItems.single.id, 'rent');
      expect(snap.recurringItems.single.name, 'Tiền nhà');
    },
  );

  test(
    'create income recurring maps add and does not require category',
    () async {
      final finance = FinanceService(
        MemoryFinanceRepository(),
        TransactionService(MemoryTransactionRepository()),
        MemoryRecurringTransactionRepository(),
        idFactory: () => 'bonus',
        clock: () => now,
      );

      final created =
          ((await finance.createRecurring(
                    draft(
                      name: 'Thưởng',
                      kind: RecurringKind.income,
                      amount: 1000000,
                      dayOfMonth: 10,
                    ),
                  ))
                  as Ok)
              .value;
      expect(created.id, 'bonus');
      expect(created.kind, RecurringKind.income);
      expect(created.direction, RecurringDirection.add);
      expect(created.categoryId, isNull);
      expect(created.frequency, RecurringFrequency.monthly);
      expect(created.intervalCount, 1);
    },
  );

  test('rejects non-positive recurring amount', () async {
    final finance = service();
    expect(
      ((await finance.createRecurring(draft(amount: 0))) as Err).failure,
      isA<ValidationFailure>(),
    );
    expect(
      ((await finance.createRecurring(draft(amount: -1))) as Err).failure,
      isA<ValidationFailure>(),
    );
  });

  test(
    'income named Lương updates recurring_salary and does not duplicate',
    () async {
      final financeRepo = MemoryFinanceRepository();
      final recurring = MemoryRecurringTransactionRepository();
      final txs = MemoryTransactionRepository();
      final at = DateTime.utc(2026, 8, 1);
      expect(
        (await recurring.replaceSalary(
          RecurringTransaction(
            id: RecurringTransaction.salaryId,
            name: 'Lương',
            kind: RecurringKind.income,
            amount: 20000000,
            frequency: RecurringFrequency.monthly,
            intervalCount: 1,
            direction: RecurringDirection.add,
            startDate: DateTime(2026, 8, 1),
            isActive: true,
            createdAt: at,
            updatedAt: at,
          ),
        )).isOk,
        isTrue,
      );
      expect(
        (await financeRepo.saveSalary(
          const MonthlySalary(amount: 20000000),
        )).isOk,
        isTrue,
      );

      final finance = FinanceService(
        financeRepo,
        TransactionService(txs),
        recurring,
        idFactory: () => 'must-not-mint',
        clock: () => now,
      );
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

      final saved =
          ((await finance.createRecurring(
                    draft(
                      name: 'Lương',
                      kind: RecurringKind.income,
                      amount: 22000000,
                      dayOfMonth: 1,
                    ),
                  ))
                  as Ok)
              .value;
      expect(saved.id, RecurringTransaction.salaryId);
      expect(saved.amount, 22000000);
      expect(saved.direction, RecurringDirection.add);

      final listed =
          ((await recurring.listAll()) as Ok<List<RecurringTransaction>>).value;
      expect(
        listed.where((RecurringTransaction item) => item.isSalary),
        hasLength(1),
      );
      expect(
        listed.singleWhere((RecurringTransaction item) => item.isSalary).amount,
        22000000,
      );
      expect(financeRepo.salary.amount, 22000000);
      expect(txs.items, hasLength(1));
      expect(txs.items.single.amount, 45000);
    },
  );

  test('edit keeps the same id and updates values', () async {
    final recurring = MemoryRecurringTransactionRepository();
    final finance = FinanceService(
      MemoryFinanceRepository(),
      TransactionService(MemoryTransactionRepository()),
      recurring,
      idFactory: () => 'rent',
      clock: () => now,
    );
    final created = ((await finance.createRecurring(draft())) as Ok).value;
    final updated =
        ((await finance.updateRecurring(
                  created,
                  draft(
                    name: 'Tiền nhà trọ',
                    amount: 5500000,
                    dayOfMonth: 26,
                    categoryId: 'bills',
                  ),
                ))
                as Ok)
            .value;
    expect(updated.id, 'rent');
    expect(updated.name, 'Tiền nhà trọ');
    expect(updated.amount, 5500000);
    expect(updated.dayOfMonth, 26);
    expect(updated.categoryId, 'bills');
    expect(((await recurring.listAll()) as Ok).value, hasLength(1));
  });

  test('delete removes the rule and leaves transactions untouched', () async {
    final txs = MemoryTransactionRepository();
    final finance = FinanceService(
      MemoryFinanceRepository(),
      TransactionService(txs),
      MemoryRecurringTransactionRepository(),
      idFactory: () => 'rent',
      clock: () => now,
    );
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
    expect((await finance.createRecurring(draft())).isOk, isTrue);
    expect((await finance.deleteRecurring('rent')).isOk, isTrue);
    expect(((await finance.load()) as Ok).value.recurringItems, isEmpty);
    expect(txs.items, hasLength(1));
  });

  test(
    'stores day 31 in start_date even when the viewed month is shorter',
    () async {
      final finance = FinanceService(
        MemoryFinanceRepository(),
        TransactionService(MemoryTransactionRepository()),
        MemoryRecurringTransactionRepository(),
        idFactory: () => 'rent',
        clock: () => DateTime(2026, 4, 10),
      );
      final created =
          ((await finance.createRecurring(draft(dayOfMonth: 31))) as Ok).value;
      expect(created.dayOfMonth, 31);
      expect(created.startDate.year, 2026);
    },
  );

  test('income and expense management lists stay partitioned', () async {
    var nextId = 0;
    final finance = FinanceService(
      MemoryFinanceRepository(),
      TransactionService(MemoryTransactionRepository()),
      MemoryRecurringTransactionRepository(),
      idFactory: () => 'rule-${nextId++}',
      clock: () => now,
    );
    expect((await finance.createRecurring(draft())).isOk, isTrue);
    expect(
      (await finance.createRecurring(
        draft(name: 'Thưởng', kind: RecurringKind.income, amount: 1000000),
      )).isOk,
      isTrue,
    );
    final snap = ((await finance.load()) as Ok).value;
    expect(snap.recurringItems.map((item) => item.name), ['Tiền nhà']);
    expect(snap.managedRecurring.map((item) => item.name), ['Tiền nhà']);
    expect(snap.managedIncome.map((item) => item.name), ['Thưởng']);
    expect(snap.recurringExpenseTotal, 5000000);
    expect(snap.recurringIncomeTotal, 1000000);
  });

  test(
    'editing salary from income management keeps recurring_salary',
    () async {
      final recurring = MemoryRecurringTransactionRepository();
      final financeRepo = MemoryFinanceRepository();
      final at = DateTime.utc(2026, 8, 1);
      expect(
        (await recurring.replaceSalary(
          RecurringTransaction(
            id: RecurringTransaction.salaryId,
            name: 'Lương',
            kind: RecurringKind.income,
            amount: 20000000,
            frequency: RecurringFrequency.monthly,
            intervalCount: 1,
            direction: RecurringDirection.add,
            startDate: DateTime(2026, 8, 1),
            isActive: true,
            createdAt: at,
            updatedAt: at,
          ),
        )).isOk,
        isTrue,
      );
      expect(
        (await financeRepo.saveSalary(
          const MonthlySalary(amount: 20000000),
        )).isOk,
        isTrue,
      );
      final finance = FinanceService(
        financeRepo,
        TransactionService(MemoryTransactionRepository()),
        recurring,
        idFactory: () => 'must-not-mint',
        clock: () => now,
      );
      final existing =
          ((await recurring.findById(RecurringTransaction.salaryId))
                  as Ok<RecurringTransaction?>)
              .value!;
      final updated =
          ((await finance.updateRecurring(
                    existing,
                    draft(
                      name: 'Lương',
                      kind: RecurringKind.income,
                      amount: 21000000,
                      dayOfMonth: 1,
                    ),
                  ))
                  as Ok)
              .value;
      expect(updated.id, RecurringTransaction.salaryId);
      final listed =
          ((await recurring.listAll()) as Ok<List<RecurringTransaction>>).value;
      expect(listed, hasLength(1));
      expect(listed.single.amount, 21000000);
      expect(
        ((await finance.load()) as Ok).value.managedIncome.single.id,
        RecurringTransaction.salaryId,
      );
    },
  );

  test('deleting recurring income leaves transactions untouched', () async {
    final txs = MemoryTransactionRepository();
    final finance = FinanceService(
      MemoryFinanceRepository(),
      TransactionService(txs),
      MemoryRecurringTransactionRepository(),
      idFactory: () => 'bonus',
      clock: () => now,
    );
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
    expect(
      (await finance.createRecurring(
        draft(name: 'Thưởng', kind: RecurringKind.income, amount: 1000000),
      )).isOk,
      isTrue,
    );
    expect((await finance.deleteRecurring('bonus')).isOk, isTrue);
    expect(((await finance.load()) as Ok).value.managedIncome, isEmpty);
    expect(txs.items, hasLength(1));
  });

  test(
    'deleting salary zeros the salary card and leaves transactions',
    () async {
      final financeRepo = MemoryFinanceRepository();
      final recurring = MemoryRecurringTransactionRepository();
      final txs = MemoryTransactionRepository();
      final at = DateTime.utc(2026, 8, 1);
      expect(
        (await recurring.replaceSalary(
          RecurringTransaction(
            id: RecurringTransaction.salaryId,
            name: 'Lương',
            kind: RecurringKind.income,
            amount: 20000000,
            frequency: RecurringFrequency.monthly,
            intervalCount: 1,
            direction: RecurringDirection.add,
            startDate: DateTime(2026, 8, 1),
            isActive: true,
            createdAt: at,
            updatedAt: at,
          ),
        )).isOk,
        isTrue,
      );
      expect(
        (await financeRepo.saveSalary(
          const MonthlySalary(amount: 20000000),
        )).isOk,
        isTrue,
      );
      final finance = FinanceService(
        financeRepo,
        TransactionService(txs),
        recurring,
        idFactory: () => 'must-not-mint',
        clock: () => now,
      );
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

      expect(
        (await finance.deleteRecurring(RecurringTransaction.salaryId)).isOk,
        isTrue,
      );
      expect(((await recurring.listAll()) as Ok).value, isEmpty);
      expect(financeRepo.salary.amount, 0);
      expect(((await finance.load()) as Ok).value.salary, 0);
      expect(((await finance.load()) as Ok).value.managedIncome, isEmpty);
      expect(txs.items, hasLength(1));
    },
  );
}
