import 'chi_cho_catalog.dart';
import 'payment_option_catalog.dart';

class TransactionCatalog {
  const TransactionCatalog({required this.categories, required this.payments});

  final List<ChiChoCategory> categories;
  final List<PaymentOption> payments;

  factory TransactionCatalog.defaults() {
    return const TransactionCatalog(
      categories: ChiChoCatalog.all,
      payments: PaymentOptionCatalog.all,
    );
  }

  TransactionCatalog copyWith({
    List<ChiChoCategory>? categories,
    List<PaymentOption>? payments,
  }) {
    return TransactionCatalog(
      categories: categories ?? this.categories,
      payments: payments ?? this.payments,
    );
  }
}
