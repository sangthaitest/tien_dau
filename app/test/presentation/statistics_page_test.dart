import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/statistics_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/statistics/statistics_payment_section.dart';

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
  String paymentSourceId = 'momo',
  String paymentSourceName = 'MoMo',
  PaymentMethodKind paymentMethod = PaymentMethodKind.eWallet,
  String? note,
}) {
  final now = DateTime.utc(2026, 8, 1);
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: category,
    occurredOn: date,
    paymentSourceId: paymentSourceId,
    paymentSourceName: paymentSourceName,
    paymentMethod: paymentMethod,
    note: note,
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

Future<void> _openStats(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-statistics')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() {});

  testWidgets('navigation opens Statistics with active tab', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(MemoryTransactionRepository()),
    );
    await _openStats(tester);
    expect(find.text('Thống kê'), findsWidgets);
    expect(find.byKey(const Key('nav-statistics')), findsOneWidget);
    expect(find.text('so với tháng trước'), findsOneWidget);
    expect(find.text('Đây nè'), findsNothing);
    expect(find.text('Lương'), findsNothing);
    expect(find.text('Ngân sách tháng'), findsNothing);
    expect(find.text('Mục tiêu tiết kiệm'), findsNothing);
  });

  testWidgets('empty statistics copy', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(MemoryTransactionRepository()),
    );
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
            _tx(
              id: '1',
              amount: 50000,
              date: DateTime(2026, 8, 7),
              category: 'cafe',
            ),
            _tx(
              id: '2',
              amount: 150000,
              date: DateTime(2026, 8, 8),
              category: 'market',
            ),
            _tx(
              id: '3',
              amount: 99999,
              date: DateTime(2026, 7, 1),
              category: 'cafe',
            ),
            _tx(
              id: '4',
              amount: 800000,
              date: DateTime(2026, 8, 9),
              type: TransactionType.income,
            ),
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
          seed: [
            _tx(
              id: '1',
              amount: 12000,
              date: DateTime(2026, 8, 4),
              category: 'xyz-unknown',
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);
    expect(find.text('Khác'), findsWidgets);
    expect(find.text('12.000 ₫'), findsWidgets);
  });

  testWidgets('list error is shown instead of a fake zero total', (
    tester,
  ) async {
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
            _tx(
              id: 'b',
              amount: 1529157,
              date: DateTime(2026, 8, 1),
              category: 'bills',
            ),
            _tx(
              id: 't',
              amount: 672000,
              date: DateTime(2026, 8, 2),
              category: 'transport',
            ),
            _tx(
              id: 'o',
              amount: 460000,
              date: DateTime(2026, 8, 3),
              category: 'other',
            ),
            _tx(
              id: 'bf',
              amount: 432000,
              date: DateTime(2026, 8, 4),
              category: 'breakfast',
            ),
            _tx(
              id: 'd',
              amount: 383000,
              date: DateTime(2026, 8, 5),
              category: 'dinner',
            ),
            _tx(
              id: 'l',
              amount: 377000,
              date: DateTime(2026, 8, 6),
              category: 'lunch',
            ),
            _tx(
              id: 'c',
              amount: 342000,
              date: DateTime(2026, 8, 7),
              category: 'cafe',
            ),
            _tx(
              id: 's',
              amount: 284000,
              date: DateTime(2026, 8, 8),
              category: 'snacks',
            ),
            _tx(
              id: 'm',
              amount: 147000,
              date: DateTime(2026, 8, 9),
              category: 'market',
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);
    final grid = find.byKey(const Key('stats-category-grid'));
    expect(grid, findsOneWidget);
    expect(
      find.descendant(of: grid, matching: find.text('Hóa đơn')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: grid, matching: find.text('Di chuyển')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: grid, matching: find.text('Ăn sáng')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: grid, matching: find.text('Đi chợ')),
      findsOneWidget,
    );
    expect(find.text('1.5tr'), findsWidgets);
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
            _tx(
              id: '1',
              amount: 50000,
              date: DateTime(2026, 8, 1),
              category: 'cafe',
            ),
            _tx(
              id: '2',
              amount: 40000,
              date: DateTime(2026, 8, 2),
              category: 'market',
            ),
            _tx(
              id: '3',
              amount: 30000,
              date: DateTime(2026, 8, 3),
              category: 'transport',
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);
    final grid = find.byKey(const Key('stats-category-grid'));
    expect(
      find.descendant(of: grid, matching: find.text('Cafe')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: grid, matching: find.text('Đi chợ')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: grid, matching: find.text('Di chuyển')),
      findsOneWidget,
    );
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
            _tx(
              id: '1',
              amount: 999999999,
              date: DateTime(2026, 8, 1),
              category: 'cafe',
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('stats-category-grid')), findsOneWidget);
    expect(find.byKey(const Key('pie-total')), findsOneWidget);
    expect(find.byKey(const Key('stats-see-all-categories')), findsNothing);
  });

  testWidgets('category grid follows the viewed month', (tester) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: 'aug',
              amount: 200000,
              date: DateTime(2026, 8, 8),
              category: 'bills',
            ),
            _tx(
              id: 'jul',
              amount: 150000,
              date: DateTime(2026, 7, 8),
              category: 'cafe',
            ),
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

  testWidgets(
    'statistics month controls the query and stays after leaving the tab',
    (tester) async {
      _phone(tester);
      await _pumpShell(
        tester,
        service: TransactionService(
          MemoryTransactionRepository(
            seed: [
              _tx(
                id: '1',
                amount: 50000,
                date: DateTime(2026, 8, 7),
                category: 'cafe',
              ),
              _tx(
                id: '2',
                amount: 150000,
                date: DateTime(2026, 8, 8),
                category: 'market',
              ),
              _tx(
                id: '3',
                amount: 99999,
                date: DateTime(2026, 7, 1),
                category: 'cafe',
              ),
            ],
          ),
        ),
      );
      await _openStats(tester);
      expect(find.text('Chi tiêu Tháng 8 · 2026'), findsOneWidget);
      expect(find.text('200.000 ₫'), findsWidgets);
      expect(find.text('Đi chợ'), findsWidgets);

      await tester.tap(find.byKey(const Key('stats-month-label')));
      await tester.pumpAndSettle();
      expect(find.text('Chọn tháng'), findsOneWidget);
      await tester.tap(find.byKey(const Key('finance-month-cell-2026-7')));
      await tester.pump();
      expect(find.text('Chi tiêu Tháng 8 · 2026'), findsOneWidget);
      expect(find.text('200.000 ₫'), findsWidgets);
      await tester.tap(find.byKey(const Key('finance-month-close')));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiêu Tháng 8 · 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('stats-month-prev')));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiêu Tháng 7 · 2026'), findsOneWidget);
      expect(find.text('99.999 ₫'), findsWidgets);
      expect(find.text('Đi chợ'), findsNothing);
      expect(find.text('Cafe'), findsWidgets);

      await tester.tap(find.byKey(const Key('nav-home')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Tháng 8 · 2026'), findsOneWidget);

      await _openStats(tester);
      expect(find.text('Chi tiêu Tháng 7 · 2026'), findsOneWidget);
      expect(find.text('99.999 ₫'), findsWidgets);
      expect(find.text('Đi chợ'), findsNothing);

      await tester.tap(find.byKey(const Key('stats-month-next')));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiêu Tháng 8 · 2026'), findsOneWidget);
      expect(find.text('200.000 ₫'), findsWidgets);
      expect(find.text('Đi chợ'), findsWidgets);

      await tester.tap(find.byKey(const Key('stats-month-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('finance-month-cell-2026-7')));
      await tester.tap(find.byKey(const Key('finance-month-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiêu Tháng 7 · 2026'), findsOneWidget);
      expect(find.text('99.999 ₫'), findsWidgets);
      expect(find.text('Đi chợ'), findsNothing);
    },
  );

  testWidgets('payment tab shows a lollipop chart from stored methods', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(seed: _paymentMonth()),
      ),
    );
    await _openStats(tester);
    expect(find.byKey(const Key('pie-total')), findsOneWidget);
    expect(find.text('Chi tiêu theo danh mục'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stats-tab-payments')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pie-total')), findsNothing);
    expect(find.text('Chi tiêu theo danh mục'), findsNothing);
    expect(find.text('Chi tiêu theo phương thức thanh toán'), findsOneWidget);
    expect(find.text('Phương thức chi nhiều nhất'), findsOneWidget);
    expect(find.text('55% tổng chi tiêu'), findsOneWidget);
    expect(find.text('30% tổng chi tiêu'), findsOneWidget);
    expect(find.text('15% tổng chi tiêu'), findsOneWidget);
    expect(find.text('675.400 ₫'), findsWidgets);
    expect(find.text('368.400 ₫'), findsWidgets);
    expect(find.text('184.200 ₫'), findsWidgets);
    expect(find.text('1.228.000 ₫'), findsWidgets);
    expect(find.text('Lương'), findsNothing);
    expect(tester.takeException(), isNull);

    final cash = _markerCenter(tester, 'cash|Tiền mặt|cash');
    final card = _markerCenter(tester, 'card|Thẻ ngân hàng|creditCard');
    final momo = _markerCenter(tester, 'momo|MoMo|eWallet');
    expect(cash, greaterThan(card));
    expect(card, greaterThan(momo));
    final track = tester.getRect(
      find.byKey(const Key('lollipop-cash|Tiền mặt|cash')),
    );
    final marker = tester.getRect(
      find.byKey(const Key('lollipop-marker-cash|Tiền mặt|cash')),
    );
    expect(marker.right, closeTo(track.right, 1.5));

    await tester.tap(find.byKey(const Key('stats-tab-categories')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pie-total')), findsOneWidget);
    expect(find.text('Chi tiêu theo danh mục'), findsOneWidget);
    expect(find.text('Cafe'), findsWidgets);
  });

  testWidgets('category ranks expand to the expenses in that category', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(seed: _paymentMonth()),
      ),
    );
    await _openStats(tester);

    expect(find.byKey(const Key('stats-category-tx-cash')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('stats-category-rank-breakfast')),
    );
    await tester.tap(find.byKey(const Key('stats-category-rank-breakfast')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-category-tx-cash')), findsOneWidget);
    expect(find.byKey(const Key('stats-category-tx-card')), findsNothing);
    expect(find.byKey(const Key('stats-category-tx-income')), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('stats-category-rank-market')),
    );
    await tester.tap(find.byKey(const Key('stats-category-rank-market')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-category-tx-cash')), findsOneWidget);
    expect(find.byKey(const Key('stats-category-tx-card')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('stats-category-rank-breakfast')),
    );
    await tester.tap(find.byKey(const Key('stats-category-rank-breakfast')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-category-tx-cash')), findsNothing);
    expect(find.byKey(const Key('stats-category-tx-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment rows expand independently and follow the month', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(seed: _paymentMonth()),
      ),
    );
    await _openStats(tester);
    await tester.tap(find.byKey(const Key('stats-tab-payments')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats-payment-tx-cash')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('stats-payment-rank-cash|Tiền mặt|cash')),
    );
    await tester.tap(
      find.byKey(const Key('stats-payment-rank-cash|Tiền mặt|cash')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-payment-tx-cash')), findsOneWidget);
    expect(find.byKey(const Key('stats-payment-tx-card')), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('stats-payment-rank-card|Thẻ ngân hàng|creditCard')),
    );
    await tester.tap(
      find.byKey(const Key('stats-payment-rank-card|Thẻ ngân hàng|creditCard')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-payment-tx-cash')), findsOneWidget);
    expect(find.byKey(const Key('stats-payment-tx-card')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('stats-payment-rank-cash|Tiền mặt|cash')),
    );
    await tester.tap(
      find.byKey(const Key('stats-payment-rank-cash|Tiền mặt|cash')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-payment-tx-cash')), findsNothing);
    expect(find.byKey(const Key('stats-payment-tx-card')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('stats-month-prev')));
    await tester.tap(find.byKey(const Key('stats-month-prev')));
    await tester.pumpAndSettle();
    expect(find.text('ZaloPay'), findsWidgets);
    expect(find.text('Tiền mặt'), findsNothing);
    expect(find.text('Quẹt thẻ'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('stats-month-next')));
    await tester.tap(find.byKey(const Key('stats-month-next')));
    await tester.pumpAndSettle();
    expect(find.text('Tiền mặt'), findsWidgets);
    expect(find.byKey(const Key('stats-payment-tx-card')), findsOneWidget);
    expect(find.byKey(const Key('stats-payment-tx-cash')), findsNothing);
  });

  testWidgets('blank and zero payment methods stay out of cash', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: 'blank',
              amount: 12000,
              date: DateTime(2026, 8, 2),
              paymentSourceId: ' ',
              paymentSourceName: ' ',
              paymentMethod: PaymentMethodKind.cash,
            ),
            _tx(
              id: 'zero',
              amount: 0,
              date: DateTime(2026, 8, 3),
              paymentSourceId: 'empty',
              paymentSourceName: 'Ví trống',
              paymentMethod: PaymentMethodKind.eWallet,
            ),
            _tx(
              id: 'cash',
              amount: 8000,
              date: DateTime(2026, 8, 4),
              paymentSourceId: 'cash',
              paymentSourceName: 'Tiền mặt',
              paymentMethod: PaymentMethodKind.cash,
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);
    await tester.tap(find.byKey(const Key('stats-tab-payments')));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có phương thức'), findsWidgets);
    expect(find.text('Ví trống'), findsWidgets);
    expect(find.text('Tiền mặt'), findsWidgets);
    expect(find.text('0% tổng chi tiêu'), findsOneWidget);
    expect(find.text('0 ₫'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment chart fits a narrow phone width', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loaded = await StatisticsQuery(
      TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: 'long',
              amount: 150000,
              date: DateTime(2026, 8, 2),
              paymentSourceId: 'long',
              paymentSourceName: 'Thẻ tín dụng quốc tế dùng cho công tác',
              paymentMethod: PaymentMethodKind.creditCard,
            ),
          ],
        ),
      ),
      clock: () => DateTime(2026, 8, 18),
    ).load();
    final snapshot = (loaded as Ok<StatisticsSnapshot>).value;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              StatisticsPaymentSection(
                snapshot: snapshot,
                expandedKeys: const {},
                onToggle: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Thẻ tín dụng quốc tế'), findsWidgets);
    expect(find.text('150.000 ₫'), findsWidgets);
    expect(tester.takeException(), isNull);
    final chart = tester.getRect(find.byKey(const Key('stats-payment-chart')));
    expect(chart.left, greaterThanOrEqualTo(0));
    expect(chart.right, lessThanOrEqualTo(320));
  });
}

List<Transaction> _paymentMonth() {
  return [
    _tx(
      id: 'cash',
      amount: 675400,
      date: DateTime(2026, 8, 2),
      category: 'breakfast',
      paymentSourceId: 'cash',
      paymentSourceName: 'Tiền mặt',
      paymentMethod: PaymentMethodKind.cash,
      note: 'Ăn sáng',
    ),
    _tx(
      id: 'card',
      amount: 368400,
      date: DateTime(2026, 8, 3),
      category: 'market',
      paymentSourceId: 'card',
      paymentSourceName: 'Thẻ ngân hàng',
      paymentMethod: PaymentMethodKind.creditCard,
      note: 'Quẹt thẻ',
    ),
    _tx(
      id: 'momo',
      amount: 184200,
      date: DateTime(2026, 8, 4),
      category: 'cafe',
      note: 'Trà sữa',
    ),
    _tx(
      id: 'income',
      amount: 900000,
      date: DateTime(2026, 8, 5),
      type: TransactionType.income,
      paymentSourceId: 'salary',
      paymentSourceName: 'Lương',
      paymentMethod: PaymentMethodKind.bankAccount,
    ),
    _tx(
      id: 'july',
      amount: 50000,
      date: DateTime(2026, 7, 8),
      paymentSourceId: 'zalo',
      paymentSourceName: 'ZaloPay',
      paymentMethod: PaymentMethodKind.eWallet,
    ),
  ];
}

double _markerCenter(WidgetTester tester, String token) {
  return tester.getRect(find.byKey(Key('lollipop-marker-$token'))).center.dx;
}
