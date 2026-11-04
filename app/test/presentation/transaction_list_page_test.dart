import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/theme/app_colors.dart';
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

Color _dayHeaderFill(WidgetTester tester, String isoDate) {
  final container = tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.byKey(Key('month-day-$isoDate')),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
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
    expect(find.textContaining('CHI TIÊU NGÀY'), findsNothing);
    expect(find.byKey(const Key('tx-sum-expense')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('date-carousel'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('tx-sum-expense'))).dy),
    );
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

  testWidgets('month mode shows category filters and collapses older days', (
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
    expect(find.textContaining('CHI TIÊU THÁNG'), findsNothing);
    expect(find.byKey(const Key('tx-sum-expense')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('cat-all'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('tx-sum-expense'))).dy),
    );
    expect(find.text('Cơm'), findsOneWidget);
    expect(find.text('Shopee'), findsOneWidget);
    expect(find.textContaining('07/08'), findsOneWidget);
    expect(
      tester
          .widget<Icon>(find.byKey(const Key('month-toggle-2026-08-18')))
          .icon,
      Icons.expand_less_rounded,
    );

    await tester.tap(find.byKey(const Key('month-day-2026-08-07')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Shopee'), findsNothing);
    expect(find.text('Cơm'), findsOneWidget);
    expect(find.textContaining('07/08'), findsOneWidget);
    expect(find.byKey(const Key('cat-all')), findsOneWidget);
    expect(
      tester
          .widget<Icon>(find.byKey(const Key('month-toggle-2026-08-07')))
          .icon,
      Icons.expand_more_rounded,
    );

    await tester.tap(find.byKey(const Key('month-toggle-2026-08-07')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Shopee'), findsOneWidget);
    expect(find.text('Cơm'), findsOneWidget);
  });

  testWidgets(
    'month mode opens the two newest days and resets on month change',
    (tester) async {
      _phone(tester);
      await _pumpShell(
        tester,
        service: TransactionService(
          MemoryTransactionRepository(
            seed: [
              _tx(
                id: 'a10',
                amount: 2000,
                date: DateTime(2026, 8, 10),
                detail: 'Ngày 10',
              ),
              _tx(
                id: 'a9',
                amount: 2500,
                date: DateTime(2026, 8, 9),
                detail: 'Ngày 9',
              ),
              _tx(
                id: 'a2',
                amount: 3000,
                date: DateTime(2026, 8, 2),
                detail: 'Ngày 2',
              ),
              _tx(
                id: 'j20',
                amount: 4000,
                date: DateTime(2026, 7, 20),
                detail: 'Tháng 7 mới',
              ),
              _tx(
                id: 'j9',
                amount: 5000,
                date: DateTime(2026, 7, 9),
                detail: 'Tháng 7 giữa',
              ),
              _tx(
                id: 'j1',
                amount: 6000,
                date: DateTime(2026, 7, 1),
                detail: 'Tháng 7 cũ',
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('nav-transactions')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('mode-month')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Ngày 10'), findsOneWidget);
      expect(find.text('Ngày 9'), findsOneWidget);
      expect(find.text('Ngày 2'), findsNothing);
      expect(find.textContaining('02/08'), findsOneWidget);
      expect(find.textContaining('18/08'), findsNothing);
      expect(_dayHeaderFill(tester, '2026-08-10'), AppColors.card);
      expect(_dayHeaderFill(tester, '2026-08-02'), Colors.transparent);
      expect(
        tester.getTopLeft(find.textContaining('10/08')).dx,
        tester.getTopLeft(find.textContaining('02/08')).dx,
      );
      final openHeader = tester.getRect(
        find.byKey(const Key('month-day-2026-08-10')),
      );
      final openTile = tester.getRect(find.byKey(const Key('tx-tile-a10')));
      final closedHeader = tester.getRect(
        find.byKey(const Key('month-day-2026-08-02')),
      );
      expect(openHeader.left, openTile.left);
      expect(openHeader.right, openTile.right);
      expect(closedHeader.left, openHeader.left);
      expect(closedHeader.right, openHeader.right);

      await tester.tap(find.byKey(const Key('month-day-2026-08-02')));
      await tester.pump();
      expect(_dayHeaderFill(tester, '2026-08-02'), AppColors.card);

      await tester.tap(find.byKey(const Key('month-prev')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Tháng 07/2026'), findsOneWidget);
      expect(find.text('Tháng 7 mới'), findsOneWidget);
      expect(find.text('Tháng 7 giữa'), findsOneWidget);
      expect(find.text('Tháng 7 cũ'), findsNothing);
      expect(find.textContaining('01/07'), findsOneWidget);
      expect(find.text('Ngày 18'), findsNothing);
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
    expect(find.byKey(const Key('date-cell-2026-08-17')), findsOneWidget);

    await tester.tap(find.byKey(const Key('date-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Hôm nay'), findsWidgets);
  });

  testWidgets('day mode month chip jumps months and stays on the day view', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: 'aug',
              amount: 45000,
              date: DateTime(2026, 8, 18),
              detail: 'Cafe hôm nay',
            ),
            _tx(
              id: 'sep',
              amount: 12000,
              date: DateTime(2026, 9, 1),
              detail: 'Cafe tháng 9',
            ),
            _tx(
              id: 'jul',
              amount: 8000,
              date: DateTime(2026, 7, 9),
              detail: 'Cafe tháng 7',
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Theo ngày'), findsOneWidget);
    expect(find.text('Tháng 08/2026'), findsOneWidget);
    expect(find.text('Cafe hôm nay'), findsOneWidget);
    expect(find.byKey(const Key('date-cell-2026-08-18')), findsOneWidget);

    await tester.tap(find.byKey(const Key('day-month-next')));
    await tester.pumpAndSettle();
    expect(find.text('Theo ngày'), findsOneWidget);
    expect(find.text('Tháng 09/2026'), findsOneWidget);
    expect(find.byKey(const Key('date-cell-2026-09-01')), findsOneWidget);
    expect(find.text('Cafe tháng 9'), findsOneWidget);
    expect(find.text('Cafe hôm nay'), findsNothing);

    await tester.tap(find.byKey(const Key('day-month-prev')));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 08/2026'), findsOneWidget);
    expect(find.byKey(const Key('date-cell-2026-08-18')), findsOneWidget);
    expect(find.text('Cafe hôm nay'), findsOneWidget);

    await tester.tap(find.byKey(const Key('day-month-label')));
    await tester.pumpAndSettle();
    expect(find.text('Chọn tháng'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finance-month-cell-2026-7')));
    await tester.tap(find.byKey(const Key('finance-month-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Theo ngày'), findsOneWidget);
    expect(find.text('Tháng 07/2026'), findsOneWidget);
    expect(find.byKey(const Key('date-cell-2026-07-01')), findsOneWidget);
    expect(find.text('Cafe tháng 7'), findsNothing);
    expect(find.text('Cafe hôm nay'), findsNothing);
  });

  testWidgets('month label opens the finance picker and reloads that month', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: 'aug',
              amount: 45000,
              date: DateTime(2026, 8, 7),
              detail: 'Cafe tháng 8',
            ),
            _tx(
              id: 'jul',
              amount: 12000,
              date: DateTime(2026, 7, 9),
              detail: 'Cafe tháng 7',
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('mode-month')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Tháng 08/2026'), findsOneWidget);
    expect(find.text('Cafe tháng 8'), findsOneWidget);
    expect(find.text('Cafe tháng 7'), findsNothing);

    await tester.tap(find.byKey(const Key('month-label')));
    await tester.pumpAndSettle();
    expect(find.text('Chọn tháng'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finance-month-cell-2026-7')));
    await tester.pump();
    expect(find.text('Tháng 08/2026'), findsOneWidget);
    expect(find.text('Cafe tháng 8'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finance-month-close')));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 08/2026'), findsOneWidget);
    expect(find.text('Cafe tháng 8'), findsOneWidget);

    await tester.tap(find.byKey(const Key('month-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finance-month-cell-2026-7')));
    await tester.tap(find.byKey(const Key('finance-month-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 07/2026'), findsOneWidget);
    expect(find.textContaining('CHI TIÊU THÁNG'), findsNothing);
    expect(find.byKey(const Key('tx-sum-expense')), findsOneWidget);
    expect(find.text('Cafe tháng 7'), findsOneWidget);
    expect(find.text('Cafe tháng 8'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Tháng 8 · 2026'), findsOneWidget);
  });
}
