import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';

import '../support/memory_transaction_repository.dart';
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
  TransactionType type = TransactionType.expense,
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

Future<void> _pumpShell(WidgetTester tester, {required TransactionService service}) async {
  final home = HomeController(HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)));
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

Future<void> _openStats(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-statistics')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() {
  });

  testWidgets('navigation opens Statistics with active tab', (tester) async {
    _phone(tester);
    await _pumpShell(tester, service: TransactionService(MemoryTransactionRepository()));
    await _openStats(tester);
    expect(find.text('Thống kê'), findsWidgets);
    expect(find.byKey(const Key('nav-statistics')), findsOneWidget);
    expect(find.text('so với tháng trước'), findsOneWidget);
    expect(find.text('Gần đây'), findsNothing);
    expect(find.text('Lương'), findsNothing);
    expect(find.text('Ngân sách tháng'), findsNothing);
    expect(find.text('Mục tiêu tiết kiệm'), findsNothing);
  });

  testWidgets('empty statistics copy', (tester) async {
    _phone(tester);
    await _pumpShell(tester, service: TransactionService(MemoryTransactionRepository()));
    await _openStats(tester);
    expect(find.byKey(const Key('stats-empty')), findsOneWidget);
    expect(find.text('Chưa có chi tiêu tháng này.'), findsOneWidget);
    expect(find.text('Chưa có dữ liệu.'), findsOneWidget);
    expect(find.byKey(const Key('stats-expense-total')), findsOneWidget);
    expect(find.text('0 ₫'), findsWidgets);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('populated statistics from real expenses', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(id: '1', amount: 50000, date: DateTime(2026, 8, 7), category: 'cafe'),
            _tx(id: '2', amount: 150000, date: DateTime(2026, 8, 8), category: 'market'),
            _tx(id: '3', amount: 99999, date: DateTime(2026, 7, 1), category: 'cafe'),
            _tx(id: '4', amount: 800000, date: DateTime(2026, 8, 9), type: TransactionType.income),
          ],
        ),
      ),
    );
    await _openStats(tester);
    expect(find.text('Chi tiêu Tháng 8 · 2026'), findsOneWidget);
    expect(find.text('200.000 ₫'), findsWidgets);
    expect(find.text('Cafe'), findsWidgets);
    expect(find.text('Đi chợ'), findsWidgets);
    expect(find.text('Chi tiêu theo danh mục'), findsOneWidget);
    expect(find.text('Danh mục chi nhiều nhất'), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
  });

  testWidgets('unknown category uses fallback label', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [_tx(id: '1', amount: 12000, date: DateTime(2026, 8, 4), category: 'xyz-unknown')],
        ),
      ),
    );
    await _openStats(tester);
    expect(find.text('Khác'), findsWidgets);
    expect(find.text('12.000 ₫'), findsWidgets);
  });

  testWidgets('list error is shown instead of a fake zero total', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(MemoryTransactionRepository(failList: true)),
    );
    await _openStats(tester);
    expect(find.byKey(const Key('stats-error')), findsOneWidget);
    expect(find.text('read failed'), findsOneWidget);
    expect(find.byKey(const Key('stats-expense-total')), findsNothing);
    expect(find.byKey(const Key('stats-empty')), findsNothing);
  });

  testWidgets('category card shows all categories in a two-column grid', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(id: 'b', amount: 1529157, date: DateTime(2026, 8, 1), category: 'bills'),
            _tx(id: 't', amount: 672000, date: DateTime(2026, 8, 2), category: 'transport'),
            _tx(id: 'o', amount: 460000, date: DateTime(2026, 8, 3), category: 'other'),
            _tx(id: 'bf', amount: 432000, date: DateTime(2026, 8, 4), category: 'breakfast'),
            _tx(id: 'd', amount: 383000, date: DateTime(2026, 8, 5), category: 'dinner'),
            _tx(id: 'l', amount: 377000, date: DateTime(2026, 8, 6), category: 'lunch'),
            _tx(id: 'c', amount: 342000, date: DateTime(2026, 8, 7), category: 'cafe'),
            _tx(id: 's', amount: 284000, date: DateTime(2026, 8, 8), category: 'snacks'),
            _tx(id: 'm', amount: 147000, date: DateTime(2026, 8, 9), category: 'market'),
          ],
        ),
      ),
    );
    await _openStats(tester);
    final grid = find.byKey(const Key('stats-category-grid'));
    expect(grid, findsOneWidget);
    expect(find.descendant(of: grid, matching: find.text('Hóa đơn')), findsOneWidget);
    expect(find.descendant(of: grid, matching: find.text('Di chuyển')), findsOneWidget);
    expect(find.descendant(of: grid, matching: find.text('Ăn sáng')), findsOneWidget);
    expect(find.descendant(of: grid, matching: find.text('Đi chợ')), findsOneWidget);
    expect(find.text('1.529.157 ₫'), findsWidgets);
    expect(find.byKey(const Key('stats-see-all-categories')), findsNothing);
    expect(find.textContaining('Xem tất cả'), findsNothing);
    expect(tester.getRect(grid).width, greaterThan(300));
  });

  testWidgets('three categories fill the grid without a leftover action', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(id: '1', amount: 50000, date: DateTime(2026, 8, 1), category: 'cafe'),
            _tx(id: '2', amount: 40000, date: DateTime(2026, 8, 2), category: 'market'),
            _tx(id: '3', amount: 30000, date: DateTime(2026, 8, 3), category: 'transport'),
          ],
        ),
      ),
    );
    await _openStats(tester);
    final grid = find.byKey(const Key('stats-category-grid'));
    expect(find.descendant(of: grid, matching: find.text('Cafe')), findsOneWidget);
    expect(find.descendant(of: grid, matching: find.text('Đi chợ')), findsOneWidget);
    expect(find.descendant(of: grid, matching: find.text('Di chuyển')), findsOneWidget);
    expect(find.byKey(const Key('stats-see-all-categories')), findsNothing);
  });

  testWidgets('one category and a large amount stay on one grid cell', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(id: '1', amount: 999999999, date: DateTime(2026, 8, 1), category: 'cafe'),
          ],
        ),
      ),
    );
    await _openStats(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('stats-category-grid')), findsOneWidget);
    expect(find.byKey(const Key('pie-total')), findsOneWidget);
    expect(find.text('999.999.999 ₫'), findsWidgets);
    expect(find.byKey(const Key('stats-see-all-categories')), findsNothing);
  });

  testWidgets('category grid follows the viewed month', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(id: 'aug', amount: 200000, date: DateTime(2026, 8, 8), category: 'bills'),
            _tx(id: 'jul', amount: 150000, date: DateTime(2026, 7, 8), category: 'cafe'),
          ],
        ),
      ),
    );
    await _openStats(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('stats-category-grid')),
        matching: find.text('Hóa đơn'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('home-month-chip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('month-pick-2026-07')));
    await tester.pumpAndSettle();
    await _openStats(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('stats-category-grid')),
        matching: find.text('Cafe'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('stats-category-grid')),
        matching: find.text('Hóa đơn'),
      ),
      findsNothing,
    );
  });
}
