import '../domain/entities/payment_method_kind.dart';
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
    this.transactions = const [],
  });

  final String categoryId;
  final int amount;
  final int percent;
  final List<Transaction> transactions;
}

/// One stored payment source in the viewed month.
///
/// Grouped by the source id, name, and method saved on each expense.
/// A blank source stays blank and is never folded into Tiền mặt.
class PaymentSpend {
  const PaymentSpend({
    required this.key,
    required this.sourceId,
    required this.name,
    required this.method,
    required this.amount,
    required this.percent,
    required this.transactions,
  });

  static const missingLabel = 'Chưa có phương thức';

  final String key;
  final String sourceId;
  final String name;
  final PaymentMethodKind method;
  final int amount;
  final int percent;
  final List<Transaction> transactions;

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return missingLabel;
    return trimmed;
  }

  /// Stable token safe to use in widget keys.
  String get token => key.replaceAll('\u0000', '|');
}

class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.month,
    required this.totalExpense,
    required this.previousExpense,
    required this.deltaPercent,
    required this.categories,
    this.paymentMethods = const [],
  });

  final DateTime month;
  final int totalExpense;
  final int previousExpense;
  final int deltaPercent;
  final List<CategorySpend> categories;
  final List<PaymentSpend> paymentMethods;

  static const topLimit = 5;

  List<CategorySpend> get topCategories =>
      categories.take(topLimit).toList(growable: false);

  int get maxPaymentAmount {
    var maxAmount = 0;
    for (final row in paymentMethods) {
      if (row.amount > maxAmount) maxAmount = row.amount;
    }
    return maxAmount;
  }

  bool get isEmpty => categories.isEmpty;
}

