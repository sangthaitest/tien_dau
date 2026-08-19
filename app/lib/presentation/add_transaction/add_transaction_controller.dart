import 'package:flutter/foundation.dart';

import '../../application/add_transaction_draft.dart';
import '../../application/transaction_service.dart';
import '../../domain/catalog/chi_cho_catalog.dart';
import '../../domain/catalog/payment_option_catalog.dart';
import '../../domain/entities/payment_source.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import 'add_transaction_copy.dart';
import '../catalog/transaction_catalog_controller.dart';

class AddTransactionController extends ChangeNotifier {
  AddTransactionController({
    required TransactionService service,
    required this.catalogController,
    required DateTime Function() clock,
    AddTransactionDraft? draft,
    this.existing,
  }) : _service = service,
       draft =
           draft ??
           (existing != null
               ? AddTransactionDraft.fromTransaction(existing)
               : AddTransactionDraft(now: clock())) {
    catalogController.addListener(_onCatalogChanged);
  }

  final TransactionService _service;
  final TransactionCatalogController catalogController;
  final AddTransactionDraft draft;
  final Transaction? existing;

  bool get isEditing => existing != null;

  bool saving = false;
  String? error;

  List<ChiChoCategory> get categories {
    final active = catalogController.categories;
    final selected = catalogController.categoryById(draft.categoryId);
    if (selected == null ||
        !selected.archived ||
        active.any((item) => item.id == selected.id)) {
      return active;
    }
    return [selected, ...active];
  }

  ChiChoCategory get category {
    return catalogController.categoryById(draft.categoryId) ?? categories.first;
  }

  List<String> get detailOptions => category.details;

  List<PaymentOption> get payments {
    final active = catalogController.payments;
    final selected = catalogController.paymentById(draft.paymentSourceId);
    if (selected == null ||
        !selected.archived ||
        active.any((item) => item.source.id == selected.source.id)) {
      return active;
    }
    return [selected, ...active];
  }

  PaymentOption get payment => _resolvedPayment;

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

    final invalid = draft.validate(paymentOverride: _resolvedPayment);
    if (invalid != null) {
      error = AddTransactionCopy.messageFor(invalid);
      notifyListeners();
      return Err(invalid);
    }

    saving = true;
    error = null;
    notifyListeners();

    final input = draft.toNewTransaction(paymentOverride: _resolvedPayment);
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

  void reconcileSelections() {
    final selectedCategory = catalogController.categoryById(draft.categoryId);
    final keepsHistoricalCategory =
        existing?.categoryId == selectedCategory?.id;
    if (selectedCategory == null ||
        (selectedCategory.archived && !keepsHistoricalCategory)) {
      draft.selectCategory(catalogController.categories.first.id);
    } else if (draft.detail != null &&
        !selectedCategory.details.contains(draft.detail)) {
      draft.detail = null;
    }

    final selectedPayment = catalogController.paymentById(
      draft.paymentSourceId,
    );
    final keepsHistoricalPayment =
        existing?.paymentSourceId == selectedPayment?.source.id;
    if (selectedPayment == null ||
        (selectedPayment.archived && !keepsHistoricalPayment)) {
      draft.selectPayment(catalogController.payments.first.source.id);
    }
    notifyListeners();
  }

  PaymentOption get _resolvedPayment {
    final stored = catalogController.paymentById(draft.paymentSourceId);
    if (stored != null) return stored;
    final tx = existing;
    if (tx != null && tx.paymentSourceId == draft.paymentSourceId) {
      return PaymentOption(
        source: PaymentSource(
          id: tx.paymentSourceId,
          name: tx.paymentSourceName,
          method: tx.paymentMethod,
        ),
        typeLabel: 'Đã lưu',
        archived: true,
      );
    }
    return catalogController.payments.first;
  }

  void _onCatalogChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    catalogController.removeListener(_onCatalogChanged);
    super.dispose();
  }
}
