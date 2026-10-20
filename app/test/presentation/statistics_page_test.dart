import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/theme/app_colors.dart';

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
  String? note,
  String? occurredTime,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.utc(2026, 8, 1);
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: category,
    detail: null,
    occurredOn: date,
    occurredTime: occurredTime,
    note: note,
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

  testWidgets('top category expands, collapses, and keeps a single open row', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: 'cafe-new',
              amount: 80000,
              date: DateTime(2026, 8, 10),
              note: 'Cà phê sữa',
            ),
            _tx(
              id: 'cafe-old',
              amount: 20000,
              date: DateTime(2026, 8, 2),
              note: 'Bánh mì',
            ),
            _tx(
              id: 'market-1',
              amount: 150000,
              date: DateTime(2026, 8, 8),
              category: 'market',
              note: 'Đi chợ cuối tuần',
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsWidgets);
    expect(find.text('5 giao dịch gần nhất'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('stats-top-cafe')));
    await tester.tap(find.byKey(const Key('stats-top-cafe')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats-top-preview-cafe')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('stats-top-cluster-cafe')),
        matching: find.byKey(const Key('stats-top-preview-cafe')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('stats-top-preview-cafe')),
        matching: find.byType(Card),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<Divider>(
            find.descendant(
              of: find.byKey(const Key('stats-top-preview-cafe')),
              matching: find.byType(Divider),
            ),
          )
          .color,
      AppColors.divider,
    );
    expect(find.text('5 giao dịch gần nhất'), findsOneWidget);
    expect(find.byKey(const Key('stats-top-see-all-cafe')), findsOneWidget);
    expect(find.text('Cà phê sữa'), findsOneWidget);
    expect(find.text('Bánh mì'), findsOneWidget);
    expect(find.text('10/08'), findsOneWidget);
    expect(find.text('Đi chợ cuối tuần'), findsNothing);
    expect(
      tester.widget<Icon>(find.byKey(const Key('stats-top-chevron-cafe'))).icon,
      Icons.keyboard_arrow_up_rounded,
    );
    expect(find.byKey(const Key('nav-statistics')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stats-top-cafe')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-top-preview-cafe')), findsNothing);
    expect(find.text('Cà phê sữa'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('stats-top-cafe')));
    await tester.tap(find.byKey(const Key('stats-top-cafe')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('stats-top-market')));
    await tester.tap(find.byKey(const Key('stats-top-market')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-top-preview-cafe')), findsNothing);
    expect(find.byKey(const Key('stats-top-preview-market')), findsOneWidget);
    expect(find.text('Đi chợ cuối tuần'), findsOneWidget);
    expect(find.text('Cà phê sữa'), findsNothing);
  });

  testWidgets(
    'expanded category lists only that month, newest first, max five',
    (tester) async {
      _phone(tester);
      await _pumpShell(
        tester,
        service: TransactionService(
          MemoryTransactionRepository(
            seed: [
              for (var day = 1; day <= 6; day++)
                _tx(
                  id: 'd$day',
                  amount: day * 1000,
                  date: DateTime(2026, 8, day),
                  note: 'Ngày $day',
                  createdAt: DateTime.utc(2026, 8, day),
                ),
              _tx(
                id: 'same-early',
                amount: 11000,
                date: DateTime(2026, 8, 6),
                note: 'Sáng',
                occurredTime: '08:00',
                createdAt: DateTime.utc(2026, 8, 6, 8),
              ),
              _tx(
                id: 'income',
                amount: 900000,
                date: DateTime(2026, 8, 6),
                type: TransactionType.income,
                note: 'Lương tháng',
              ),
              _tx(
                id: 'july',
                amount: 7000,
                date: DateTime(2026, 7, 20),
                note: 'Tháng bảy',
              ),
              _tx(
                id: 'market',
                amount: 4000,
                date: DateTime(2026, 8, 6),
                category: 'market',
                note: 'Rau củ',
              ),
            ],
          ),
        ),
      );
      await _openStats(tester);
      await tester.ensureVisible(find.byKey(const Key('stats-top-cafe')));
      await tester.tap(find.byKey(const Key('stats-top-cafe')));
      await tester.pumpAndSettle();

      expect(find.text('Ngày 1'), findsNothing);
      expect(find.text('Lương tháng'), findsNothing);
      expect(find.text('Tháng bảy'), findsNothing);
      expect(find.text('Rau củ'), findsNothing);
      expect(find.byKey(const Key('stats-top-tx-d1')), findsNothing);
      final titles = ['Sáng', 'Ngày 6', 'Ngày 5', 'Ngày 4', 'Ngày 3'];
      for (final title in titles) {
        expect(find.text(title), findsOneWidget);
      }
      final sangY = tester.getTopLeft(find.text('Sáng')).dy;
      final day6Y = tester.getTopLeft(find.text('Ngày 6')).dy;
      final day3Y = tester.getTopLeft(find.text('Ngày 3')).dy;
      expect(sangY, lessThan(day6Y));
      expect(day6Y, lessThan(day3Y));
    },
  );

  testWidgets('changing month closes the preview and drops the old rows', (
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
              amount: 50000,
              date: DateTime(2026, 8, 7),
              note: 'Cafe tháng tám',
            ),
            _tx(
              id: 'jul',
              amount: 30000,
              date: DateTime(2026, 7, 7),
              note: 'Cafe tháng bảy',
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);
    await tester.ensureVisible(find.byKey(const Key('stats-top-cafe')));
    await tester.tap(find.byKey(const Key('stats-top-cafe')));
    await tester.pumpAndSettle();
    expect(find.text('Cafe tháng tám'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stats-month-prev')));
    await tester.pumpAndSettle();
    expect(find.text('Cafe tháng tám'), findsNothing);
    expect(find.byKey(const Key('stats-top-preview-cafe')), findsNothing);
    expect(find.text('Chi tiêu Tháng 7 · 2026'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('stats-top-cafe')));
    await tester.tap(find.byKey(const Key('stats-top-cafe')));
    await tester.pumpAndSettle();
    expect(find.text('Cafe tháng bảy'), findsOneWidget);
    expect(find.text('Cafe tháng tám'), findsNothing);
  });

  testWidgets('empty and failed category queries stay inside the card', (
    tester,
  ) async {
    _phone(tester);
    final repo = MemoryTransactionRepository(
      seed: [
        _tx(
          id: '1',
          amount: 25000,
          date: DateTime(2026, 8, 4),
          note: 'Ly cafe',
        ),
      ],
    );
    await _pumpShell(tester, service: TransactionService(repo));
    await _openStats(tester);
    await repo.delete('1');
    await tester.ensureVisible(find.byKey(const Key('stats-top-cafe')));
    await tester.tap(find.byKey(const Key('stats-top-cafe')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-top-empty-cafe')), findsOneWidget);
    expect(find.text('Ly cafe'), findsNothing);
  });

  testWidgets('a failed category query shows the error inside the card', (
    tester,
  ) async {
    _phone(tester);
    final repo = MemoryTransactionRepository(
      seed: [
        _tx(
          id: '1',
          amount: 25000,
          date: DateTime(2026, 8, 4),
          note: 'Ly cafe',
        ),
      ],
    );
    await _pumpShell(tester, service: TransactionService(repo));
    await _openStats(tester);
    repo.failQuery = true;
    await tester.ensureVisible(find.byKey(const Key('stats-top-cafe')));
    await tester.tap(find.byKey(const Key('stats-top-cafe')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-top-error-cafe')), findsOneWidget);
    expect(find.text('read failed'), findsOneWidget);
    expect(find.text('Ly cafe'), findsNothing);
  });

  testWidgets('long transaction title and large amount do not overflow', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: 'long',
              amount: 999999999,
              date: DateTime(2026, 8, 9),
              note: 'Mua đồ dùng gia đình cho cả tháng và thêm vài món rất dài',
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);
    await tester.ensureVisible(find.byKey(const Key('stats-top-cafe')));
    await tester.tap(find.byKey(const Key('stats-top-cafe')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('stats-top-tx-long')), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('stats-top-tx-long')),
              matching: find.textContaining('Mua đồ dùng'),
            ),
          )
          .overflow,
      TextOverflow.ellipsis,
    );
  });

  testWidgets('see all opens transactions for the category and month', (
    tester,
  ) async {
    _phone(tester);
    await _pumpShell(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(
          seed: [
            _tx(
              id: 'cafe-1',
              amount: 45000,
              date: DateTime(2026, 8, 6),
              note: 'Cà phê đá',
            ),
            _tx(
              id: 'market-1',
              amount: 120000,
              date: DateTime(2026, 8, 6),
              category: 'market',
              note: 'Thịt cá',
            ),
            _tx(
              id: 'july',
              amount: 10000,
              date: DateTime(2026, 7, 6),
              note: 'Cafe tháng trước',
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);
    await tester.ensureVisible(find.byKey(const Key('stats-top-cafe')));
    await tester.tap(find.byKey(const Key('stats-top-cafe')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('stats-top-see-all-cafe')));
    await tester.tap(find.byKey(const Key('stats-top-see-all-cafe')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('month-label')), findsOneWidget);
    expect(find.text('Tháng 08/2026'), findsOneWidget);
    expect(find.text('Cà phê đá'), findsOneWidget);
    expect(find.text('Thịt cá'), findsNothing);
    expect(find.text('Cafe tháng trước'), findsNothing);
    expect(
      tester
          .widget<Material>(
            find.descendant(
              of: find.byKey(const Key('cat-cafe')),
              matching: find.byType(Material),
            ),
          )
          .color,
      AppColors.primary,
    );
  });

  testWidgets('million amounts in the ranking share one column width', (
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
              amount: 2265000,
              date: DateTime(2026, 8, 3),
              category: 'other',
            ),
            _tx(
              id: '2',
              amount: 1681000,
              date: DateTime(2026, 8, 4),
              category: 'shopping',
            ),
            _tx(
              id: '3',
              amount: 1455000,
              date: DateTime(2026, 8, 5),
              category: 'bills',
            ),
          ],
        ),
      ),
    );
    await _openStats(tester);
    final other = tester.getRect(
      find.byKey(const Key('stats-top-amount-other')),
    );
    final shopping = tester.getRect(
      find.byKey(const Key('stats-top-amount-shopping')),
    );
    final bills = tester.getRect(
      find.byKey(const Key('stats-top-amount-bills')),
    );
    expect(shopping.width, other.width);
    expect(bills.width, other.width);
    expect(shopping.right, other.right);
    expect(bills.right, other.right);
  });
}
