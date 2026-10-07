import '../domain/entities/finance.dart';
import '../domain/entities/recurring_month_entry.dart';
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
    this.spendableAmount = 0,
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

  /// Thu nhập − tổng khoản định kỳ (money available to spend this month).
  final int spendableAmount;

  /// Tiền có thể chi − đã chi tiêu.
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
    final budget = await _finance.getBudget(currentMonthKey: key);
    final goals = await _finance.getGoals();
    final ensured = await _ensureMonthSnapshots(selected);
    final recurring = await _recurring.listMonthEntries(key);
    final txs = await _transactions.summarizeExpenses(
      fromInclusive: selected,
      toExclusive: DateTime(selected.year, selected.month + 1),
    );

    if (budget is Err<MonthlyBudget>) return Err(budget.failure);
    if (goals is Err<List<SavingsGoal>>) return Err(goals.failure);
    if (ensured is Err<void>) return Err(ensured.failure);
    if (recurring is Err<List<RecurringMonthEntry>>) {
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
        final monthRules = _rulesForView(
          (recurring as Ok<List<RecurringMonthEntry>>).value,
        );
        final managedExpense = _sorted([
          for (final rule in monthRules)
            if (rule.kind == RecurringKind.expense) rule,
        ]);
        final managedIncome = _sorted([
          for (final rule in monthRules)
            if (rule.kind == RecurringKind.income) rule,
        ]);
        final visibleExpenses = [
          for (final rule in managedExpense)
            if (rule.isActive) rule,
        ];
        var expenseTotal = 0;
        var extraIncome = 0;
        var salaryAmount = 0;
        for (final rule in monthRules) {
          if (!rule.isActive) continue;
          switch (rule.kind) {
            case RecurringKind.expense:
              expenseTotal += rule.amount;
            case RecurringKind.income:
              if (rule.isSalary) {
                salaryAmount = rule.amount;
              } else {
                extraIncome += rule.amount;
              }
          }
        }
        final incomeTotal = salaryAmount + extraIncome;
        final spendable = incomeTotal - expenseTotal;
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
            spendableAmount: spendable,
            projectedRemaining: spendable - used,
          ),
        );
    }
  }

  Future<Result<MonthlySalary>> saveSalary(
    int amount, {
    DateTime? month,
  }) async {
    if (amount <= 0) {
      return const Err(ValidationFailure('Nhập số lương hợp lệ'));
    }
    final saved = await _finance.saveSalary(MonthlySalary(amount: amount));
    if (saved is Err<MonthlySalary>) return saved;
    final selected = monthStart(month ?? _clock());
    final snapshot = await _writeSalarySnapshot(amount, selected);
    if (snapshot is Err<void>) return Err(snapshot.failure);
    return saved;
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
    final created = await _recurring.create(rule);
    if (created is Err<RecurringTransaction>) return created;
    final entry = await _recurring.saveMonthEntry(
      RecurringMonthEntry.fromTemplate(rule, monthKey(selected)),
    );
    if (entry is Err<void>) return Err(entry.failure);
    return created;
  }

  Future<Result<RecurringTransaction>> updateRecurring(
    RecurringTransaction existing,
    RecurringDraft draft, {
    DateTime? month,
  }) async {
    final validated = _validateDraft(draft);
    if (validated != null) return Err(validated);
    final selected = monthStart(month ?? _clock());
    final template = await _templateOr(existing);
    if (template is Err<RecurringTransaction>) return template;
    final base = (template as Ok<RecurringTransaction>).value;
    if (existing.isSalary) {
      if (draft.kind != RecurringKind.income) {
        return const Err(ValidationFailure('Lương phải là thu nhập'));
      }
      return _upsertSalaryFromDraft(draft, selected);
    }
    if (_isSalaryDraft(draft)) {
      return _upsertSalaryFromDraft(draft, selected, replaceId: existing.id);
    }
    final updated = _monthRule(
      id: existing.id,
      draft: draft,
      month: selected,
      createdAt: base.createdAt,
      endDate: base.endDate,
    );
    final entry = await _saveMonthFromRule(updated, selected);
    if (entry is Err<void>) return Err(entry.failure);
    return Ok(updated);
  }

  Future<Result<RecurringTransaction>> setRecurringActive(
    RecurringTransaction existing,
    bool isActive, {
    DateTime? month,
  }) async {
    final selected = monthStart(month ?? _clock());
    final updated = existing.copyWith(
      isActive: isActive,
      updatedAt: _clock().toUtc(),
    );
    final entry = await _saveMonthFromRule(updated, selected);
    if (entry is Err<void>) return Err(entry.failure);
    return Ok(updated);
  }

  Future<Result<void>> deleteRecurring(String id, {DateTime? month}) async {
    final selected = monthStart(month ?? _clock());
    return _recurring.saveMonthEntry(
      RecurringMonthEntry.omitted(
        templateId: id,
        monthKey: monthKey(selected),
        at: _clock().toUtc(),
      ),
    );
  }

  Future<Result<RecurringTransaction>> _upsertSalaryFromDraft(
    RecurringDraft draft,
    DateTime month, {
    String? replaceId,
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
    final rule = _monthRule(
      id: RecurringTransaction.salaryId,
      draft: draft,
      month: month,
      createdAt: previous?.createdAt ?? now,
      endDate: previous?.endDate,
      salary: true,
    );
    final stored = previous == null
        ? rule.copyWith(startDate: _startDateForDay(draft.dayOfMonth, month))
        : rule;
    if (previous == null) {
      final replaced = await _recurring.replaceSalary(stored);
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
    }
    final entry = await _saveMonthFromRule(stored, month);
    if (entry is Err<void>) return Err(entry.failure);
    if (replaceId != null && replaceId != RecurringTransaction.salaryId) {
      final dropped = await _recurring.deleteMonthEntry(
        templateId: replaceId,
        monthKey: monthKey(monthStart(month)),
      );
      if (dropped is Err<void>) return Err(dropped.failure);
      final deleted = await _recurring.delete(replaceId);
      switch (deleted) {
        case Err(:final failure):
          return Err(failure);
        case Ok():
      }
    }
    return Ok(stored);
  }

  /// Values for one month. Does not rewrite the shared template, so another
  /// month keeps the values it already shows.
  RecurringTransaction _monthRule({
    required String id,
    required RecurringDraft draft,
    required DateTime month,
    required DateTime createdAt,
    DateTime? endDate,
    bool salary = false,
  }) {
    final selected = monthStart(month);
    final lastDay = DateTime(selected.year, selected.month + 1, 0).day;
    final kind = salary ? RecurringKind.income : draft.kind;
    return RecurringTransaction(
      id: id,
      name: draft.name.trim(),
      kind: kind,
      amount: draft.amount,
      frequency: RecurringFrequency.monthly,
      intervalCount: 1,
      direction: kind.derivedDirection,
      categoryId: kind == RecurringKind.expense
          ? _optionalText(draft.categoryId)
          : null,
      paymentSourceId: _optionalText(draft.paymentSourceId),
      note: _optionalText(draft.note),
      startDate: DateTime(
        selected.year,
        selected.month,
        draft.dayOfMonth.clamp(1, lastDay),
      ),
      endDate: endDate,
      isActive: draft.isActive,
      createdAt: createdAt,
      updatedAt: _clock().toUtc(),
    );
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

  /// Writes a snapshot only when a template's start month is [month] and that
  /// snapshot is missing.
  ///
  /// Opening another month does not rewrite the template. Other months are
  /// calculated in [_rulesForView].
  Future<Result<void>> _ensureMonthSnapshots(DateTime month) async {
    final selected = monthStart(month);
    final key = monthKey(selected);
    final templates = await _recurring.listAll();
    if (templates is Err<List<RecurringTransaction>>) {
      return Err(templates.failure);
    }
    final existing = await _recurring.listMonthEntries(key);
    if (existing is Err<List<RecurringMonthEntry>>) {
      return Err(existing.failure);
    }
    final present = {
      for (final entry in (existing as Ok<List<RecurringMonthEntry>>).value)
        entry.templateId,
    };
    for (final rule in (templates as Ok<List<RecurringTransaction>>).value) {
      if (present.contains(rule.id)) continue;
      if (rule.frequency != RecurringFrequency.monthly) continue;
      final start = DateTime(rule.startDate.year, rule.startDate.month);
      if (start != selected) continue;
      if (!rule.appliesToMonth(selected)) continue;
      final saved = await _recurring.saveMonthEntry(
        RecurringMonthEntry.fromTemplate(rule, key),
      );
      if (saved is Err<void>) return saved;
    }
    return const Ok(null);
  }

  /// A month shows only rows stored for that month. A template does not
  /// appear in later months until that month has its own row.
  List<RecurringTransaction> _rulesForView(List<RecurringMonthEntry> entries) {
    return [
      for (final entry in entries)
        if (!entry.omitsMonth) entry.toRule(),
    ];
  }

  Future<Result<void>> _writeSalarySnapshot(int amount, DateTime month) async {
    final selected = monthStart(month);
    final found = await _recurring.findById(RecurringTransaction.salaryId);
    if (found is Err<RecurringTransaction?>) return Err(found.failure);
    final now = _clock().toUtc();
    final existing = (found as Ok<RecurringTransaction?>).value;
    final startDay = existing?.dayOfMonth ?? 1;
    final lastDay = DateTime(selected.year, selected.month + 1, 0).day;
    final rule = existing == null
        ? RecurringTransaction(
            id: RecurringTransaction.salaryId,
            name: 'Lương',
            kind: RecurringKind.income,
            amount: amount,
            frequency: RecurringFrequency.monthly,
            intervalCount: 1,
            direction: RecurringDirection.add,
            startDate: DateTime(selected.year, selected.month, 1),
            isActive: true,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            amount: amount,
            isActive: true,
            updatedAt: now,
            startDate: DateTime(
              selected.year,
              selected.month,
              startDay.clamp(1, lastDay),
            ),
          );
    final replaced = await _recurring.replaceSalary(rule);
    if (replaced is Err<RecurringTransaction>) return Err(replaced.failure);
    return _saveMonthFromRule(rule, selected);
  }

  Future<Result<void>> _saveMonthFromRule(
    RecurringTransaction rule,
    DateTime month,
  ) {
    return _recurring.saveMonthEntry(
      RecurringMonthEntry.fromTemplate(rule, monthKey(monthStart(month))),
    );
  }

  Future<Result<RecurringTransaction>> _templateOr(
    RecurringTransaction fallback,
  ) async {
    final found = await _recurring.findById(fallback.id);
    switch (found) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        return Ok(value ?? fallback);
    }
  }

  /// Keeps the template's start month and stores [day] on that date.
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
