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
}

enum RecurringKind {
  income,
  expense;

  String get storageValue => name;

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
