import 'package:tien_day/domain/entities/finance.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/domain/repositories/finance_repository.dart';
import 'package:tien_day/domain/repositories/pin_repository.dart';

class MemoryPinRepository implements PinRepository {
  PinRecord? record;

  @override
  Future<Result<PinRecord?>> load() async => Ok(record);

  @override
  Future<Result<void>> save(PinRecord value) async {
    record = value;
    return const Ok(null);
  }
}

class MemoryFinanceRepository implements FinanceRepository {
  MonthlySalary salary = const MonthlySalary(amount: 0);
  MonthlyBudget budget = const MonthlyBudget(monthKey: '1970-01', totalLimit: 0);
  final List<SavingsGoal> goals = [];

  @override
  Future<Result<MonthlySalary>> getSalary() async => Ok(salary);

  @override
  Future<Result<MonthlySalary>> saveSalary(MonthlySalary value) async {
    salary = value;
    return Ok(salary);
  }

  @override
  Future<Result<MonthlyBudget>> getBudget({required String currentMonthKey}) async {
    if (budget.monthKey != currentMonthKey) {
      budget = MonthlyBudget(monthKey: currentMonthKey, totalLimit: budget.totalLimit);
    }
    return Ok(budget);
  }

  @override
  Future<Result<MonthlyBudget>> saveBudget(MonthlyBudget value) async {
    budget = value;
    return Ok(budget);
  }

  @override
  Future<Result<List<SavingsGoal>>> getGoals() async => Ok(List.of(goals));

  @override
  Future<Result<SavingsGoal>> createGoal(SavingsGoal goal) async {
    goals.add(goal);
    return Ok(goal);
  }

  @override
  Future<Result<SavingsGoal>> updateGoal(SavingsGoal goal) async {
    final i = goals.indexWhere((e) => e.id == goal.id);
    if (i < 0) return const Err(NotFoundFailure('Goal not found'));
    goals[i] = goal;
    return Ok(goal);
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
    final before = goals.length;
    goals.removeWhere((e) => e.id == id);
    if (goals.length == before) {
      return const Err(NotFoundFailure('Goal not found'));
    }
    return const Ok(null);
  }
}
