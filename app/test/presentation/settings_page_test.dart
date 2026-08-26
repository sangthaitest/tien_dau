import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/finance.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/format/money_format.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/theme/app_colors.dart';

import '../support/memory_app_settings_repository.dart';
import '../support/memory_finance_repository.dart';
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

Transaction _tx() {
  final now = DateTime.utc(2026, 8, 18);
  return Transaction(
    id: '1',
    amount: 45000,
    type: TransactionType.expense,
    categoryId: 'cafe',
    detail: 'Highlands',
    occurredOn: DateTime(2026, 8, 7),
    paymentSourceId: 'momo',
    paymentSourceName: 'MoMo',
    paymentMethod: PaymentMethodKind.eWallet,
    createdAt: now,
    updatedAt: now,
  );
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

void main() {
  setUpAll(() {});

  tearDown(() {
    AppColors.dark = false;
  });

  testWidgets('Settings shows V3 groups and currency stays VND', (
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
    addTearDown(harness.settings.dispose);
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();

    expect(find.text('Cài đặt'), findsWidgets);
    expect(find.text('QUẢN LÝ TÀI CHÍNH'), findsOneWidget);
    expect(find.text('TÙY CHỌN'), findsOneWidget);
    expect(find.text('Tài chính'), findsOneWidget);
    expect(find.text('Mật khẩu quản lý'), findsOneWidget);
    expect(find.text('Tiền tệ'), findsOneWidget);
    expect(find.text('VND (₫)'), findsOneWidget);
    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Riêng tư'), findsOneWidget);
    expect(find.text('Hiện số'), findsOneWidget);
    expect(find.text('Giao diện tối'), findsOneWidget);
    expect(find.text('Đăng xuất (prototype)'), findsOneWidget);
    expect(find.text('Sao lưu'), findsNothing);
    expect(find.text('Google Drive'), findsNothing);

    await tester.tap(find.byKey(const Key('settings-currency')));
    await tester.pump();
    expect(find.text('MVP dùng VND (₫).'), findsOneWidget);
  });

  testWidgets('notifications toggle persists and shows toast', (tester) async {
    _phone(tester);
    final repo = MemoryAppSettingsRepository();
    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    final harness = buildShell(
      transactions: service,
      home: home,
      clock: () => DateTime(2026, 8, 18, 9),
      settingsRepo: repo,
    );
    addTearDown(harness.settings.dispose);
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('toggle-notif')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Đã tắt thông báo'), findsOneWidget);
    expect(repo.stored.notificationsEnabled, isFalse);
  });

  testWidgets('privacy hides Home amounts and keeps category names', (
    tester,
  ) async {
    _phone(tester);
    final service = TransactionService(
      MemoryTransactionRepository(seed: [_tx()]),
    );
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    final harness = buildShell(
      transactions: service,
      home: home,
      clock: () => DateTime(2026, 8, 18, 9),
    );
    addTearDown(harness.settings.dispose);
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('45.000 ₫'), findsWidgets);
    expect(find.text('Highlands'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-privacy')));
    await tester.pump();
    expect(find.text('Ẩn số'), findsOneWidget);
    expect(find.text('Hiện số'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(kHiddenMoney), findsOneWidget);
    expect(find.text(kHiddenMoneyShort), findsOneWidget);
    expect(find.text('45.000 ₫'), findsNothing);
    expect(find.text('Highlands'), findsOneWidget);
    expect(find.textContaining('Cafe'), findsOneWidget);
  });

  testWidgets('privacy masks Tài chính amounts and keeps labels', (
    tester,
  ) async {
    _phone(tester);
    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    final finance = MemoryFinanceRepository()
      ..salary = const MonthlySalary(amount: 18500000);
    final harness = buildShell(
      transactions: service,
      home: home,
      clock: () => DateTime(2026, 8, 18, 9),
      financeRepo: finance,
    );
    addTearDown(harness.settings.dispose);
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-privacy')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await _submitPin(tester, '5820');
    expect(find.text('Tháng 8/2026'), findsOneWidget);
    expect(find.text(kHiddenMoney), findsWidgets);
    expect(find.text('18.500.000 ₫'), findsNothing);
  });

  testWidgets('dark mode toggle applies and persists', (tester) async {
    _phone(tester);
    final repo = MemoryAppSettingsRepository();
    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    final harness = buildShell(
      transactions: service,
      home: home,
      clock: () => DateTime(2026, 8, 18, 9),
      settingsRepo: repo,
    );
    addTearDown(harness.settings.dispose);
    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    expect(AppColors.dark, isFalse);
    await tester.tap(find.byKey(const Key('toggle-dark')));
    await tester.pump();
    expect(AppColors.dark, isTrue);
    expect(repo.stored.darkMode, isTrue);
    expect(find.byType(Scaffold).evaluate().first.widget, isA<Scaffold>());
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFF0E1116));
  });

  testWidgets('logout locks PIN session and keeps local data', (tester) async {
    _phone(tester);
    final service = TransactionService(
      MemoryTransactionRepository(seed: [_tx()]),
    );
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    final pins = MemoryPinRepository();
    final harness = buildShell(
      transactions: service,
      home: home,
      clock: () => DateTime(2026, 8, 18, 9),
      pinRepo: pins,
    );
    addTearDown(harness.settings.dispose);
    await harness.access.setupPin('5820');
    expect(await harness.access.isUnlocked(), isTrue);

    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    final logout = tester.getRect(find.byKey(const Key('settings-logout')));
    await tester.tapAt(Offset(logout.left + 24, logout.center.dy));
    await tester.pump();
    expect(
      find.text('Dữ liệu cục bộ vẫn được giữ trên thiết bị.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('dialog-logout-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(await harness.access.isUnlocked(), isFalse);
    expect(find.text('Đã khóa khu vực tài chính'), findsOneWidget);
    expect(find.text('Cài đặt'), findsWidgets);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pump();
    expect(find.text('Highlands'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Nhập mật khẩu'), findsWidgets);
    await _submitPin(tester, '5820');
    expect(find.text('Tài chính'), findsOneWidget);
  });
}
