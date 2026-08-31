import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/home/home_page.dart';
import 'package:tien_day/presentation/home/widgets/home_transaction_tile.dart';
import 'package:tien_day/presentation/theme/app_colors.dart';

import '../support/memory_transaction_catalog_repository.dart';
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
  String? detail,
}) {
  final now = DateTime.utc(2026, 8, 18);
  return Transaction(
    id: id,
    amount: amount,
    type: TransactionType.expense,
    categoryId: 'cafe',
    detail: detail,
    occurredOn: date,
    paymentSourceId: 'momo',
    paymentSourceName: 'MoMo',
    paymentMethod: PaymentMethodKind.eWallet,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {});

  testWidgets('Home shows monthly spend, empty recent copy, and + control', (
    tester,
  ) async {
    _phone(tester);

    final service = TransactionService(MemoryTransactionRepository());
    final controller = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          controller: controller,
          transactionService: service,
          catalogController: buildTestCatalogController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tháng này tiền đi đâu rồi?'), findsOneWidget);
    expect(find.text('0 ₫'), findsOneWidget);
    expect(find.text('Đây nè'), findsOneWidget);
    expect(find.text('Xem tất cả'), findsOneWidget);
    expect(
      find.text('Hiện tại tiền chưa đi đâu cả. Nhấn + để thêm nhé!'),
      findsOneWidget,
    );
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.byKey(const Key('fab-add')), findsOneWidget);
    expect(find.text('Lương'), findsNothing);
    expect(find.text('Ngân sách'), findsNothing);
    expect(find.text('Mục tiêu tiết kiệm'), findsNothing);

    final calendar = tester.widget<Icon>(
      find.byKey(const Key('home-month-calendar-icon')),
    );
    expect(calendar.color, AppColors.yellow);
    final month = tester.widget<Text>(find.text('Tháng 8 · 2026'));
    expect(month.style?.color, AppColors.primary);
    final spend = tester.widget<Text>(
      find.byKey(const Key('home-month-spend')),
    );
    expect(spend.data, '0 ₫');
    expect(spend.style?.color, Colors.white);
    expect(spend.data, isNot(contains('−')));
  });

  testWidgets('Home lists a recent expense from the repository', (
    tester,
  ) async {
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
    final controller = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          controller: controller,
          transactionService: service,
          catalogController: buildTestCatalogController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('45.000 ₫'), findsWidgets);
    expect(find.text('−45.000 ₫'), findsNothing);
    expect(find.text('Highlands'), findsOneWidget);
    expect(find.textContaining('Cafe'), findsOneWidget);

    final amount = tester
        .widgetList<Text>(find.text('45.000 ₫'))
        .firstWhere((text) => text.key != const Key('home-month-spend'));
    expect(amount.style?.color, AppColors.text);
    final amountRect = tester.getRect(find.byWidget(amount));
    final tileRect = tester.getRect(find.byKey(const Key('tx-tile-1')));
    expect(tileRect.right - amountRect.right, closeTo(16, 1));
  });

  testWidgets('Home load error does not fake a zero monthly total', (
    tester,
  ) async {
    _phone(tester);
    final service = TransactionService(
      MemoryTransactionRepository(failList: true),
    );
    final controller = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          controller: controller,
          transactionService: service,
          catalogController: buildTestCatalogController(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-error')), findsOneWidget);
    expect(find.text('0 ₫'), findsNothing);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('avatar opens Settings', (tester) async {
    _phone(tester);
    final service = TransactionService(MemoryTransactionRepository());
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
    await tester.tap(find.byKey(const Key('btn-avatar')));
    await tester.pump();
    expect(find.text('Cài đặt'), findsWidgets);
    expect(find.text('Đây nè'), findsNothing);
  });

  testWidgets('month chip switches Home spend to the selected month', (
    tester,
  ) async {
    _phone(tester);
    final service = TransactionService(
      MemoryTransactionRepository(
        seed: [
          _tx(id: 'aug', amount: 45000, date: DateTime(2026, 8, 7)),
          _tx(id: 'jul', amount: 12000, date: DateTime(2026, 7, 20)),
        ],
      ),
    );
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
    expect(find.text('45.000 ₫'), findsWidgets);
    expect(find.text('12.000 ₫'), findsNothing);

    await tester.tap(find.byKey(const Key('home-month-chip')));
    await tester.pumpAndSettle();
    expect(find.text('Chọn tháng'), findsOneWidget);
    await tester.tap(find.byKey(const Key('month-pick-2026-07')));
    await tester.pumpAndSettle();

    expect(find.text('Tháng 7 · 2026'), findsOneWidget);
    expect(find.text('12.000 ₫'), findsWidgets);
    expect(find.text('45.000 ₫'), findsNothing);
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    required int count,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seed = [
      for (var i = 0; i < count; i++)
        _tx(
          id: '${i + 1}',
          amount: (i + 1) * 1000,
          date: DateTime(2026, 8, 18 - i),
          detail: 'Tx ${i + 1}',
        ),
    ];
    final service = TransactionService(MemoryTransactionRepository(seed: seed));
    final controller = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          controller: controller,
          transactionService: service,
          catalogController: buildTestCatalogController(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Home shows 1 recent transaction', (tester) async {
    await pumpHome(tester, count: 1);
    expect(find.byType(HomeTransactionTile), findsOneWidget);
    expect(find.text('Xem tất cả'), findsOneWidget);
  });

  testWidgets('Home shows 3 recent transactions', (tester) async {
    await pumpHome(tester, count: 3);
    expect(find.byType(HomeTransactionTile), findsNWidgets(3));
  });

  testWidgets('Home shows 4 recent transactions', (tester) async {
    await pumpHome(tester, count: 4);
    expect(find.byType(HomeTransactionTile), findsNWidgets(4));
  });

  testWidgets('Home shows 5 recent transactions', (tester) async {
    await pumpHome(tester, count: 5);
    expect(find.byType(HomeTransactionTile), findsNWidgets(5));
  });

  testWidgets('Home shows at most 5 of 10 recent transactions', (tester) async {
    await pumpHome(tester, count: 10);
    expect(find.byType(HomeTransactionTile), findsNWidgets(5));
    expect(find.text('Xem tất cả'), findsOneWidget);
  });

  testWidgets(
    'short Home keeps 5 recent rows and scrolls instead of clipping',
    (tester) async {
      await pumpHome(tester, count: 10, size: const Size(390, 640));
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeTransactionTile), findsNWidgets(5));
      expect(find.byKey(const Key('fab-add')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('nav-home'))).dy,
        lessThan(640),
      );
    },
  );
}
