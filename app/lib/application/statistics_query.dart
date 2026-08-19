import '../domain/entities/transaction.dart';
import '../domain/entities/transaction_query.dart';
import '../domain/entities/transaction_type.dart';
import '../domain/failures/result.dart';
import '../domain/time/clock_format.dart';
import 'transaction_service.dart';

class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.amount,
    required this.percent,
  });

  final String categoryId;
  final int amount;
  final int percent;
}

class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.month,
    required this.totalExpense,
    required this.previousExpense,
    required this.deltaPercent,
    required this.categories,
  });

  final DateTime month;
  final int totalExpense;
  final int previousExpense;
  final int deltaPercent;
  final List<CategorySpend> categories;

  static const topLimit = 5;

  List<CategorySpend> get topCategories =>
      categories.take(topLimit).toList(growable: false);

  bool get isEmpty => categories.isEmpty;
}

/// Builds V3 month statistics from one transaction list fetch.
/// Expenses only. No salary, budget, or savings.
class StatisticsQuery {
  StatisticsQuery(this._service, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TransactionService _service;
  final DateTime Function() _clock;

  Future<Result<StatisticsSnapshot>> load({DateTime? month}) async {
    final currentMonth = monthStart(month ?? _clock());
    final previousMonth = previousMonthStart(currentMonth);
    final current = await _service.summarizeExpenses(
      fromInclusive: currentMonth,
      toExclusive: DateTime(currentMonth.year, currentMonth.month + 1),
    );
    if (current case Err(:final failure)) return Err(failure);

    final previous = await _service.summarizeExpenses(
      fromInclusive: previousMonth,
      toExclusive: currentMonth,
    );
    if (previous case Err(:final failure)) return Err(failure);

    return Ok(
      _buildFromSummaries(
        month: currentMonth,
        current: (current as Ok<ExpenseSummary>).value,
        previous: (previous as Ok<ExpenseSummary>).value,
      ),
    );
  }

  StatisticsSnapshot build(List<Transaction> all, DateTime now) {
    final month = monthStart(now);
    final previous = previousMonthStart(month);
    final currentTotal = _expenseInMonth(all, month);
    final previousTotal = _expenseInMonth(all, previous);
    return StatisticsSnapshot(
      month: month,
      totalExpense: currentTotal,
      previousExpense: previousTotal,
      deltaPercent: deltaPercent(
        current: currentTotal,
        previous: previousTotal,
      ),
      categories: _categories(all, month, currentTotal),
    );
  }

  StatisticsSnapshot _buildFromSummaries({
    required DateTime month,
    required ExpenseSummary current,
    required ExpenseSummary previous,
  }) {
    final categories =
        [
          for (final entry in current.byCategory.entries)
            CategorySpend(
              categoryId: entry.key,
              amount: entry.value,
              percent: percentOf(entry.value, current.total),
            ),
        ]..sort((a, b) {
          final byAmount = b.amount.compareTo(a.amount);
          if (byAmount != 0) return byAmount;
          return a.categoryId.compareTo(b.categoryId);
        });
    return StatisticsSnapshot(
      month: month,
      totalExpense: current.total,
      previousExpense: previous.total,
      deltaPercent: deltaPercent(
        current: current.total,
        previous: previous.total,
      ),
      categories: categories,
    );
  }

  static int percentOf(int amount, int total) {
    if (total <= 0 || amount <= 0) return 0;
    return ((amount / total) * 100).round();
  }

  static int deltaPercent({required int current, required int previous}) {
    if (previous > 0) {
      return (((current - previous) / previous) * 100).round();
    }
    if (current > 0) return 100;
    return 0;
  }

  int _expenseInMonth(List<Transaction> all, DateTime month) {
    return all
        .where((tx) => _isExpenseInMonth(tx, month))
        .fold<int>(0, (sum, tx) => sum + tx.amount);
  }

  List<CategorySpend> _categories(
    List<Transaction> all,
    DateTime month,
    int total,
  ) {
    final sums = <String, int>{};
    for (final tx in all) {
      if (!_isExpenseInMonth(tx, month)) continue;
      sums[tx.categoryId] = (sums[tx.categoryId] ?? 0) + tx.amount;
    }
    final rows =
        [
          for (final entry in sums.entries)
            CategorySpend(
              categoryId: entry.key,
              amount: entry.value,
              percent: percentOf(entry.value, total),
            ),
        ]..sort((a, b) {
          final byAmount = b.amount.compareTo(a.amount);
          if (byAmount != 0) return byAmount;
          return a.categoryId.compareTo(b.categoryId);
        });
    return rows;
  }

  bool _isExpenseInMonth(Transaction tx, DateTime month) {
    return tx.type == TransactionType.expense && inMonth(tx.occurredOn, month);
  }
}
