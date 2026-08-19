import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/result.dart';

import '../support/memory_transaction_repository.dart';

Transaction _tx({
  required String id,
  required int amount,
  required DateTime date,
  String? time,
  TransactionType type = TransactionType.expense,
  String category = 'cafe',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: category,
    detail: id,
    occurredOn: date,
    occurredTime: time,
    paymentSourceId: 'momo',
    paymentSourceName: 'MoMo',
    paymentMethod: PaymentMethodKind.eWallet,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final august = DateTime(2026, 8, 18, 10);

  HomeQuery query(List<Transaction> items) {
    return HomeQuery(
      TransactionService(MemoryTransactionRepository(seed: items)),
      clock: () => august,
    );
  }

  test('empty store yields zero spend and no recent items', () async {
    final result = await query([]).load();
    final snap = (result as Ok).value;
    expect(snap.monthExpense, 0);
    expect(snap.recent, isEmpty);
  });

  test('sums expenses in the current month only', () async {
    final result = await query([
      _tx(id: 'a', amount: 10000, date: DateTime(2026, 8, 1)),
      _tx(id: 'b', amount: 20000, date: DateTime(2026, 8, 10)),
      _tx(id: 'c', amount: 99999, date: DateTime(2026, 7, 31)),
      _tx(
        id: 'income',
        amount: 50000,
        date: DateTime(2026, 8, 5),
        type: TransactionType.income,
      ),
    ]).load();
    expect((result as Ok).value.monthExpense, 30000);
  });

  test('recent is the three newest expenses this month', () async {
    final result = await query([
      _tx(id: '1', amount: 1, date: DateTime(2026, 8, 1), time: '09:00'),
      _tx(id: '2', amount: 2, date: DateTime(2026, 8, 18), time: '08:00'),
      _tx(id: '3', amount: 3, date: DateTime(2026, 8, 18), time: '10:00'),
      _tx(id: '4', amount: 4, date: DateTime(2026, 8, 17), time: '12:00'),
    ]).load();
    final ids = (result as Ok).value.recent.map((e) => e.id).toList();
    expect(ids, ['3', '2', '4']);
  });

  test('load uses the requested month instead of the clock', () async {
    final result = await query([
      _tx(id: 'aug', amount: 10000, date: DateTime(2026, 8, 2)),
      _tx(id: 'jul', amount: 45000, date: DateTime(2026, 7, 20)),
    ]).load(month: DateTime(2026, 7));
    final snap = (result as Ok).value;
    expect(snap.month, DateTime(2026, 7));
    expect(snap.monthExpense, 45000);
    expect(snap.recent.single.id, 'jul');
  });
}
