import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';

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
}) {
  final now = DateTime.utc(2026, 8, 1);
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: category,
    occurredOn: date,
    paymentSourceId: 'momo',
    paymentSourceName: 'MoMo',
    paymentMethod: PaymentMethodKind.eWallet,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _pumpShell(WidgetTester tester, {required TransactionService service}) async {
  final home = HomeController(HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)));
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
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('navigation opens Statistics with active tab', (tester) async {
    _phone(tester);
    await _pumpShell(tester, service: TransactionService(MemoryTransactionRepository()));
    await _openStats(tester);
    expect(find.text('Thống kê'), findsWidgets);
    expect(find.byKey(const Key('nav-statistics')), findsOneWidget);
    expect(find.text('so với tháng trước'), findsOneWidget);
    expect(find.text('Gần đây'), findsNothing);
    expect(find.text('Lương'), findsNothing);
    expect(find.text('Ngân sách tháng'), findsNothing);
    expect(find.text('Mục tiêu tiết kiệm'), findsNothing);
  });

  testWidgets('empty statistics copy', (tester) async {
    _phone(tester);
    await _pumpShell(tester, service: TransactionService(MemoryTransactionRepository()));
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
            _tx(id: '1', amount: 50000, date: DateTime(2026, 8, 7), category: 'cafe'),
            _tx(id: '2', amount: 150000, date: DateTime(2026, 8, 8), category: 'market'),
            _tx(id: '3', amount: 99999, date: DateTime(2026, 7, 1), category: 'cafe'),
            _tx(id: '4', amount: 800000, date: DateTime(2026, 8, 9), type: TransactionType.income),
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
          seed: [_tx(id: '1', amount: 12000, date: DateTime(2026, 8, 4), category: 'xyz-unknown')],
        ),
      ),
    );
    await _openStats(tester);
    expect(find.text('Khác'), findsWidgets);
    expect(find.text('12.000 ₫'), findsWidgets);
  });

  testWidgets('list error is shown instead of a fake zero total', (tester) async {
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
}
