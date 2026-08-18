import 'package:flutter/foundation.dart';

import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';

class TransactionDetailController extends ChangeNotifier {
  TransactionDetailController(this._service);

  final TransactionService _service;

  bool loading = true;
  String? error;
  Transaction? transaction;

  Future<void> load(String id) async {
    loading = true;
    error = null;
    transaction = null;
    notifyListeners();

    final result = await _service.get(id);
    switch (result) {
      case Ok(:final value):
        transaction = value;
        error = null;
      case Err(:final failure):
        transaction = null;
        error = failure is NotFoundFailure
            ? 'Không tìm thấy giao dịch'
            : failure.message;
    }
    loading = false;
    notifyListeners();
  }

  Future<Result<void>> delete() async {
    final current = transaction;
    if (current == null) {
      return const Err(NotFoundFailure('Transaction not found'));
    }
    final result = await _service.remove(current.id);
    switch (result) {
      case Ok():
        error = null;
      case Err(:final failure):
        error = failure.message;
        notifyListeners();
    }
    return result;
  }
}
