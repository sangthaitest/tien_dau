import '../domain/entities/finance.dart';
import '../domain/entities/recurring_transaction.dart';
import '../domain/failures/app_failure.dart';
import '../domain/failures/result.dart';
import '../domain/repositories/finance_repository.dart';
import '../domain/repositories/recurring_transaction_repository.dart';
import '../domain/time/clock_format.dart';
import 'transaction_service.dart';

class RecurringDraft {
  const RecurringDraft({
    required this.name,
    required this.kind,
    required this.amount,
    required this.dayOfMonth,
    this.categoryId,
    this.paymentSourceId,
    this.note,
    this.isActive = true,
  });

  final String name;
  final RecurringKind kind;
  final int amount;
  final int dayOfMonth;
  final String? categoryId;
  final String? paymentSourceId;
  final String? note;
  final bool isActive;
}

class FinanceSnapshot {
  const FinanceSnapshot({
    required this.month,
    required this.salary,
    required this.budgetLimit,
    required this.used,
    required this.remaining,
    required this.percentUsed,
    required this.goals,
    this.recurringItems = const [],
    this.managedRecurring = const [],
    this.managedIncome = const [],
    this.recurringExpenseTotal = 0,
    this.recurringIncomeTotal = 0,
    this.projectedRemaining = 0,
  });

  final DateTime month;
  final int salary;
  final int budgetLimit;
  final int used;
  final int remaining;
  final int percentUsed;
  final List<SavingsGoal> goals;

  /// Active expense rules that apply to [month]. Income is never included.
  final List<RecurringTransaction> recurringItems;

  /// All expense rules for Khoản định kỳ → Quản lý, including inactive.
  final List<RecurringTransaction> managedRecurring;

  /// All income rules for Thu nhập → Quản lý, including salary and inactive.
  final List<RecurringTransaction> managedIncome;
  final int recurringExpenseTotal;
  final int recurringIncomeTotal;
  final int projectedRemaining;
}

class FinanceService {
  FinanceService(
    this._finance,
    this._transactions,
    this._recurring, {
    required String Function() idFactory,
    required DateTime Function() clock,
  }) : _idFactory = idFactory,
       _clock = clock;

