import 'package:flutter/foundation.dart';

import '../../application/statistics_query.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';

class StatisticsController extends ChangeNotifier {
  StatisticsController(
    this._query, {
    DateTime Function()? clock,
    DateTime Function()? now,
  }) : _clock = clock ?? DateTime.now,
       now = now ?? DateTime.now,
       selectedMonth = monthStart((clock ?? DateTime.now)()),
       snapshot = StatisticsSnapshot(
         month: monthStart((clock ?? DateTime.now)()),
         totalExpense: 0,
         previousExpense: 0,
         deltaPercent: 0,
         categories: const [],
       );

  final StatisticsQuery _query;
  final DateTime Function() _clock;
  final DateTime Function() now;

  bool loading = false;
  bool _hasLoaded = false;
  bool _pinned = false;
  int _generation = 0;
  String? error;
  DateTime selectedMonth;
  StatisticsSnapshot snapshot;

  Future<void> load() async {
    final generation = ++_generation;
    if (!_pinned) {
      selectedMonth = monthStart(_clock());
    }
    final month = selectedMonth;
    error = null;
    if (!_hasLoaded) {
      loading = true;
      notifyListeners();
    }
    final result = await _query.load(month: month);
    if (generation != _generation) return;
    switch (result) {
      case Ok(:final value):
        snapshot = value;
        error = null;
      case Err(:final failure):
        error = failure.message;
    }
    loading = false;
    _hasLoaded = true;
    notifyListeners();
  }

  Future<void> selectMonth(DateTime value) async {
    final next = monthStart(value);
    _pinned = true;
    if (next == selectedMonth) return;
    selectedMonth = next;
    await load();
  }

  Future<void> shiftMonth(int delta) {
    return selectMonth(
      DateTime(selectedMonth.year, selectedMonth.month + delta),
    );
  }
}
