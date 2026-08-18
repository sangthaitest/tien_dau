import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/data/datasources/transaction_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/repositories/transaction_repository_impl.dart';
import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';

int _seq = 0;

NewTransaction _sample({int amount = 25000, String category = 'breakfast'}) {
  return NewTransaction(
    amount: amount,
    type: TransactionType.expense,
    categoryId: category,
    occurredOn: DateTime(2026, 8, 18),
    occurredTime: '07:20',
    paymentSourceId: 'cash',
    paymentSourceName: 'Tiền mặt',
    paymentMethod: PaymentMethodKind.cash,
    note: 'test',
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase db;
  late TransactionService service;

  setUp(() async {
    _seq += 1;
    final dir = await Directory.systemTemp.createTemp('tien_day_$_seq');
    db = await AppDatabase.openPath(p.join(dir.path, 'tien_day.db'));
    var ids = 0;
    var now = DateTime.utc(2026, 8, 18, 10);
    service = TransactionService(
      TransactionRepositoryImpl(
        local: TransactionLocalDataSource(db),
        idFactory: () {
          ids += 1;
          return 'id-$ids';
        },
        clock: () {
          now = now.add(const Duration(seconds: 1));
          return now;
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('fresh database has no transactions', () async {
    final result = await service.list();
    expect(result, isA<Ok>());
    expect((result as Ok).value, isEmpty);
  });

  test('create persists and can be read', () async {
    final created = await service.add(_sample());
    expect(created, isA<Ok>());
    final tx = (created as Ok).value;

    final fetched = await service.get(tx.id);
    final loaded = (fetched as Ok).value;
    expect(loaded.amount, 25000);
    expect(loaded.categoryId, 'breakfast');
    expect(loaded.paymentMethod, PaymentMethodKind.cash);
  });

  test('create rejects invalid amount and does not persist', () async {
    final result = await service.add(_sample(amount: 0));
    expect(result, isA<Err>());
    expect((result as Err).failure, isA<ValidationFailure>());
    final list = await service.list();
    expect((list as Ok).value, isEmpty);
  });

  test('update changes amount', () async {
    final created = (await service.add(_sample()) as Ok).value;
    final updated = await service.update(created.copyWith(amount: 30000));
    expect((updated as Ok).value.amount, 30000);
    final fetched = await service.get(created.id);
    expect((fetched as Ok).value.amount, 30000);
  });

  test('delete removes the row', () async {
    final created = (await service.add(_sample()) as Ok).value;
    final deleted = await service.remove(created.id);
    expect(deleted, isA<Ok>());
    final fetched = await service.get(created.id);
    expect((fetched as Err).failure, isA<NotFoundFailure>());
  });

  test('get and delete missing ids return not found', () async {
    final missing = await service.get('nope');
    expect((missing as Err).failure, isA<NotFoundFailure>());
    final deleted = await service.remove('nope');
    expect((deleted as Err).failure, isA<NotFoundFailure>());
  });

  test('persistence errors are not swallowed', () async {
    await db.close();
    final result = await service.add(_sample());
    expect(result, isA<Err>());
    expect((result as Err).failure, isA<PersistenceFailure>());
  });
}
