import 'package:flutter/foundation.dart';

import '../../application/home_query.dart';
import '../../domain/failures/result.dart';

class HomeController extends ChangeNotifier {
  HomeController(this._query);

  final HomeQuery _query;

  bool loading = true;
  String? error;
  HomeSnapshot snapshot = HomeSnapshot(
    month: DateTime(1970),
    monthExpense: 0,
    recent: const [],
  );

  Future<void> load({DateTime? month}) async {
    loading = true;
    error = null;
    notifyListeners();

    final result = await _query.load(month: month);
    switch (result) {
      case Ok(:final value):
        snapshot = value;
        error = null;
      case Err(:final failure):
        error = failure.message;
    }
    loading = false;
    notifyListeners();
  }
}
