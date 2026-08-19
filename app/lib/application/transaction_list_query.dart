import '../domain/entities/transaction.dart';
import '../domain/entities/transaction_type.dart';
import '../domain/time/clock_format.dart';

enum TxDateFilter { thisMonth, lastMonth, custom }

enum TxTypeFilter { all, expense }

class TransactionListFilter {
  const TransactionListFilter({
    this.date = TxDateFilter.thisMonth,
    this.type = TxTypeFilter.all,
    this.categoryId = 'all',
    this.customFrom,
    this.customTo,
  });

  final TxDateFilter date;
  final TxTypeFilter type;
  final String categoryId;
  final DateTime? customFrom;
  final DateTime? customTo;

  TransactionListFilter copyWith({
    TxDateFilter? date,
    TxTypeFilter? type,
    String? categoryId,
    DateTime? customFrom,
    DateTime? customTo,
    bool clearCustomFrom = false,
    bool clearCustomTo = false,
  }) {
    return TransactionListFilter(
      date: date ?? this.date,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      customFrom: clearCustomFrom ? null : (customFrom ?? this.customFrom),
      customTo: clearCustomTo ? null : (customTo ?? this.customTo),
    );
  }
}

class TransactionDayGroup {
  const TransactionDayGroup({
    required this.date,
    required this.label,
    required this.dayExpense,
    required this.items,
  });

  final DateTime date;
  final String label;
  final int dayExpense;
  final List<Transaction> items;
}

class TransactionListSnapshot {
  const TransactionListSnapshot({
    required this.expenseSum,
    required this.groups,
    required this.filter,
  });

  final int expenseSum;
  final List<TransactionDayGroup> groups;
  final TransactionListFilter filter;

  List<Transaction> get items => [for (final group in groups) ...group.items];

  bool get isEmpty => items.isEmpty;
}

/// Filters/groups transactions in memory. Callers fetch the list once.
class TransactionListQuery {
  const TransactionListQuery();

  TransactionListSnapshot apply({
    required List<Transaction> all,
    required DateTime now,
    required TransactionListFilter filter,
    DateTime? viewMonth,
    int? expenseSumOverride,
  }) {
    final month = monthStart(viewMonth ?? now);
    final previous = previousMonthStart(month);

    var list = all.where((tx) => tx.type != TransactionType.income).toList();

    switch (filter.date) {
      case TxDateFilter.thisMonth:
        list = list.where((tx) => inMonth(tx.occurredOn, month)).toList();
      case TxDateFilter.lastMonth:
        list = list.where((tx) => inMonth(tx.occurredOn, previous)).toList();
      case TxDateFilter.custom:
        final from = filter.customFrom ?? DateTime(0);
        final to = filter.customTo ?? DateTime(9999, 12, 31);
        list = list.where((tx) {
          final d = dateOnly(tx.occurredOn);
          return !d.isBefore(dateOnly(from)) && !d.isAfter(dateOnly(to));
        }).toList();
    }

    if (filter.type == TxTypeFilter.expense) {
      list = list.where((tx) => tx.type == TransactionType.expense).toList();
    }

    if (filter.categoryId != 'all') {
      list = list.where((tx) => tx.categoryId == filter.categoryId).toList();
    }

    list.sort(_byRecency);

    final expenseSum =
        expenseSumOverride ?? list.fold<int>(0, (sum, tx) => sum + tx.amount);
    final groups = <TransactionDayGroup>[];
    for (final tx in list) {
      final day = dateOnly(tx.occurredOn);
      if (groups.isEmpty || groups.last.date != day) {
        groups.add(
          TransactionDayGroup(
            date: day,
            label: formatDateLabel(day, now),
            dayExpense: 0,
            items: [],
          ),
        );
      }
      final last = groups.last;
      last.items.add(tx);
    }

    final withTotals = [
      for (final group in groups)
        TransactionDayGroup(
          date: group.date,
          label: group.label,
          dayExpense: group.items.fold<int>(0, (sum, tx) => sum + tx.amount),
          items: group.items,
        ),
    ];

    return TransactionListSnapshot(
      expenseSum: expenseSum,
      groups: withTotals,
      filter: filter,
    );
  }

  int _byRecency(Transaction a, Transaction b) {
    final date = b.occurredOn.compareTo(a.occurredOn);
    if (date != 0) return date;
    return (b.occurredTime ?? '').compareTo(a.occurredTime ?? '');
  }
}
