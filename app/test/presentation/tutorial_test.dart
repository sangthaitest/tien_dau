import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/domain/entities/app_settings.dart';
import 'package:tien_day/presentation/add_transaction/add_transaction_copy.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/settings/settings_page.dart';

import '../support/memory_app_settings_repository.dart';
import '../support/memory_transaction_repository.dart';
import '../support/shell_harness.dart';

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding.zero;
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
}

Future<MemoryAppSettingsRepository> _pump(
  WidgetTester tester, {
  required AppSettings stored,
}) async {
  final service = TransactionService(MemoryTransactionRepository());
  final home = HomeController(
    HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
  );
  final repo = MemoryAppSettingsRepository(stored: stored);
  final harness = buildShell(
    transactions: service,
    home: home,
    clock: () => DateTime(2026, 8, 18, 9),
    settingsRepo: repo,
  );
  addTearDown(harness.settings.dispose);
  await tester.pumpWidget(MaterialApp(home: harness.shell));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 400));
  return repo;
}

Finder _settingsScrollable() {
  return find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;
}

Future<void> _openTutorialFromSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-settings')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.scrollUntilVisible(
    find.byKey(const Key('settings-tutorial')),
    80,
    scrollable: _settingsScrollable(),
  );
  await tester.tap(find.byKey(const Key('settings-tutorial')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tick(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _submitPin(WidgetTester tester, String pin) async {
  await tester.enterText(find.byKey(const Key('input-finance-pin')), pin);
  tester.view.viewInsets = FakeViewPadding.zero;
  await tester.pump();
  tester
      .widget<FilledButton>(find.byKey(const Key('btn-submit-pin')))
      .onPressed!
      .call();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _openFinanceFromSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-settings')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.byKey(const Key('settings-finance')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await _submitPin(tester, '5820');
  await _tick(tester);
}

Future<void> _openBackupFromSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-settings')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.byKey(const Key('settings-backup-restore')));
  await _tick(tester);
}

Future<void> _advance(WidgetTester tester) async {
  expect(find.text('Tiếp tục'), findsOneWidget);
  await tester.tap(find.byKey(const Key('tutorial-next')));
  await _tick(tester);
}

void main() {
  testWidgets('fresh install opens the tutorial after Home renders', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repo = await _pump(tester, stored: AppSettings.defaults);

    expect(find.byKey(const Key('tutorial-overlay')), findsOneWidget);
    expect(find.text('Chào mừng đến với Tiền đâu nè'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);
    expect(repo.stored.hasCompletedTutorial, isFalse);
  });

  testWidgets('completed tutorial does not auto-open on launch', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    await _pump(
      tester,
      stored: AppSettings.defaults.copyWith(hasCompletedTutorial: true),
    );

    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Chào mừng đến với Tiền đâu nè'), findsNothing);
    expect(find.text('Tháng này tiền đi đâu rồi?'), findsOneWidget);
  });

  testWidgets('skip closes tutorial without marking it completed', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repo = await _pump(tester, stored: AppSettings.defaults);

    await tester.tap(find.byKey(const Key('tutorial-skip')));
    await _tick(tester);

    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(repo.stored.hasCompletedTutorial, isFalse);
    expect(find.text('Tháng này tiền đi đâu rồi?'), findsOneWidget);
    expect(find.byKey(const Key('fab-add')), findsOneWidget);
  });

  testWidgets('first-launch covers Home and the + button', (tester) async {
    _setSize(tester, const Size(390, 844));
    final repo = await _pump(tester, stored: AppSettings.defaults);

    expect(find.text('Chào mừng đến với Tiền đâu nè'), findsOneWidget);
    await _advance(tester);
    expect(find.text('Thêm giao dịch'), findsWidgets);
    expect(find.byKey(const Key('fab-add')), findsOneWidget);
    expect(find.text('Bắt đầu sử dụng'), findsOneWidget);
    expect(find.text('Nhập số tiền'), findsNothing);

    await tester.tap(find.byKey(const Key('tutorial-next')));
    await _tick(tester);

    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(repo.stored.hasCompletedTutorial, isTrue);
    expect(repo.stored.hasCompletedAddTutorial, isFalse);
    expect(find.text('Tháng này tiền đi đâu rồi?'), findsOneWidget);
  });

  testWidgets('first visit to Thêm giao dịch shows only the add guide', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repo = await _pump(
      tester,
      stored: AppSettings.defaults.copyWith(hasCompletedTutorial: true),
    );

    await tester.tap(find.byKey(const Key('fab-add')));
    await _tick(tester);
    expect(find.text('Nhập số tiền'), findsOneWidget);
    expect(find.text(AddTransactionCopy.amountLabel), findsOneWidget);
    expect(find.text('Chào mừng đến với Tiền đâu nè'), findsNothing);
    expect(find.text('Danh sách giao dịch'), findsNothing);

    await _advance(tester);
    expect(find.text('Chọn khoản chi'), findsOneWidget);
    expect(find.text(AddTransactionCopy.chiCho), findsOneWidget);

    await _advance(tester);
    expect(find.text('Lưu giao dịch'), findsWidgets);
    expect(find.text('Bắt đầu sử dụng'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-next')));
    await _tick(tester);

    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Thêm giao dịch'), findsWidgets);
    expect(repo.stored.hasCompletedAddTutorial, isTrue);
    expect(repo.stored.hasCompletedTutorial, isTrue);

    await tester.tap(find.byTooltip('Quay lại'));
    await _tick(tester);
    await tester.tap(find.byKey(const Key('fab-add')));
    await _tick(tester);
    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Thêm giao dịch'), findsWidgets);
  });

  testWidgets(
    'Settings replay runs the full tutorial then returns to Settings',
    (tester) async {
      _setSize(tester, const Size(390, 844));
      final repo = await _pump(
        tester,
        stored: AppSettings.defaults.copyWith(
          hasCompletedTutorial: true,
          hasCompletedFinanceTutorial: true,
          hasCompletedBackupTutorial: true,
          hasCompletedTransactionsTutorial: true,
          hasCompletedStatisticsTutorial: true,
          hasCompletedAddTutorial: true,
        ),
      );

      await _openTutorialFromSettings(tester);
      expect(find.text('Chào mừng đến với Tiền đâu nè'), findsOneWidget);

      await _advance(tester);
      expect(find.text('Thêm giao dịch'), findsWidgets);
      expect(find.byKey(const Key('fab-add')), findsOneWidget);

      await _advance(tester);
      expect(find.text('Nhập số tiền'), findsOneWidget);

      await _advance(tester);
      expect(find.text('Chọn khoản chi'), findsOneWidget);

      await _advance(tester);
      expect(find.text('Lưu giao dịch'), findsWidgets);

      await _advance(tester);
      expect(find.text('Danh sách giao dịch'), findsOneWidget);
      expect(find.byKey(const Key('tx-sum-expense')), findsOneWidget);

      await _advance(tester);
      expect(find.text('Lọc giao dịch'), findsOneWidget);
      expect(find.byKey(const Key('date-thisMonth')), findsOneWidget);

      await _advance(tester);
      expect(find.text('Chi tiêu tháng này'), findsOneWidget);
      expect(find.byKey(const Key('stats-expense-total')), findsOneWidget);

      await _advance(tester);
      expect(find.text('Chi tiêu theo danh mục'), findsWidgets);

      await _advance(tester);
      expect(find.text('Thu nhập của bạn'), findsOneWidget);
      expect(find.text('Thu nhập'), findsWidgets);

      await _advance(tester);
      expect(find.text('Khoản định kỳ'), findsWidgets);

      await _advance(tester);
      expect(find.text('Chi tiêu'), findsOneWidget);

      await _advance(tester);
      expect(find.text('Sao lưu dữ liệu'), findsWidgets);
      expect(find.byKey(const Key('backup-export')), findsOneWidget);

      await _advance(tester);
      expect(find.text('Khôi phục dữ liệu'), findsWidgets);
      expect(find.byKey(const Key('backup-import')), findsOneWidget);
      expect(find.text('Bắt đầu sử dụng'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tutorial-next')));
      await _tick(tester);

      expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Cài đặt'), findsWidgets);
      expect(find.text('Hướng dẫn sử dụng'), findsOneWidget);
      expect(repo.stored.hasCompletedTutorial, isTrue);
      expect(repo.stored.hasCompletedFinanceTutorial, isTrue);
      expect(repo.stored.hasCompletedBackupTutorial, isTrue);
      expect(repo.stored.hasCompletedTransactionsTutorial, isTrue);
      expect(repo.stored.hasCompletedStatisticsTutorial, isTrue);
      expect(repo.stored.hasCompletedAddTutorial, isTrue);
    },
  );

  testWidgets('first visit to Tài chính shows only the finance guide', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repo = await _pump(
      tester,
      stored: AppSettings.defaults.copyWith(hasCompletedTutorial: true),
    );

    await _openFinanceFromSettings(tester);
    expect(find.text('Thu nhập của bạn'), findsOneWidget);
    expect(find.text('Chào mừng đến với Tiền đâu nè'), findsNothing);
    expect(find.text('Sao lưu dữ liệu'), findsNothing);

    await _advance(tester);
    expect(find.text('Khoản định kỳ'), findsWidgets);
    await _advance(tester);
    expect(find.text('Chi tiêu'), findsOneWidget);
    expect(find.text('Bắt đầu sử dụng'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-next')));
    await _tick(tester);

    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Tài chính'), findsOneWidget);
    expect(find.byKey(const Key('finance-back')), findsOneWidget);
    expect(find.text('Còn lại'), findsOneWidget);
    expect(repo.stored.hasCompletedFinanceTutorial, isTrue);
    expect(repo.stored.hasCompletedTutorial, isTrue);
    expect(repo.stored.hasCompletedBackupTutorial, isFalse);

    await tester.tap(find.byKey(const Key('finance-back')));
    await _tick(tester);
    await tester.tap(find.byKey(const Key('settings-finance')));
    await _tick(tester);
    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Thu nhập'), findsWidgets);
  });

  testWidgets('first visit to Sao lưu shows only backup and restore', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repo = await _pump(
      tester,
      stored: AppSettings.defaults.copyWith(
        hasCompletedTutorial: true,
        hasCompletedFinanceTutorial: true,
      ),
    );

    await _openBackupFromSettings(tester);
    expect(find.text('Sao lưu dữ liệu'), findsWidgets);
    expect(find.byKey(const Key('backup-export')), findsOneWidget);
    expect(find.text('Thu nhập của bạn'), findsNothing);
    expect(find.text('Chào mừng đến với Tiền đâu nè'), findsNothing);

    await _advance(tester);
    expect(find.text('Khôi phục dữ liệu'), findsWidgets);
    expect(find.byKey(const Key('backup-import')), findsOneWidget);
    expect(find.text('Bắt đầu sử dụng'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-next')));
    await _tick(tester);

    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Sao lưu & khôi phục'), findsWidgets);
    expect(repo.stored.hasCompletedBackupTutorial, isTrue);
    expect(repo.stored.hasCompletedTutorial, isTrue);
    expect(repo.stored.hasCompletedFinanceTutorial, isTrue);

    await tester.tap(find.byKey(const Key('backup-back')));
    await _tick(tester);
    await tester.tap(find.byKey(const Key('settings-backup-restore')));
    await _tick(tester);
    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Sao lưu & khôi phục'), findsWidgets);
  });

  testWidgets('first visit to Giao dịch shows only the transactions guide', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repo = await _pump(
      tester,
      stored: AppSettings.defaults.copyWith(hasCompletedTutorial: true),
    );

    await tester.tap(find.byKey(const Key('nav-transactions')));
    await _tick(tester);
    expect(find.text('Danh sách giao dịch'), findsOneWidget);
    expect(find.byKey(const Key('tx-sum-expense')), findsOneWidget);
    expect(find.text('Chào mừng đến với Tiền đâu nè'), findsNothing);
    expect(find.text('Chi tiêu tháng này'), findsNothing);

    await _advance(tester);
    expect(find.text('Lọc giao dịch'), findsOneWidget);
    expect(find.byKey(const Key('date-thisMonth')), findsOneWidget);
    expect(find.text('Bắt đầu sử dụng'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-next')));
    await _tick(tester);

    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Giao dịch'), findsWidgets);
    expect(repo.stored.hasCompletedTransactionsTutorial, isTrue);
    expect(repo.stored.hasCompletedStatisticsTutorial, isFalse);

    await tester.tap(find.byKey(const Key('nav-home')));
    await _tick(tester);
    await tester.tap(find.byKey(const Key('nav-transactions')));
    await _tick(tester);
    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Giao dịch'), findsWidgets);
  });

  testWidgets('first visit to Thống kê shows only the statistics guide', (
    tester,
  ) async {
    _setSize(tester, const Size(390, 844));
    final repo = await _pump(
      tester,
      stored: AppSettings.defaults.copyWith(
        hasCompletedTutorial: true,
        hasCompletedTransactionsTutorial: true,
      ),
    );

    await tester.tap(find.byKey(const Key('nav-statistics')));
    await _tick(tester);
    expect(find.text('Chi tiêu tháng này'), findsOneWidget);
    expect(find.byKey(const Key('stats-expense-total')), findsOneWidget);
    expect(find.text('Danh sách giao dịch'), findsNothing);
    expect(find.text('Thu nhập của bạn'), findsNothing);

    await _advance(tester);
    expect(find.text('Chi tiêu theo danh mục'), findsWidgets);
    expect(find.text('Bắt đầu sử dụng'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-next')));
    await _tick(tester);

    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Thống kê'), findsWidgets);
    expect(repo.stored.hasCompletedStatisticsTutorial, isTrue);
    expect(repo.stored.hasCompletedTransactionsTutorial, isTrue);

    await tester.tap(find.byKey(const Key('nav-home')));
    await _tick(tester);
    await tester.tap(find.byKey(const Key('nav-statistics')));
    await _tick(tester);
    expect(find.byKey(const Key('tutorial-overlay')), findsNothing);
    expect(find.text('Thống kê'), findsWidgets);
  });

  testWidgets('tutorial layout holds on a phone', (tester) async {
    _setSize(tester, const Size(390, 844));
    await _pump(tester, stored: AppSettings.defaults);
    expect(find.byKey(const Key('tutorial-overlay')), findsOneWidget);
    expect(find.text('Chào mừng đến với Tiền đâu nè'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial-skip')));
    await _tick(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tutorial layout holds on a tablet', (tester) async {
    _setSize(tester, const Size(1024, 1366));
    await _pump(tester, stored: AppSettings.defaults);
    expect(find.byKey(const Key('tutorial-overlay')), findsOneWidget);
    expect(find.text('Chào mừng đến với Tiền đâu nè'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial-skip')));
    await _tick(tester);
    expect(tester.takeException(), isNull);
  });
}
