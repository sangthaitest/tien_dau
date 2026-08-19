import 'dart:convert';

import '../../domain/catalog/chi_cho_catalog.dart';
import '../../domain/catalog/payment_option_catalog.dart';
import '../../domain/catalog/transaction_catalog.dart';
import '../../domain/entities/payment_method_kind.dart';
import '../../domain/entities/payment_source.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/repositories/transaction_catalog_repository.dart';
import '../datasources/finance_local_datasource.dart';

class TransactionCatalogRepositoryImpl implements TransactionCatalogRepository {
  TransactionCatalogRepositoryImpl(this._prefs);

  static const _key = 'transaction_catalog_v1';
  final PrefsLocalDataSource _prefs;

  @override
  Future<Result<TransactionCatalog?>> load() async {
    try {
      final raw = await _prefs.get(_key);
      if (raw == null || raw.isEmpty) return const Ok(null);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final categories = (map['categories'] as List<dynamic>)
          .map((item) => _categoryFromJson(item as Map<String, dynamic>))
          .toList(growable: false);
      final payments = (map['payments'] as List<dynamic>)
          .map((item) => _paymentFromJson(item as Map<String, dynamic>))
          .toList(growable: false);
      return Ok(TransactionCatalog(categories: categories, payments: payments));
    } catch (error) {
      return Err(
        PersistenceFailure('Không thể đọc danh mục giao dịch.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> save(TransactionCatalog catalog) async {
    try {
      await _prefs.set(
        _key,
        jsonEncode({
          'version': 1,
          'categories': catalog.categories.map(_categoryToJson).toList(),
          'payments': catalog.payments.map(_paymentToJson).toList(),
        }),
      );
      return const Ok(null);
    } catch (error) {
      return Err(
        PersistenceFailure('Không thể lưu danh mục giao dịch.', cause: error),
      );
    }
  }

  Map<String, dynamic> _categoryToJson(ChiChoCategory category) => {
    'id': category.id,
    'name': category.name,
    'details': category.details,
    'visualKey': category.visualKey,
    'archived': category.archived,
  };

  ChiChoCategory _categoryFromJson(Map<String, dynamic> map) {
    return ChiChoCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      details: (map['details'] as List<dynamic>).cast<String>(),
      visualKey: map['visualKey'] as String? ?? 'other',
      archived: map['archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _paymentToJson(PaymentOption payment) => {
    'id': payment.source.id,
    'name': payment.source.name,
    'method': payment.source.method.storageValue,
    'typeLabel': payment.typeLabel,
    'archived': payment.archived,
  };

  PaymentOption _paymentFromJson(Map<String, dynamic> map) {
    return PaymentOption(
      source: PaymentSource(
        id: map['id'] as String,
        name: map['name'] as String,
        method: PaymentMethodKind.fromStorage(map['method'] as String),
      ),
      typeLabel: map['typeLabel'] as String,
      archived: map['archived'] as bool? ?? false,
    );
  }
}
