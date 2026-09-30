import '../../domain/entities/recurring_month_entry.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/time/clock_format.dart';

class RecurringTransactionMapper {
  static Map<String, Object?> toMap(RecurringTransaction rule) {
    return {
      'id': rule.id,
      'name': rule.name,
      'kind': rule.kind.storageValue,
      'amount': rule.amount,
      'frequency': rule.frequency.storageValue,
      'interval_count': rule.intervalCount,
      'direction': rule.direction.storageValue,
      'category_id': rule.categoryId,
      'detail': rule.detail,
      'payment_source_id': rule.paymentSourceId,
      'note': rule.note,
      'start_date': formatIsoDate(rule.startDate),
      'end_date': rule.endDate == null ? null : formatIsoDate(rule.endDate!),
      'is_active': rule.isActive ? 1 : 0,
      'created_at': rule.createdAt.toUtc().toIso8601String(),
      'updated_at': rule.updatedAt.toUtc().toIso8601String(),
    };
  }

  static RecurringTransaction fromMap(Map<String, Object?> row) {
    return RecurringTransaction(
      id: row['id']! as String,
      name: row['name']! as String,
      kind: RecurringKind.fromStorage(row['kind']! as String),
      amount: (row['amount'] as num).toInt(),
      frequency: RecurringFrequency.fromStorage(row['frequency']! as String),
      intervalCount: (row['interval_count'] as num).toInt(),
      direction: RecurringDirection.fromStorage(row['direction']! as String),
      categoryId: row['category_id'] as String?,
      detail: row['detail'] as String?,
      paymentSourceId: row['payment_source_id'] as String?,
      note: row['note'] as String?,
      startDate: DateTime.parse(row['start_date']! as String),
      endDate: row['end_date'] == null
          ? null
          : DateTime.parse(row['end_date']! as String),
      isActive: (row['is_active'] as num).toInt() == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  static Map<String, Object?> monthToMap(RecurringMonthEntry entry) {
    return {
      'id': entry.id,
      'template_id': entry.templateId,
      'month_key': entry.monthKey,
      'name': entry.name,
      'kind': entry.kind.storageValue,
      'amount': entry.amount,
      'direction': entry.direction.storageValue,
      'category_id': entry.categoryId,
      'detail': entry.detail,
      'payment_source_id': entry.paymentSourceId,
      'note': entry.note,
      'day_of_month': entry.dayOfMonth,
      'is_active': entry.isActive ? 1 : 0,
      'created_at': entry.createdAt.toUtc().toIso8601String(),
      'updated_at': entry.updatedAt.toUtc().toIso8601String(),
    };
  }

  static RecurringMonthEntry monthFromMap(Map<String, Object?> row) {
    return RecurringMonthEntry(
      id: row['id']! as String,
      templateId: row['template_id']! as String,
      monthKey: row['month_key']! as String,
      name: row['name']! as String,
      kind: RecurringKind.fromStorage(row['kind']! as String),
      amount: (row['amount'] as num).toInt(),
      direction: RecurringDirection.fromStorage(row['direction']! as String),
      categoryId: row['category_id'] as String?,
      detail: row['detail'] as String?,
      paymentSourceId: row['payment_source_id'] as String?,
      note: row['note'] as String?,
      dayOfMonth: (row['day_of_month'] as num).toInt(),
      isActive: (row['is_active'] as num).toInt() == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }
}
