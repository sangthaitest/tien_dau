import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/transaction_list_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/presentation/add_transaction/add_transaction_controller.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/presentation/transactions/transaction_detail_controller.dart';
import 'package:tien_day/presentation/transactions/transaction_list_controller.dart';

import '../support/memory_transaction_repository.dart';
import '../support/memory_transaction_catalog_repository.dart';

Transaction _tx({
  required String id,
  required int amount,
  required DateTime date,
  String? time,
  String category = 'cafe',
  String? detail,
  TransactionType type = TransactionType.expense,
}) {
  final now = DateTime.utc(2026, 8, 1);
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: category,
    detail: detail,
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
  final now = DateTime(2026, 8, 18, 10);

  test('empty list snapshot', () {
    const query = TransactionListQuery();
    final snap = query.apply(
      all: const [],
      now: now,
      filter: const TransactionListFilter(),
    );
    expect(snap.isEmpty, isTrue);
    expect(snap.expenseSum, 0);
  });

  test('newest-first ordering and grouping', () {
    const query = TransactionListQuery();
    final snap = query.apply(
      all: [
        _tx(id: 'a', amount: 10000, date: DateTime(2026, 8, 10), time: '09:00'),
        _tx(id: 'b', amount: 20000, date: DateTime(2026, 8, 18), time: '08:00'),
        _tx(id: 'c', amount: 30000, date: DateTime(2026, 8, 18), time: '11:00'),
      ],
      now: now,
      filter: const TransactionListFilter(),
    );
    expect(snap.items.map((e) => e.id), ['c', 'b', 'a']);
    expect(snap.groups.first.label, 'Hôm nay');
    expect(snap.groups.first.items.map((e) => e.id), ['c', 'b']);
  });

  test('month filtering this vs last', () {
    const query = TransactionListQuery();
    final all = [
      _tx(id: 'aug', amount: 10000, date: DateTime(2026, 8, 2)),
      _tx(id: 'jul', amount: 50000, date: DateTime(2026, 7, 20)),
    ];
    final thisMonth = query.apply(
      all: all,
      now: now,
      filter: const TransactionListFilter(),
    );
    expect(thisMonth.items.map((e) => e.id), ['aug']);
    final last = query.apply(
      all: all,
      now: now,
      filter: const TransactionListFilter(date: TxDateFilter.lastMonth),
    );
    expect(last.items.map((e) => e.id), ['jul']);
    expect(last.expenseSum, 50000);
  });

  test('thisMonth follows viewMonth when it differs from now', () {
    const query = TransactionListQuery();
    final all = [
      _tx(id: 'aug', amount: 10000, date: DateTime(2026, 8, 2)),
      _tx(id: 'jul', amount: 50000, date: DateTime(2026, 7, 20)),
    ];
    final snap = query.apply(
      all: all,
      now: now,
      viewMonth: DateTime(2026, 7),
      filter: const TransactionListFilter(),
    );
    expect(snap.items.single.id, 'jul');
  });

  test('category filter and income excluded', () {
    const query = TransactionListQuery();
    final snap = query.apply(
      all: [
        _tx(
          id: 'cafe',
          amount: 10000,
          date: DateTime(2026, 8, 2),
          category: 'cafe',
        ),
        _tx(
          id: 'grab',
          amount: 20000,
          date: DateTime(2026, 8, 2),
          category: 'transport',
        ),
        _tx(
          id: 'pay',
          amount: 99999,
          date: DateTime(2026, 8, 2),
          type: TransactionType.income,
        ),
      ],
      now: now,
      filter: const TransactionListFilter(categoryId: 'transport'),
    );
    expect(snap.items.single.id, 'grab');
  });

  test('list controller loads and refetches the selected date range', () async {
    final repo = MemoryTransactionRepository(
      seed: [
        _tx(
          id: '1',
          amount: 10000,
          date: DateTime(2026, 8, 2),
          category: 'cafe',
        ),
        _tx(
          id: '2',
          amount: 20000,
          date: DateTime(2026, 7, 2),
          category: 'market',
        ),
      ],
    );
    final controller = TransactionListController(
      TransactionService(repo),
      clock: () => now,
    );
    await controller.load();
    expect(controller.snapshot.items.single.id, '1');
    await controller.setDateFilter(TxDateFilter.lastMonth);
    expect(controller.snapshot.items.single.id, '2');
  });

  test('list controller thisMonth uses viewMonth', () async {
    final repo = MemoryTransactionRepository(
      seed: [
        _tx(id: 'aug', amount: 10000, date: DateTime(2026, 8, 2)),
        _tx(id: 'jul', amount: 20000, date: DateTime(2026, 7, 2)),
      ],
    );
    final controller = TransactionListController(
      TransactionService(repo),
      clock: () => now,
      viewMonth: () => DateTime(2026, 7),
    );
    await controller.load();
    expect(controller.snapshot.items.single.id, 'jul');
  });

  test('custom date filter never runs an unbounded query', () async {
    final repo = MemoryTransactionRepository();
    final controller = TransactionListController(
      TransactionService(repo),
      clock: () => DateTime(2026, 8, 19),
    );
    await controller.load();
    final initialQueries = repo.querySpecs.length;

    await controller.setDateFilter(TxDateFilter.custom);
    expect(repo.querySpecs, hasLength(initialQueries));
    expect(controller.snapshot.isEmpty, isTrue);

    await controller.setCustomFrom(DateTime(2026, 8, 5));
    expect(repo.querySpecs, hasLength(initialQueries));

    await controller.setCustomTo(DateTime(2026, 8, 12));
    expect(repo.querySpecs, hasLength(initialQueries + 1));
    expect(repo.querySpecs.last.fromInclusive, DateTime(2026, 8, 5));
    expect(repo.querySpecs.last.toExclusive, DateTime(2026, 8, 13));
  });

  test('list controller loads transaction pages incrementally', () async {
    final repo = MemoryTransactionRepository(
      seed: [
        for (var i = 0; i < 125; i++)
          _tx(
            id: 'tx-$i',
            amount: 1000,
            date: DateTime(2026, 8, (i % 28) + 1),
            time: '${(i % 24).toString().padLeft(2, '0')}:00',
          ),
      ],
    );
    final controller = TransactionListController(
      TransactionService(repo),
      clock: () => now,
    );

    await controller.load();
    expect(controller.snapshot.items, hasLength(50));
    expect(controller.snapshot.expenseSum, 125000);
    expect(controller.hasMore, isTrue);

    await controller.loadMore();
    expect(controller.snapshot.items, hasLength(100));
    expect(controller.hasMore, isTrue);

    await controller.loadMore();
    expect(controller.snapshot.items, hasLength(125));
    expect(controller.hasMore, isFalse);
  });

  test('list controller surfaces repository errors', () async {
    final controller = TransactionListController(
      TransactionService(MemoryTransactionRepository(failList: true)),
      clock: () => now,
    );
    await controller.load();
    expect(controller.error, isNotNull);
    expect(controller.snapshot.isEmpty, isTrue);
  });

  test('detail loads a transaction and reports not found', () async {
    final repo = MemoryTransactionRepository(
      seed: [
        _tx(
          id: '1',
          amount: 45000,
          date: DateTime(2026, 8, 7),
          detail: 'Highlands',
        ),
      ],
    );
    final service = TransactionService(repo);
    final found = TransactionDetailController(service);
    await found.load('1');
    expect(found.transaction?.detail, 'Highlands');

    final missing = TransactionDetailController(service);
    await missing.load('nope');
    expect(missing.transaction, isNull);
    expect(missing.error, 'Không tìm thấy giao dịch');
  });

  test('edit and delete go through the service and refresh Home', () async {
    final repo = MemoryTransactionRepository(
      seed: [
        _tx(
          id: '1',
          amount: 10000,
          date: DateTime(2026, 8, 18),
          detail: 'Highlands',
        ),
      ],
    );
    final service = TransactionService(repo);
    final home = HomeController(HomeQuery(service, clock: () => now));
    await home.load();
    expect(home.snapshot.recent.single.amount, 10000);

    final add = AddTransactionController(
      service: service,
      catalogController: buildTestCatalogController(),
      clock: () => now,
      existing: repo.items.single,
    );
    add.applyShortcut(20000);
    expect((await add.save()).isOk, isTrue);
    await home.load();
    expect(home.snapshot.recent.single.amount, 20000);
    expect(home.snapshot.recent.single.detail, 'Highlands');
    expect(home.snapshot.monthExpense, 20000);

    final detail = TransactionDetailController(service);
    await detail.load('1');
    expect((await detail.delete()).isOk, isTrue);
    await home.load();
    expect(home.snapshot.recent, isEmpty);
    expect(repo.items, isEmpty);
  });

  test('delete missing id is not found', () async {
    final result = await TransactionService(
      MemoryTransactionRepository(),
    ).remove('nope');
    expect(result, isA<Err>());
    expect((result as Err).failure, isA<NotFoundFailure>());
  });
}
