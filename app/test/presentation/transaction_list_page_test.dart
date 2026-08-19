import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/transactions/transaction_detail_controller.dart';
import 'package:tien_day/presentation/transactions/transaction_detail_sheet.dart';

import '../support/memory_transaction_repository.dart';
import '../support/memory_transaction_catalog_repository.dart';
import '../support/shell_harness.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Transaction _tx({
  required String id,
  required int amount,
  required DateTime date,
  String category = 'cafe',
  String? detail,
}) {
  final now = DateTime.utc(2026, 8, 1);
  return Transaction(
    id: id,
    amount: amount,
    type: TransactionType.expense,
    categoryId: category,
    detail: detail,
    occurredOn: date,
    occurredTime: '09:15',
    paymentSourceId: 'momo',
    paymentSourceName: 'MoMo',
    paymentMethod: PaymentMethodKind.eWallet,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required TransactionService service,
}) async {
  final home = HomeController(
    HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: buildShell(
        transactions: service,
        home: home,
        clock: () => DateTime(2026, 8, 18, 9),
      ).shell,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() {});

  testWidgets('empty transaction list copy', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(MemoryTransactionRepository()),
    );
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Chưa có giao dịch'), findsOneWidget);
    expect(find.text('Nhấn + để thêm giao dịch đầu tiên.'), findsOneWidget);
  });

  testWidgets('Home Xem tất cả opens Giao dịch with real rows', (tester) async {
    _phone(tester);
    final service = TransactionService(
      MemoryTransactionRepository(
        seed: [
          _tx(
            id: '1',
            amount: 45000,
            date: DateTime(2026, 8, 7),
            detail: 'Highlands',
          ),
        ],
      ),
    );
    await _pumpShell(tester, service: service);
    await tester.tap(find.byKey(const Key('see-all')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Giao dịch'), findsWidgets);
    expect(find.text('Highlands'), findsWidgets);
    expect(find.textContaining('45.000'), findsWidgets);
    expect(find.text('Cafe'), findsWidgets);
  });

  testWidgets('bottom navigation opens Giao dịch', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: '1',
              amount: 10000,
              date: DateTime(2026, 8, 18),
              detail: 'Grab',
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Grab'), findsOneWidget);
    expect(find.text('Tháng này'), findsOneWidget);
  });

  testWidgets('row tap opens detail', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: '1',
              amount: 45000,
              date: DateTime(2026, 8, 7),
              detail: 'Highlands',
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('tx-tile-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Chi tiết'), findsWidgets);
    expect(find.text('Highlands'), findsWidgets);
    expect(find.text('Chi cho'), findsOneWidget);
    expect(find.text('MoMo'), findsOneWidget);
    expect(tester.getTopLeft(find.byType(BottomSheet)).dy, greaterThan(80));
    expect(
      tester.getRect(find.byKey(const Key('btn-detail-edit'))).bottom,
      lessThan(844),
    );
    expect(
      tester.getRect(find.byKey(const Key('btn-detail-delete'))).bottom,
      lessThan(844),
    );
  });

  testWidgets('detail not found', (tester) async {
    _phone(tester);
    final service = TransactionService(MemoryTransactionRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionDetailSheet(
            controller: TransactionDetailController(service),
            transactionService: service,
            catalogController: buildTestCatalogController(),
            clock: DateTime.now,
            transactionId: 'missing',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Không tìm thấy giao dịch'), findsOneWidget);
  });

  testWidgets('list surfaces a load error', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(MemoryTransactionRepository(failList: true)),
    );
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('tx-list-error')), findsOneWidget);
  });

  testWidgets('type filter chips are not on the transaction list', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(MemoryTransactionRepository()),
    );
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('type-all')), findsNothing);
    expect(find.byKey(const Key('type-expense')), findsNothing);
  });

  testWidgets('swipe-to-delete removes a transaction after confirm', (
    tester,
  ) async {
    _phone(tester);
    final repo = MemoryTransactionRepository(
      seed: [
        _tx(
          id: '1',
          amount: 10000,
          date: DateTime(2026, 8, 18),
          detail: 'Grab',
        ),
      ],
    );
    await _pumpShell(tester, service: TransactionService(repo));
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Grab'), findsOneWidget);

    await tester.drag(find.byKey(const Key('tx-swipe-1')), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Xóa giao dịch?'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Grab'), findsNothing);
    expect(repo.items, isEmpty);
  });
}
