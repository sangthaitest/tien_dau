import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/transaction_catalog_service.dart';
import 'package:tien_day/domain/catalog/chi_cho_catalog.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/domain/failures/result.dart';

import '../support/memory_transaction_catalog_repository.dart';

void main() {
  test('category, detail, and payment changes survive reload', () async {
    final repository = MemoryTransactionCatalogRepository();
    var nextId = 0;
    final service = TransactionCatalogService(
      repository,
      idFactory: () => '${nextId++}',
    );

    var catalog = (await service.load()).unwrapOrThrow();
    expect(catalog.categories, isNotEmpty);
    expect(catalog.payments, isNotEmpty);

    catalog = (await service.addCategory(
      catalog,
      name: 'Thú cưng',
      visualKey: 'other',
    )).unwrapOrThrow();
    final category = catalog.categories.last;

    catalog = (await service.addDetail(
      catalog,
      categoryId: category.id,
      name: 'Hạt',
    )).unwrapOrThrow();
    catalog = (await service.addPayment(
      catalog,
      name: 'Ví gia đình',
      method: PaymentMethodKind.eWallet,
      typeLabel: 'Ví điện tử',
    )).unwrapOrThrow();

    final reloaded = (await service.load()).unwrapOrThrow();
    expect(
      reloaded.categories.singleWhere((item) => item.id == category.id).details,
      contains('Hạt'),
    );
    expect(
      reloaded.payments.map((item) => item.source.name),
      contains('Ví gia đình'),
    );
  });

  test(
    'archive hides an option without removing its stored identity',
    () async {
      final service = TransactionCatalogService(
        MemoryTransactionCatalogRepository(),
        idFactory: () => 'new',
      );
      var catalog = (await service.load()).unwrapOrThrow();

      catalog = (await service.archiveCategory(
        catalog,
        'market',
      )).unwrapOrThrow();
      catalog = (await service.archivePayment(catalog, 'cash')).unwrapOrThrow();

      expect(
        catalog.categories.singleWhere((item) => item.id == 'market').archived,
        isTrue,
      );
      expect(
        catalog.payments
            .singleWhere((item) => item.source.id == 'cash')
            .archived,
        isTrue,
      );
    },
  );

  test('duplicate names are rejected case-insensitively', () async {
    final service = TransactionCatalogService(
      MemoryTransactionCatalogRepository(),
      idFactory: () => 'new',
    );
    final catalog = (await service.load()).unwrapOrThrow();

    expect(
      await service.addCategory(catalog, name: '  cafe ', visualKey: 'cafe'),
      isA<Err>(),
    );
    expect(
      await service.addPayment(
        catalog,
        name: 'momo',
        method: PaymentMethodKind.eWallet,
        typeLabel: 'Ví điện tử',
      ),
      isA<Err>(),
    );
  });

  test('catalog lists can be reordered and kept after reload', () async {
    final service = TransactionCatalogService(
      MemoryTransactionCatalogRepository(),
      idFactory: () => 'new',
    );
    var catalog = (await service.load()).unwrapOrThrow();
    final first = catalog.categories.firstWhere((item) => !item.archived);
    final second = catalog.categories.where((item) => !item.archived).elementAt(1);

    catalog = (await service.reorderCategories(
      catalog,
      from: 0,
      to: 1,
    )).unwrapOrThrow();
    final visible = catalog.categories.where((item) => !item.archived).toList();
    expect(visible[0].id, second.id);
    expect(visible[1].id, first.id);

    catalog = (await service.reorderDetails(
      catalog,
      categoryId: first.id,
      from: 0,
      to: 1,
    )).unwrapOrThrow();
    final details = catalog.categories
        .singleWhere((item) => item.id == first.id)
        .details;
    expect(details[1], ChiChoCatalog.byId(first.id).details.first);

    catalog = (await service.reorderPayments(
      catalog,
      from: 0,
      to: 1,
    )).unwrapOrThrow();
    final payments = catalog.payments.where((item) => !item.archived).toList();
    expect(payments.first.source.id, 'vcb');

    final reloaded = (await service.load()).unwrapOrThrow();
    expect(
      reloaded.categories.where((item) => !item.archived).first.id,
      second.id,
    );
  });
}
