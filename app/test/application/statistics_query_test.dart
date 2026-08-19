import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/statistics_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/presentation/format/money_format.dart';
import 'package:tien_day/presentation/theme/category_look.dart';

import '../support/memory_transaction_repository.dart';

Transaction _tx({
  required String id,
  required int amount,
  required DateTime date,
  TransactionType type = TransactionType.expense,
  String category = 'cafe',
}) {
  final now = DateTime.utc(2026, 8, 1);
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: category,
    occurredOn: date,
    paymentSourceId: 'momo',
    paymentSourceName: 'MoMo',
    paymentMethod: PaymentMethodKind.eWallet,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final august = DateTime(2026, 8, 18, 10);

  StatisticsQuery query(List<Transaction> items) {
    return StatisticsQuery(
      TransactionService(MemoryTransactionRepository(seed: items)),
      clock: () => august,
    );
  }

  test('empty statistics', () async {
    final snap = ((await query([]).load()) as Ok).value;
    expect(snap.isEmpty, isTrue);
    expect(snap.totalExpense, 0);
    expect(snap.previousExpense, 0);
    expect(snap.deltaPercent, 0);
    expect(snap.categories, isEmpty);
    expect(StatisticsQuery.percentOf(10, 0), 0);
  });

  test('total spending is expenses in the viewed month', () async {
    final snap = ((await query([
      _tx(id: 'a', amount: 10000, date: DateTime(2026, 8, 1)),
      _tx(id: 'b', amount: 20000, date: DateTime(2026, 8, 10)),
      _tx(id: 'july', amount: 99999, date: DateTime(2026, 7, 31)),
      _tx(id: 'income', amount: 500000, date: DateTime(2026, 8, 5), type: TransactionType.income),
    ]).load()) as Ok).value;
    expect(snap.totalExpense, 30000);
    expect(snap.month, DateTime(2026, 8));
  });

  test('category aggregation ranking and percentage', () async {
    final snap = ((await query([
      _tx(id: 'c1', amount: 30000, date: DateTime(2026, 8, 1), category: 'cafe'),
      _tx(id: 'c2', amount: 10000, date: DateTime(2026, 8, 2), category: 'cafe'),
      _tx(id: 'm1', amount: 60000, date: DateTime(2026, 8, 3), category: 'market'),
    ]).load()) as Ok).value;
    expect(snap.totalExpense, 100000);
    expect(snap.categories.map((e) => e.categoryId).toList(), ['market', 'cafe']);
    expect(snap.categories.first.amount, 60000);
    expect(snap.categories.first.percent, 60);
    expect(snap.categories.last.amount, 40000);
    expect(snap.categories.last.percent, 40);
    expect(StatisticsQuery.percentOf(1, 3), 33);
  });

  test('date filtering uses calendar month and previous month comparison', () async {
    final snap = ((await query([
      _tx(id: 'aug', amount: 8000, date: DateTime(2026, 8, 18)),
      _tx(id: 'jul', amount: 10000, date: DateTime(2026, 7, 2)),
      _tx(id: 'jun', amount: 40000, date: DateTime(2026, 6, 1)),
    ]).load()) as Ok).value;
    expect(snap.totalExpense, 8000);
    expect(snap.previousExpense, 10000);
    expect(snap.deltaPercent, -20);
    expect(snap.categories.single.amount, 8000);
  });

  test('previous-period comparison when previous month is zero', () async {
    expect(StatisticsQuery.deltaPercent(current: 0, previous: 0), 0);
    expect(StatisticsQuery.deltaPercent(current: 12000, previous: 0), 100);
    expect(StatisticsQuery.deltaPercent(current: 15000, previous: 10000), 50);
    expect(StatisticsQuery.deltaPercent(current: 8000, previous: 10000), -20);
  });

  test('unknown category does not crash and uses fallback look', () async {
    final snap = ((await query([
      _tx(id: 'x', amount: 12000, date: DateTime(2026, 8, 4), category: 'not-a-real-cat'),
    ]).load()) as Ok).value;
    expect(snap.categories.single.categoryId, 'not-a-real-cat');
    expect(categoryLook('not-a-real-cat').name, 'Khác');
  });

  test('top categories are capped at five', () async {
    final items = [
      for (var i = 0; i < 6; i++)
        _tx(
          id: '$i',
          amount: (6 - i) * 1000,
          date: DateTime(2026, 8, 1 + i),
          category: 'cat-$i',
        ),
    ];
    final snap = ((await query(items).load()) as Ok).value;
    expect(snap.categories, hasLength(6));
    expect(snap.topCategories, hasLength(5));
    expect(snap.topCategories.first.amount, 6000);
  });

  test('VND formatting for statistics amounts', () {
    expect(formatVnd(0), '0 ₫');
    expect(formatVnd(45000), '45.000 ₫');
    expect(formatVnd(1500000), '1.500.000 ₫');
    expect(formatVndShort(45000), '45k');
    expect(formatVndShort(1500000), '1.5tr');
  });

  test('repository persistence error is returned', () async {
    final result = await StatisticsQuery(
      TransactionService(MemoryTransactionRepository(failList: true)),
      clock: () => august,
    ).load();
    expect((result as Err).failure, isA<PersistenceFailure>());
  });
}
