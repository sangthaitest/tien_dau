import '../entities/detail_amount_bucket.dart';
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

  /// Expense amounts already stored for one category, grouped by detail.
  Future<Result<List<DetailAmountBucket>>> detailAmountBuckets(
    String categoryId,
  );

  Future<Result<Transaction>> update(Transaction transaction);

  Future<Result<void>> delete(String id);
}
