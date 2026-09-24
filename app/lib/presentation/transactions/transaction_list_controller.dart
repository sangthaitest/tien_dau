import 'package:flutter/foundation.dart';

import '../../application/transaction_list_query.dart';
import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';

enum TxListMode { day, month }

class TransactionListController extends ChangeNotifier {
  TransactionListController(
    this._service, {
    DateTime Function()? clock,
    DateTime Function()? viewMonth,
    TransactionListQuery query = const TransactionListQuery(),
  }) : _clock = clock ?? DateTime.now,
       _viewMonth = viewMonth,
       _query = query {
    selectedDay = dateOnly(_clock());
    selectedMonth = monthStart(_viewMonth?.call() ?? _clock());
    _syncFilterRange();
  }

  final TransactionService _service;
  final DateTime Function() _clock;
  final DateTime Function()? _viewMonth;
  final TransactionListQuery _query;

  static const pageSize = 50;

  TxListMode mode = TxListMode.day;
  late DateTime selectedDay;
  late DateTime selectedMonth;

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
  bool _awaitingCustomRange = false;

  Future<void> load() async {
    await _loadFirstPage();
  }

  bool get _customRangeIncomplete =>
      _awaitingCustomRange &&
      (filter.customFrom == null || filter.customTo == null);

  Future<void> _loadFirstPage() async {
    if (_customRangeIncomplete) {
      _requestGeneration++;
      loading = false;
      loadingMore = false;
      hasMore = false;
      error = null;
      _loaded = [];
      _expenseSum = 0;
      snapshot = TransactionListSnapshot(
        expenseSum: 0,
        groups: const [],
        filter: filter,
      );
      notifyListeners();
      return;
    }
    final generation = ++_requestGeneration;
    loadingMore = false;
    error = null;
    if (_loaded.isEmpty) {
      loading = true;
      notifyListeners();
    }

    final spec = _spec(offset: 0);
    final result = await _service.query(spec);
    if (generation != _requestGeneration) return;
    switch (result) {
      case Ok(:final value):
        _loaded = value.items;
        _expenseSum = value.expenseSum;
        hasMore = value.hasMore;
        error = null;
        if (mode == TxListMode.month &&
            filter.categoryId != 'all' &&
            spec.fromInclusive != null &&
            spec.toExclusive != null) {
          final summary = await _service.summarizeExpenses(
            fromInclusive: spec.fromInclusive!,
            toExclusive: spec.toExclusive!,
          );
          if (generation != _requestGeneration) return;
          if (summary case Ok(value: final total)) {
            _expenseSum = total.total;
          }
        }
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

  Future<void> setMode(TxListMode value) async {
    if (mode == value) return;
    mode = value;
    _awaitingCustomRange = false;
    _syncFilterRange();
    await _loadFirstPage();
  }

  Future<void> selectDay(DateTime day) async {
    final next = dateOnly(day);
    if (mode == TxListMode.day && next == selectedDay) return;
    selectedDay = next;
    mode = TxListMode.day;
    _awaitingCustomRange = false;
    _syncFilterRange();
    await _loadFirstPage();
  }

  Future<void> shiftDay(int days) async {
    await selectDay(addCalendarDays(selectedDay, days));
  }

  Future<void> shiftMonth(int months) async {
    selectedMonth = addCalendarMonths(selectedMonth, months);
    mode = TxListMode.month;
    _awaitingCustomRange = false;
    _syncFilterRange();
    await _loadFirstPage();
  }

  Future<void> setDateFilter(TxDateFilter date) async {
    if (date == TxDateFilter.custom) {
      _awaitingCustomRange = true;
      filter = filter.copyWith(
        date: date,
        clearCustomFrom: true,
        clearCustomTo: true,
      );
      await _loadFirstPage();
      return;
    }
    _awaitingCustomRange = false;
    mode = TxListMode.month;
    final currentMonth = monthStart(_viewMonth?.call() ?? _clock());
    selectedMonth = date == TxDateFilter.lastMonth
        ? previousMonthStart(currentMonth)
        : currentMonth;
    filter = filter.copyWith(
      date: date,
      clearCustomFrom: true,
      clearCustomTo: true,
    );
    _syncFilterRange();
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
    final from = dateOnly(value);
    final currentTo = filter.customTo;
    _awaitingCustomRange = true;
    filter = filter.copyWith(
      date: TxDateFilter.custom,
      customFrom: from,
      customTo: currentTo != null && currentTo.isBefore(from)
          ? from
          : currentTo,
    );
    await _loadFirstPage();
  }

  Future<void> setCustomTo(DateTime value) async {
    final to = dateOnly(value);
    final currentFrom = filter.customFrom;
    _awaitingCustomRange = true;
    filter = filter.copyWith(
      date: TxDateFilter.custom,
      customFrom: currentFrom != null && currentFrom.isAfter(to)
          ? to
          : currentFrom,
      customTo: to,
    );
    await _loadFirstPage();
  }

  void _syncFilterRange() {
    if (mode == TxListMode.day) {
      filter = filter.copyWith(
        date: TxDateFilter.custom,
        customFrom: selectedDay,
        customTo: selectedDay,
      );
      return;
    }
    final start = monthStart(selectedMonth);
    filter = filter.copyWith(
      date: TxDateFilter.custom,
      customFrom: start,
      customTo: addCalendarDays(nextMonthStart(start), -1),
    );
  }

  void _rebuild() {
    snapshot = _query.apply(
      all: _loaded,
      now: _clock(),
      viewMonth: selectedMonth,
      filter: mode == TxListMode.day
          ? filter.copyWith(categoryId: 'all')
          : filter,
      expenseSumOverride: _expenseSum,
      chronological: mode == TxListMode.day,
    );
  }

  TransactionQuerySpec _spec({required int offset}) {
    if (_awaitingCustomRange) {
      final from = filter.customFrom;
      final customTo = filter.customTo;
      return TransactionQuerySpec(
        fromInclusive: from,
        toExclusive: customTo == null ? null : dayToExclusive(customTo),
        type: TransactionType.expense,
        categoryId: filter.categoryId == 'all' ? null : filter.categoryId,
        limit: pageSize,
        offset: offset,
        includeExpenseSum: offset == 0,
      );
    }

    DateTime from;
    DateTime to;
    String? categoryId;
    if (mode == TxListMode.day) {
      from = selectedDay;
      to = dayToExclusive(selectedDay);
      categoryId = null;
    } else {
      from = monthStart(selectedMonth);
      to = nextMonthStart(from);
      categoryId = filter.categoryId == 'all' ? null : filter.categoryId;
    }
    return TransactionQuerySpec(
      fromInclusive: from,
      toExclusive: to,
      type: TransactionType.expense,
      categoryId: categoryId,
      limit: pageSize,
      offset: offset,
      includeExpenseSum: offset == 0,
    );
  }
}
