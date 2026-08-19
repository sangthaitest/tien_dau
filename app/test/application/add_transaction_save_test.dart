import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/presentation/add_transaction/add_transaction_controller.dart';
import 'package:tien_day/presentation/home/home_controller.dart';

import '../support/memory_transaction_repository.dart';
import '../support/memory_transaction_catalog_repository.dart';

void main() {
  test('successful save persists through the service', () async {
    final repo = MemoryTransactionRepository();
    final controller = AddTransactionController(
      service: TransactionService(repo),
      catalogController: buildTestCatalogController(),
      clock: () => DateTime(2026, 8, 18, 9, 15),
    );
    controller.applyShortcut(10000);
    controller.toggleDetail('Highlands');
    controller.setNote('mang đi');

    final result = await controller.save();
    expect(result, isA<Ok>());
    expect(controller.error, isNull);

    final saved = repo.items.single;
    expect(saved.amount, 10000);
    expect(saved.categoryId, 'cafe');
    expect(saved.detail, 'Highlands');
    expect(saved.note, 'mang đi');
    expect(saved.occurredOn, DateTime(2026, 8, 18));
    expect(saved.occurredTime, '09:15');
    expect(saved.paymentSourceId, 'momo');
    expect(saved.paymentSourceName, 'MoMo');
    expect(saved.paymentMethod, PaymentMethodKind.eWallet);
  });

  test('invalid amount cannot save and does not persist', () async {
    final repo = MemoryTransactionRepository();
    final controller = AddTransactionController(
      service: TransactionService(repo),
      catalogController: buildTestCatalogController(),
      clock: () => DateTime(2026, 8, 18, 9, 15),
    );

    final result = await controller.save();
    expect(result, isA<Err>());
    expect((result as Err).failure, isA<ValidationFailure>());
    expect(controller.error, 'Vui lòng nhập số tiền');
    expect(repo.items, isEmpty);
  });

  test('persistence failure keeps input and surfaces an error', () async {
    final repo = MemoryTransactionRepository(failCreate: true);
    final controller = AddTransactionController(
      service: TransactionService(repo),
      catalogController: buildTestCatalogController(),
      clock: () => DateTime(2026, 8, 18, 9, 15),
    );
    controller.applyShortcut(200000);
    controller.selectCategory('market');
    controller.setNote('giữ form');

    final result = await controller.save();
    expect(result, isA<Err>());
    expect((result as Err).failure, isA<PersistenceFailure>());
    expect(controller.error, 'Không lưu được giao dịch. Thử lại.');
    expect(controller.draft.amount, 200000);
    expect(controller.draft.categoryId, 'market');
    expect(controller.draft.note, 'giữ form');
    expect(repo.items, isEmpty);
  });

  test('Home refreshes after a successful save', () async {
    final repo = MemoryTransactionRepository();
    final service = TransactionService(repo);
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 10)),
    );
    await home.load();
    expect(home.snapshot.recent, isEmpty);
    expect(home.snapshot.monthExpense, 0);

    final add = AddTransactionController(
      service: service,
      catalogController: buildTestCatalogController(),
      clock: () => DateTime(2026, 8, 18, 9, 15),
    );
    add.applyShortcut(50000);
    add.selectCategory('transport');
    add.toggleDetail('Grab');
    expect((await add.save()).isOk, isTrue);

    await home.load();
    expect(home.snapshot.monthExpense, 50000);
    expect(home.snapshot.recent, hasLength(1));
    expect(home.snapshot.recent.single.detail, 'Grab');
    expect(home.snapshot.recent.single.categoryId, 'transport');
  });

  test('editing preserves a historical payment outside the catalog', () async {
    final now = DateTime.utc(2026, 8, 18);
    final existing = Transaction(
      id: 'legacy',
      amount: 30000,
      type: TransactionType.expense,
      categoryId: 'cafe',
      occurredOn: DateTime(2026, 8, 18),
      paymentSourceId: 'legacy-bank',
      paymentSourceName: 'Ngân hàng cũ',
      paymentMethod: PaymentMethodKind.bankAccount,
      createdAt: now,
      updatedAt: now,
    );
    final repo = MemoryTransactionRepository(seed: [existing]);
    final controller = AddTransactionController(
      service: TransactionService(repo),
      catalogController: buildTestCatalogController(),
      clock: () => now,
      existing: existing,
    );

    controller.applyShortcut(50000);
    expect((await controller.save()).isOk, isTrue);

    expect(repo.items.single.amount, 50000);
    expect(repo.items.single.paymentSourceId, 'legacy-bank');
    expect(repo.items.single.paymentSourceName, 'Ngân hàng cũ');
    expect(repo.items.single.paymentMethod, PaymentMethodKind.bankAccount);
  });
}
