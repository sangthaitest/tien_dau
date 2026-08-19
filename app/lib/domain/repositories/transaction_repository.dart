import '../entities/new_transaction.dart';
import '../entities/transaction.dart';
import '../entities/transaction_query.dart';
import '../failures/result.dart';

abstract class TransactionRepository {
  Future<Result<Transaction>> create(NewTransaction input);

  Future<Result<Transaction>> getById(String id);

  Future<Result<TransactionPage>> query(TransactionQuerySpec spec);

  Future<Result<ExpenseSummary>> summarizeExpenses({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  });

  Future<Result<Transaction>> update(Transaction transaction);

  Future<Result<void>> delete(String id);
}
