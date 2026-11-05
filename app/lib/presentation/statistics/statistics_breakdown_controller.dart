import 'package:flutter/foundation.dart';

import '../../application/statistics_query.dart';
import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';

/// Expenses in one statistics month for a single category or payment source.
sealed class StatisticsBreakdownFilter {
  const StatisticsBreakdownFilter();

  bool matches(Transaction transaction);
}

class CategoryBreakdownFilter extends StatisticsBreakdownFilter {
  const CategoryBreakdownFilter(this.categoryId);

  final String categoryId;

  @override
  bool matches(Transaction transaction) => transaction.categoryId == categoryId;
}

class PaymentBreakdownFilter extends StatisticsBreakdownFilter {
  const PaymentBreakdownFilter(this.paymentKey);

  final String paymentKey;

  @override
  bool matches(Transaction transaction) =>
      PaymentSpend.keyFor(transaction) == paymentKey;
}

class StatisticsBreakdownRequest {
  const StatisticsBreakdownRequest({
    required this.title,
    required this.month,
    required this.filter,
  });

  final String title;
  final DateTime month;
  final StatisticsBreakdownFilter filter;

  String get token => switch (filter) {
    CategoryBreakdownFilter(:final categoryId) => 'category:$categoryId',
    PaymentBreakdownFilter(:final paymentKey) => 'payment:$paymentKey',
  };
}

class StatisticsBreakdownController extends ChangeNotifier {
  StatisticsBreakdownController({
    required TransactionService service,
    required this.month,
    required this.filter,
  }) : _service = service;

  final TransactionService _service;
  final DateTime month;
  final StatisticsBreakdownFilter filter;

  bool loading = false;
  String? error;
  List<Transaction> transactions = const [];

  int get total =>
      transactions.fold<int>(0, (sum, transaction) => sum + transaction.amount);

  Future<void> load() async {
    final showSpinner = transactions.isEmpty;
    if (showSpinner) {
      loading = true;
      error = null;
      notifyListeners();
    }

    final loaded = await _expensesInMonth();
    switch (loaded) {
      case Err(:final failure):
        error = failure.message;
        transactions = const [];
      case Ok(:final value):
        error = null;
        final matched = [
          for (final transaction in value)
            if (filter.matches(transaction)) transaction,
        ]..sort(_newestFirst);
        transactions = List.unmodifiable(matched);
    }
    loading = false;
    notifyListeners();
  }

  Future<Result<List<Transaction>>> _expensesInMonth() async {
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

int _newestFirst(Transaction a, Transaction b) {
  final date = b.occurredOn.compareTo(a.occurredOn);
  if (date != 0) return date;
  final time = (b.occurredTime ?? '').compareTo(a.occurredTime ?? '');
  if (time != 0) return time;
  return b.createdAt.compareTo(a.createdAt);
}
