import 'package:flutter/foundation.dart';

import '../../application/statistics_query.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';

class StatisticsController extends ChangeNotifier {
  StatisticsController(this._query, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        snapshot = StatisticsSnapshot(
          month: monthStart((clock ?? DateTime.now)()),
          totalExpense: 0,
          previousExpense: 0,
          deltaPercent: 0,
          categories: const [],
        );

  final StatisticsQuery _query;
  final DateTime Function() _clock;

  bool loading = false;
  bool _hasLoaded = false;
  String? error;
  StatisticsSnapshot snapshot;

  Future<void> load() async {
    error = null;
    if (!_hasLoaded) {
      loading = true;
      notifyListeners();
    }
    final result = await _query.load(month: _clock());
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
}
