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
import 'package:tien_day/domain/entities/transaction_query.dart';
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
    final result = await service.query(
      const TransactionQuerySpec(type: TransactionType.expense),
    );
    expect(result, isA<Ok>());
    expect((result as Ok<TransactionPage>).value.items, isEmpty);
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
    final page = await service.query(
      const TransactionQuerySpec(type: TransactionType.expense),
    );
    expect((page as Ok<TransactionPage>).value.items, isEmpty);
  });

  test('indexed queries page and summarize 10k transactions', () async {
    final batch = db.raw.batch();
    for (var i = 0; i < 10000; i++) {
      final day = (i % 28) + 1;
      final category = 'category-${i % 5}';
      batch.insert('transactions', {
        'id': 'bulk-$i',
        'amount': 1000,
        'type': 'expense',
        'category_id': category,
        'detail': null,
        'occurred_date': '2026-08-${day.toString().padLeft(2, '0')}',
        'occurred_time': '${(i % 24).toString().padLeft(2, '0')}:00',
        'payment_source_id': 'cash',
        'payment_source_name': 'Tiền mặt',
        'payment_method': 'cash',
        'note': null,
        'created_at': DateTime.utc(
          2026,
          8,
          day,
        ).add(Duration(seconds: i)).toIso8601String(),
        'updated_at': DateTime.utc(
          2026,
          8,
          day,
        ).add(Duration(seconds: i)).toIso8601String(),
      });
    }
    await batch.commit(noResult: true);

    final watch = Stopwatch()..start();
    final page = await service.query(
      TransactionQuerySpec(
        fromInclusive: DateTime(2026, 8),
        toExclusive: DateTime(2026, 9),
        type: TransactionType.expense,
        limit: 50,
      ),
    );
    final summary = await service.summarizeExpenses(
      fromInclusive: DateTime(2026, 8),
      toExclusive: DateTime(2026, 9),
    );
    watch.stop();

    final pageValue = (page as Ok<TransactionPage>).value;
    expect(pageValue.items, hasLength(50));
    expect(pageValue.expenseSum, 10000000);
    expect(pageValue.hasMore, isTrue);
    final summaryValue = (summary as Ok<ExpenseSummary>).value;
    expect(summaryValue.total, 10000000);
    expect(summaryValue.byCategory, hasLength(5));
    expect(watch.elapsed, lessThan(const Duration(seconds: 3)));

    final indexes = await db.raw.rawQuery("PRAGMA index_list('transactions')");
    final names = indexes.map((row) => row['name']).toSet();
    expect(names, contains('idx_transactions_type_date_time'));
    expect(names, contains('idx_transactions_type_category_date'));

    final plan = await db.raw.rawQuery(
      '''
EXPLAIN QUERY PLAN
SELECT *
FROM transactions
WHERE type = ? AND occurred_date >= ? AND occurred_date < ?
ORDER BY occurred_date DESC, occurred_time DESC, created_at DESC
LIMIT 51
''',
      ['expense', '2026-08-01', '2026-09-01'],
    );
    final planText = plan.map((row) => row['detail']).join(' ');
    expect(planText, contains('idx_transactions_type_date_time'));
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
