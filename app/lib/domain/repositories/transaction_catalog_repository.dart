import '../catalog/transaction_catalog.dart';
import '../failures/result.dart';

abstract class TransactionCatalogRepository {
  Future<Result<TransactionCatalog?>> load();

  Future<Result<void>> save(TransactionCatalog catalog);
}
