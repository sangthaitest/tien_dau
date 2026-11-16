import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/application/detail_suggestions.dart';
import 'package:tien_day/data/datasources/transaction_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/repositories/transaction_repository_impl.dart';
import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/result.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('stored expenses suggest the usual detail amount', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_details');
    final database = await AppDatabase.openPath(
      p.join(dir.path, 'tien_day.db'),
    );
    var nextId = 0;
    final repo = TransactionRepositoryImpl(
      local: TransactionLocalDataSource(database),
      idFactory: () => 'tx-${nextId++}',
      clock: () => DateTime.utc(2026, 8, 18),
    );

    Future<void> add({
      required int amount,
      required String categoryId,
      String? detail,
      required DateTime on,
      String? time,
      TransactionType type = TransactionType.expense,
    }) async {
      final result = await repo.create(
        NewTransaction(
          amount: amount,
          type: type,
          categoryId: categoryId,
          detail: detail,
          occurredOn: on,
          occurredTime: time,
          paymentSourceId: 'cash',
          paymentSourceName: 'Tiền mặt',
          paymentMethod: PaymentMethodKind.cash,
        ),
      );
      expect(result, isA<Ok>());
    }

    await add(
      amount: 27000,
      categoryId: 'lunch',
      detail: 'Cơm',
      on: DateTime(2026, 8, 1),
      time: '12:00',
    );
    await add(
      amount: 27000,
      categoryId: 'lunch',
      detail: 'Cơm',
      on: DateTime(2026, 8, 2),
      time: '12:00',
    );
    await add(
      amount: 35000,
      categoryId: 'lunch',
      detail: 'Cơm',
      on: DateTime(2026, 8, 10),
      time: '12:00',
    );
    await add(
      amount: 30000,
      categoryId: 'lunch',
      detail: 'Bún',
      on: DateTime(2026, 8, 3),
      time: '12:10',
    );
    await add(
      amount: 30000,
      categoryId: 'lunch',
      detail: 'Bún',
      on: DateTime(2026, 8, 4),
      time: '12:10',
    );
    await add(
      amount: 32000,
      categoryId: 'lunch',
      detail: 'Bún',
      on: DateTime(2026, 8, 4),
      time: '18:00',
    );
    await add(
      amount: 29000,
      categoryId: 'cafe',
      detail: 'Highlands',
      on: DateTime(2026, 8, 5),
      time: '08:00',
    );
    await add(
      amount: 900000,
      categoryId: 'lunch',
      detail: 'Lương',
      on: DateTime(2026, 8, 1),
      time: '09:00',
      type: TransactionType.income,
    );
    await add(
      amount: 15000,
      categoryId: 'lunch',
      detail: '   ',
      on: DateTime(2026, 8, 6),
      time: '12:00',
    );
    final pho = await repo.create(
      NewTransaction(
        amount: 40000,
        type: TransactionType.expense,
        categoryId: 'lunch',
        detail: 'Phở',
        occurredOn: DateTime(2026, 8, 7),
        occurredTime: '12:00',
        paymentSourceId: 'cash',
        paymentSourceName: 'Tiền mặt',
        paymentMethod: PaymentMethodKind.cash,
      ),
    );
    await repo.delete((pho as Ok).value.id);

    final buckets = await repo.detailAmountBuckets('lunch');
    expect(buckets, isA<Ok>());
    final suggestions = suggestDetailAmounts((buckets as Ok).value);
    expect(suggestions['Cơm'], 27000);
    expect(suggestions['Bún'], 30000);
    expect(suggestions.containsKey('Highlands'), isFalse);
    expect(suggestions.containsKey('Lương'), isFalse);
    expect(suggestions.containsKey('Phở'), isFalse);

    await database.raw.close();
    await dir.delete(recursive: true);
  });
}
