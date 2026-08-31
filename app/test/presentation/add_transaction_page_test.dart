import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/presentation/add_transaction/add_transaction_controller.dart';
import 'package:tien_day/presentation/add_transaction/add_transaction_page.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/home/home_page.dart';
import 'package:tien_day/presentation/theme/app_typography.dart';

import '../support/memory_transaction_repository.dart';
import '../support/memory_transaction_catalog_repository.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding.zero;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
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
        catalogController: buildTestCatalogController(),
        clock: () => DateTime(2026, 8, 18, 9, 15),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openAdd(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('fab-add')));
  await tester.pumpAndSettle();
  tester.view.viewInsets = FakeViewPadding.zero;
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _scrollAddTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find
        .descendant(
          of: find.byType(AddTransactionPage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
}

void main() {
  setUpAll(() {});

  testWidgets('FAB opens Add Transaction sheet', (tester) async {
    _phone(tester);
    await _pumpHome(
      tester,
      service: TransactionService(MemoryTransactionRepository()),
    );

    await _openAdd(tester);

    expect(find.text('Thêm giao dịch'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Thêm giao dịch'));
    expect(title.style?.fontSize, AppTypography.screenTitleSize);
    expect(title.style?.fontWeight, AppTypography.extraWeight);
    expect(find.text('Số tiền'), findsOneWidget);
    expect(find.text('10k'), findsOneWidget);
    expect(find.text('200k'), findsOneWidget);
    expect(find.text('Chi cho'), findsOneWidget);
    expect(find.text('Chi tiết'), findsOneWidget);
    await _scrollAddTo(tester, find.text('Thanh toán bằng'));
    expect(find.text('Thanh toán bằng'), findsOneWidget);
    expect(find.text('Lưu giao dịch'), findsOneWidget);
    final save = tester.widget<FilledButton>(
      find.byKey(const Key('btn-save-tx')),
    );
    expect(
      save.style?.textStyle?.resolve(const {})?.fontWeight,
      AppTypography.extraWeight,
    );
    expect(find.text('Cafe'), findsWidgets);
  });

  testWidgets('invalid amount cannot save and stays on the sheet', (
    tester,
  ) async {
    _phone(tester);
    await _pumpHome(
      tester,
      service: TransactionService(MemoryTransactionRepository()),
    );

    await _openAdd(tester);
    await tester.tap(find.byKey(const Key('btn-save-tx')));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập số tiền'), findsOneWidget);
    expect(find.text('Thêm giao dịch'), findsOneWidget);
  });

  testWidgets('shortcut save returns to Home with the new transaction', (
    tester,
  ) async {
    _phone(tester);
    await _pumpHome(
      tester,
      service: TransactionService(MemoryTransactionRepository()),
    );

    await _openAdd(tester);
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

  testWidgets('manual amount, category, payment, and note persist', (
    tester,
  ) async {
    _phone(tester);
    final repo = MemoryTransactionRepository();
    await _pumpHome(tester, service: TransactionService(repo));

    await _openAdd(tester);

    await tester.enterText(find.byKey(const Key('input-amount')), '25000');
    await tester.pump();
    expect(find.text('25.000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chi-cho-transport')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grab'));
    await tester.pumpAndSettle();

    await _scrollAddTo(tester, find.byKey(const Key('pay-select')));
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

  testWidgets('persistence failure keeps the sheet and the entered amount', (
    tester,
  ) async {
    _phone(tester);
    await _pumpHome(
      tester,
      service: TransactionService(
        MemoryTransactionRepository(failCreate: true),
      ),
    );

    await _openAdd(tester);
    await tester.tap(find.byKey(const Key('quick-amt-200000')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('btn-save-tx')));
    await tester.tap(find.byKey(const Key('btn-save-tx')));
    await tester.pumpAndSettle();

    expect(find.text('Không lưu được giao dịch. Thử lại.'), findsOneWidget);
    expect(find.text('Thêm giao dịch'), findsOneWidget);
    expect(find.text('200.000'), findsOneWidget);
  });

  testWidgets('manage links add category, detail, and payment options', (
    tester,
  ) async {
    _phone(tester);
    final repository = MemoryTransactionRepository();
    final catalog = buildTestCatalogController();
    final controller = AddTransactionController(
      service: TransactionService(repository),
      catalogController: catalog,
      clock: () => DateTime(2026, 8, 19, 9),
    );
    await tester.pumpWidget(
      MaterialApp(home: AddTransactionPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage-categories')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-category')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-name-input')),
      'Thú cưng',
    );
    await tester.tap(find.byKey(const Key('save-catalog-item')));
    await tester.pumpAndSettle();
    expect(find.text('Thú cưng'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();

    final category = catalog.categories.singleWhere(
      (item) => item.name == 'Thú cưng',
    );
    expect(find.byKey(Key('chi-cho-${category.id}')), findsOneWidget);
    await tester.tap(find.byKey(Key('chi-cho-${category.id}')));
    await tester.tap(find.byKey(const Key('manage-details')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-detail')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('detail-name-input')), 'Hạt');
    await tester.tap(find.byKey(const Key('save-catalog-item')));
    await tester.pumpAndSettle();
    expect(find.text('Hạt'), findsWidgets);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage-payments')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-payment')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('payment-name-input')),
      'Ví gia đình',
    );
    await tester.tap(find.byKey(const Key('save-catalog-item')));
    await tester.pumpAndSettle();
    expect(find.text('Ví gia đình'), findsWidgets);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();

    final payment = catalog.payments.singleWhere(
      (item) => item.source.name == 'Ví gia đình',
    );
    controller.applyShortcut(50000);
    controller.toggleDetail('Hạt');
    controller.selectPayment(payment.source.id);
    expect((await controller.save()).isOk, isTrue);
    expect(repository.items.single.categoryId, category.id);
    expect(repository.items.single.detail, 'Hạt');
    expect(repository.items.single.paymentSourceName, 'Ví gia đình');
  });
}
