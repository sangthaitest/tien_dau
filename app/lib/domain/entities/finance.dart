class MonthlySalary {
  const MonthlySalary({required this.amount});

  /// Whole VND. 0 means not set.
  final int amount;
}

class MonthlyBudget {
  const MonthlyBudget({
    required this.monthKey,
    required this.totalLimit,
  });

  /// `yyyy-MM`
  final String monthKey;
  final int totalLimit;
}

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int targetAmount;
  final int currentAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get remaining => (targetAmount - currentAmount).clamp(0, targetAmount);

  int get progressPercent {
    if (targetAmount <= 0) return 0;
    final pct = ((currentAmount / targetAmount) * 100).round();
    if (pct < 0) return 0;
    if (pct > 100) return 100;
    return pct;
  }

  SavingsGoal copyWith({
    String? name,
    int? targetAmount,
    int? currentAmount,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
