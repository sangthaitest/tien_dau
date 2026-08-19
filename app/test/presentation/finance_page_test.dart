import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/finance.dart';
import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';

import '../support/memory_transaction_repository.dart';
import '../support/shell_harness.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding.zero;
  tester.view.padding = FakeViewPadding.zero;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.view.resetPadding);
}

Future<void> _submitPin(WidgetTester tester, String pin) async {
  await tester.enterText(find.byKey(const Key('input-finance-pin')), pin);
  tester.view.viewInsets = FakeViewPadding.zero;
  await tester.pump();
  final button = tester.widget<FilledButton>(find.byKey(const Key('btn-submit-pin')));
  button.onPressed!.call();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() {
  });

  testWidgets('Home does not show salary budget or savings', (tester) async {
    _phone(tester);
    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)));
    await tester.pumpWidget(
      MaterialApp(
        home: buildShell(transactions: service, home: home, clock: () => DateTime(2026, 8, 18, 9)).shell,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Lương'), findsNothing);
    expect(find.text('Ngân sách tháng'), findsNothing);
    expect(find.text('Mục tiêu tiết kiệm'), findsNothing);
  });

  testWidgets('Settings → PIN setup → Tài chính', (tester) async {
    _phone(tester);
    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)));
    await tester.pumpWidget(
      MaterialApp(
        home: buildShell(transactions: service, home: home, clock: () => DateTime(2026, 8, 18, 9)).shell,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    expect(find.text('Cài đặt'), findsWidgets);
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Tạo mật khẩu'), findsWidgets);
    await _submitPin(tester, '5820');
    expect(find.text('Tài chính'), findsOneWidget);
    expect(find.text('Lương'), findsOneWidget);
    expect(find.text('Ngân sách tháng'), findsOneWidget);
    expect(find.text('Mục tiêu tiết kiệm'), findsOneWidget);
  });

  testWidgets('wrong PIN stays locked', (tester) async {
    _phone(tester);
    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)));
    final harness = buildShell(transactions: service, home: home, clock: () => DateTime(2026, 8, 18, 9));
    await harness.access.setupPin('5820');
    await harness.access.lock();
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await _submitPin(tester, '1234');
    expect(find.text('Mật khẩu không đúng'), findsOneWidget);
    expect(find.text('Ngân sách tháng'), findsNothing);
  });

  testWidgets('goal form scrolls above the keyboard on small Android screens', (tester) async {
    _phone(tester);
    tester.view.physicalSize = const Size(360, 640);
    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)));
    final harness = buildShell(transactions: service, home: home, clock: () => DateTime(2026, 8, 18, 9));
    await harness.access.setupPin('5820');
    await harness.access.unlock('5820');
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('btn-create-goal')));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.tap(find.byKey(const Key('goal-name-input')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('goal-name-input')), 'Quỹ dự phòng');
    await tester.ensureVisible(find.byKey(const Key('goal-save')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('goal-save')), findsOneWidget);
  });

  testWidgets('monthly budget shows a negative remainder when overspent', (tester) async {
    _phone(tester);
    final transactions = TransactionService(MemoryTransactionRepository());
    await transactions.add(
      NewTransaction(
        amount: 120000,
        type: TransactionType.expense,
        categoryId: 'market',
        occurredOn: DateTime(2026, 8, 18),
        paymentSourceId: 'cash',
        paymentSourceName: 'Tiền mặt',
        paymentMethod: PaymentMethodKind.cash,
      ),
    );
    final home = HomeController(HomeQuery(transactions, clock: () => DateTime(2026, 8, 18, 9)));
    final harness = buildShell(
      transactions: transactions,
      home: home,
      clock: () => DateTime(2026, 8, 18, 9),
    );
    harness.finance.budget = const MonthlyBudget(monthKey: '2026-08', totalLimit: 100000);
    await harness.access.setupPin('5820');
    await harness.access.unlock('5820');
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('100.000 ₫'), findsOneWidget);
    expect(find.text('120.000 ₫'), findsOneWidget);
    expect(find.text('−20.000 ₫'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
