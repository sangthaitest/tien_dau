import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/finance.dart';
import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/finance/finance_page.dart';
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
    expect(find.text('Khoản sắp trả'), findsNothing);
    expect(find.text('Khoản định kỳ'), findsNothing);
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
    expect(find.text('Lương · Tháng 8/2026'), findsOneWidget);
    expect(find.text('Ngân sách tháng'), findsOneWidget);
    expect(find.text('Khoản định kỳ'), findsOneWidget);
    expect(find.text('Thẻ tín dụng'), findsOneWidget);
    expect(find.text('Chuyển cho Minh'), findsOneWidget);
    expect(find.text('Điện nước'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mục tiêu tiết kiệm'),
      80,
      scrollable: find.descendant(
        of: find.byType(FinancePage),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Mục tiêu tiết kiệm'), findsOneWidget);
    expect(find.text('Quản lý →'), findsWidgets);
    expect(find.text('+ Tạo mới'), findsNothing);
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
    tester.view.physicalSize = const Size(390, 640);
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('btn-create-goal')),
      80,
      scrollable: find.descendant(
        of: find.byType(FinancePage),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('btn-create-goal')));
    await tester.pumpAndSettle();
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
    final bar = tester.getRect(find.byType(LinearProgressIndicator));
    expect(tester.getRect(find.textContaining('Đã dùng')).left, closeTo(bar.left, 1));
    expect(tester.getRect(find.textContaining('Còn lại ·')).right, closeTo(bar.right, 1));
    expect(tester.getRect(find.text('−20.000 ₫')).right, closeTo(bar.right, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('goal amount fields group digits while typing', (tester) async {
    _phone(tester);
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('btn-create-goal')),
      80,
      scrollable: find.descendant(
        of: find.byType(FinancePage),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('btn-create-goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-create-goal')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goal-target-input')), '1500000');
    await tester.pump();
    expect(find.text('1.500.000'), findsOneWidget);
  });

  testWidgets('upcoming payments demo sheet and detail stay in memory', (
    tester,
  ) async {
    _phone(tester);
    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    final harness = buildShell(
      transactions: service,
      home: home,
      clock: () => DateTime(2026, 8, 18, 9),
    );
    await harness.access.setupPin('5820');
    await harness.access.unlock('5820');
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('finance-upcoming-section')), findsOneWidget);
    expect(find.text('5.000.000 ₫'), findsWidgets);
    expect(find.text('Ngày 25/08'), findsOneWidget);
    expect(find.text('Ngày 28/08'), findsOneWidget);
    expect(find.text('Ngày 30/08'), findsOneWidget);
    expect(find.text('Tổng định kỳ'), findsOneWidget);
    expect(find.text('3 khoản'), findsOneWidget);
    expect(find.text('Còn lại dự kiến'), findsOneWidget);
    expect(find.byKey(const Key('finance-upcoming-total')), findsOneWidget);
    expect(find.text('7.500.000 ₫'), findsWidgets);
    expect(find.byKey(const Key('finance-upcoming-expected')), findsOneWidget);
    expect(find.text('7.873.843 ₫'), findsOneWidget);
    expect(find.text('Sau khi trừ khoản đã dùng\nvà khoản định kỳ'), findsOneWidget);
    expect(find.text('Ngân sách tháng'), findsOneWidget);
    expect(find.text('+ Tạo mới'), findsNothing);

    double rightEdge(Finder finder) => tester.getRect(finder).right;
    final amountRights = [
      rightEdge(
        find.descendant(
          of: find.byKey(const Key('finance-upcoming-row-card')),
          matching: find.text('5.000.000 ₫'),
        ),
      ),
      rightEdge(
        find.descendant(
          of: find.byKey(const Key('finance-upcoming-row-transfer')),
          matching: find.text('2.000.000 ₫'),
        ),
      ),
      rightEdge(
        find.descendant(
          of: find.byKey(const Key('finance-upcoming-row-utility')),
          matching: find.text('500.000 ₫'),
        ),
      ),
      rightEdge(find.byKey(const Key('finance-upcoming-total'))),
      rightEdge(find.byKey(const Key('finance-upcoming-expected'))),
    ];
    for (final right in amountRights.skip(1)) {
      expect(right, closeTo(amountRights.first, 0.5));
    }
    expect(
      rightEdge(find.byKey(const Key('salary-amount'))),
      isNot(closeTo(amountRights.first, 0.5)),
    );

    await tester.ensureVisible(find.byKey(const Key('finance-upcoming-row-card')));
    await tester.tap(find.byKey(const Key('finance-upcoming-row-card')));
    await tester.pumpAndSettle();
    expect(find.text('Trạng thái: Chưa thanh toán'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finance-upcoming-mark-paid')));
    await tester.pumpAndSettle();
    expect(find.text('Đã thanh toán'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ngân sách tháng'),
      -80,
      scrollable: find.descendant(
        of: find.byType(FinancePage),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Ngân sách tháng'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mục tiêu tiết kiệm'),
      80,
      scrollable: find.descendant(
        of: find.byType(FinancePage),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Mục tiêu tiết kiệm'), findsOneWidget);
  });

  testWidgets('upcoming payments can be created edited and deleted in memory', (
    tester,
  ) async {
    _phone(tester);
    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    final harness = buildShell(
      transactions: service,
      home: home,
      clock: () => DateTime(2026, 8, 18, 9),
    );
    await harness.access.setupPin('5820');
    await harness.access.unlock('5820');
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.ensureVisible(find.byKey(const Key('finance-upcoming-manage')));
    await tester.tap(find.byKey(const Key('finance-upcoming-manage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finance-upcoming-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('upcoming-name-input')), 'Wifi');
    await tester.enterText(find.byKey(const Key('upcoming-amount-input')), '1000000');
    await tester.enterText(find.byKey(const Key('upcoming-due-input')), '31/08');
    await tester.tap(find.byKey(const Key('upcoming-save')));
    await tester.pumpAndSettle();
    expect(find.text('Wifi'), findsWidgets);

    await tester.tap(find.byKey(const Key('finance-upcoming-edit-card')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('upcoming-name-input')),
      'Thẻ Visa',
    );
    await tester.tap(find.byKey(const Key('upcoming-save')));
    await tester.pumpAndSettle();
    expect(find.text('Thẻ Visa'), findsWidgets);
    expect(find.text('Thẻ tín dụng'), findsNothing);

    await tester.tap(find.byKey(const Key('finance-upcoming-delete-utility')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finance-upcoming-confirm-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Điện nước'), findsNothing);
    expect(find.text('Thẻ Visa'), findsWidgets);
    expect(find.text('Wifi'), findsWidgets);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ngân sách tháng'),
      -80,
      scrollable: find.descendant(
        of: find.byType(FinancePage),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Ngân sách tháng'), findsOneWidget);
    expect(find.byKey(const Key('finance-upcoming-section')), findsOneWidget);
  });
}
