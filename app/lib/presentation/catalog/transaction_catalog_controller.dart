import 'package:flutter/foundation.dart';

import '../../application/transaction_catalog_service.dart';
import '../../domain/catalog/chi_cho_catalog.dart';
import '../../domain/catalog/list_order.dart';
import '../../domain/catalog/payment_option_catalog.dart';
import '../../domain/catalog/transaction_catalog.dart';
import '../../domain/entities/payment_method_kind.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';

class TransactionCatalogController extends ChangeNotifier {
  TransactionCatalogController(this._service)
    : _catalog = TransactionCatalog.defaults();

  final TransactionCatalogService _service;
  TransactionCatalog _catalog;

  bool loading = false;
  String? error;

  TransactionCatalog get catalog => _catalog;
  List<ChiChoCategory> get categories => _catalog.categories
      .where((item) => !item.archived)
      .toList(growable: false);
  List<PaymentOption> get payments =>
      _catalog.payments.where((item) => !item.archived).toList(growable: false);

  ChiChoCategory? categoryById(String id) {
    for (final category in _catalog.categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  PaymentOption? paymentById(String id) {
    for (final payment in _catalog.payments) {
      if (payment.source.id == id) return payment;
    }
    return null;
  }

  Future<Result<void>> load() async {
    loading = true;
    error = null;
    notifyListeners();
    final result = await _service.load();
    loading = false;
    return switch (result) {
      Ok(:final value) => _accept(value),
      Err(:final failure) => _reject(failure),
    };
  }

  Future<Result<void>> addCategory({
    required String name,
    required String visualKey,
  }) {
    return _run(
      _service.addCategory(_catalog, name: name, visualKey: visualKey),
    );
  }

  Future<Result<void>> updateCategory({
    required String id,
    required String name,
    required String visualKey,
  }) {
    return _run(
      _service.updateCategory(
        _catalog,
        id: id,
        name: name,
        visualKey: visualKey,
      ),
    );
  }

  Future<Result<void>> archiveCategory(String id) {
    return _run(_service.archiveCategory(_catalog, id));
  }

  Future<Result<void>> addDetail({
    required String categoryId,
    required String name,
  }) {
    return _run(
      _service.addDetail(_catalog, categoryId: categoryId, name: name),
    );
  }

  Future<Result<void>> updateDetail({
    required String categoryId,
    required String oldName,
    required String newName,
  }) {
    return _run(
      _service.updateDetail(
        _catalog,
        categoryId: categoryId,
        oldName: oldName,
        newName: newName,
      ),
    );
  }

  Future<Result<void>> deleteDetail({
    required String categoryId,
    required String name,
  }) {
    return _run(
      _service.deleteDetail(_catalog, categoryId: categoryId, name: name),
    );
  }

  Future<Result<void>> addPayment({
    required String name,
    required PaymentMethodKind method,
    required String typeLabel,
  }) {
    return _run(
      _service.addPayment(
        _catalog,
        name: name,
        method: method,
        typeLabel: typeLabel,
      ),
    );
  }

  Future<Result<void>> updatePayment({
    required String id,
    required String name,
    required PaymentMethodKind method,
    required String typeLabel,
  }) {
    return _run(
      _service.updatePayment(
        _catalog,
        id: id,
        name: name,
        method: method,
        typeLabel: typeLabel,
      ),
    );
  }

  Future<Result<void>> archivePayment(String id) {
    return _run(_service.archivePayment(_catalog, id));
  }

  Future<Result<void>> reorderCategories(int oldIndex, int newIndex) {
    final from = oldIndex;
    final to = adjustedReorderIndex(oldIndex, newIndex);
    return _run(_service.reorderCategories(_catalog, from: from, to: to));
  }

  Future<Result<void>> reorderDetails({
    required String categoryId,
    required int oldIndex,
    required int newIndex,
  }) {
    return _run(
      _service.reorderDetails(
        _catalog,
        categoryId: categoryId,
        from: oldIndex,
        to: adjustedReorderIndex(oldIndex, newIndex),
      ),
    );
  }

  Future<Result<void>> reorderPayments(int oldIndex, int newIndex) {
    return _run(
      _service.reorderPayments(
        _catalog,
        from: oldIndex,
        to: adjustedReorderIndex(oldIndex, newIndex),
      ),
    );
  }

  Future<Result<void>> _run(
    Future<Result<TransactionCatalog>> operation,
  ) async {
    error = null;
    final result = await operation;
    return switch (result) {
      Ok(:final value) => _accept(value),
      Err(:final failure) => _reject(failure),
    };
  }

  Result<void> _accept(TransactionCatalog value) {
    _catalog = value;
    error = null;
    notifyListeners();
    return const Ok(null);
  }

  Result<void> _reject(AppFailure failure) {
    error = failure.message;
    notifyListeners();
    return Err(failure);
  }
}
