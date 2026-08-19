import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/home/home_page.dart';

import '../support/memory_transaction_repository.dart';

void main() {
  setUpAll(() {
  });

  testWidgets('Home shows monthly spend, empty recent copy, and + control', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = TransactionService(MemoryTransactionRepository());
    final controller = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(controller: controller, transactionService: service),
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

  testWidgets('Home lists a recent expense from the repository', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 8, 18);
    final service = TransactionService(
      MemoryTransactionRepository(
        seed: [
          Transaction(
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
          ),
        ],
      ),
    );
    final controller = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(controller: controller, transactionService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('45.000 ₫'), findsWidgets);
    expect(find.text('Highlands'), findsOneWidget);
    expect(find.textContaining('Cafe'), findsOneWidget);
  });
}
