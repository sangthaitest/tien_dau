import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/application/finance_service.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/data/datasources/finance_local_datasource.dart';
import 'package:tien_day/data/datasources/recurring_transaction_local_datasource.dart';
import 'package:tien_day/data/datasources/transaction_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/db/migrations/recurring_transactions.dart';
import 'package:tien_day/data/repositories/finance_repository_impl.dart';
import 'package:tien_day/data/repositories/recurring_transaction_repository_impl.dart';
import 'package:tien_day/data/repositories/transaction_repository_impl.dart';
import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/recurring_transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/result.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  RecurringDraft rentDraft({int day = 25, int amount = 5000000}) {
    return RecurringDraft(
      name: 'Tiền nhà',
      kind: RecurringKind.expense,
      amount: amount,
      dayOfMonth: day,
    );
  }

  Future<({AppDatabase database, FinanceService finance})> openStack(
    String path, {
    String Function()? idFactory,
  }) async {
    final database = await AppDatabase.openPath(path);
    final recurringDs = RecurringTransactionsLocalDataSource(database);
    var ids = 0;
    final finance = FinanceService(
      FinanceRepositoryImpl(
        prefs: PrefsLocalDataSource(database),
        goals: GoalsLocalDataSource(database),
        recurring: recurringDs,
      ),
      TransactionService(
        TransactionRepositoryImpl(
          local: TransactionLocalDataSource(database),
          idFactory: () => 'tx-${ids++}',
          clock: () => DateTime.utc(2026, 8, 18, 10),
        ),
      ),
      RecurringTransactionRepositoryImpl(recurringDs),
      idFactory: idFactory ?? () => 'rent',
      clock: () => DateTime(2026, 8, 18, 10),
    );
    return (database: database, finance: finance);
  }

  test(
    'created recurring item survives closing and reopening the database',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'tien_day_recurring_form',
      );
      addTearDown(() => dir.delete(recursive: true));
      final path = p.join(dir.path, 'tien_day.db');

      var stack = await openStack(path);
      expect((await stack.finance.createRecurring(rentDraft())).isOk, isTrue);
      await stack.database.close();

      stack = await openStack(path);
      addTearDown(stack.database.close);
      final snap = ((await stack.finance.load()) as Ok).value;
      expect(snap.recurringItems, hasLength(1));
      expect(snap.recurringItems.single.name, 'Tiền nhà');
      expect(snap.recurringItems.single.amount, 5000000);
      expect(snap.recurringItems.single.dayOfMonth, 25);
      expect(snap.recurringItems.single.direction, RecurringDirection.subtract);

      final version = (await stack.database.raw.rawQuery(
        'PRAGMA user_version',
      )).first['user_version'];
      expect(version, 5);
    },
  );

  test(
    'Lương form updates recurring_salary without a transaction or salary_amount',
    () async {
      final dir = await Directory.systemTemp.createTemp('tien_day_salary_form');
      addTearDown(() => dir.delete(recursive: true));
      final path = p.join(dir.path, 'tien_day.db');
      final stack = await openStack(
        path,
        idFactory: () => throw StateError('must not mint a salary id'),
      );
      addTearDown(stack.database.close);

      expect((await stack.finance.saveSalary(20000000)).isOk, isTrue);
      expect(
        (await stack.finance.createRecurring(
          RecurringDraft(
            name: 'Lương',
            kind: RecurringKind.income,
            amount: 22000000,
            dayOfMonth: 1,
          ),
        )).isOk,
        isTrue,
      );
      expect(
        (await stack.finance.createRecurring(
          RecurringDraft(
            name: 'Lương',
            kind: RecurringKind.income,
            amount: 23000000,
            dayOfMonth: 1,
          ),
        )).isOk,
        isTrue,
      );

      final salaryRows = await stack.database.raw.query(
        recurringTransactionsTable,
        where: 'id = ?',
        whereArgs: [recurringSalaryId],
      );
      final allRecurring = await stack.database.raw.query(
        recurringTransactionsTable,
      );
      final prefs = await stack.database.raw.query(
        'app_prefs',
        where: 'key = ?',
        whereArgs: [salaryAmountPrefKey],
      );
      final transactions = await stack.database.raw.query('transactions');

      expect(salaryRows, hasLength(1));
      expect(allRecurring.where((row) => row['name'] == 'Lương'), hasLength(1));
      expect(salaryRows.single['amount'], 23000000);
      expect(salaryRows.single['kind'], 'income');
      expect(salaryRows.single['direction'], 'add');
      expect(salaryRows.single['frequency'], 'monthly');
      expect(salaryRows.single['interval_count'], 1);
      expect(prefs, isEmpty);
      expect(transactions, isEmpty);
      expect(((await stack.finance.load()) as Ok).value.salary, 23000000);
    },
  );

  test('deleting a recurring rule does not delete transactions', () async {
    final dir = await Directory.systemTemp.createTemp(
      'tien_day_recurring_delete',
    );
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    final stack = await openStack(path);
    addTearDown(stack.database.close);

    expect(
      (await TransactionService(
            TransactionRepositoryImpl(
              local: TransactionLocalDataSource(stack.database),
              idFactory: () => 'tx-keep',
              clock: () => DateTime.utc(2026, 8, 18, 10),
            ),
          ).add(
            NewTransaction(
              amount: 45000,
              type: TransactionType.expense,
              categoryId: 'cafe',
              occurredOn: DateTime(2026, 8, 7),
              paymentSourceId: 'momo',
              paymentSourceName: 'MoMo',
              paymentMethod: PaymentMethodKind.eWallet,
            ),
          ))
          .isOk,
      isTrue,
    );
    expect((await stack.finance.createRecurring(rentDraft())).isOk, isTrue);
    expect((await stack.finance.deleteRecurring('rent')).isOk, isTrue);

    final recurring = await stack.database.raw.query(
      recurringTransactionsTable,
    );
    final transactions = await stack.database.raw.query('transactions');
    expect(recurring.where((row) => row['id'] == 'rent'), isEmpty);
    expect(transactions, hasLength(1));
    expect(transactions.single['amount'], 45000);
  });

  test(
    'income and expense both survive closing and reopening the database',
    () async {
      final dir = await Directory.systemTemp.createTemp('tien_day_both_kinds');
      addTearDown(() => dir.delete(recursive: true));
      final path = p.join(dir.path, 'tien_day.db');
      var ids = 0;
      var stack = await openStack(path, idFactory: () => 'rule-${ids++}');
      expect((await stack.finance.createRecurring(rentDraft())).isOk, isTrue);
      expect(
        (await stack.finance.createRecurring(
          RecurringDraft(
            name: 'Thưởng',
            kind: RecurringKind.income,
            amount: 1000000,
            dayOfMonth: 10,
          ),
        )).isOk,
        isTrue,
      );
      await stack.database.close();

      stack = await openStack(path);
      addTearDown(stack.database.close);
      final snap = ((await stack.finance.load()) as Ok).value;
      expect(snap.managedRecurring.map((item) => item.name), ['Tiền nhà']);
      expect(snap.managedIncome.map((item) => item.name), ['Thưởng']);
      expect(snap.recurringItems.map((item) => item.kind), [
        RecurringKind.expense,
      ]);
    },
  );

  test('deleting recurring income does not delete transactions', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_income_delete');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    final stack = await openStack(path, idFactory: () => 'bonus');
    addTearDown(stack.database.close);

    expect(
      (await TransactionService(
            TransactionRepositoryImpl(
              local: TransactionLocalDataSource(stack.database),
              idFactory: () => 'tx-keep',
              clock: () => DateTime.utc(2026, 8, 18, 10),
            ),
          ).add(
            NewTransaction(
              amount: 45000,
              type: TransactionType.expense,
              categoryId: 'cafe',
              occurredOn: DateTime(2026, 8, 7),
              paymentSourceId: 'momo',
              paymentSourceName: 'MoMo',
              paymentMethod: PaymentMethodKind.eWallet,
            ),
          ))
          .isOk,
      isTrue,
    );
    expect(
      (await stack.finance.createRecurring(
        RecurringDraft(
          name: 'Thưởng',
          kind: RecurringKind.income,
          amount: 1000000,
          dayOfMonth: 10,
        ),
      )).isOk,
      isTrue,
    );
    expect((await stack.finance.deleteRecurring('bonus')).isOk, isTrue);

    final recurring = await stack.database.raw.query(
      recurringTransactionsTable,
    );
    final transactions = await stack.database.raw.query('transactions');
    expect(recurring.where((row) => row['id'] == 'bonus'), isEmpty);
    expect(transactions, hasLength(1));
    expect(transactions.single['amount'], 45000);
  });

  test('deleting salary removes recurring_salary and zeros salary', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_salary_delete');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    final stack = await openStack(path);
    addTearDown(stack.database.close);

    expect((await stack.finance.saveSalary(20000000)).isOk, isTrue);
    expect(
      (await stack.finance.deleteRecurring(RecurringTransaction.salaryId)).isOk,
      isTrue,
    );

    final salaryRows = await stack.database.raw.query(
      recurringTransactionsTable,
      where: 'id = ?',
      whereArgs: [recurringSalaryId],
    );
    final prefs = await stack.database.raw.query(
      'app_prefs',
      where: 'key = ?',
      whereArgs: [salaryAmountPrefKey],
    );
    expect(salaryRows, isEmpty);
    expect(prefs, isEmpty);
    expect(((await stack.finance.load()) as Ok).value.salary, 0);
  });
}
