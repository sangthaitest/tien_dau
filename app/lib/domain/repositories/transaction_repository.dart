import '../entities/new_transaction.dart';
import '../entities/transaction.dart';
import '../failures/result.dart';

abstract class TransactionRepository {
  Future<Result<Transaction>> create(NewTransaction input);

  Future<Result<Transaction>> getById(String id);

  Future<Result<List<Transaction>>> getAll();

  Future<Result<Transaction>> update(Transaction transaction);

  Future<Result<void>> delete(String id);
}
