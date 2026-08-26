/// Recurring RULE, not an actual ledger row.
/// Actual expenses stay in [transactions].
class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.name,
    required this.kind,
    required this.amount,
    required this.frequency,
    required this.intervalCount,
    required this.direction,
    required this.startDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.detail,
    this.paymentSourceId,
    this.note,
    this.endDate,
  });

  final String id;
  final String name;
  final RecurringKind kind;

  /// Whole VND. Always positive; [kind] + [direction] decide inflow vs outflow.
  final int amount;
  final RecurringFrequency frequency;
  final int intervalCount;
  final RecurringDirection direction;
  final String? categoryId;
  final String? detail;
  final String? paymentSourceId;
  final String? note;

  /// Calendar date `YYYY-MM-DD`.
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get dayOfMonth => startDate.day;

  /// Canonical salary rule. Never duplicate this id.
  static const salaryId = 'recurring_salary';

  bool get isSalary => id == salaryId;

  bool appliesToMonth(DateTime month) {
    if (frequency != RecurringFrequency.monthly) return false;
    final start = DateTime(startDate.year, startDate.month);
    final selected = DateTime(month.year, month.month);
    if (start.isAfter(selected)) return false;
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month);
      if (end.isBefore(selected)) return false;
    }
    return true;
  }

  /// Occurrence label for [month], from this rule's day — not a display-only date.
  String dueLabelForMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final day = startDate.day.clamp(1, lastDay);
    final dd = day.toString().padLeft(2, '0');
    final mm = month.month.toString().padLeft(2, '0');
    return 'Ngày $dd/$mm';
  }

  RecurringTransaction copyWith({
    String? name,
    RecurringKind? kind,
    int? amount,
    RecurringFrequency? frequency,
    int? intervalCount,
    RecurringDirection? direction,
    String? categoryId,
    String? detail,
    String? paymentSourceId,
    String? note,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      intervalCount: intervalCount ?? this.intervalCount,
      direction: direction ?? this.direction,
      categoryId: categoryId ?? this.categoryId,
      detail: detail ?? this.detail,
      paymentSourceId: paymentSourceId ?? this.paymentSourceId,
      note: note ?? this.note,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum RecurringKind {
  income,
  expense;

  String get storageValue => name;

  RecurringDirection get derivedDirection => switch (this) {
    RecurringKind.income => RecurringDirection.add,
    RecurringKind.expense => RecurringDirection.subtract,
  };

  static RecurringKind fromStorage(String raw) {
    return RecurringKind.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw FormatException('Unknown recurring kind: $raw'),
    );
  }
}

enum RecurringDirection {
  add,
  subtract;

  String get storageValue => name;

  static RecurringDirection fromStorage(String raw) {
    return RecurringDirection.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw FormatException('Unknown recurring direction: $raw'),
    );
  }
}

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get storageValue => name;

  static RecurringFrequency fromStorage(String raw) {
    return RecurringFrequency.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw FormatException('Unknown recurring frequency: $raw'),
    );
  }
}
