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

/// List subtitle. Keeps category and payment, and adds the note when it is
/// not already used as the title.
String transactionListMeta(Transaction tx, {String? categoryName}) {
  final category = categoryName ?? ChiChoCatalog.byId(tx.categoryId).name;
  final base = '$category · ${tx.paymentSourceName}';
  final note = tx.note?.trim();
  if (note == null || note.isEmpty) return base;
  if (note == transactionTitle(tx, categoryName: category)) return base;
  return '$note · $base';
}
