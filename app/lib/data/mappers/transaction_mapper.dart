import '../../domain/entities/payment_method_kind.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionMapper {
  static const String table = 'transactions';

  static Map<String, Object?> toMap(Transaction tx) {
    return {
      'id': tx.id,
      'amount': tx.amount,
      'type': tx.type.storageValue,
      'category_id': tx.categoryId,
      'detail': tx.detail,
      'occurred_date': dateToStorage(tx.occurredOn),
      'occurred_time': tx.occurredTime,
      'payment_source_id': tx.paymentSourceId,
      'payment_source_name': tx.paymentSourceName,
      'payment_method': tx.paymentMethod.storageValue,
      'note': tx.note,
      'created_at': tx.createdAt.toUtc().toIso8601String(),
      'updated_at': tx.updatedAt.toUtc().toIso8601String(),
    };
  }

  static Transaction fromMap(Map<String, Object?> row) {
    return Transaction(
      id: row['id']! as String,
      amount: row['amount']! as int,
      type: TransactionType.fromStorage(row['type']! as String),
      categoryId: row['category_id']! as String,
      detail: row['detail'] as String?,
      occurredOn: DateTime.parse(row['occurred_date']! as String),
      occurredTime: row['occurred_time'] as String?,
      paymentSourceId: row['payment_source_id']! as String,
      paymentSourceName: row['payment_source_name']! as String,
      paymentMethod: PaymentMethodKind.fromStorage(
        row['payment_method']! as String,
      ),
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  static String dateToStorage(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
