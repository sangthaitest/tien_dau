import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/home/home_page.dart';

import '../support/memory_transaction_repository.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required TransactionService service,
}) async {
  final controller = HomeController(
    HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9, 15)),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: HomePage(
        controller: controller,
        transactionService: service,
        clock: () => DateTime(2026, 8, 18, 9, 15),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
  });

  testWidgets('FAB opens Add Transaction sheet', (tester) async {
    _phone(tester);
    await _pumpHome(tester, service: TransactionService(MemoryTransactionRepository()));

    await tester.tap(find.byKey(const Key('fab-add')));
    await tester.pumpAndSettle();

    expect(find.text('Thêm giao dịch'), findsOneWidget);
    expect(find.text('Số tiền'), findsOneWidget);
    expect(find.text('10k'), findsOneWidget);
    expect(find.text('200k'), findsOneWidget);
    expect(find.text('Chi cho'), findsOneWidget);
    expect(find.text('Chi tiết'), findsOneWidget);
    expect(find.text('Thanh toán bằng'), findsOneWidget);
    expect(find.text('Lưu giao dịch'), findsOneWidget);
    expect(find.text('Cafe'), findsWidgets);
  });

  testWidgets('invalid amount cannot save and stays on the sheet', (tester) async {
    _phone(tester);
    await _pumpHome(tester, service: TransactionService(MemoryTransactionRepository()));

    await tester.tap(find.byKey(const Key('fab-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn-save-tx')));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập số tiền'), findsOneWidget);
    expect(find.text('Thêm giao dịch'), findsOneWidget);
  });

  testWidgets('shortcut save returns to Home with the new transaction', (tester) async {
    _phone(tester);
    await _pumpHome(tester, service: TransactionService(MemoryTransactionRepository()));

    await tester.tap(find.byKey(const Key('fab-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-amt-100000')));
    await tester.pumpAndSettle();
    expect(find.text('100.000'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('btn-save-tx')));
    await tester.tap(find.byKey(const Key('btn-save-tx')));
    await tester.pumpAndSettle();

    expect(find.text('Thêm giao dịch'), findsNothing);
    expect(find.text('Cafe'), findsWidgets);
    expect(find.textContaining('100.000'), findsWidgets);
  });

  testWidgets('manual amount, category, payment, and note persist', (tester) async {
    _phone(tester);
    final repo = MemoryTransactionRepository();
    await _pumpHome(tester, service: TransactionService(repo));

    await tester.tap(find.byKey(const Key('fab-add')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input-amount')), '25000');
    await tester.pump();
    expect(find.text('25.000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chi-cho-transport')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grab'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pay-select')));
    await tester.tap(find.byKey(const Key('pay-select')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pay-cash')));
    await tester.tap(find.byKey(const Key('pay-cash')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('input-note')));
    await tester.enterText(find.byKey(const Key('input-note')), 'đi làm');
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('btn-save-tx')));
    await tester.tap(find.byKey(const Key('btn-save-tx')));
    await tester.pumpAndSettle();

    final saved = repo.items.single;
    expect(saved.amount, 25000);
    expect(saved.categoryId, 'transport');
    expect(saved.detail, 'Grab');
    expect(saved.paymentSourceId, 'cash');
    expect(saved.paymentMethod.toString(), contains('cash'));
    expect(saved.note, 'đi làm');
    expect(find.text('Grab'), findsOneWidget);
  });

  testWidgets('persistence failure keeps the sheet and the entered amount', (tester) async {
    _phone(tester);
    await _pumpHome(
      tester,
      service: TransactionService(MemoryTransactionRepository(failCreate: true)),
    );

    await tester.tap(find.byKey(const Key('fab-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-amt-200000')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('btn-save-tx')));
    await tester.tap(find.byKey(const Key('btn-save-tx')));
    await tester.pumpAndSettle();

    expect(find.text('Không lưu được giao dịch. Thử lại.'), findsOneWidget);
    expect(find.text('Thêm giao dịch'), findsOneWidget);
    expect(find.text('200.000'), findsOneWidget);
  });
}
