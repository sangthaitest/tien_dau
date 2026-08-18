import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/domain/repositories/transaction_repository.dart';
import 'package:tien_day/domain/validation/transaction_validator.dart';

class MemoryTransactionRepository implements TransactionRepository {
  MemoryTransactionRepository({List<Transaction>? seed}) : _items = [...?seed];

  final List<Transaction> _items;

  @override
  Future<Result<Transaction>> create(NewTransaction input) async {
    final invalid = validateNewTransaction(input);
    if (invalid != null) return Err(invalid);
    final now = DateTime.utc(2026, 8, 18);
    final tx = Transaction(
      id: 'mem-${_items.length + 1}',
      amount: input.amount,
      type: input.type,
      categoryId: input.categoryId,
      detail: input.detail,
      occurredOn: input.occurredOn,
      occurredTime: input.occurredTime,
      paymentSourceId: input.paymentSourceId,
      paymentSourceName: input.paymentSourceName,
      paymentMethod: input.paymentMethod,
      note: input.note,
      createdAt: now,
      updatedAt: now,
    );
    _items.add(tx);
    return Ok(tx);
  }

  @override
  Future<Result<void>> delete(String id) async {
    final before = _items.length;
    _items.removeWhere((e) => e.id == id);
    if (_items.length == before) {
      return const Err(NotFoundFailure('Transaction not found'));
    }
    return const Ok(null);
  }

  @override
  Future<Result<List<Transaction>>> getAll() async => Ok(List.of(_items));

  @override
  Future<Result<Transaction>> getById(String id) async {
    for (final tx in _items) {
      if (tx.id == id) return Ok(tx);
    }
    return const Err(NotFoundFailure('Transaction not found'));
  }

  @override
  Future<Result<Transaction>> update(Transaction transaction) async {
    final i = _items.indexWhere((e) => e.id == transaction.id);
    if (i < 0) return const Err(NotFoundFailure('Transaction not found'));
    _items[i] = transaction;
    return Ok(transaction);
  }
}
