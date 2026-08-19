import 'transaction_service.dart';
import '../domain/entities/transaction.dart';
import '../domain/entities/transaction_query.dart';
import '../domain/entities/transaction_type.dart';
import '../domain/failures/result.dart';

class HomeSnapshot {
  const HomeSnapshot({
    required this.month,
    required this.monthExpense,
    required this.recent,
  });

  final DateTime month;
  final int monthExpense;
  final List<Transaction> recent;
}

/// Builds Home numbers from the transaction repository. No salary/budget/savings.
class HomeQuery {
  HomeQuery(this._service, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TransactionService _service;
  final DateTime Function() _clock;

  static const recentLimit = 3;

  Future<Result<HomeSnapshot>> load() async {
    final now = _clock();
    final month = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final result = await _service.query(
      TransactionQuerySpec(
        fromInclusive: month,
        toExclusive: nextMonth,
        type: TransactionType.expense,
        limit: recentLimit,
      ),
    );
    return switch (result) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => Ok(
        HomeSnapshot(
          month: month,
          monthExpense: value.expenseSum,
          recent: value.items,
        ),
      ),
    };
  }
}
