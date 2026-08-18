import '../entities/finance.dart';
import '../failures/result.dart';

abstract class FinanceRepository {
  Future<Result<MonthlySalary>> getSalary();

  Future<Result<MonthlySalary>> saveSalary(MonthlySalary salary);

  Future<Result<MonthlyBudget>> getBudget({required String currentMonthKey});

  Future<Result<MonthlyBudget>> saveBudget(MonthlyBudget budget);

  Future<Result<List<SavingsGoal>>> getGoals();

  Future<Result<SavingsGoal>> createGoal(SavingsGoal goal);

  Future<Result<SavingsGoal>> updateGoal(SavingsGoal goal);

  Future<Result<void>> deleteGoal(String id);
}
