import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
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
    expect(find.text('Lương'), findsOneWidget);
  });
}
