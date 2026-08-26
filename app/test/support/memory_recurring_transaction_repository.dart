import 'package:tien_day/data/db/migrations/recurring_transactions.dart';
import 'package:tien_day/domain/entities/recurring_transaction.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/domain/repositories/recurring_transaction_repository.dart';

class MemoryRecurringTransactionRepository
    implements RecurringTransactionRepository {
  final Map<String, RecurringTransaction> _items = {};

  @override
  Future<Result<List<RecurringTransaction>>> listAll() async {
    return Ok(_items.values.toList(growable: false));
  }

  @override
  Future<Result<RecurringTransaction?>> findById(String id) async {
    return Ok(_items[id]);
  }

  @override
  Future<Result<RecurringTransaction>> create(RecurringTransaction rule) async {
    if (rule.id == recurringSalaryId) {
      return const Err(ValidationFailure('Không tạo thêm dòng Lương'));
    }
    _items[rule.id] = rule;
    return Ok(rule);
  }

  @override
  Future<Result<RecurringTransaction>> update(RecurringTransaction rule) async {
    if (rule.id == recurringSalaryId) {
      return const Err(ValidationFailure('Sửa lương ở thẻ Lương'));
    }
    if (!_items.containsKey(rule.id)) {
      return const Err(NotFoundFailure('Không tìm thấy khoản định kỳ'));
    }
    _items[rule.id] = rule;
    return Ok(rule);
  }

  @override
  Future<Result<RecurringTransaction>> replaceSalary(
    RecurringTransaction row,
  ) async {
    if (row.id != recurringSalaryId) {
      return const Err(ValidationFailure('Invalid salary id.'));
    }
    _items[row.id] = row;
    return Ok(row);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (id == recurringSalaryId) {
      return const Err(ValidationFailure('Không xóa Lương khỏi khoản định kỳ'));
    }
    if (_items.remove(id) == null) {
      return const Err(NotFoundFailure('Không tìm thấy khoản định kỳ'));
    }
    return const Ok(null);
  }
}
