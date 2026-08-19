import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/home/home_page.dart';
import 'package:tien_day/presentation/theme/app_theme.dart';
import 'package:tien_day/presentation/theme/app_typography.dart';

import '../support/memory_transaction_repository.dart';

void main() {
  testWidgets('app theme uses the bundled Be Vietnam Pro weight system', (
    tester,
  ) async {
    late ThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(theme.textTheme.bodyMedium?.fontFamily, AppTypography.fontFamily);
    expect(theme.textTheme.bodyMedium?.fontWeight, AppTypography.bodyWeight);
    expect(
      theme.textTheme.labelMedium?.fontWeight,
      AppTypography.metadataWeight,
    );
    expect(theme.textTheme.titleMedium?.fontWeight, AppTypography.titleWeight);
    expect(
      theme.textTheme.headlineMedium?.fontWeight,
      AppTypography.strongWeight,
    );
  });

  testWidgets('polished Home fits small and large Android densities', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 8, 18);
    final service = TransactionService(
      MemoryTransactionRepository(
        seed: [
          Transaction(
            id: 'responsive',
            amount: 123456789,
            type: TransactionType.expense,
            categoryId: 'transport',
            detail: 'Di chuyển công việc trong thành phố',
            occurredOn: DateTime(2026, 8, 18),
            paymentSourceId: 'bank',
            paymentSourceName: 'Tài khoản ngân hàng',
            paymentMethod: PaymentMethodKind.bankAccount,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
    );
    final controller = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );

    for (final physicalSize in [
      const Size(960, 1704),
      const Size(1290, 2796),
    ]) {
      tester.view.physicalSize = physicalSize;
      tester.view.devicePixelRatio = 3;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HomePage(controller: controller, transactionService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home-month-spend')), findsOneWidget);
      expect(find.byKey(const Key('tx-tile-responsive')), findsOneWidget);
      expect(find.byKey(const Key('fab-add')), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
