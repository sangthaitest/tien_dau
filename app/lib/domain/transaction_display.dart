import 'catalog/chi_cho_catalog.dart';
import 'entities/transaction.dart';

/// Display title: note, else detail, else category name.
String transactionTitle(Transaction tx, {String? categoryName}) {
  final note = tx.note?.trim();
  if (note != null && note.isNotEmpty) return note;
  final detail = tx.detail?.trim();
  if (detail != null && detail.isNotEmpty) return detail;
  return categoryName ?? ChiChoCatalog.byId(tx.categoryId).name;
}

/// List subtitle. Keeps category and payment, and adds detail when the note
/// is already used as the title.
String transactionListMeta(Transaction tx, {String? categoryName}) {
  final category = categoryName ?? ChiChoCatalog.byId(tx.categoryId).name;
  final base = '$category · ${tx.paymentSourceName}';
  final detail = tx.detail?.trim();
  if (detail == null || detail.isEmpty) return base;
  if (detail == transactionTitle(tx, categoryName: category)) return base;
  return '$detail · $base';
}
