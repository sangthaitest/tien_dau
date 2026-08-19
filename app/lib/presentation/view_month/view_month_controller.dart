import 'package:flutter/foundation.dart';

import '../../application/view_month_service.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';

class ViewMonthController extends ChangeNotifier {
  ViewMonthController(this._service, {required DateTime Function() clock})
    : _clock = clock,
      month = monthStart(clock());

  final ViewMonthService _service;
  final DateTime Function() _clock;

  DateTime month;
  String? error;

  List<DateTime> get options => lastTwelveMonths(_clock());

  Future<void> load() async {
    final result = await _service.load(fallback: _clock());
    switch (result) {
      case Ok(:final value):
        month = monthStart(value);
        error = null;
      case Err(:final failure):
        error = failure.message;
        month = monthStart(_clock());
    }
    notifyListeners();
  }

  Future<void> select(DateTime value) async {
    month = monthStart(value);
    error = null;
    notifyListeners();
    final result = await _service.save(month);
    if (result is Err) {
      error = result.failure.message;
      notifyListeners();
    }
  }
}
