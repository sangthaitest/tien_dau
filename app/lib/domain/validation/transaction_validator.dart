import '../entities/new_transaction.dart';
import '../entities/transaction.dart';
import '../failures/app_failure.dart';

final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

ValidationFailure? validateNewTransaction(NewTransaction input) {
  return _validateAmount(input.amount) ??
      _validateCategory(input.categoryId) ??
      _validatePaymentSource(input.paymentSourceId, input.paymentSourceName) ??
      _validateTime(input.occurredTime);
}

ValidationFailure? validateTransaction(Transaction transaction) {
  return _validateAmount(transaction.amount) ??
      _validateCategory(transaction.categoryId) ??
      _validatePaymentSource(
        transaction.paymentSourceId,
        transaction.paymentSourceName,
      ) ??
      _validateTime(transaction.occurredTime);
}

ValidationFailure? _validateAmount(int amount) {
  if (amount <= 0) {
    return const ValidationFailure('Amount must be greater than 0');
  }
  return null;
}

ValidationFailure? _validateCategory(String categoryId) {
  if (categoryId.trim().isEmpty) {
    return const ValidationFailure('Category is required');
  }
  return null;
}

ValidationFailure? _validatePaymentSource(String id, String name) {
  if (id.trim().isEmpty || name.trim().isEmpty) {
    return const ValidationFailure('Payment source is required');
  }
  return null;
}

ValidationFailure? _validateTime(String? occurredTime) {
  if (occurredTime == null || occurredTime.isEmpty) return null;
  if (!_timePattern.hasMatch(occurredTime)) {
    return const ValidationFailure('Time must be HH:mm');
  }
  return null;
}
