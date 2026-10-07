import 'package:flutter/foundation.dart';

import '../../application/finance_service.dart';
import '../../domain/entities/finance.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';

class FinanceController extends ChangeNotifier {
  FinanceController(
    this._service, {
    DateTime Function()? month,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now,
       selectedMonth = monthStart((month ?? clock ?? DateTime.now).call());

  final FinanceService _service;
  final DateTime Function() clock;
  DateTime selectedMonth;
  int _loadGeneration = 0;

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

  Future<void> load({bool silent = false}) async {
    final generation = ++_loadGeneration;
    final month = selectedMonth;
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    final result = await _service.load(month: month);
    if (generation != _loadGeneration) return;
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

  Future<void> selectMonth(DateTime value) async {
    final next = monthStart(value);
    if (next == selectedMonth) return;
    selectedMonth = next;
    notifyListeners();
    await load(silent: true);
  }

  Future<void> shiftMonth(int delta) {
    return selectMonth(
      DateTime(selectedMonth.year, selectedMonth.month + delta),
    );
  }

  Future<Result<void>> saveSalary(int amount) async {
    final result = await _service.saveSalary(amount, month: selectedMonth);
    if (result.isOk) await load();
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> saveBudget(int limit) async {
    final result = await _service.saveBudget(limit, month: selectedMonth);
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
    final result = await _service.createRecurring(draft, month: selectedMonth);
    if (result.isOk) await load(silent: true);
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> updateRecurring(
    RecurringTransaction existing,
    RecurringDraft draft,
  ) async {
    final result = await _service.updateRecurring(
      existing,
      draft,
      month: selectedMonth,
    );
    if (result.isOk) await load(silent: true);
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> setRecurringActive(
    RecurringTransaction existing,
    bool isActive,
  ) async {
    final result = await _service.setRecurringActive(
      existing,
      isActive,
      month: selectedMonth,
    );
    if (result.isOk) await load(silent: true);
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }

  Future<Result<void>> deleteRecurring(String id) async {
    final result = await _service.deleteRecurring(id, month: selectedMonth);
    if (result.isOk) await load(silent: true);
    return result.isOk ? const Ok(null) : Err((result as Err).failure);
  }
}
