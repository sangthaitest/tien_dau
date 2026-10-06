import '../entities/recurring_month_entry.dart';
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

  Future<Result<List<RecurringMonthEntry>>> listMonthEntries(String monthKey);

  /// Insert or replace the snapshot for one template and one month.
  Future<Result<void>> saveMonthEntry(RecurringMonthEntry entry);

  /// Removes one month snapshot. Does not delete the template or other months.
  Future<Result<void>> deleteMonthEntry({
    required String templateId,
    required String monthKey,
  });

  /// Removes every month snapshot for [templateId]. Does not delete the template.
  Future<Result<void>> deleteMonthEntries(String templateId);
}
