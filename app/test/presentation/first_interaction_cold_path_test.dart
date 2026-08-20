import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/presentation/add_transaction/add_transaction_page.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/home/widgets/home_transaction_tile.dart';
import 'package:tien_day/presentation/settings/settings_page.dart';
import 'package:tien_day/presentation/statistics/statistics_page.dart';
import 'package:tien_day/presentation/transactions/transaction_list_page.dart';

import '../support/memory_transaction_repository.dart';
import '../support/shell_harness.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Transaction _tx(int i) {
  return Transaction(
    id: 'tx-$i',
    amount: 10000 + i,
    type: TransactionType.expense,
    categoryId: 'cafe',
    detail: 'Highlands',
    occurredOn: DateTime(2026, 8, 1 + (i % 18)),
    paymentSourceId: 'momo',
    paymentSourceName: 'MoMo',
    paymentMethod: PaymentMethodKind.eWallet,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );
}

Future<MemoryTransactionRepository> _pumpShell(
  WidgetTester tester, {
  int seedCount = 80,
  bool idleWarmup = true,
}) async {
  _phone(tester);
  final repo = MemoryTransactionRepository(
    seed: [for (var i = 0; i < seedCount; i++) _tx(i)],
  );
  final service = TransactionService(repo);
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
  if (idleWarmup) {
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
  return repo;
}

Future<int> _measureUs(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  final watch = Stopwatch()..start();
  await action();
  watch.stop();
  return watch.elapsedMicroseconds;
}

void main() {
  testWidgets('first frame mounts all tabs and add for paint warmup', (
    tester,
  ) async {
    final repo = await _pumpShell(tester, idleWarmup: false);

    expect(
      repo.querySpecs.where((spec) => spec.limit == HomeQuery.recentLimit),
      isNotEmpty,
    );
    expect(find.byType(TransactionListPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(StatisticsPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(SettingsPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(AddTransactionPage, skipOffstage: false), findsOneWidget);
  });

  testWidgets('idle warmup mounts tabs and add before the first tap', (
    tester,
  ) async {
    await _pumpShell(tester);

    expect(
      find.byType(TransactionListPage, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(StatisticsPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(SettingsPage, skipOffstage: false), findsOneWidget);
    expect(find.byType(AddTransactionPage, skipOffstage: false), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    expect(find.byType(TransactionListPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-statistics')));
    await tester.pump();
    expect(find.byType(StatisticsPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pump();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('first + still opens add, later Giao dịch still loads', (
    tester,
  ) async {
    final repo = await _pumpShell(tester);

    final firstAddUs = await _measureUs(tester, () async {
      await tester.tap(find.byKey(const Key('fab-add')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    });
    expect(find.byType(AddTransactionPage), findsOneWidget);
    debugPrint('TD_PERF firstAddUs=$firstAddUs');

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    final secondAddUs = await _measureUs(tester, () async {
      await tester.tap(find.byKey(const Key('fab-add')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    });
    debugPrint('TD_PERF secondAddUs=$secondAddUs');
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-transactions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(TransactionListPage), findsOneWidget);
    expect(repo.querySpecs.where((spec) => spec.limit == 50), isNotEmpty);
    expect(find.byType(HomeTransactionTile), findsWidgets);
  });

  testWidgets('amount field focuses after add route animation completes', (
    tester,
  ) async {
    await _pumpShell(tester, seedCount: 0);
    await tester.tap(find.byKey(const Key('fab-add')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('input-amount')),
    );
    expect(field.focusNode?.hasFocus, isTrue);
  });
}
