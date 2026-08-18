import 'package:flutter/foundation.dart';

import '../../application/add_transaction_draft.dart';
import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import 'add_transaction_copy.dart';

class AddTransactionController extends ChangeNotifier {
  AddTransactionController({
    required TransactionService service,
    required DateTime Function() clock,
    AddTransactionDraft? draft,
    this.existing,
  })  : _service = service,
        draft = draft ??
            (existing != null
                ? AddTransactionDraft.fromTransaction(existing)
                : AddTransactionDraft(now: clock()));

  final TransactionService _service;
  final AddTransactionDraft draft;
  final Transaction? existing;

  bool get isEditing => existing != null;

  bool saving = false;
  String? error;

  void applyShortcut(int value) {
    draft.applyShortcut(value);
    error = null;
    notifyListeners();
  }

  void setAmountFromRaw(String raw) {
    draft.setAmountFromRaw(raw);
    error = null;
    notifyListeners();
  }

  void selectCategory(String id) {
    draft.selectCategory(id);
    notifyListeners();
  }

  void toggleDetail(String name) {
    draft.toggleDetail(name);
    notifyListeners();
  }

  void selectPayment(String id) {
    draft.selectPayment(id);
    notifyListeners();
  }

  void setOccurredOn(DateTime value) {
    draft.setOccurredOn(value);
    notifyListeners();
  }

  void setOccurredTime(String hhmm) {
    draft.setOccurredTime(hhmm);
    notifyListeners();
  }

  void setNote(String value) {
    draft.setNote(value);
    notifyListeners();
  }

  Future<Result<Transaction>> save() async {
    if (saving) {
      return const Err(ValidationFailure('Save already in progress'));
    }

    final invalid = draft.validate();
    if (invalid != null) {
      error = AddTransactionCopy.messageFor(invalid);
      notifyListeners();
      return Err(invalid);
    }

    saving = true;
    error = null;
    notifyListeners();

    final input = draft.toNewTransaction();
    final result = existing == null
        ? await _service.add(input)
        : await _service.update(
            existing!.copyWith(
              amount: input.amount,
              type: input.type,
              categoryId: input.categoryId,
              detail: input.detail,
              clearDetail: input.detail == null,
              occurredOn: input.occurredOn,
              occurredTime: input.occurredTime,
              paymentSourceId: input.paymentSourceId,
              paymentSourceName: input.paymentSourceName,
              paymentMethod: input.paymentMethod,
              note: input.note,
              clearNote: input.note == null,
            ),
          );
    saving = false;
    switch (result) {
      case Ok():
        error = null;
      case Err(:final failure):
        error = AddTransactionCopy.messageFor(failure);
    }
    notifyListeners();
    return result;
  }
}
