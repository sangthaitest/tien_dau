import 'package:tien_day/domain/entities/new_transaction.dart';
import 'package:tien_day/domain/entities/transaction.dart';
import 'package:tien_day/domain/entities/transaction_query.dart';
import 'package:tien_day/domain/entities/transaction_type.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/domain/repositories/transaction_repository.dart';
import 'package:tien_day/domain/validation/transaction_validator.dart';

class MemoryTransactionRepository implements TransactionRepository {
  MemoryTransactionRepository({
    List<Transaction>? seed,
    this.failCreate = false,
    this.failList = false,
  }) : _items = [...?seed];

  final List<Transaction> _items;
  bool failCreate;
  bool failList;

  List<Transaction> get items => List.unmodifiable(_items);

  @override
  Future<Result<Transaction>> create(NewTransaction input) async {
    if (failCreate) {
      return const Err(PersistenceFailure('write failed'));
    }
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
  Future<Result<TransactionPage>> query(TransactionQuerySpec spec) async {
    if (failList) {
      return const Err(PersistenceFailure('read failed'));
    }
    final filtered = _items.where((tx) => _matches(tx, spec)).toList()
      ..sort(_byRecency);
    final expenseSum = spec.includeExpenseSum
        ? _items
              .where(
                (tx) =>
                    tx.type == TransactionType.expense &&
                    _matches(
                      tx,
                      TransactionQuerySpec(
                        fromInclusive: spec.fromInclusive,
                        toExclusive: spec.toExclusive,
                        type: TransactionType.expense,
                        categoryId: spec.categoryId,
                      ),
                    ),
              )
              .fold<int>(0, (sum, tx) => sum + tx.amount)
        : 0;
    final end = (spec.offset + spec.limit).clamp(0, filtered.length);
    final items = spec.offset >= filtered.length
        ? const <Transaction>[]
        : filtered.sublist(spec.offset, end);
    return Ok(
      TransactionPage(
        items: items,
        expenseSum: expenseSum,
        hasMore: end < filtered.length,
      ),
    );
  }

  @override
  Future<Result<ExpenseSummary>> summarizeExpenses({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    if (failList) {
      return const Err(PersistenceFailure('read failed'));
    }
    final byCategory = <String, int>{};
    for (final tx in _items) {
      if (tx.type != TransactionType.expense ||
          tx.occurredOn.isBefore(fromInclusive) ||
          !tx.occurredOn.isBefore(toExclusive)) {
        continue;
      }
      byCategory[tx.categoryId] = (byCategory[tx.categoryId] ?? 0) + tx.amount;
    }
    return Ok(
      ExpenseSummary(
        total: byCategory.values.fold(0, (sum, amount) => sum + amount),
        byCategory: byCategory,
      ),
    );
  }

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

  bool _matches(Transaction tx, TransactionQuerySpec spec) {
    if (spec.fromInclusive != null &&
        tx.occurredOn.isBefore(spec.fromInclusive!)) {
      return false;
    }
    if (spec.toExclusive != null &&
        !tx.occurredOn.isBefore(spec.toExclusive!)) {
      return false;
    }
    if (spec.type != null && tx.type != spec.type) return false;
    if (spec.categoryId != null && tx.categoryId != spec.categoryId) {
      return false;
    }
    return true;
  }

  int _byRecency(Transaction a, Transaction b) {
    final date = b.occurredOn.compareTo(a.occurredOn);
    if (date != 0) return date;
    return (b.occurredTime ?? '').compareTo(a.occurredTime ?? '');
  }
}
