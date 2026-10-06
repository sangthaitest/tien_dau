import '../../domain/entities/recurring_month_entry.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';
import '../datasources/recurring_transaction_local_datasource.dart';
import '../db/migrations/recurring_transactions.dart';

class RecurringTransactionRepositoryImpl
    implements RecurringTransactionRepository {
  RecurringTransactionRepositoryImpl(this._local);

  final RecurringTransactionsLocalDataSource _local;

  @override
  Future<Result<List<RecurringTransaction>>> listAll() async {
    try {
      return Ok(await _local.findAll());
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<RecurringTransaction?>> findById(String id) async {
    try {
      return Ok(await _local.findById(id));
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<RecurringTransaction>> create(RecurringTransaction rule) async {
    try {
      if (rule.id == recurringSalaryId) {
        return const Err(ValidationFailure('Không tạo thêm dòng Lương'));
      }
      await _local.insert(rule);
      return Ok(rule);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<RecurringTransaction>> update(RecurringTransaction rule) async {
    try {
      if (rule.id == recurringSalaryId) {
        return const Err(ValidationFailure('Sửa lương ở thẻ Lương'));
      }
      final changed = await _local.update(rule);
      if (changed == 0) {
        return const Err(NotFoundFailure('Không tìm thấy khoản định kỳ'));
      }
      return Ok(rule);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<RecurringTransaction>> replaceSalary(
    RecurringTransaction row,
  ) async {
    try {
      if (row.id != recurringSalaryId) {
        return const Err(ValidationFailure('Invalid salary id.'));
      }
      await _local.replaceSalary(row);
      return Ok(row);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final changed = await _local.delete(id);
      if (changed == 0) {
        return const Err(NotFoundFailure('Không tìm thấy khoản định kỳ'));
      }
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<List<RecurringMonthEntry>>> listMonthEntries(
    String monthKey,
  ) async {
    try {
      return Ok(await _local.findMonthEntries(monthKey));
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<void>> saveMonthEntry(RecurringMonthEntry entry) async {
    try {
      await _local.saveMonthEntry(entry);
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<void>> deleteMonthEntry({
    required String templateId,
    required String monthKey,
  }) async {
    try {
      await _local.deleteMonthEntry(templateId: templateId, monthKey: monthKey);
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<void>> deleteMonthEntries(String templateId) async {
    try {
      await _local.deleteMonthEntries(templateId);
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }
}
