import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/home/home_page.dart';

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

    expect(find.text('Chi tiêu tháng này'), findsOneWidget);
    expect(find.text('0 ₫'), findsOneWidget);
    expect(find.text('Gần đây'), findsOneWidget);
    expect(find.text('Chưa có giao dịch. Nhấn + để thêm.'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Lương'), findsNothing);
    expect(find.text('Ngân sách'), findsNothing);
    expect(find.text('Mục tiêu tiết kiệm'), findsNothing);
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
    expect(find.text('Highlands'), findsOneWidget);
    expect(find.textContaining('Cafe'), findsOneWidget);
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
    expect(find.text('Gần đây'), findsNothing);
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
}
