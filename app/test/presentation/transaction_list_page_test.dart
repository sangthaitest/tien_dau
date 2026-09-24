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
    expect(find.text('Chưa có giao dịch hôm nay'), findsOneWidget);
    expect(find.text('Nhấn + để thêm giao dịch'), findsOneWidget);
    expect(find.byKey(const Key('tx-empty-add')), findsNothing);
    expect(find.byKey(const Key('cat-all')), findsNothing);
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
    await tester.tap(find.byKey(const Key('mode-month')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
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
    expect(find.text('Theo ngày'), findsOneWidget);
    expect(find.text('1 giao dịch'), findsOneWidget);
    expect(find.textContaining('CHI TIÊU NGÀY'), findsOneWidget);
    expect(find.text('Tháng này'), findsNothing);
    expect(find.byKey(const Key('cat-all')), findsNothing);
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
              date: DateTime(2026, 8, 18),
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

  testWidgets('detail sheet swipe up does not show a progress indicator', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: '1',
              amount: 45000,
              date: DateTime(2026, 8, 18),
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

    await tester.drag(find.text('Chi cho'), const Offset(0, -240));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final sheet = find.byType(TransactionDetailSheet);
    expect(
      find.descendant(
        of: sheet,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byType(LinearProgressIndicator),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byType(RefreshProgressIndicator),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byType(StretchingOverscrollIndicator),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byType(GlowingOverscrollIndicator),
      ),
      findsNothing,
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

  testWidgets('type filter chips are not on the transaction list', (
    tester,
  ) async {
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

  testWidgets('delete goes through transaction detail', (tester) async {
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
    expect(find.byKey(const Key('tx-swipe-1')), findsNothing);

    await tester.tap(find.byKey(const Key('tx-tile-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('btn-detail-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Xóa giao dịch?'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('tx-tile-1')), findsNothing);
    expect(find.text('Chi tiết'), findsNothing);
    expect(repo.items, isEmpty);
  });

  testWidgets(
    'month mode shows category filters and opens a day on header tap',
    (tester) async {
      _phone(tester);
      await _pumpShell(
        tester,
        service: TransactionService(
          MemoryTransactionRepository(
            seed: [
              _tx(
                id: '1',
                amount: 12000,
                date: DateTime(2026, 8, 7),
                detail: 'Shopee',
              ),
              _tx(
                id: '2',
                amount: 15000,
                date: DateTime(2026, 8, 18),
                detail: 'Cơm',
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('nav-transactions')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Cơm'), findsOneWidget);
      expect(find.text('Shopee'), findsNothing);

      await tester.tap(find.byKey(const Key('mode-month')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('cat-all')), findsOneWidget);
      expect(find.textContaining('CHI TIÊU THÁNG'), findsOneWidget);
      expect(find.text('Shopee'), findsOneWidget);
      expect(find.text('Cơm'), findsOneWidget);

      await tester.tap(find.byKey(const Key('month-toggle-2026-08-07')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Shopee'), findsNothing);
      expect(find.text('Cơm'), findsOneWidget);
      await tester.tap(find.byKey(const Key('month-toggle-2026-08-07')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Shopee'), findsOneWidget);

      await tester.tap(find.byKey(const Key('month-day-2026-08-07')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Theo ngày'), findsOneWidget);
      expect(find.text('Shopee'), findsOneWidget);
      expect(find.text('Cơm'), findsNothing);
      expect(find.byKey(const Key('cat-all')), findsNothing);
      expect(find.text('CHI TIÊU NGÀY 07/08'), findsOneWidget);
    },
  );

  testWidgets('day arrows move the selected date', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: '1',
              amount: 10000,
              date: DateTime(2026, 8, 17),
              detail: 'Hôm qua',
            ),
            _tx(
              id: '2',
              amount: 20000,
              date: DateTime(2026, 8, 18),
              detail: 'Hôm nay',
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Hôm nay'), findsWidgets);
    expect(find.text('Hôm qua'), findsNothing);

    await tester.tap(find.byKey(const Key('date-prev')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Hôm qua'), findsWidgets);
    expect(find.textContaining('17/08'), findsWidgets);

    await tester.tap(find.byKey(const Key('date-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Hôm nay'), findsWidgets);
  });
}
