import 'package:flutter/foundation.dart';

import '../../application/finance_service.dart';
import '../../domain/entities/finance.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/failures/result.dart';

class FinanceController extends ChangeNotifier {
  FinanceController(this._service, {DateTime Function()? month})
    : _month = month;

  final FinanceService _service;
  final DateTime Function()? _month;

  bool loading = false;
  String? error;
  FinanceSnapshot snapshot = FinanceSnapshot(
    month: DateTime(1970),
    salary: 0,
    budgetLimit: 0,
    used: 0,
    remaining: 0,
    percentUsed: 0,
    goals: const [],
  );

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    final result = await _service.load(month: _month?.call());
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

  Future<Result<void>> saveSalary(int amount) async {
    final result = await _service.saveSalary(amount);
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> saveBudget(int limit) async {
    final result = await _service.saveBudget(limit, month: _month?.call());
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> createGoal({
    required String name,
    required int targetAmount,
    int currentAmount = 0,
  }) async {
    final result = await _service.createGoal(
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
    );
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> updateGoal(SavingsGoal goal) async {
    final result = await _service.updateGoal(goal);
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> addToGoal(SavingsGoal goal, int amount) async {
    final result = await _service.addToGoal(goal, amount);
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> deleteGoal(String id) async {
    final result = await _service.deleteGoal(id);
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> createRecurring(RecurringDraft draft) async {
    final result = await _service.createRecurring(draft, month: _month?.call());
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> updateRecurring(
    RecurringTransaction existing,
    RecurringDraft draft,
  ) async {
    final result = await _service.updateRecurring(
      existing,
      draft,
      month: _month?.call(),
    );
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> setRecurringActive(
    RecurringTransaction existing,
    bool isActive,
  ) async {
    final result = await _service.setRecurringActive(existing, isActive);
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> deleteRecurring(String id) async {
    final result = await _service.deleteRecurring(id);
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }
}
