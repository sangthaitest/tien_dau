import '../../domain/entities/finance.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_local_datasource.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl({
    required PrefsLocalDataSource prefs,
    required GoalsLocalDataSource goals,
  })  : _prefs = prefs,
        _goals = goals;

  static const salaryKey = 'salary_amount';
  static const budgetMonthKey = 'budget_month';
  static const budgetLimitKey = 'budget_limit';

  final PrefsLocalDataSource _prefs;
  final GoalsLocalDataSource _goals;

  @override
  Future<Result<MonthlySalary>> getSalary() async {
    try {
      final raw = await _prefs.get(salaryKey);
      final amount = int.tryParse(raw ?? '') ?? 0;
      return Ok(MonthlySalary(amount: amount));
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<MonthlySalary>> saveSalary(MonthlySalary salary) async {
    try {
      await _prefs.set(salaryKey, '${salary.amount}');
      return Ok(salary);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<MonthlyBudget>> getBudget({required String currentMonthKey}) async {
    try {
      final storedMonth = await _prefs.get(budgetMonthKey);
      final limit = int.tryParse(await _prefs.get(budgetLimitKey) ?? '') ?? 0;
      if (storedMonth != currentMonthKey) {
        final rolled = MonthlyBudget(monthKey: currentMonthKey, totalLimit: limit);
        await _prefs.set(budgetMonthKey, currentMonthKey);
        await _prefs.set(budgetLimitKey, '$limit');
        return Ok(rolled);
      }
      return Ok(MonthlyBudget(monthKey: currentMonthKey, totalLimit: limit));
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<MonthlyBudget>> saveBudget(MonthlyBudget budget) async {
    try {
      await _prefs.set(budgetMonthKey, budget.monthKey);
      await _prefs.set(budgetLimitKey, '${budget.totalLimit}');
      return Ok(budget);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<List<SavingsGoal>>> getGoals() async {
    try {
      return Ok(await _goals.findAll());
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<SavingsGoal>> createGoal(SavingsGoal goal) async {
    try {
      await _goals.insert(goal);
      return Ok(goal);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<SavingsGoal>> updateGoal(SavingsGoal goal) async {
    try {
      final changed = await _goals.update(goal);
      if (changed == 0) {
        return const Err(NotFoundFailure('Goal not found'));
      }
      return Ok(goal);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
    try {
      final changed = await _goals.delete(id);
      if (changed == 0) {
        return const Err(NotFoundFailure('Goal not found'));
      }
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }
}
