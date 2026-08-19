import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/data/datasources/finance_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/repositories/transaction_catalog_repository_impl.dart';
import 'package:tien_day/domain/catalog/chi_cho_catalog.dart';
import 'package:tien_day/domain/catalog/transaction_catalog.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('catalog is serialized to and restored from SQLite prefs', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_catalog');
    final database = await AppDatabase.openPath(p.join(dir.path, 'catalog.db'));
    final repository = TransactionCatalogRepositoryImpl(
      PrefsLocalDataSource(database),
    );
    final catalog = TransactionCatalog.defaults().copyWith(
      categories: [
        ...ChiChoCatalog.all,
        const ChiChoCategory(
          id: 'pet',
          name: 'Thú cưng',
          details: ['Hạt', 'Khám bệnh'],
          visualKey: 'other',
        ),
      ],
    );

    expect((await repository.save(catalog)).isOk, isTrue);
    final restored = (await repository.load()).unwrapOrThrow()!;

    expect(restored.categories.last.id, 'pet');
    expect(restored.categories.last.details, ['Hạt', 'Khám bệnh']);
    expect(restored.payments.length, catalog.payments.length);

    await database.close();
    await dir.delete(recursive: true);
  });
}
