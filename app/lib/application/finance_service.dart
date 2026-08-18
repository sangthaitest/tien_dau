import '../domain/entities/finance.dart';
import '../domain/entities/transaction_type.dart';
import '../domain/failures/app_failure.dart';
import '../domain/failures/result.dart';
import '../domain/repositories/finance_repository.dart';
import '../domain/time/clock_format.dart';
import 'transaction_service.dart';

class FinanceSnapshot {
  const FinanceSnapshot({
    required this.month,
    required this.salary,
    required this.budgetLimit,
    required this.used,
    required this.remaining,
    required this.percentUsed,
    required this.goals,
  });

  final DateTime month;
  final int salary;
  final int budgetLimit;
  final int used;
  final int remaining;
  final int percentUsed;
  final List<SavingsGoal> goals;
}

class FinanceService {
  FinanceService(
    this._finance,
    this._transactions, {
    required String Function() idFactory,
    required DateTime Function() clock,
  })  : _idFactory = idFactory,
        _clock = clock;

  final FinanceRepository _finance;
  final TransactionService _transactions;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  Future<Result<FinanceSnapshot>> load() async {
    final now = _clock();
    final key = monthKey(now);
    final salary = await _finance.getSalary();
    final budget = await _finance.getBudget(currentMonthKey: key);
    final goals = await _finance.getGoals();
    final txs = await _transactions.list();

    if (salary is Err<MonthlySalary>) return Err(salary.failure);
    if (budget is Err<MonthlyBudget>) return Err(budget.failure);
    if (goals is Err<List<SavingsGoal>>) return Err(goals.failure);
    switch (txs) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final limit = (budget as Ok<MonthlyBudget>).value.totalLimit;
        final used = value.where((tx) {
          return tx.type == TransactionType.expense && inMonth(tx.occurredOn, now);
        }).fold<int>(0, (sum, tx) => sum + tx.amount);
        final pct = limit > 0 ? ((used / limit) * 100).round().clamp(0, 100) : 0;
        return Ok(
          FinanceSnapshot(
            month: monthStart(now),
            salary: (salary as Ok<MonthlySalary>).value.amount,
            budgetLimit: limit,
            used: used,
            remaining: limit - used,
            percentUsed: pct,
            goals: (goals as Ok<List<SavingsGoal>>).value,
          ),
        );
    }
  }

  Future<Result<MonthlySalary>> saveSalary(int amount) {
    if (amount <= 0) {
      return Future.value(const Err(ValidationFailure('Nhập số lương hợp lệ')));
    }
    return _finance.saveSalary(MonthlySalary(amount: amount));
  }

  Future<Result<MonthlyBudget>> saveBudget(int limit) {
    if (limit <= 0) {
      return Future.value(const Err(ValidationFailure('Nhập hạn mức hợp lệ')));
    }
    return _finance.saveBudget(
      MonthlyBudget(monthKey: monthKey(_clock()), totalLimit: limit),
    );
  }

  Future<Result<SavingsGoal>> createGoal({
    required String name,
    required int targetAmount,
    int currentAmount = 0,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Err(ValidationFailure('Nhập tên mục tiêu')));
    }
    if (targetAmount <= 0) {
      return Future.value(const Err(ValidationFailure('Nhập mục tiêu hợp lệ')));
    }
    final now = _clock().toUtc();
    return _finance.createGoal(
      SavingsGoal(
        id: _idFactory(),
        name: trimmed,
        targetAmount: targetAmount,
        currentAmount: currentAmount < 0 ? 0 : currentAmount,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Result<SavingsGoal>> updateGoal(SavingsGoal goal) {
    if (goal.name.trim().isEmpty) {
      return Future.value(const Err(ValidationFailure('Nhập tên mục tiêu')));
    }
    if (goal.targetAmount <= 0) {
      return Future.value(const Err(ValidationFailure('Nhập mục tiêu hợp lệ')));
    }
    return _finance.updateGoal(goal.copyWith(updatedAt: _clock().toUtc()));
  }

  Future<Result<SavingsGoal>> addToGoal(SavingsGoal goal, int amount) {
    if (amount <= 0) {
      return Future.value(const Err(ValidationFailure('Nhập số tiền hợp lệ')));
    }
    return _finance.updateGoal(
      goal.copyWith(
        currentAmount: goal.currentAmount + amount,
        updatedAt: _clock().toUtc(),
      ),
    );
  }

  Future<Result<void>> deleteGoal(String id) => _finance.deleteGoal(id);
}
