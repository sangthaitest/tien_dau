import 'package:tien_day/application/transaction_catalog_service.dart';
import 'package:tien_day/domain/catalog/transaction_catalog.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/domain/repositories/transaction_catalog_repository.dart';
import 'package:tien_day/presentation/catalog/transaction_catalog_controller.dart';

class MemoryTransactionCatalogRepository
    implements TransactionCatalogRepository {
  MemoryTransactionCatalogRepository({TransactionCatalog? initial})
    : value = initial;

  TransactionCatalog? value;

  @override
  Future<Result<TransactionCatalog?>> load() async => Ok(value);

  @override
  Future<Result<void>> save(TransactionCatalog catalog) async {
    value = catalog;
    return const Ok(null);
  }
}

TransactionCatalogController buildTestCatalogController({
  MemoryTransactionCatalogRepository? repository,
}) {
  var nextId = 0;
  return TransactionCatalogController(
    TransactionCatalogService(
      repository ?? MemoryTransactionCatalogRepository(),
      idFactory: () => 'catalog-${nextId++}',
    ),
  );
}