/// Builds month statistics from stored expenses.
/// Expenses only. Income is excluded. There is no separate transfer type.
/// Payment rows use the source saved on each expense.
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

    final expenses = await _expensesInMonth(currentMonth);
    if (expenses case Err(:final failure)) return Err(failure);

    return Ok(
      _buildFromSummaries(
        month: currentMonth,
        current: (current as Ok<ExpenseSummary>).value,
        previous: (previous as Ok<ExpenseSummary>).value,
        expenses: (expenses as Ok<List<Transaction>>).value,
      ),
    );
  }

  StatisticsSnapshot build(List<Transaction> all, DateTime now) {
    final month = monthStart(now);
    final previous = previousMonthStart(month);
    final currentTotal = _expenseInMonth(all, month);
    final previousTotal = _expenseInMonth(all, previous);
    final monthExpenses = [
      for (final tx in all)
        if (_isExpenseInMonth(tx, month)) tx,
    ];
    return StatisticsSnapshot(
      month: month,
      totalExpense: currentTotal,
      previousExpense: previousTotal,
      deltaPercent: deltaPercent(
        current: currentTotal,
        previous: previousTotal,
      ),
      categories: _categories(all, month, currentTotal),
      paymentMethods: paymentRows(monthExpenses, currentTotal),
    );
  }

  StatisticsSnapshot _buildFromSummaries({
    required DateTime month,
    required ExpenseSummary current,
    required ExpenseSummary previous,
    required List<Transaction> expenses,
  }) {
    final byCategory = _transactionsByCategory(expenses);
    final categories =
        [
          for (final entry in current.byCategory.entries)
            CategorySpend(
              categoryId: entry.key,
              amount: entry.value,
              percent: percentOf(entry.value, current.total),
              transactions: byCategory[entry.key] ?? const [],
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
      paymentMethods: paymentRows(expenses, current.total),
    );
  }

  /// Expenses grouped by the payment source stored on the transaction.
  /// Duplicate ids are counted once. Income is ignored.
  static List<PaymentSpend> paymentRows(
    List<Transaction> transactions,
    int total,
  ) {
    final seen = <String>{};
    final groups = <String, _PaymentGroup>{};
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (!seen.add(tx.id)) continue;
      final sourceId = tx.paymentSourceId.trim();
      final sourceName = tx.paymentSourceName.trim();
      final key = '$sourceId\u0000$sourceName\u0000${tx.paymentMethod.name}';
      final group = groups.putIfAbsent(
        key,
        () => _PaymentGroup(
          key: key,
          sourceId: sourceId,
          name: sourceName,
          method: tx.paymentMethod,
        ),
      );
      group.amount += tx.amount;
      group.transactions.add(tx);
    }
    final rows =
        [
          for (final group in groups.values)
            PaymentSpend(
              key: group.key,
              sourceId: group.sourceId,
              name: group.name,
              method: group.method,
              amount: group.amount,
              percent: percentOf(group.amount, total),
              transactions: List.unmodifiable(
                group.transactions..sort(_newestFirst),
              ),
            ),
        ]..sort((a, b) {
          final byAmount = b.amount.compareTo(a.amount);
          if (byAmount != 0) return byAmount;
          final byName = a.displayName.compareTo(b.displayName);
          if (byName != 0) return byName;
          return a.key.compareTo(b.key);
        });
    return rows;
  }

  static int percentOf(int amount, int total) {
    if (total <= 0 || amount <= 0) return 0;
    return ((amount / total) * 100).round();
  }

  /// 0 at the start of the track, 1 at the end. Scaled by the largest amount.
  static double markerFraction(int amount, int maxAmount) {
    if (maxAmount <= 0 || amount <= 0) return 0;
    final fraction = amount / maxAmount;
    if (fraction.isNaN || fraction.isInfinite) return 0;
    return fraction.clamp(0.0, 1.0);
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
    final buckets = <String, List<Transaction>>{};
    final seen = <String>{};
    for (final tx in all) {
      if (!_isExpenseInMonth(tx, month)) continue;
      sums[tx.categoryId] = (sums[tx.categoryId] ?? 0) + tx.amount;
      if (!seen.add(tx.id)) continue;
      buckets.putIfAbsent(tx.categoryId, () => []).add(tx);
    }
    final rows =
        [
          for (final entry in sums.entries)
            CategorySpend(
              categoryId: entry.key,
              amount: entry.value,
              percent: percentOf(entry.value, total),
              transactions: _newest(buckets[entry.key] ?? const []),
            ),
        ]..sort((a, b) {
          final byAmount = b.amount.compareTo(a.amount);
          if (byAmount != 0) return byAmount;
          return a.categoryId.compareTo(b.categoryId);
        });
    return rows;
  }

  static Map<String, List<Transaction>> _transactionsByCategory(
    List<Transaction> transactions,
  ) {
    final seen = <String>{};
    final groups = <String, List<Transaction>>{};
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (!seen.add(tx.id)) continue;
      groups.putIfAbsent(tx.categoryId, () => []).add(tx);
    }
    return {
      for (final entry in groups.entries) entry.key: _newest(entry.value),
    };
  }

  static List<Transaction> _newest(List<Transaction> transactions) {
    final copy = [...transactions]..sort(_newestFirst);
    return List.unmodifiable(copy);
  }

  bool _isExpenseInMonth(Transaction tx, DateTime month) {
    return tx.type == TransactionType.expense && inMonth(tx.occurredOn, month);
  }

  Future<Result<List<Transaction>>> _expensesInMonth(DateTime month) async {
    final start = monthStart(month);
    final end = DateTime(start.year, start.month + 1);
    final items = <Transaction>[];
    var offset = 0;
    const pageSize = 200;
    while (true) {
      final page = await _service.query(
        TransactionQuerySpec(
          fromInclusive: start,
          toExclusive: end,
          type: TransactionType.expense,
          limit: pageSize,
          offset: offset,
          includeExpenseSum: false,
        ),
      );
      switch (page) {
        case Err(:final failure):
          return Err(failure);
        case Ok(:final value):
          items.addAll(value.items);
          if (!value.hasMore || value.items.isEmpty) return Ok(items);
          offset += value.items.length;
      }
    }
  }
}

class _PaymentGroup {
  _PaymentGroup({
    required this.key,
    required this.sourceId,
    required this.name,
    required this.method,
  });

  final String key;
  final String sourceId;
  final String name;
  final PaymentMethodKind method;
  var amount = 0;
  final transactions = <Transaction>[];
}

int _newestFirst(Transaction a, Transaction b) {
  final date = b.occurredOn.compareTo(a.occurredOn);
  if (date != 0) return date;
  final time = (b.occurredTime ?? '').compareTo(a.occurredTime ?? '');
  if (time != 0) return time;
  return b.createdAt.compareTo(a.createdAt);
}
