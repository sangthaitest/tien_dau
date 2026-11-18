import 'package:flutter/foundation.dart';

import '../../application/add_transaction_draft.dart';
import '../../application/detail_suggestions.dart';
import '../../application/transaction_service.dart';
import '../../domain/catalog/chi_cho_catalog.dart';
import '../../domain/catalog/payment_option_catalog.dart';
import '../../domain/time/clock_format.dart';
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
    refreshDetailSuggestions();
  }

  final TransactionService _service;
  final TransactionCatalogController catalogController;
  final AddTransactionDraft draft;
  final Transaction? existing;

  bool get isEditing => existing != null;

  bool saving = false;
  String? error;
  Map<String, int> detailSuggestions = const {};
  int _suggestionRequest = 0;
  String? _pendingSuggestionDetail;
  bool _amountEditedSinceDetailTap = false;
  bool _suggestionsReady = false;
  bool _disposed = false;

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
    _amountEditedSinceDetailTap = true;
    error = null;
    notifyListeners();
  }

  void setAmountFromRaw(String raw) {
    draft.setAmountFromRaw(raw);
    _amountEditedSinceDetailTap = true;
    error = null;
    notifyListeners();
  }

  void selectCategory(String id) {
    final categoryChanged = draft.categoryId != id;
    draft.selectCategory(id);
    if (categoryChanged) {
      _pendingSuggestionDetail = null;
      detailSuggestions = const {};
      _suggestionsReady = false;
    }
    notifyListeners();
    refreshDetailSuggestions();
  }

  void toggleDetail(String name) {
    final selecting = draft.detail != name;
    draft.toggleDetail(name);
    if (!selecting) {
      _pendingSuggestionDetail = null;
    } else {
      _amountEditedSinceDetailTap = false;
      final suggested = lookupDetailSuggestion(name, detailSuggestions);
      if (suggested != null) {
        draft.setAmount(suggested);
        _pendingSuggestionDetail = null;
      } else if (!_suggestionsReady) {
        _pendingSuggestionDetail = name;
      } else {
        _pendingSuggestionDetail = null;
      }
    }
    error = null;
    notifyListeners();
  }

  Future<void> refreshDetailSuggestions() async {
    final request = ++_suggestionRequest;
    final categoryId = draft.categoryId;
    final result = await _service.detailSuggestions(categoryId);
    if (_disposed || request != _suggestionRequest) return;
    if (draft.categoryId != categoryId) return;
    detailSuggestions = switch (result) {
      Ok(:final value) => value,
      Err() => const {},
    };
    _suggestionsReady = true;
    final pending = _pendingSuggestionDetail;
    if (pending != null &&
        !_amountEditedSinceDetailTap &&
        draft.detail == pending) {
      final suggested = lookupDetailSuggestion(pending, detailSuggestions);
      if (suggested != null) {
        draft.setAmount(suggested);
        _pendingSuggestionDetail = null;
      }
    }
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

  void reset({required DateTime now}) {
    draft.amount = 0;
    draft.note = '';
    draft.selectCategory(ChiChoCatalog.defaultId);
    draft.selectPayment(PaymentOptionCatalog.defaultId);
    draft.setOccurredOn(now);
    draft.setOccurredTime(formatHHmm(now));
    saving = false;
    error = null;
    _pendingSuggestionDetail = null;
    _amountEditedSinceDetailTap = false;
    detailSuggestions = const {};
    _suggestionsReady = false;
    notifyListeners();
    refreshDetailSuggestions();
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
    final previousCategory = draft.categoryId;
    final selectedCategory = catalogController.categoryById(draft.categoryId);
    final keepsHistoricalCategory =
        existing?.categoryId == selectedCategory?.id;
    if (selectedCategory == null ||
        (selectedCategory.archived && !keepsHistoricalCategory)) {
      draft.selectCategory(catalogController.categories.first.id);
    } else if (draft.detail != null &&
        !selectedCategory.details.contains(draft.detail)) {
      draft.detail = null;
      _pendingSuggestionDetail = null;
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
    if (draft.categoryId != previousCategory) {
      _pendingSuggestionDetail = null;
      detailSuggestions = const {};
      _suggestionsReady = false;
      refreshDetailSuggestions();
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
    _disposed = true;
    catalogController.removeListener(_onCatalogChanged);
    super.dispose();
  }
}
