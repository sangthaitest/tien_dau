import 'payment_method_kind.dart';
import 'transaction_type.dart';

/// Production transaction. Independent of Demo/ runtime `account` string.
class Transaction {
  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.occurredOn,
    required this.paymentSourceId,
    required this.paymentSourceName,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.detail,
    this.occurredTime,
    this.note,
  });

  final String id;

  /// Whole VND units. Always positive; [type] decides inflow vs outflow.
  final int amount;

  final TransactionType type;

  /// Category id (e.g. chi-cho id). Not a display label.
  final String categoryId;

  /// Optional finer label under the category.
  final String? detail;

  /// Calendar date (time-of-day lives in [occurredTime]).
  final DateTime occurredOn;

  /// `HH:mm` 24h, optional.
  final String? occurredTime;

  final String paymentSourceId;
  final String paymentSourceName;
  final PaymentMethodKind paymentMethod;

  final String? note;

  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction copyWith({
    int? amount,
    TransactionType? type,
    String? categoryId,
    String? detail,
    DateTime? occurredOn,
    String? occurredTime,
    String? paymentSourceId,
    String? paymentSourceName,
    PaymentMethodKind? paymentMethod,
    String? note,
    DateTime? updatedAt,
    bool clearDetail = false,
    bool clearOccurredTime = false,
    bool clearNote = false,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      detail: clearDetail ? null : (detail ?? this.detail),
      occurredOn: occurredOn ?? this.occurredOn,
      occurredTime: clearOccurredTime ? null : (occurredTime ?? this.occurredTime),
      paymentSourceId: paymentSourceId ?? this.paymentSourceId,
      paymentSourceName: paymentSourceName ?? this.paymentSourceName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
