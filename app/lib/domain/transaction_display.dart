import 'catalog/chi_cho_catalog.dart';
import 'entities/transaction.dart';

/// Display title: detail, else note, else category name (V3 save rule).
String transactionTitle(Transaction tx, {String? categoryName}) {
  final detail = tx.detail?.trim();
  if (detail != null && detail.isNotEmpty) return detail;
  final note = tx.note?.trim();
  if (note != null && note.isNotEmpty) return note;
  return categoryName ?? ChiChoCatalog.byId(tx.categoryId).name;
}
