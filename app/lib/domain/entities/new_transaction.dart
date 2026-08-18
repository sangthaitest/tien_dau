import 'payment_method_kind.dart';
import 'transaction_type.dart';

/// Input for creating a transaction. Id and timestamps are assigned by the app layer.
class NewTransaction {
  const NewTransaction({
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.occurredOn,
    required this.paymentSourceId,
    required this.paymentSourceName,
    required this.paymentMethod,
    this.detail,
    this.occurredTime,
    this.note,
  });

  final int amount;
  final TransactionType type;
  final String categoryId;
  final String? detail;
  final DateTime occurredOn;
  final String? occurredTime;
  final String paymentSourceId;
  final String paymentSourceName;
  final PaymentMethodKind paymentMethod;
  final String? note;
}
