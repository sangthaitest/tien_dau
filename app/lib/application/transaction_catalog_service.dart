import '../domain/catalog/chi_cho_catalog.dart';
import '../domain/catalog/list_order.dart';
import '../domain/catalog/payment_option_catalog.dart';
import '../domain/catalog/transaction_catalog.dart';
import '../domain/entities/payment_method_kind.dart';
import '../domain/entities/payment_source.dart';
import '../domain/failures/app_failure.dart';
import '../domain/failures/result.dart';
import '../domain/repositories/transaction_catalog_repository.dart';

class TransactionCatalogService {
  TransactionCatalogService(
    this._repository, {
    required String Function() idFactory,
  }) : _idFactory = idFactory;

  final TransactionCatalogRepository _repository;
  final String Function() _idFactory;

  Future<Result<TransactionCatalog>> load() async {
    final result = await _repository.load();
    return switch (result) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => _ensureDefaults(value),
    };
  }

  Future<Result<TransactionCatalog>> _ensureDefaults(
    TransactionCatalog? stored,
  ) async {
    if (stored != null &&
        stored.categories.any((item) => !item.archived) &&
        stored.payments.any((item) => !item.archived)) {
      return Ok(stored);
    }
    final defaults = TransactionCatalog.defaults();
    final saved = await _repository.save(defaults);
    return switch (saved) {
      Err(:final failure) => Err(failure),
      Ok() => Ok(defaults),
    };
  }

  Future<Result<TransactionCatalog>> addCategory(
    TransactionCatalog current, {
    required String name,
    required String visualKey,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Tên khoản chi không được để trống.')),
      );
    }
    if (_hasCategoryName(current, cleanName)) {
      return Future.value(
        const Err(ValidationFailure('Khoản chi này đã tồn tại.')),
      );
    }
    final next = current.copyWith(
      categories: [
        ...current.categories,
        ChiChoCategory(
          id: 'category_${_idFactory()}',
          name: cleanName,
          details: const ['Khác'],
          visualKey: visualKey,
        ),
      ],
    );
    return _save(next);
  }

  Future<Result<TransactionCatalog>> updateCategory(
    TransactionCatalog current, {
    required String id,
    required String name,
    required String visualKey,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Tên khoản chi không được để trống.')),
      );
    }
    if (_hasCategoryName(current, cleanName, exceptId: id)) {
      return Future.value(
        const Err(ValidationFailure('Khoản chi này đã tồn tại.')),
      );
    }
    return _replaceCategory(
      current,
      id,
      (category) => category.copyWith(name: cleanName, visualKey: visualKey),
    );
  }

  Future<Result<TransactionCatalog>> archiveCategory(
    TransactionCatalog current,
    String id,
  ) {
    if (current.categories.where((item) => !item.archived).length <= 1) {
      return Future.value(
        const Err(ValidationFailure('Cần giữ lại ít nhất một khoản chi.')),
      );
    }
    return _replaceCategory(
      current,
      id,
      (category) => category.copyWith(archived: true),
    );
  }

  Future<Result<TransactionCatalog>> addDetail(
    TransactionCatalog current, {
    required String categoryId,
    required String name,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Tên chi tiết không được để trống.')),
      );
    }
    return _replaceCategory(current, categoryId, (category) {
      if (_containsIgnoreCase(category.details, cleanName)) {
        throw const ValidationFailure('Chi tiết này đã tồn tại.');
      }
      return category.copyWith(details: [...category.details, cleanName]);
    });
  }

  Future<Result<TransactionCatalog>> updateDetail(
    TransactionCatalog current, {
    required String categoryId,
    required String oldName,
    required String newName,
  }) {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Tên chi tiết không được để trống.')),
      );
    }
    return _replaceCategory(current, categoryId, (category) {
      if (_containsIgnoreCase(
        category.details.where((item) => item != oldName),
        cleanName,
      )) {
        throw const ValidationFailure('Chi tiết này đã tồn tại.');
      }
      return category.copyWith(
        details: [
          for (final detail in category.details)
            if (detail == oldName) cleanName else detail,
        ],
      );
    });
  }

  Future<Result<TransactionCatalog>> deleteDetail(
    TransactionCatalog current, {
    required String categoryId,
    required String name,
  }) {
    return _replaceCategory(current, categoryId, (category) {
      if (category.details.length <= 1) {
        throw const ValidationFailure('Cần giữ lại ít nhất một chi tiết.');
      }
      return category.copyWith(
        details: category.details.where((item) => item != name).toList(),
      );
    });
  }

  Future<Result<TransactionCatalog>> addPayment(
    TransactionCatalog current, {
    required String name,
    required PaymentMethodKind method,
    required String typeLabel,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Tên phương thức không được để trống.')),
      );
    }
    if (_hasPaymentName(current, cleanName)) {
      return Future.value(
        const Err(ValidationFailure('Phương thức này đã tồn tại.')),
      );
    }
    final option = PaymentOption(
      source: PaymentSource(
        id: 'payment_${_idFactory()}',
        name: cleanName,
        method: method,
      ),
      typeLabel: typeLabel,
    );
    return _save(current.copyWith(payments: [...current.payments, option]));
  }

  Future<Result<TransactionCatalog>> updatePayment(
    TransactionCatalog current, {
    required String id,
    required String name,
    required PaymentMethodKind method,
    required String typeLabel,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return Future.value(
        const Err(ValidationFailure('Tên phương thức không được để trống.')),
      );
    }
    if (_hasPaymentName(current, cleanName, exceptId: id)) {
      return Future.value(
        const Err(ValidationFailure('Phương thức này đã tồn tại.')),
      );
    }
    return _replacePayment(
      current,
      id,
      (payment) => payment.copyWith(
        source: PaymentSource(
          id: payment.source.id,
          name: cleanName,
          method: method,
        ),
        typeLabel: typeLabel,
      ),
    );
  }

  Future<Result<TransactionCatalog>> archivePayment(
    TransactionCatalog current,
    String id,
  ) {
    if (current.payments.where((item) => !item.archived).length <= 1) {
      return Future.value(
        const Err(ValidationFailure('Cần giữ lại ít nhất một phương thức.')),
      );
    }
    return _replacePayment(
      current,
      id,
      (payment) => payment.copyWith(archived: true),
    );
  }

  Future<Result<TransactionCatalog>> reorderCategories(
    TransactionCatalog current, {
    required int from,
    required int to,
  }) {
    return _save(
      current.copyWith(
        categories: moveVisible(
          current.categories,
          (item) => !item.archived,
          from,
          to,
        ),
      ),
    );
  }

  Future<Result<TransactionCatalog>> reorderDetails(
    TransactionCatalog current, {
    required String categoryId,
    required int from,
    required int to,
  }) {
    return _replaceCategory(current, categoryId, (category) {
      return category.copyWith(details: moveAt(category.details, from, to));
    });
  }

  Future<Result<TransactionCatalog>> reorderPayments(
    TransactionCatalog current, {
    required int from,
    required int to,
  }) {
    return _save(
      current.copyWith(
        payments: moveVisible(
          current.payments,
          (item) => !item.archived,
          from,
          to,
        ),
      ),
    );
  }

  Future<Result<TransactionCatalog>> _replaceCategory(
    TransactionCatalog current,
    String id,
    ChiChoCategory Function(ChiChoCategory) transform,
  ) async {
    final index = current.categories.indexWhere((item) => item.id == id);
    if (index < 0) {
      return const Err(NotFoundFailure('Không tìm thấy khoản chi.'));
    }
    try {
      final categories = [...current.categories];
      categories[index] = transform(categories[index]);
      return _save(current.copyWith(categories: categories));
    } on AppFailure catch (failure) {
      return Err(failure);
    }
  }

  Future<Result<TransactionCatalog>> _replacePayment(
    TransactionCatalog current,
    String id,
    PaymentOption Function(PaymentOption) transform,
  ) {
    final index = current.payments.indexWhere((item) => item.source.id == id);
    if (index < 0) {
      return Future.value(
        const Err(NotFoundFailure('Không tìm thấy phương thức.')),
      );
    }
    final payments = [...current.payments];
    payments[index] = transform(payments[index]);
    return _save(current.copyWith(payments: payments));
  }

  Future<Result<TransactionCatalog>> _save(TransactionCatalog catalog) async {
    final result = await _repository.save(catalog);
    return switch (result) {
      Err(:final failure) => Err(failure),
      Ok() => Ok(catalog),
    };
  }

  bool _hasCategoryName(
    TransactionCatalog current,
    String name, {
    String? exceptId,
  }) {
    return current.categories.any(
      (item) =>
          item.id != exceptId &&
          !item.archived &&
          item.name.toLowerCase() == name.toLowerCase(),
    );
  }

  bool _hasPaymentName(
    TransactionCatalog current,
    String name, {
    String? exceptId,
  }) {
    return current.payments.any(
      (item) =>
          item.source.id != exceptId &&
          !item.archived &&
          item.source.name.toLowerCase() == name.toLowerCase(),
    );
  }

  bool _containsIgnoreCase(Iterable<String> items, String value) {
    return items.any((item) => item.toLowerCase() == value.toLowerCase());
  }
}