  final FinanceRepository _finance;
  final TransactionService _transactions;
  final RecurringTransactionRepository _recurring;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  Future<Result<FinanceSnapshot>> load({DateTime? month}) async {
    final selected = monthStart(month ?? _clock());
    final key = monthKey(selected);
    final salary = await _finance.getSalary();
    final budget = await _finance.getBudget(currentMonthKey: key);
    final goals = await _finance.getGoals();
    final recurring = await _recurring.listAll();
    final txs = await _transactions.summarizeExpenses(
      fromInclusive: selected,
      toExclusive: DateTime(selected.year, selected.month + 1),
    );

    if (salary is Err<MonthlySalary>) return Err(salary.failure);
    if (budget is Err<MonthlyBudget>) return Err(budget.failure);
    if (goals is Err<List<SavingsGoal>>) return Err(goals.failure);
    if (recurring is Err<List<RecurringTransaction>>) {
      return Err(recurring.failure);
    }
    switch (txs) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final limit = (budget as Ok<MonthlyBudget>).value.totalLimit;
        final used = value.total;
        final pct = limit > 0
            ? ((used / limit) * 100).round().clamp(0, 100)
            : 0;
        final allRules = (recurring as Ok<List<RecurringTransaction>>).value;
        final managedExpense = _sorted([
          for (final rule in allRules)
            if (rule.kind == RecurringKind.expense) rule,
        ]);
        final managedIncome = _sorted([
          for (final rule in allRules)
            if (rule.kind == RecurringKind.income) rule,
        ]);
        final visibleExpenses = [
          for (final rule in managedExpense)
            if (rule.isActive && rule.appliesToMonth(selected)) rule,
        ];
        var expenseTotal = 0;
        var extraIncome = 0;
        for (final rule in allRules) {
          if (!rule.isActive || !rule.appliesToMonth(selected)) continue;
          switch (rule.kind) {
            case RecurringKind.expense:
              expenseTotal += rule.amount;
            case RecurringKind.income:
              if (!rule.isSalary) extraIncome += rule.amount;
          }
        }
        final salaryAmount = (salary as Ok<MonthlySalary>).value.amount;
        final incomeTotal = salaryAmount + extraIncome;
        return Ok(
          FinanceSnapshot(
            month: selected,
            salary: salaryAmount,
            budgetLimit: limit,
            used: used,
            remaining: limit - used,
            percentUsed: pct,
            goals: (goals as Ok<List<SavingsGoal>>).value,
            recurringItems: visibleExpenses,
            managedRecurring: managedExpense,
            managedIncome: managedIncome,
            recurringExpenseTotal: expenseTotal,
            recurringIncomeTotal: incomeTotal,
            projectedRemaining: incomeTotal - used - expenseTotal,
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

  Future<Result<MonthlyBudget>> saveBudget(int limit, {DateTime? month}) {
    if (limit <= 0) {
      return Future.value(const Err(ValidationFailure('Nhập hạn mức hợp lệ')));
    }
    return _finance.saveBudget(
      MonthlyBudget(monthKey: monthKey(month ?? _clock()), totalLimit: limit),
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

  Future<Result<RecurringTransaction>> createRecurring(
    RecurringDraft draft, {
    DateTime? month,
  }) async {
    final validated = _validateDraft(draft);
    if (validated != null) return Err(validated);
    final selected = monthStart(month ?? _clock());
    if (_isSalaryDraft(draft)) {
      return _upsertSalaryFromDraft(draft, selected);
    }
    final now = _clock().toUtc();
    final rule = RecurringTransaction(
      id: _idFactory(),
      name: draft.name.trim(),
      kind: draft.kind,
      amount: draft.amount,
      frequency: RecurringFrequency.monthly,
      intervalCount: 1,
      direction: draft.kind.derivedDirection,
      categoryId: draft.kind == RecurringKind.expense
          ? _optionalText(draft.categoryId)
          : null,
      paymentSourceId: _optionalText(draft.paymentSourceId),
      note: _optionalText(draft.note),
      startDate: _startDateForDay(draft.dayOfMonth, selected),
      isActive: draft.isActive,
      createdAt: now,
      updatedAt: now,
    );
    return _recurring.create(rule);
  }

  Future<Result<RecurringTransaction>> updateRecurring(
    RecurringTransaction existing,
    RecurringDraft draft, {
    DateTime? month,
  }) async {
    final validated = _validateDraft(draft);
    if (validated != null) return Err(validated);
    final selected = monthStart(month ?? _clock());
    if (existing.isSalary) {
      if (draft.kind != RecurringKind.income) {
        return const Err(ValidationFailure('Lương phải là thu nhập'));
      }
      return _upsertSalaryFromDraft(
        draft,
        selected,
        previousStart: existing.startDate,
      );
    }
    if (_isSalaryDraft(draft)) {
      return _upsertSalaryFromDraft(
        draft,
        selected,
        replaceId: existing.id,
        previousStart: existing.startDate,
      );
    }
    return _recurring.update(
      RecurringTransaction(
        id: existing.id,
        name: draft.name.trim(),
        kind: draft.kind,
        amount: draft.amount,
        frequency: RecurringFrequency.monthly,
        intervalCount: 1,
        direction: draft.kind.derivedDirection,
        categoryId: draft.kind == RecurringKind.expense
            ? _optionalText(draft.categoryId)
            : null,
        paymentSourceId: _optionalText(draft.paymentSourceId),
        note: _optionalText(draft.note),
        startDate: _startDateForDay(
          draft.dayOfMonth,
          selected,
          existing.startDate,
        ),
        isActive: draft.isActive,
        createdAt: existing.createdAt,
        updatedAt: _clock().toUtc(),
        endDate: existing.endDate,
      ),
    );
  }

  Future<Result<RecurringTransaction>> setRecurringActive(
    RecurringTransaction existing,
    bool isActive,
  ) {
    final updated = existing.copyWith(
      isActive: isActive,
      updatedAt: _clock().toUtc(),
    );
    if (existing.isSalary) {
      return _recurring.replaceSalary(updated);
    }
    return _recurring.update(updated);
  }

  Future<Result<void>> deleteRecurring(String id) async {
    final deleted = await _recurring.delete(id);
    switch (deleted) {
      case Err(:final failure):
        return Err(failure);
      case Ok():
        if (id == RecurringTransaction.salaryId) {
          final cleared = await _finance.saveSalary(
            const MonthlySalary(amount: 0),
          );
          switch (cleared) {
            case Err(:final failure):
              return Err(failure);
            case Ok():
          }
        }
        return deleted;
    }
  }

  Future<Result<RecurringTransaction>> _upsertSalaryFromDraft(
    RecurringDraft draft,
    DateTime month, {
    String? replaceId,
    DateTime? previousStart,
  }) async {
    final found = await _recurring.findById(RecurringTransaction.salaryId);
    RecurringTransaction? previous;
    switch (found) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        previous = value;
    }
    final now = _clock().toUtc();
    final rule = RecurringTransaction(
      id: RecurringTransaction.salaryId,
      name: draft.name.trim(),
      kind: RecurringKind.income,
      amount: draft.amount,
      frequency: RecurringFrequency.monthly,
      intervalCount: 1,
      direction: RecurringDirection.add,
      paymentSourceId: _optionalText(draft.paymentSourceId),
      note: _optionalText(draft.note),
      startDate: _startDateForDay(
        draft.dayOfMonth,
        month,
        previous?.startDate ?? previousStart,
      ),
      endDate: previous?.endDate,
      isActive: draft.isActive,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
    final replaced = await _recurring.replaceSalary(rule);
    switch (replaced) {
      case Err(:final failure):
        return Err(failure);
      case Ok():
    }
    final salarySaved = await _finance.saveSalary(
      MonthlySalary(amount: draft.amount),
    );
    switch (salarySaved) {
      case Err(:final failure):
        return Err(failure);
      case Ok():
    }
    if (replaceId != null && replaceId != RecurringTransaction.salaryId) {
      final deleted = await _recurring.delete(replaceId);
      switch (deleted) {
        case Err(:final failure):
          return Err(failure);
        case Ok():
      }
    }
    return Ok(rule);
  }

  ValidationFailure? _validateDraft(RecurringDraft draft) {
    if (draft.name.trim().isEmpty) {
      return const ValidationFailure('Nhập tên khoản định kỳ');
    }
    if (draft.amount <= 0) {
      return const ValidationFailure('Nhập số tiền hợp lệ');
    }
    if (draft.dayOfMonth < 1 || draft.dayOfMonth > 31) {
      return const ValidationFailure('Nhập ngày trong tháng hợp lệ');
    }
    return null;
  }

  bool _isSalaryDraft(RecurringDraft draft) {
    return draft.kind == RecurringKind.income &&
        draft.name.trim().toLowerCase() == 'lương';
  }

  /// Persist the selected monthly day in `start_date` (v5 has no day_of_month).
  DateTime _startDateForDay(int day, DateTime month, [DateTime? previous]) {
    final year = previous?.year ?? month.year;
    var monthNumber = previous?.month ?? month.month;
    final lastDay = DateTime(year, monthNumber + 1, 0).day;
    if (day > lastDay) {
      monthNumber = 1;
    }
    final storedLast = DateTime(year, monthNumber + 1, 0).day;
    return DateTime(year, monthNumber, day.clamp(1, storedLast));
  }

  String? _optionalText(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  List<RecurringTransaction> _sorted(List<RecurringTransaction> rules) {
    rules.sort((a, b) {
      if (a.isSalary != b.isSalary) return a.isSalary ? -1 : 1;
      final day = a.dayOfMonth.compareTo(b.dayOfMonth);
      if (day != 0) return day;
      return a.name.compareTo(b.name);
    });
    return rules;
  }
}
