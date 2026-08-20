import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/home/widgets/home_bottom_nav.dart';

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

  testWidgets('core flow: Home → add → Giao dịch → edit → delete → Thống kê → Cài đặt → Tài chính → PIN', (tester) async {
    _phone(tester);
    final repo = MemoryTransactionRepository();
    final service = TransactionService(repo);
    final home = HomeController(HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)));
    final harness = buildShell(transactions: service, home: home, clock: () => DateTime(2026, 8, 18, 9));
    addTearDown(harness.settings.dispose);

    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Chi tiêu tháng này'), findsOneWidget);
    expect(find.text('0 ₫'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fab-add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Thêm giao dịch'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick-amt-50000')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('btn-save-tx')));
    await tester.tap(find.byKey(const Key('btn-save-tx')));
    await tester.pumpAndSettle();

    expect(find.textContaining('50.000'), findsWidgets);
    expect(repo.items, hasLength(1));

    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Giao dịch'), findsWidgets);
    expect(find.text('Cafe'), findsWidgets);

    await tester.tap(find.byKey(Key('tx-tile-${repo.items.single.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết'), findsWidgets);
    final editRect = tester.getRect(find.byKey(const Key('btn-detail-edit')));
    expect(editRect.bottom, lessThan(844));
    await tester.tap(find.byKey(const Key('btn-detail-edit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Sửa giao dịch'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick-amt-100000')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('btn-save-tx')));
    await tester.tap(find.byKey(const Key('btn-save-tx')));
    await tester.pumpAndSettle();
    expect(repo.items.single.amount, 100000);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.tap(find.byKey(Key('tx-tile-${repo.items.single.id}')));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const Key('btn-detail-delete'))).bottom, lessThan(844));
    await tester.tap(find.byKey(const Key('btn-detail-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(repo.items, isEmpty);

    await tester.tap(find.byKey(const Key('nav-statistics')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Thống kê'), findsWidgets);
    expect(find.text('so với tháng trước'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    expect(find.text('Cài đặt'), findsWidgets);
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Tạo mật khẩu'), findsWidgets);
    await _submitPin(tester, '5820');
    expect(find.text('Tài chính'), findsOneWidget);
    expect(find.textContaining('Lương'), findsOneWidget);
  });

  testWidgets('duplicate + taps open only one add screen', (tester) async {
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
    final add = tester.widget<GestureDetector>(
      find.byKey(const Key('fab-add')),
    );
    add.onTap!();
    add.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Thêm giao dịch'), findsOneWidget);
  });

  testWidgets('tap on the protruding plus opens add not the item below', (
    tester,
  ) async {
    _phone(tester);
    final now = DateTime.utc(2026, 8, 18);
    final service = TransactionService(
      MemoryTransactionRepository(
        seed: [
          Transaction(
            id: 'under-fab',
            amount: 32000,
            type: TransactionType.expense,
            categoryId: 'cafe',
            detail: 'Highlands',
            occurredOn: DateTime(2026, 8, 18),
            paymentSourceId: 'momo',
            paymentSourceName: 'MoMo',
            paymentMethod: PaymentMethodKind.eWallet,
            createdAt: now,
            updatedAt: now,
          ),
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

    final fab = tester.getRect(find.byKey(const Key('fab-add')));
    await tester.tapAt(Offset(fab.center.dx, fab.top + 6));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Thêm giao dịch'), findsOneWidget);
  });

  testWidgets('iPhone home indicator padding lifts nav and PIN sheet', (
    tester,
  ) async {
    _phone(tester);
    tester.view.padding = const FakeViewPadding(bottom: 34, top: 47);
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
    expect(tester.getSize(find.byType(HomeBottomNav)).height, 78 + 34);

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-finance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Tạo mật khẩu'), findsWidgets);
    expect(find.byKey(const Key('btn-submit-pin')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
