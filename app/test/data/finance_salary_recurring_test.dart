import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/data/datasources/finance_local_datasource.dart';
import 'package:tien_day/data/datasources/recurring_transaction_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/db/migrations/recurring_transactions.dart';
import 'package:tien_day/data/repositories/finance_repository_impl.dart';
import 'package:tien_day/domain/entities/finance.dart';
import 'package:tien_day/domain/failures/result.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('salary is stored as recurring_salary, not salary_amount or a transaction', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_salary');
    addTearDown(() => dir.delete(recursive: true));
    final database = await AppDatabase.openPath(p.join(dir.path, 'tien_day.db'));
    addTearDown(database.close);

    final repo = FinanceRepositoryImpl(
      prefs: PrefsLocalDataSource(database),
      goals: GoalsLocalDataSource(database),
      recurring: RecurringTransactionsLocalDataSource(database),
    );

    expect(((await repo.getSalary()) as Ok).value.amount, 0);
    expect((await repo.saveSalary(const MonthlySalary(amount: 18500000))).isOk, isTrue);
    expect(((await repo.getSalary()) as Ok).value.amount, 18500000);
    expect((await repo.saveSalary(const MonthlySalary(amount: 20000000))).isOk, isTrue);
    expect(((await repo.getSalary()) as Ok).value.amount, 20000000);

    final prefs = await database.raw.query(
      'app_prefs',
      where: 'key = ?',
      whereArgs: [salaryAmountPrefKey],
    );
    final salaryRows = await database.raw.query(
      recurringTransactionsTable,
      where: 'id = ?',
      whereArgs: [recurringSalaryId],
    );
    final transactions = await database.raw.query('transactions');

    expect(prefs, isEmpty);
    expect(salaryRows, hasLength(1));
    expect(salaryRows.single['amount'], 20000000);
    expect(salaryRows.single['kind'], 'income');
    expect(salaryRows.single['direction'], 'add');
    expect(transactions, isEmpty);
  });
}
