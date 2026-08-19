import '../domain/entities/new_transaction.dart';
import '../domain/entities/transaction.dart';
import '../domain/entities/transaction_query.dart';
import '../domain/failures/result.dart';
import '../domain/repositories/transaction_repository.dart';

/// Application layer: single entry for transaction writes so UI never talks to SQLite.
class TransactionService {
  TransactionService(this._repository);

  final TransactionRepository _repository;

  Future<Result<Transaction>> add(NewTransaction input) {
    return _repository.create(input);
  }

  Future<Result<Transaction>> get(String id) {
    return _repository.getById(id);
  }

  Future<Result<TransactionPage>> query(TransactionQuerySpec spec) {
    return _repository.query(spec);
  }

  Future<Result<ExpenseSummary>> summarizeExpenses({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) {
    return _repository.summarizeExpenses(
      fromInclusive: fromInclusive,
      toExclusive: toExclusive,
    );
  }

  Future<Result<Transaction>> update(Transaction transaction) {
    return _repository.update(transaction);
  }

  Future<Result<void>> remove(String id) {
    return _repository.delete(id);
  }
}
