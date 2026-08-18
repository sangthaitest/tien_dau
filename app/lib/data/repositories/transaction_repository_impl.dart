import '../../domain/entities/new_transaction.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/validation/transaction_validator.dart';
import '../datasources/transaction_local_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required TransactionLocalDataSource local,
    required String Function() idFactory,
    required DateTime Function() clock,
  })  : _local = local,
        _idFactory = idFactory,
        _clock = clock;

  final TransactionLocalDataSource _local;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  @override
  Future<Result<Transaction>> create(NewTransaction input) async {
    final invalid = validateNewTransaction(input);
    if (invalid != null) return Err(invalid);

    final now = _clock().toUtc();
    final tx = Transaction(
      id: _idFactory(),
      amount: input.amount,
      type: input.type,
      categoryId: input.categoryId.trim(),
      detail: _emptyToNull(input.detail),
      occurredOn: DateTime(input.occurredOn.year, input.occurredOn.month, input.occurredOn.day),
      occurredTime: _emptyToNull(input.occurredTime),
      paymentSourceId: input.paymentSourceId.trim(),
      paymentSourceName: input.paymentSourceName.trim(),
      paymentMethod: input.paymentMethod,
      note: _emptyToNull(input.note),
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _local.insert(tx);
      return Ok(tx);
    } on PersistenceFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(PersistenceFailure('Failed to create transaction', cause: e));
    }
  }

  @override
  Future<Result<Transaction>> getById(String id) async {
    try {
      final found = await _local.findById(id);
      if (found == null) {
        return const Err(NotFoundFailure('Transaction not found'));
      }
      return Ok(found);
    } on PersistenceFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(PersistenceFailure('Failed to read transaction', cause: e));
    }
  }

  @override
  Future<Result<List<Transaction>>> getAll() async {
    try {
      return Ok(await _local.findAll());
    } on PersistenceFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(PersistenceFailure('Failed to list transactions', cause: e));
    }
  }

  @override
  Future<Result<Transaction>> update(Transaction transaction) async {
    final invalid = validateTransaction(transaction);
    if (invalid != null) return Err(invalid);

    final existing = await getById(transaction.id);
    if (existing is Err<Transaction>) return existing;

    final next = transaction.copyWith(updatedAt: _clock().toUtc());
    try {
      final changed = await _local.update(next);
      if (changed == 0) {
        return const Err(NotFoundFailure('Transaction not found'));
      }
      return Ok(next);
    } on PersistenceFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(PersistenceFailure('Failed to update transaction', cause: e));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final changed = await _local.delete(id);
      if (changed == 0) {
        return const Err(NotFoundFailure('Transaction not found'));
      }
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    } catch (e) {
      return Err(PersistenceFailure('Failed to delete transaction', cause: e));
    }
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
