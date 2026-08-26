import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/data/datasources/recurring_transaction_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/db/migrations/recurring_transactions.dart';
import 'package:tien_day/data/repositories/recurring_transaction_repository_impl.dart';
import 'package:tien_day/domain/entities/recurring_transaction.dart';
import 'package:tien_day/domain/failures/result.dart';

RecurringTransaction _rule({
  required String id,
  String name = 'Tiền nhà',
  RecurringKind kind = RecurringKind.expense,
  int amount = 5000000,
  int day = 25,
  bool isActive = true,
}) {
  final now = DateTime.utc(2026, 8, 18);
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
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<RecurringTransactionRepositoryImpl> openRepo() async {
    final dir = await Directory.systemTemp.createTemp('tien_day_recurring');
    addTearDown(() => dir.delete(recursive: true));
    final database = await AppDatabase.openPath(
      p.join(dir.path, 'tien_day.db'),
    );
    addTearDown(database.close);
    return RecurringTransactionRepositoryImpl(
      RecurringTransactionsLocalDataSource(database),
    );
  }

  test('create read update delete and active flag persist', () async {
    final repo = await openRepo();
    final created = _rule(id: 'rent');
    expect((await repo.create(created)).isOk, isTrue);

    var listed = ((await repo.listAll()) as Ok).value;
    expect(listed.single.id, 'rent');
    expect(listed.single.amount, 5000000);
    expect(listed.single.isActive, isTrue);

    final updated = created.copyWith(
      name: 'Tiền nhà trọ',
      amount: 5500000,
      isActive: false,
      updatedAt: DateTime.utc(2026, 8, 19),
    );
    expect((await repo.update(updated)).isOk, isTrue);
    listed = ((await repo.listAll()) as Ok).value;
    expect(listed.single.name, 'Tiền nhà trọ');
    expect(listed.single.amount, 5500000);
    expect(listed.single.isActive, isFalse);

    expect((await repo.delete('rent')).isOk, isTrue);
    listed = ((await repo.listAll()) as Ok).value;
    expect(listed, isEmpty);
  });

  test(
    'refuses to create or update recurring_salary via generic writes',
    () async {
      final repo = await openRepo();
      final salary = _rule(
        id: recurringSalaryId,
        name: 'Lương',
        kind: RecurringKind.income,
        amount: 20000000,
      );
      expect((await repo.create(salary)).isErr, isTrue);
      expect((await repo.update(salary)).isErr, isTrue);
    },
  );

  test('delete removes recurring_salary', () async {
    final repo = await openRepo();
    final salary = _rule(
      id: recurringSalaryId,
      name: 'Lương',
      kind: RecurringKind.income,
      amount: 20000000,
      day: 1,
    );
    expect((await repo.replaceSalary(salary)).isOk, isTrue);
    expect((await repo.delete(recurringSalaryId)).isOk, isTrue);
    expect(((await repo.listAll()) as Ok).value, isEmpty);
  });

  test('create survives reopening the database file', () async {
    final dir = await Directory.systemTemp.createTemp(
      'tien_day_recurring_restart',
    );
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');

    var database = await AppDatabase.openPath(path);
    var repo = RecurringTransactionRepositoryImpl(
      RecurringTransactionsLocalDataSource(database),
    );
    expect(
      (await repo.create(
        _rule(id: 'wifi', name: 'Wifi', amount: 1000000, day: 5),
      )).isOk,
      isTrue,
    );
    await database.close();

    database = await AppDatabase.openPath(path);
    addTearDown(database.close);
    repo = RecurringTransactionRepositoryImpl(
      RecurringTransactionsLocalDataSource(database),
    );
    final listed = ((await repo.listAll()) as Ok).value;
    expect(listed, hasLength(1));
    expect(listed.single.name, 'Wifi');
    expect(listed.single.amount, 1000000);
    expect(listed.single.dayOfMonth, 5);
  });

  test(
    'replaceSalary updates recurring_salary without minting a second row',
    () async {
      final repo = await openRepo();
      final first = _rule(
        id: recurringSalaryId,
        name: 'Lương',
        kind: RecurringKind.income,
        amount: 20000000,
        day: 1,
      );
      expect((await repo.replaceSalary(first)).isOk, isTrue);
      expect(
        (await repo.replaceSalary(first.copyWith(amount: 22000000))).isOk,
        isTrue,
      );
      final listed = ((await repo.listAll()) as Ok).value;
      expect(listed, hasLength(1));
      expect(listed.single.id, recurringSalaryId);
      expect(listed.single.amount, 22000000);
    },
  );
}
