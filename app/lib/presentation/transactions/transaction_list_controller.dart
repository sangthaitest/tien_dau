import 'package:flutter/foundation.dart';

import '../../application/transaction_list_query.dart';
import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';

class TransactionListController extends ChangeNotifier {
  TransactionListController(
    this._service, {
    DateTime Function()? clock,
    TransactionListQuery query = const TransactionListQuery(),
  }) : _clock = clock ?? DateTime.now,
       _query = query;

  final TransactionService _service;
  final DateTime Function() _clock;
  final TransactionListQuery _query;

  static const pageSize = 50;

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = false;
  String? error;
  TransactionListFilter filter = const TransactionListFilter();
  TransactionListSnapshot snapshot = const TransactionListSnapshot(
    expenseSum: 0,
    groups: [],
    filter: TransactionListFilter(),
  );

  List<Transaction> _loaded = [];
  int _expenseSum = 0;
  int _requestGeneration = 0;

  Future<void> load() async {
    await _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    final generation = ++_requestGeneration;
    loading = true;
    loadingMore = false;
    error = null;
    notifyListeners();

    final result = await _service.query(_spec(offset: 0));
    if (generation != _requestGeneration) return;
    switch (result) {
      case Ok(:final value):
        _loaded = value.items;
        _expenseSum = value.expenseSum;
        hasMore = value.hasMore;
        error = null;
        _rebuild();
      case Err(:final failure):
        error = failure.message;
        _loaded = [];
        _expenseSum = 0;
        hasMore = false;
        snapshot = TransactionListSnapshot(
          expenseSum: 0,
          groups: const [],
          filter: filter,
        );
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final generation = _requestGeneration;
    loadingMore = true;
    notifyListeners();
    final result = await _service.query(_spec(offset: _loaded.length));
    if (generation != _requestGeneration) return;
    switch (result) {
      case Ok(:final value):
        _loaded = [..._loaded, ...value.items];
        hasMore = value.hasMore;
        error = null;
        _rebuild();
      case Err(:final failure):
        error = failure.message;
    }
    loadingMore = false;
    notifyListeners();
  }

  Future<void> setDateFilter(TxDateFilter date) async {
    filter = filter.copyWith(date: date);
    await _loadFirstPage();
  }

  Future<void> setTypeFilter(TxTypeFilter type) async {
    filter = filter.copyWith(type: type);
    await _loadFirstPage();
  }

  Future<void> setCategory(String categoryId) async {
    filter = filter.copyWith(categoryId: categoryId);
    await _loadFirstPage();
  }

  Future<void> setCustomFrom(DateTime value) async {
    filter = filter.copyWith(
      date: TxDateFilter.custom,
      customFrom: dateOnly(value),
    );
    await _loadFirstPage();
  }

  Future<void> setCustomTo(DateTime value) async {
    filter = filter.copyWith(
      date: TxDateFilter.custom,
      customTo: dateOnly(value),
    );
    await _loadFirstPage();
  }

  void _rebuild() {
    snapshot = _query.apply(
      all: _loaded,
      now: _clock(),
      filter: filter,
      expenseSumOverride: _expenseSum,
    );
  }

  TransactionQuerySpec _spec({required int offset}) {
    final now = _clock();
    final currentMonth = monthStart(now);
    DateTime? from;
    DateTime? to;
    switch (filter.date) {
      case TxDateFilter.thisMonth:
        from = currentMonth;
        to = DateTime(currentMonth.year, currentMonth.month + 1);
      case TxDateFilter.lastMonth:
        from = previousMonthStart(currentMonth);
        to = currentMonth;
      case TxDateFilter.custom:
        from = filter.customFrom;
        final customTo = filter.customTo;
        to = customTo == null
            ? null
            : dateOnly(customTo).add(const Duration(days: 1));
    }
    return TransactionQuerySpec(
      fromInclusive: from,
      toExclusive: to,
      type: TransactionType.expense,
      categoryId: filter.categoryId == 'all' ? null : filter.categoryId,
      limit: pageSize,
      offset: offset,
      includeExpenseSum: offset == 0,
    );
  }
}
