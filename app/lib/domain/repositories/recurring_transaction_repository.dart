import '../entities/recurring_transaction.dart';
import '../failures/result.dart';

abstract class RecurringTransactionRepository {
  Future<Result<List<RecurringTransaction>>> listAll();

  Future<Result<RecurringTransaction?>> findById(String id);

  Future<Result<RecurringTransaction>> create(RecurringTransaction rule);

  Future<Result<RecurringTransaction>> update(RecurringTransaction rule);

  /// Insert or UPDATE `recurring_salary`. Never assigns a new id.
  Future<Result<RecurringTransaction>> replaceSalary(RecurringTransaction row);

  Future<Result<void>> delete(String id);
}
