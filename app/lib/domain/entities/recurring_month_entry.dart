import '../time/clock_format.dart';
import 'recurring_transaction.dart';

/// One month's snapshot of a recurring template.
///
/// Editing this row must not change another month or rewrite [transactions].
class RecurringMonthEntry {
  const RecurringMonthEntry({
    required this.id,
    required this.templateId,
    required this.monthKey,
    required this.name,
    required this.kind,
    required this.amount,
    required this.direction,
    required this.dayOfMonth,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.detail,
    this.paymentSourceId,
    this.note,
  });

  final String id;
  final String templateId;
  final String monthKey;
  final String name;
  final RecurringKind kind;
  final int amount;
  final RecurringDirection direction;
  final String? categoryId;
  final String? detail;
  final String? paymentSourceId;
  final String? note;
  final int dayOfMonth;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSalary => templateId == RecurringTransaction.salaryId;

  static String idFor(String templateId, String monthKey) =>
      '$templateId@$monthKey';

  factory RecurringMonthEntry.fromTemplate(
    RecurringTransaction rule,
    String monthKey,
  ) {
    return RecurringMonthEntry(
      id: idFor(rule.id, monthKey),
      templateId: rule.id,
      monthKey: monthKey,
      name: rule.name,
      kind: rule.kind,
      amount: rule.amount,
      direction: rule.direction,
      categoryId: rule.categoryId,
      detail: rule.detail,
      paymentSourceId: rule.paymentSourceId,
      note: rule.note,
      dayOfMonth: rule.dayOfMonth,
      isActive: rule.isActive,
      createdAt: rule.createdAt,
      updatedAt: rule.updatedAt,
    );
  }

  /// View model for the existing finance UI. [RecurringTransaction.id] stays
  /// the template id so salary and list keys do not change.
  RecurringTransaction toRule() {
    final month = parseMonthKey(monthKey) ?? DateTime(1970);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final day = dayOfMonth.clamp(1, lastDay);
    return RecurringTransaction(
      id: templateId,
      name: name,
      kind: kind,
      amount: amount,
      frequency: RecurringFrequency.monthly,
      intervalCount: 1,
      direction: direction,
      categoryId: categoryId,
      detail: detail,
      paymentSourceId: paymentSourceId,
      note: note,
      startDate: DateTime(month.year, month.month, day),
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
