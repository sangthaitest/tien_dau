import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/finance.dart';
import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/recurring_transaction.dart';
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
  final button = tester.widget<FilledButton>(
    find.byKey(const Key('btn-submit-pin')),
  );
  button.onPressed!.call();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pickDueDay(WidgetTester tester, int day) async {
  await tester.tap(find.byKey(const Key('upcoming-due-input')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text('$day'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {});

  testWidgets('Home does not show salary budget or savings', (tester) async {
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
    expect(find.text('Lương'), findsNothing);
    expect(find.text('Thu nhập'), findsNothing);
    expect(find.text('Ngân sách tháng'), findsNothing);
    expect(find.text('Mục tiêu tiết kiệm'), findsNothing);
    expect(find.text('Khoản sắp trả'), findsNothing);
    expect(find.text('Khoản định kỳ'), findsNothing);
  });

  testWidgets('Settings → PIN setup → Tài chính', (tester) async {
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
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    expect(find.text('Cài đặt'), findsWidgets);
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Tạo mật khẩu'), findsWidgets);
    await _submitPin(tester, '5820');
    expect(find.text('Tài chính'), findsOneWidget);
    expect(find.text('Thu nhập'), findsOneWidget);
    expect(find.text('Tháng 8/2026'), findsOneWidget);
    expect(find.text('Lương · Tháng 8/2026'), findsNothing);
    expect(find.byKey(const Key('btn-edit-salary')), findsNothing);
    expect(find.byKey(const Key('btn-edit-budget')), findsNothing);
    expect(find.text('Sửa'), findsNothing);
    expect(find.text('Ngân sách tháng'), findsNothing);
    expect(find.text('Tiền có thể chi'), findsOneWidget);
    expect(find.text('Đã chi tiêu'), findsOneWidget);
    expect(find.text('Còn lại'), findsOneWidget);
    expect(find.text('Trừ khoản định kỳ'), findsOneWidget);
    expect(find.text('Trừ chi tiêu'), findsOneWidget);
    expect(find.text('Khoản định kỳ'), findsOneWidget);
    expect(find.textContaining('Chưa có khoản định kỳ'), findsOneWidget);
    expect(find.text('Thẻ tín dụng'), findsNothing);
    expect(find.text('Chuyển cho Minh'), findsNothing);
    expect(find.text('Điện nước'), findsNothing);
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
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    final harness = buildShell(
      transactions: service,
      home: home,
      clock: () => DateTime(2026, 8, 18, 9),
    );
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

  testWidgets('goal form scrolls above the keyboard on small Android screens', (
    tester,
  ) async {
    _phone(tester);
    tester.view.physicalSize = const Size(390, 640);
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
    await tester.enterText(
      find.byKey(const Key('goal-name-input')),
      'Quỹ dự phòng',
    );
    await tester.ensureVisible(find.byKey(const Key('goal-save')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('goal-save')), findsOneWidget);
  });

  testWidgets(
    'finance cash flow shows spendable and remaining without budget',
    (tester) async {
      _phone(tester);
      final transactions = TransactionService(MemoryTransactionRepository());
      await transactions.add(
        NewTransaction(
          amount: 6619557,
          type: TransactionType.expense,
          categoryId: 'market',
          occurredOn: DateTime(2026, 8, 18),
          paymentSourceId: 'cash',
          paymentSourceName: 'Tiền mặt',
          paymentMethod: PaymentMethodKind.cash,
        ),
      );
      final home = HomeController(
        HomeQuery(transactions, clock: () => DateTime(2026, 8, 18, 9)),
      );
      final harness = buildShell(
        transactions: transactions,
        home: home,
        clock: () => DateTime(2026, 8, 18, 9),
      );
      final now = DateTime.utc(2026, 8, 18);
      expect(
        (await harness.finance.saveSalary(
          const MonthlySalary(amount: 22500000),
        )).isOk,
        isTrue,
      );
      expect(
        (await harness.recurring.create(
          RecurringTransaction(
            id: 'vk',
            name: 'Lương VK',
            kind: RecurringKind.expense,
            amount: 15000000,
            frequency: RecurringFrequency.monthly,
            intervalCount: 1,
            direction: RecurringDirection.subtract,
            categoryId: 'transfer',
            startDate: DateTime(2026, 8, 27),
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        )).isOk,
        isTrue,
      );
      await harness.access.setupPin('5820');
      await harness.access.unlock('5820');
      await tester.pumpWidget(MaterialApp(home: harness.shell));
      await tester.pump();
      await tester.tap(find.byKey(const Key('nav-settings')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('settings-finance')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Ngân sách tháng'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byKey(const Key('btn-edit-budget')), findsNothing);
      expect(find.text('22.500.000 ₫'), findsWidgets);
      expect(find.text('15.000.000 ₫'), findsWidgets);
      expect(find.text('7.500.000 ₫'), findsOneWidget);
      expect(find.text('6.619.557 ₫'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('finance-remaining-amount')),
        80,
        scrollable: find.descendant(
          of: find.byType(FinancePage),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('880.443 ₫'), findsOneWidget);
      expect(find.text('Tiền có thể chi'), findsOneWidget);
      expect(find.text('Đã chi tiêu'), findsOneWidget);
      expect(find.text('Còn lại'), findsOneWidget);
      expect(find.text('Còn lại dự kiến'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('goal amount fields group digits while typing', (tester) async {
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
    await tester.enterText(
      find.byKey(const Key('goal-target-input')),
      '1500000',
    );
    await tester.pump();
    expect(find.text('1.500.000'), findsOneWidget);
  });

  testWidgets('recurring list loads from repository and empty state appears', (
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
    expect(find.textContaining('Chưa có khoản định kỳ'), findsOneWidget);
    expect(find.text('Thẻ tín dụng'), findsNothing);
    expect(find.text('Còn lại dự kiến'), findsNothing);
    expect(find.byKey(const Key('finance-upcoming-expected')), findsNothing);
    expect(find.text('Còn lại'), findsOneWidget);
    expect(find.byKey(const Key('finance-remaining-amount')), findsOneWidget);
  });

  testWidgets('seeded recurring rule appears on Finance from the repository', (
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
    final now = DateTime.utc(2026, 8, 18);
    expect(
      (await harness.recurring.create(
        RecurringTransaction(
          id: 'card',
          name: 'Thẻ tín dụng',
          kind: RecurringKind.expense,
          amount: 5000000,
          frequency: RecurringFrequency.monthly,
          intervalCount: 1,
          direction: RecurringDirection.subtract,
          categoryId: 'bills',
          startDate: DateTime(2026, 8, 25),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      )).isOk,
      isTrue,
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

    expect(find.text('Thẻ tín dụng'), findsOneWidget);
    expect(find.text('Ngày 25/08'), findsOneWidget);
    expect(find.text('5.000.000 ₫'), findsWidgets);
    expect(find.text('Tổng định kỳ'), findsOneWidget);
    expect(find.textContaining('Chưa có khoản định kỳ'), findsNothing);
  });

  testWidgets('recurring add edit delete persist in the repository', (
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

    await tester.ensureVisible(
      find.byKey(const Key('finance-upcoming-manage')),
    );
    await tester.tap(find.byKey(const Key('finance-upcoming-manage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finance-upcoming-add')));
    await tester.pumpAndSettle();
    expect(find.text('Loại'), findsNothing);
    expect(find.text('Danh mục'), findsNothing);
    expect(find.byKey(const Key('upcoming-due-input')), findsOneWidget);
    expect(find.text('2026-08-18'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('upcoming-name-input')),
      'Wifi',
    );
    await tester.enterText(
      find.byKey(const Key('upcoming-amount-input')),
      '1000000',
    );
    await _pickDueDay(tester, 1);
    await tester.tap(find.byKey(const Key('upcoming-save')));
    await tester.pumpAndSettle();
    expect(find.text('Wifi'), findsWidgets);
    expect(find.textContaining('Ngày 01/08'), findsWidgets);

    final listed = (await harness.recurring.listAll()).unwrapOrThrow();
    expect(listed, hasLength(1));
    expect(listed.single.name, 'Wifi');
    expect(listed.single.amount, 1000000);
    expect(listed.single.categoryId, isNull);
    expect(listed.single.kind, RecurringKind.expense);
    expect(listed.single.direction, RecurringDirection.subtract);
    expect(listed.single.frequency, RecurringFrequency.monthly);
    expect(listed.single.intervalCount, 1);
    final id = listed.single.id;

    await tester.tap(find.byKey(Key('finance-upcoming-edit-$id')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('upcoming-name-input')),
      'Internet',
    );
    await tester.tap(find.byKey(const Key('upcoming-save')));
    await tester.pumpAndSettle();
    expect(find.text('Internet'), findsWidgets);

    await tester.tap(find.byKey(Key('finance-upcoming-delete-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finance-upcoming-confirm-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Internet'), findsNothing);
    expect((await harness.recurring.listAll()).unwrapOrThrow(), isEmpty);

    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có khoản định kỳ'), findsOneWidget);
    expect(find.byKey(const Key('finance-upcoming-section')), findsOneWidget);
  });

  testWidgets(
    'Thu nhập named Lương updates recurring_salary instead of minting',
    (tester) async {
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
      final at = DateTime.utc(2026, 8, 1);
      expect(
        (await harness.finance.saveSalary(
          const MonthlySalary(amount: 20000000),
        )).isOk,
        isTrue,
      );
      expect(
        (await harness.recurring.replaceSalary(
          RecurringTransaction(
            id: RecurringTransaction.salaryId,
            name: 'Lương',
            kind: RecurringKind.income,
            amount: 20000000,
            frequency: RecurringFrequency.monthly,
            intervalCount: 1,
            direction: RecurringDirection.add,
            startDate: DateTime(2026, 8, 1),
            isActive: true,
            createdAt: at,
            updatedAt: at,
          ),
        )).isOk,
        isTrue,
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

      await tester.ensureVisible(
        find.byKey(const Key('finance-income-manage')),
      );
      await tester.tap(find.byKey(const Key('finance-income-manage')));
      await tester.pumpAndSettle();
      expect(find.text('Quản lý thu nhập'), findsOneWidget);
      expect(find.text('Lương'), findsWidgets);
      await tester.tap(find.byKey(const Key('finance-income-add')));
      await tester.pumpAndSettle();
      expect(find.text('Thêm thu nhập'), findsOneWidget);
      expect(find.text('Loại'), findsNothing);
      expect(find.byKey(const Key('upcoming-due-input')), findsOneWidget);
      expect(find.text('2026-08-18'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('upcoming-name-input')),
        'Lương',
      );
      await tester.enterText(
        find.byKey(const Key('upcoming-amount-input')),
        '22000000',
      );
      await _pickDueDay(tester, 1);
      await tester.tap(find.byKey(const Key('upcoming-save')));
      await tester.pumpAndSettle();

      final listed = (await harness.recurring.listAll()).unwrapOrThrow();
      expect(listed.where((item) => item.isSalary), hasLength(1));
      expect(listed.single.id, RecurringTransaction.salaryId);
      expect(listed.single.amount, 22000000);
      expect(harness.finance.salary.amount, 22000000);
      expect(find.text('Thẻ tín dụng'), findsNothing);
    },
  );

  testWidgets('income management does not list expenses and vice versa', (
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
    final now = DateTime.utc(2026, 8, 18);
    expect(
      (await harness.finance.saveSalary(
        const MonthlySalary(amount: 20000000),
      )).isOk,
      isTrue,
    );
    expect(
      (await harness.recurring.replaceSalary(
        RecurringTransaction(
          id: RecurringTransaction.salaryId,
          name: 'Lương',
          kind: RecurringKind.income,
          amount: 20000000,
          frequency: RecurringFrequency.monthly,
          intervalCount: 1,
          direction: RecurringDirection.add,
          startDate: DateTime(2026, 8, 1),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      )).isOk,
      isTrue,
    );
    expect(
      (await harness.recurring.create(
        RecurringTransaction(
          id: 'bonus',
          name: 'Thưởng',
          kind: RecurringKind.income,
          amount: 1000000,
          frequency: RecurringFrequency.monthly,
          intervalCount: 1,
          direction: RecurringDirection.add,
          startDate: DateTime(2026, 8, 10),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      )).isOk,
      isTrue,
    );
    expect(
      (await harness.recurring.create(
        RecurringTransaction(
          id: 'rent',
          name: 'Tiền nhà',
          kind: RecurringKind.expense,
          amount: 5000000,
          frequency: RecurringFrequency.monthly,
          intervalCount: 1,
          direction: RecurringDirection.subtract,
          startDate: DateTime(2026, 8, 25),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      )).isOk,
      isTrue,
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

    expect(find.text('Tiền nhà'), findsOneWidget);
    expect(find.text('Thưởng'), findsNothing);
    expect(find.text('Tháng 8/2026'), findsOneWidget);
    expect(find.text('21.000.000 ₫'), findsOneWidget);
    expect(find.text('Sửa'), findsNothing);

    await tester.tap(find.byKey(const Key('finance-income-card')));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý thu nhập'), findsOneWidget);
    expect(
      find.byKey(const Key('finance-income-manage-sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('finance-income-managed-recurring_salary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('finance-income-managed-bonus')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('finance-income-manage-sheet')),
        matching: find.text('Tiền nhà'),
      ),
      findsNothing,
    );
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('finance-upcoming-manage')),
    );
    await tester.tap(find.byKey(const Key('finance-upcoming-manage')));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý khoản định kỳ'), findsOneWidget);
    expect(
      find.byKey(const Key('finance-upcoming-managed-rent')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('finance-upcoming-manage-sheet')),
        matching: find.text('Lương'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('finance-upcoming-manage-sheet')),
        matching: find.text('Thưởng'),
      ),
      findsNothing,
    );
  });

  testWidgets('adding income from income manage stays out of expense list', (
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

    await tester.tap(find.byKey(const Key('finance-income-manage')));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có khoản. Nhấn + để thêm.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finance-income-add')));
    await tester.pumpAndSettle();
    expect(find.text('Thêm thu nhập'), findsOneWidget);
    expect(find.byKey(const Key('upcoming-due-input')), findsOneWidget);
    expect(find.text('2026-08-18'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('upcoming-name-input')),
      'Freelance',
    );
    await tester.enterText(
      find.byKey(const Key('upcoming-amount-input')),
      '3000000',
    );
    await _pickDueDay(tester, 5);
    await tester.tap(find.byKey(const Key('upcoming-save')));
    await tester.pumpAndSettle();

    final listed = (await harness.recurring.listAll()).unwrapOrThrow();
    expect(listed, hasLength(1));
    expect(listed.single.name, 'Freelance');
    expect(listed.single.kind, RecurringKind.income);
    expect(find.text('Freelance'), findsWidgets);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có khoản định kỳ'), findsOneWidget);
    expect(find.text('Freelance'), findsNothing);
  });

  testWidgets('salary can be deleted from income management', (tester) async {
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
    final at = DateTime.utc(2026, 8, 1);
    expect(
      (await harness.finance.saveSalary(
        const MonthlySalary(amount: 20000000),
      )).isOk,
      isTrue,
    );
    expect(
      (await harness.recurring.replaceSalary(
        RecurringTransaction(
          id: RecurringTransaction.salaryId,
          name: 'Lương',
          kind: RecurringKind.income,
          amount: 20000000,
          frequency: RecurringFrequency.monthly,
          intervalCount: 1,
          direction: RecurringDirection.add,
          startDate: DateTime(2026, 8, 1),
          isActive: true,
          createdAt: at,
          updatedAt: at,
        ),
      )).isOk,
      isTrue,
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

    await tester.ensureVisible(find.byKey(const Key('finance-income-manage')));
    await tester.tap(find.byKey(const Key('finance-income-manage')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('finance-upcoming-delete-recurring_salary')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finance-upcoming-confirm-delete')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('finance-income-managed-recurring_salary')),
      findsNothing,
    );
    expect((await harness.recurring.listAll()).unwrapOrThrow(), isEmpty);
    expect(harness.finance.salary.amount, 0);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('salary-amount'))).data,
      '0 ₫',
    );
  });
}
