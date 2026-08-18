import 'package:flutter/foundation.dart';

import '../../application/transaction_list_query.dart';
import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';

class TransactionListController extends ChangeNotifier {
  TransactionListController(
    this._service, {
    DateTime Function()? clock,
    TransactionListQuery query = const TransactionListQuery(),
  })  : _clock = clock ?? DateTime.now,
        _query = query;

  final TransactionService _service;
  final DateTime Function() _clock;
  final TransactionListQuery _query;

  bool loading = false;
  String? error;
  TransactionListFilter filter = const TransactionListFilter();
  TransactionListSnapshot snapshot = const TransactionListSnapshot(
    expenseSum: 0,
    groups: [],
    filter: TransactionListFilter(),
  );

  List<Transaction> _all = [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    final result = await _service.list();
    switch (result) {
      case Ok(:final value):
        _all = value;
        error = null;
        _rebuild();
      case Err(:final failure):
        error = failure.message;
        _all = [];
        snapshot = TransactionListSnapshot(
          expenseSum: 0,
          groups: const [],
          filter: filter,
        );
    }
    loading = false;
    notifyListeners();
  }

  void setDateFilter(TxDateFilter date) {
    filter = filter.copyWith(date: date);
    _rebuild();
    notifyListeners();
  }

  void setTypeFilter(TxTypeFilter type) {
    filter = filter.copyWith(type: type);
    _rebuild();
    notifyListeners();
  }

  void setCategory(String categoryId) {
    filter = filter.copyWith(categoryId: categoryId);
    _rebuild();
    notifyListeners();
  }

  void setCustomFrom(DateTime value) {
    filter = filter.copyWith(date: TxDateFilter.custom, customFrom: dateOnly(value));
    _rebuild();
    notifyListeners();
  }

  void setCustomTo(DateTime value) {
    filter = filter.copyWith(date: TxDateFilter.custom, customTo: dateOnly(value));
    _rebuild();
    notifyListeners();
  }

  void _rebuild() {
    snapshot = _query.apply(all: _all, now: _clock(), filter: filter);
  }
}
