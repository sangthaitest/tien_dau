import 'transaction.dart';
import 'transaction_type.dart';

class TransactionQuerySpec {
  const TransactionQuerySpec({
    this.fromInclusive,
    this.toExclusive,
    this.type,
    this.categoryId,
    this.limit = 50,
    this.offset = 0,
    this.includeExpenseSum = true,
  }) : assert(limit > 0),
       assert(offset >= 0);

  final DateTime? fromInclusive;
  final DateTime? toExclusive;
  final TransactionType? type;
  final String? categoryId;
  final int limit;
  final int offset;
  final bool includeExpenseSum;
}

class TransactionPage {
  const TransactionPage({
    required this.items,
    required this.expenseSum,
    required this.hasMore,
  });

  final List<Transaction> items;
  final int expenseSum;
  final bool hasMore;
}

class ExpenseSummary {
  const ExpenseSummary({required this.total, required this.byCategory});

  final int total;
  final Map<String, int> byCategory;
}
