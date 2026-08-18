import '../domain/amount/amount_input.dart';
import '../domain/catalog/chi_cho_catalog.dart';
import '../domain/catalog/payment_option_catalog.dart';
import '../domain/entities/new_transaction.dart';
import '../domain/entities/transaction_type.dart';
import '../domain/failures/app_failure.dart';
import '../domain/time/clock_format.dart';
import '../domain/validation/transaction_validator.dart';

/// In-memory Add Transaction form. Maps V3 UX to the production model.
class AddTransactionDraft {
  AddTransactionDraft({required DateTime now})
      : occurredOn = dateOnly(now),
        occurredTime = formatHHmm(now),
        categoryId = ChiChoCatalog.defaultId,
        paymentSourceId = PaymentOptionCatalog.defaultId;

  int amount = 0;
  String categoryId;
  String? detail;
  String paymentSourceId;
  DateTime occurredOn;
  String occurredTime;
  String note = '';

  ChiChoCategory get category => ChiChoCatalog.byId(categoryId);

  PaymentOption get payment => PaymentOptionCatalog.byId(paymentSourceId);

  int? get activeShortcut => AmountInput.matchingShortcut(amount);

  List<String> get detailOptions => category.details;

  void setAmount(int value) {
    amount = value < 0 ? 0 : value;
  }

  void setAmountFromRaw(String raw) {
    setAmount(AmountInput.parse(raw));
  }

  void applyShortcut(int value) {
    setAmount(value);
  }

  void selectCategory(String id) {
    categoryId = ChiChoCatalog.byId(id).id;
    detail = null;
  }

  void toggleDetail(String name) {
    detail = detail == name ? null : name;
  }

  void selectPayment(String id) {
    paymentSourceId = PaymentOptionCatalog.byId(id).source.id;
  }

  void setOccurredOn(DateTime value) {
    occurredOn = dateOnly(value);
  }

  void setOccurredTime(String hhmm) {
    occurredTime = hhmm;
  }

  void setNote(String value) {
    note = value;
  }

  NewTransaction toNewTransaction() {
    final trimmedNote = note.trim();
    final trimmedDetail = detail?.trim();
    final pay = payment.source;
    return NewTransaction(
      amount: amount,
      type: TransactionType.expense,
      categoryId: categoryId,
      detail: (trimmedDetail == null || trimmedDetail.isEmpty) ? null : trimmedDetail,
      occurredOn: occurredOn,
      occurredTime: occurredTime,
      paymentSourceId: pay.id,
      paymentSourceName: pay.name,
      paymentMethod: pay.method,
      note: trimmedNote.isEmpty ? null : trimmedNote,
    );
  }

  ValidationFailure? validate() => validateNewTransaction(toNewTransaction());
}
