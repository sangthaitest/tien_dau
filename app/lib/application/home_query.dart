import 'transaction_service.dart';
import '../domain/entities/transaction.dart';
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
    final result = await _service.list();
    return switch (result) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => Ok(_build(value, _clock())),
    };
  }

  HomeSnapshot _build(List<Transaction> all, DateTime now) {
    final month = DateTime(now.year, now.month);
    final inMonth = all.where((tx) {
      return tx.type == TransactionType.expense &&
          tx.occurredOn.year == month.year &&
          tx.occurredOn.month == month.month;
    }).toList()
      ..sort(_byRecency);

    final spend = inMonth.fold<int>(0, (sum, tx) => sum + tx.amount);
    final recent = inMonth.take(recentLimit).toList();
    return HomeSnapshot(month: month, monthExpense: spend, recent: recent);
  }

  int _byRecency(Transaction a, Transaction b) {
    final date = b.occurredOn.compareTo(a.occurredOn);
    if (date != 0) return date;
    return (b.occurredTime ?? '').compareTo(a.occurredTime ?? '');
  }
}
