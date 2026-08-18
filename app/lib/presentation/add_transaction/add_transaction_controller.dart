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
  })  : _service = service,
        draft = draft ?? AddTransactionDraft(now: clock());

  final TransactionService _service;
  final AddTransactionDraft draft;

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

    final result = await _service.add(draft.toNewTransaction());
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
