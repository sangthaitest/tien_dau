import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../domain/catalog/chi_cho_catalog.dart';
import '../../../domain/catalog/payment_option_catalog.dart';

class CategoryNormalizeAborted implements Exception {
  CategoryNormalizeAborted(this.report);
  final CategoryNormalizeReport report;

  @override
  String toString() => report.summary;
}

class TxSnapshot {
  const TxSnapshot({
    required this.transactionId,
    required this.amount,
    required this.occurredDate,
    required this.occurredTime,
    required this.categoryId,
    required this.categoryName,
    required this.parentCategoryId,
    required this.parentCategoryName,
    required this.paymentSourceId,
    required this.paymentSourceName,
    required this.note,
    required this.detail,
    required this.createdAt,
    required this.updatedAt,
  });

  final String transactionId;
  final int amount;
  final String occurredDate;
  final String? occurredTime;
  final String categoryId;
  final String categoryName;
  final String parentCategoryId;
  final String parentCategoryName;
  final String paymentSourceId;
  final String paymentSourceName;
  final String? note;
  final String? detail;
  final String createdAt;
  final String updatedAt;
}

class PlannedMove {
  const PlannedMove({
    required this.before,
    required this.targetCategoryId,
    required this.targetCategoryName,
    required this.targetDetail,
    required this.kind,
  });

  final TxSnapshot before;
  final String targetCategoryId;
  final String targetCategoryName;
  final String? targetDetail;
  final String kind;
}

class CategoryNormalizeReport {
  const CategoryNormalizeReport({
    required this.committed,
    required this.categoriesCreated,
    required this.childCategoriesCreated,
    required this.otherToSnacks,
    required this.utilitiesToBills,
    required this.cafeToHighlands,
    required this.cafeToObau,
    required this.otherUnchanged,
    required this.cafeUnspecified,
    required this.beforeCount,
    required this.beforeAmount,
    required this.beforeCategories,
    required this.beforeChildren,
    required this.afterCount,
    required this.afterAmount,
    required this.afterCategories,
    required this.afterChildren,
    required this.countPass,
    required this.amountPass,
    required this.idsPass,
    required this.fieldsPass,
    required this.integrityPass,
    required this.mappingPass,
    required this.errors,
    required this.planned,
  });

  final bool committed;
  final int categoriesCreated;
  final int childCategoriesCreated;
  final int otherToSnacks;
  final int utilitiesToBills;
  final int cafeToHighlands;
  final int cafeToObau;
  final int otherUnchanged;
  final int cafeUnspecified;
  final int beforeCount;
  final int beforeAmount;
  final int beforeCategories;
  final int beforeChildren;
  final int afterCount;
  final int afterAmount;
  final int afterCategories;
  final int afterChildren;
  final bool countPass;
  final bool amountPass;
  final bool idsPass;
  final bool fieldsPass;
  final bool integrityPass;
  final bool mappingPass;
  final List<String> errors;
  final List<PlannedMove> planned;

  int get transactionsMigrated =>
      otherToSnacks + utilitiesToBills + cafeToHighlands + cafeToObau;

  bool get allPass =>
      countPass &&
      amountPass &&
      idsPass &&
      fieldsPass &&
      integrityPass &&
      mappingPass;

  String get summary {
    final lines = <String>[
      '=== CATEGORY MIGRATION REPORT ===',
      '',
      'BEFORE',
      'Transactions: $beforeCount',
      'Total amount: $beforeAmount',
      'Categories: $beforeCategories',
      'Child categories: $beforeChildren',
      '',
      'PLANNED',
      'Moves: ${planned.length}',
      for (final move in planned)
        '${move.before.transactionId} | ${move.before.amount} | '
        '${move.before.categoryName}/${move.before.detail} → '
        '${move.targetCategoryName}/${move.targetDetail}',
      '',
      'MIGRATED',
      'Khác → Ăn vặt: $otherToSnacks',
      'Điện nước → Hóa đơn: $utilitiesToBills',
      'Cafe → Highlands: $cafeToHighlands',
      'Cafe → Ô Bầu: $cafeToObau',
      '',
      'UNCHANGED',
      'Khác: $otherUnchanged',
      'Cafe chưa xác định: $cafeUnspecified',
      '',
      'AFTER',
      'Transactions: $afterCount',
      'Total amount: $afterAmount',
      'Categories: $afterCategories',
      'Child categories: $afterChildren',
      '',
      'VALIDATION',
      'Transaction count: ${_flag(countPass)}',
      'Total amount: ${_flag(amountPass)}',
      'Transaction IDs: ${_flag(idsPass)}',
      'Transaction fields: ${_flag(fieldsPass)}',
      'Category integrity: ${_flag(integrityPass)}',
      'Mapping verification: ${_flag(mappingPass)}',
    ];
    if (errors.isNotEmpty) {
      lines
        ..add('')
        ..add('ERRORS');
      for (final error in errors) {
        lines.add('- $error');
      }
    }
    lines.add('================================');
    if (!committed) {
      lines
        ..add('ROLLBACK')
        ..add('Migration aborted');
    }
    return lines.join('\n');
  }
}

String _flag(bool pass) => pass ? 'PASS' : 'FAIL';

const _catalogPrefKey = 'transaction_catalog_v1';
const _snacksName = 'Ăn vặt';
const _billsName = 'Hóa đơn';
const _otherName = 'Khác';
const _cafeName = 'Cafe';
const _utilitiesName = 'Điện nước';
const _highlands = 'Highlands';
const _obau = 'Ô Bầu';
const _nuocCam = 'Nước cam';
const _nuocDua = 'Nước dừa';
const _nuocMia = 'Nước mía';

Future<CategoryNormalizeReport> normalizeCategories(
  Database db, {
  void Function(String)? log,
}) async {
  final write = log ?? debugPrint;
  final stored = await _loadCatalogJson(db);
  final currentCatalog = _catalogFromStoredOrV3(stored);
  final rows = await db.query('transactions');
  final rowErrors = _precheckRowErrors(rows);
  final before = _snapshots(rows, currentCatalog);
  final beforeIntegrity = [
    ...rowErrors,
    ..._integrityErrors(before, currentCatalog),
  ];

  if (beforeIntegrity.isNotEmpty) {
    final report = _abortedReport(
      before: before,
      catalog: currentCatalog,
      errors: ['PRE-CHECK failed. Database was not modified.', ...beforeIntegrity],
    );
    write(report.summary);
    throw CategoryNormalizeAborted(report);
  }

  var categories = [...currentCatalog];
  var categoriesCreated = 0;
  var childCategoriesCreated = 0;

  final snacks = _ensureCategory(
    categories,
    name: _snacksName,
    preferredId: 'snacks',
    visualKey: 'snacks',
  );
  categories = snacks.categories;
  if (snacks.created) categoriesCreated += 1;

  final bills = _ensureCategory(
    categories,
    name: _billsName,
    preferredId: 'bills',
    visualKey: 'bills',
  );
  categories = bills.categories;
  if (bills.created) categoriesCreated += 1;

  var ensured = _ensureDetails(categories, snacks.id, [
    _nuocCam,
    _nuocDua,
    _nuocMia,
    _otherName,
  ]);
  categories = ensured.categories;
  childCategoriesCreated += ensured.added;

  final cafeId =
      _findByName(categories, _cafeName)?.id ?? ChiChoCatalog.defaultId;
  ensured = _ensureDetails(categories, cafeId, [_highlands, _obau]);
  categories = ensured.categories;
  childCategoriesCreated += ensured.added;

  ensured = _ensureDetails(categories, bills.id, ['Điện', 'Nước', _otherName]);
  categories = ensured.categories;
  childCategoriesCreated += ensured.added;

  final utilities = _findByName(categories, _utilitiesName);
  if (utilities != null && utilities.id != bills.id && !utilities.archived) {
    final index = categories.indexWhere((item) => item.id == utilities.id);
    categories[index] = utilities.copyWith(archived: true);
  }

  final otherId = _findByName(categories, _otherName)?.id ?? 'other';
  final snacksId = _findByName(categories, _snacksName)!.id;
  final billsId = _findByName(categories, _billsName)!.id;
  final names = {for (final item in categories) item.id: item.name};

  final planned = <PlannedMove>[];
  for (final snap in before) {
    final next = _classify(
      categoryId: snap.categoryId,
      amount: snap.amount,
      detail: snap.detail,
      note: snap.note,
      cafeId: cafeId,
      snacksId: snacksId,
      billsId: billsId,
      otherId: otherId,
      utilitiesId: utilities?.id,
      categoryNameById: names,
    );
    if (next.kind == _MoveKind.none &&
        next.categoryId == snap.categoryId &&
        next.detail == snap.detail) {
      continue;
    }
    if (next.kind == _MoveKind.snacks && next.detail != null) {
      ensured = _ensureDetails(categories, snacksId, [next.detail!]);
      categories = ensured.categories;
      childCategoriesCreated += ensured.added;
    }
    planned.add(
      PlannedMove(
        before: snap,
        targetCategoryId: next.categoryId,
        targetCategoryName: names[next.categoryId] ?? next.categoryId,
        targetDetail: next.detail,
        kind: next.kind.name,
      ),
    );
  }

  try {
    await db.execute('SAVEPOINT category_normalize');
    try {
      await db.execute('''
CREATE TABLE IF NOT EXISTS app_prefs (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
      for (final move in planned) {
        await db.update(
          'transactions',
          {
            'category_id': move.targetCategoryId,
            'detail': move.targetDetail,
          },
          where: 'id = ?',
          whereArgs: [move.before.transactionId],
        );
      }
      await _saveCatalogJson(db, stored, categories);

      final afterRows = await db.query('transactions');
      final after = _snapshots(afterRows, categories);
      final post = _postCheck(
        before: before,
        after: after,
        catalog: categories,
        planned: planned,
        cafeId: cafeId,
      );
      final built = _report(
        committed: post.errors.isEmpty,
        categoriesCreated: categoriesCreated,
        childCategoriesCreated: childCategoriesCreated,
        planned: planned,
        before: before,
        after: after,
        beforeCatalog: currentCatalog,
        afterCatalog: categories,
        otherId: otherId,
        cafeId: cafeId,
        errors: post.errors,
        countPass: post.countPass,
        amountPass: post.amountPass,
        idsPass: post.idsPass,
        fieldsPass: post.fieldsPass,
        integrityPass: post.integrityPass,
        mappingPass: post.mappingPass,
      );
      if (!built.allPass) {
        throw CategoryNormalizeAborted(built);
      }
      await db.execute('RELEASE SAVEPOINT category_normalize');
      write(built.summary);
      return built;
    } catch (error) {
      await db.execute('ROLLBACK TO SAVEPOINT category_normalize');
      await db.execute('RELEASE SAVEPOINT category_normalize');
      rethrow;
    }
  } on CategoryNormalizeAborted catch (aborted) {
    write(aborted.report.summary);
    rethrow;
  }
}

class _PostCheck {
  const _PostCheck({
    required this.errors,
    required this.countPass,
    required this.amountPass,
    required this.idsPass,
    required this.fieldsPass,
    required this.integrityPass,
    required this.mappingPass,
  });

  final List<String> errors;
  final bool countPass;
  final bool amountPass;
  final bool idsPass;
  final bool fieldsPass;
  final bool integrityPass;
  final bool mappingPass;
}

_PostCheck _postCheck({
  required List<TxSnapshot> before,
  required List<TxSnapshot> after,
  required List<ChiChoCategory> catalog,
  required List<PlannedMove> planned,
  required String cafeId,
}) {
  final errors = <String>[];
  final countPass = before.length == after.length;
  if (!countPass) {
    errors.add(
      'Transaction count changed: ${before.length} → ${after.length}',
    );
  }

  final beforeAmount = _totalAmount(before);
  final afterAmount = _totalAmount(after);
  final amountPass = beforeAmount == afterAmount;
  if (!amountPass) {
    errors.add('Total amount changed: $beforeAmount → $afterAmount');
  }

  final beforeIds = before.map((tx) => tx.transactionId).toSet();
  final afterIds = after.map((tx) => tx.transactionId).toSet();
  final idsPass =
      beforeIds.length == before.length &&
      afterIds.length == after.length &&
      beforeIds.length == afterIds.length &&
      beforeIds.containsAll(afterIds);
  if (!idsPass) {
    errors.add('Transaction ID set changed.');
    errors.addAll([
      for (final id in beforeIds.difference(afterIds)) 'Missing ID after: $id',
      for (final id in afterIds.difference(beforeIds)) 'New ID after: $id',
    ]);
  }

  final afterById = {for (final tx in after) tx.transactionId: tx};
  final plannedById = {
    for (final move in planned) move.before.transactionId: move,
  };
  var fieldsPass = true;
  for (final snap in before) {
    final next = afterById[snap.transactionId];
    if (next == null) continue;
    if (!_immutableFieldsMatch(snap, next)) {
      fieldsPass = false;
      errors.add('Immutable fields changed for ${snap.transactionId}.');
    }
    final move = plannedById[snap.transactionId];
    if (move == null &&
        (next.categoryId != snap.categoryId || next.detail != snap.detail)) {
      fieldsPass = false;
      errors.add('Unplanned category change for ${snap.transactionId}.');
    }
  }

  final integrity = _integrityErrors(after, catalog);
  final integrityPass = integrity.isEmpty;
  errors.addAll(integrity);

  var mappingPass = true;
  for (final move in planned) {
    final next = afterById[move.before.transactionId];
    if (next == null) {
      mappingPass = false;
      errors.add('Planned ${move.before.transactionId} missing after migrate.');
      continue;
    }
    if (next.categoryId != move.targetCategoryId ||
        next.detail != move.targetDetail) {
      mappingPass = false;
      errors.add(
        'Mapping failed for ${move.before.transactionId}: '
        'expected ${move.targetCategoryName} / ${move.targetDetail}, '
        'got ${next.categoryName} / ${next.detail}',
      );
    }
  }

  for (final snap in before) {
    if (!_isCafeSnap(snap, cafeId) ||
        snap.amount == 29000 ||
        snap.amount == 26000) {
      continue;
    }
    final next = afterById[snap.transactionId];
    if (next == null) continue;
    if (foldKey(next.detail ?? '') == foldKey(_highlands) &&
        foldKey(snap.detail ?? '') != foldKey(_highlands)) {
      mappingPass = false;
      errors.add(
        'Cafe ${snap.transactionId} amount ${snap.amount} was assigned Highlands.',
      );
    }
    if (foldKey(next.detail ?? '') == foldKey(_obau) &&
        foldKey(snap.detail ?? '') != foldKey(_obau)) {
      mappingPass = false;
      errors.add(
        'Cafe ${snap.transactionId} amount ${snap.amount} was assigned Ô Bầu.',
      );
    }
  }

  return _PostCheck(
    errors: errors,
    countPass: countPass,
    amountPass: amountPass,
    idsPass: idsPass,
    fieldsPass: fieldsPass,
    integrityPass: integrityPass,
    mappingPass: mappingPass,
  );
}

bool _immutableFieldsMatch(TxSnapshot before, TxSnapshot after) {
  return before.transactionId == after.transactionId &&
      before.amount == after.amount &&
      before.occurredDate == after.occurredDate &&
      before.occurredTime == after.occurredTime &&
      before.paymentSourceId == after.paymentSourceId &&
      before.paymentSourceName == after.paymentSourceName &&
      before.note == after.note &&
      before.createdAt == after.createdAt &&
      before.updatedAt == after.updatedAt;
}

bool _isCafeSnap(TxSnapshot snap, String cafeId) {
  final blob = foldKey(
    '${snap.detail ?? ''} ${snap.note ?? ''} ${snap.categoryName}',
  );
  return snap.categoryId == cafeId ||
      foldKey(snap.categoryName) == 'cafe' ||
      blob.contains('cafe') ||
      blob.contains('ca phe') ||
      blob.contains('coffee');
}

List<String> _integrityErrors(
  List<TxSnapshot> txs,
  List<ChiChoCategory> catalog,
) {
  final errors = <String>[];
  final ids = <String>{};
  for (final tx in txs) {
    if (tx.transactionId.trim().isEmpty) {
      errors.add('Transaction missing ID.');
    } else if (!ids.add(tx.transactionId)) {
      errors.add('Duplicate transaction ID: ${tx.transactionId}');
    }
  }

  final categoryIds = <String>{};
  final categoryNames = <String>{};
  for (final category in catalog) {
    if (!categoryIds.add(category.id)) {
      errors.add('Duplicate category id: ${category.id}');
    }
    if (!category.archived) {
      final name = foldKey(category.name);
      if (!categoryNames.add(name)) {
        errors.add('Duplicate category name: ${category.name}');
      }
    }
    final childNames = <String>{};
    for (final detail in category.details) {
      final folded = foldKey(detail);
      if (!childNames.add(folded)) {
        errors.add('Duplicate child "$detail" under ${category.name}.');
      }
    }
  }

  for (final tx in txs) {
    if (tx.categoryId.isNotEmpty && !categoryIds.contains(tx.categoryId)) {
      errors.add(
        'Transaction ${tx.transactionId} references missing category ${tx.categoryId}.',
      );
    }
  }
  return errors;
}

List<TxSnapshot> _snapshots(
  List<Map<String, Object?>> rows,
  List<ChiChoCategory> catalog,
) {
  final byId = {for (final item in catalog) item.id: item};
  return [
    for (final row in rows)
      TxSnapshot(
        transactionId: (row['id'] as String?)?.trim() ?? '',
        amount: (row['amount'] as num?)?.toInt() ?? 0,
        occurredDate: row['occurred_date'] as String? ?? '',
        occurredTime: row['occurred_time'] as String?,
        categoryId: row['category_id'] as String? ?? '',
        categoryName: byId[row['category_id']]?.name ?? '',
        parentCategoryId: row['category_id'] as String? ?? '',
        parentCategoryName: byId[row['category_id']]?.name ?? '',
        paymentSourceId: row['payment_source_id'] as String? ?? '',
        paymentSourceName: row['payment_source_name'] as String? ?? '',
        note: row['note'] as String?,
        detail: row['detail'] as String?,
        createdAt: row['created_at'] as String? ?? '',
        updatedAt: row['updated_at'] as String? ?? '',
      ),
  ];
}

List<String> _precheckRowErrors(List<Map<String, Object?>> rows) {
  final errors = <String>[];
  for (final row in rows) {
    final id = row['id'] as String?;
    if (id == null || id.trim().isEmpty) {
      errors.add('Transaction missing ID.');
    }
    if (row['amount'] == null) {
      errors.add('Transaction ${id ?? '(no id)'} missing amount.');
    }
  }
  return errors;
}

int _totalAmount(List<TxSnapshot> txs) {
  var total = 0;
  for (final tx in txs) {
    total += tx.amount;
  }
  return total;
}

int _childCount(List<ChiChoCategory> catalog) {
  var total = 0;
  for (final category in catalog) {
    total += category.details.length;
  }
  return total;
}

CategoryNormalizeReport _abortedReport({
  required List<TxSnapshot> before,
  required List<ChiChoCategory> catalog,
  required List<String> errors,
}) {
  return _report(
    committed: false,
    categoriesCreated: 0,
    childCategoriesCreated: 0,
    planned: const [],
    before: before,
    after: before,
    beforeCatalog: catalog,
    afterCatalog: catalog,
    otherId: _findByName(catalog, _otherName)?.id ?? 'other',
    cafeId: _findByName(catalog, _cafeName)?.id ?? ChiChoCatalog.defaultId,
    errors: errors,
    countPass: false,
    amountPass: false,
    idsPass: false,
    fieldsPass: false,
    integrityPass: false,
    mappingPass: false,
  );
}

CategoryNormalizeReport _report({
  required bool committed,
  required int categoriesCreated,
  required int childCategoriesCreated,
  required List<PlannedMove> planned,
  required List<TxSnapshot> before,
  required List<TxSnapshot> after,
  required List<ChiChoCategory> beforeCatalog,
  required List<ChiChoCategory> afterCatalog,
  required String otherId,
  required String cafeId,
  required List<String> errors,
  required bool countPass,
  required bool amountPass,
  required bool idsPass,
  required bool fieldsPass,
  required bool integrityPass,
  required bool mappingPass,
}) {
  var otherToSnacks = 0;
  var utilitiesToBills = 0;
  var cafeToHighlands = 0;
  var cafeToObau = 0;
  for (final move in planned) {
    switch (move.kind) {
      case 'snacks':
        otherToSnacks += 1;
      case 'bills':
        utilitiesToBills += 1;
      case 'highlands':
        cafeToHighlands += 1;
      case 'obau':
        cafeToObau += 1;
      default:
        break;
    }
  }
  return CategoryNormalizeReport(
    committed: committed,
    categoriesCreated: categoriesCreated,
    childCategoriesCreated: childCategoriesCreated,
    otherToSnacks: otherToSnacks,
    utilitiesToBills: utilitiesToBills,
    cafeToHighlands: cafeToHighlands,
    cafeToObau: cafeToObau,
    otherUnchanged: after.where((tx) => tx.categoryId == otherId).length,
    cafeUnspecified: after
        .where(
          (tx) =>
              _isCafeSnap(tx, cafeId) &&
              tx.amount != 29000 &&
              tx.amount != 26000,
        )
        .length,
    beforeCount: before.length,
    beforeAmount: _totalAmount(before),
    beforeCategories: beforeCatalog.length,
    beforeChildren: _childCount(beforeCatalog),
    afterCount: after.length,
    afterAmount: _totalAmount(after),
    afterCategories: afterCatalog.length,
    afterChildren: _childCount(afterCatalog),
    countPass: countPass,
    amountPass: amountPass,
    idsPass: idsPass,
    fieldsPass: fieldsPass,
    integrityPass: integrityPass,
    mappingPass: mappingPass,
    errors: errors,
    planned: planned,
  );
}

enum _MoveKind { none, snacks, bills, highlands, obau }

class _Classified {
  const _Classified({
    required this.categoryId,
    required this.detail,
    required this.kind,
  });

  final String categoryId;
  final String? detail;
  final _MoveKind kind;
}

_Classified _classify({
  required String categoryId,
  required int amount,
  required String? detail,
  required String? note,
  required String cafeId,
  required String snacksId,
  required String billsId,
  required String otherId,
  required String? utilitiesId,
  required Map<String, String> categoryNameById,
}) {
  final categoryName = categoryNameById[categoryId] ?? '';
  final blob = foldKey('${detail ?? ''} ${note ?? ''} $categoryName');
  final detailFold = foldKey(detail ?? '');

  final isCafe =
      categoryId == cafeId ||
      foldKey(categoryName) == 'cafe' ||
      blob.contains('cafe') ||
      blob.contains('ca phe') ||
      blob.contains('coffee');
  if (isCafe && amount == 29000 && detailFold != foldKey(_highlands)) {
    return _Classified(
      categoryId: cafeId,
      detail: _highlands,
      kind: _MoveKind.highlands,
    );
  }
  if (isCafe && amount == 26000 && detailFold != foldKey(_obau)) {
    return _Classified(
      categoryId: cafeId,
      detail: _obau,
      kind: _MoveKind.obau,
    );
  }

  final isUtilityCategory =
      categoryId == utilitiesId ||
      foldKey(categoryName) == foldKey(_utilitiesName);
  if ((isUtilityCategory || _isBillText(detailFold)) && categoryId != billsId) {
    return _Classified(
      categoryId: billsId,
      detail: detail,
      kind: _MoveKind.bills,
    );
  }

  if (categoryId == otherId || foldKey(categoryName) == foldKey(_otherName)) {
    final mapped = _mapSnackDetail(detail, detailFold, blob);
    if (mapped != null) {
      return _Classified(
        categoryId: snacksId,
        detail: mapped,
        kind: _MoveKind.snacks,
      );
    }
  }

  return _Classified(
    categoryId: categoryId,
    detail: detail,
    kind: _MoveKind.none,
  );
}

bool _isBillText(String detailFold) {
  return detailFold == 'dien' ||
      detailFold == 'nuoc' ||
      detailFold == 'tien dien' ||
      detailFold == 'tien nuoc' ||
      detailFold == 'dien nuoc' ||
      detailFold == 'hoa don';
}

String? _mapSnackDetail(String? detail, String detailFold, String blob) {
  if (detailFold == 'nuoc cam' || blob.contains('nuoc cam')) return _nuocCam;
  if (detailFold == 'nuoc dua' || blob.contains('nuoc dua')) return _nuocDua;
  if (detailFold == 'nuoc mia' || blob.contains('nuoc mia')) return _nuocMia;
  if (detailFold == 'dua') return _nuocDua;

  const phrases = [
    'che bap',
    'kem',
    'tau hu',
    'sinh to',
    'sua dau xanh',
    'rau ma',
    'tra o long',
    'revive',
    'reveive',
  ];
  for (final phrase in phrases) {
    if (detailFold == phrase ||
        detailFold.startsWith('$phrase ') ||
        blob.contains(phrase)) {
      return detail;
    }
  }
  return null;
}

class _EnsureCategory {
  const _EnsureCategory({
    required this.categories,
    required this.id,
    required this.created,
  });
  final List<ChiChoCategory> categories;
  final String id;
  final bool created;
}

class _EnsureDetails {
  const _EnsureDetails({required this.categories, required this.added});
  final List<ChiChoCategory> categories;
  final int added;
}

List<ChiChoCategory> _catalogFromStoredOrV3(Map<String, dynamic>? stored) {
  if (stored != null) return _categoriesFromJson(stored);
  return [
    for (final item in ChiChoCatalog.all)
      if (foldKey(item.name) != foldKey(_snacksName) &&
          foldKey(item.name) != foldKey(_billsName))
        item,
  ];
}

_EnsureCategory _ensureCategory(
  List<ChiChoCategory> current, {
  required String name,
  required String preferredId,
  required String visualKey,
}) {
  final existing = _findByName(current, name);
  if (existing != null) {
    if (existing.archived) {
      final next = [...current];
      final index = next.indexWhere((item) => item.id == existing.id);
      next[index] = existing.copyWith(archived: false);
      return _EnsureCategory(categories: next, id: existing.id, created: false);
    }
    return _EnsureCategory(categories: current, id: existing.id, created: false);
  }

  final id = current.any((item) => item.id == preferredId)
      ? '${preferredId}_${name.hashCode.abs()}'
      : preferredId;
  final created = ChiChoCategory(
    id: id,
    name: name,
    details: const [_otherName],
    visualKey: visualKey,
  );
  final otherIndex = current.indexWhere(
    (item) => foldKey(item.name) == foldKey(_otherName),
  );
  final next = [...current];
  if (otherIndex >= 0) {
    next.insert(otherIndex, created);
  } else {
    next.add(created);
  }
  return _EnsureCategory(categories: next, id: id, created: true);
}

_EnsureDetails _ensureDetails(
  List<ChiChoCategory> current,
  String categoryId,
  List<String> names,
) {
  final index = current.indexWhere((item) => item.id == categoryId);
  if (index < 0) return _EnsureDetails(categories: current, added: 0);

  final category = current[index];
  final details = [...category.details];
  var added = 0;
  for (final name in names) {
    if (details.any((item) => foldKey(item) == foldKey(name))) continue;
    final otherIndex = details.indexWhere(
      (item) => foldKey(item) == foldKey(_otherName),
    );
    if (otherIndex >= 0) {
      details.insert(otherIndex, name);
    } else {
      details.add(name);
    }
    added += 1;
  }
  if (added == 0) return _EnsureDetails(categories: current, added: 0);
  final next = [...current];
  next[index] = category.copyWith(details: details);
  return _EnsureDetails(categories: next, added: added);
}

ChiChoCategory? _findByName(List<ChiChoCategory> categories, String name) {
  final folded = foldKey(name);
  for (final category in categories) {
    if (foldKey(category.name) == folded) return category;
  }
  return null;
}

List<ChiChoCategory> _categoriesFromJson(Map<String, dynamic> map) {
  return [
    for (final item in map['categories'] as List<dynamic>)
      ChiChoCategory(
        id: (item as Map<String, dynamic>)['id'] as String,
        name: item['name'] as String,
        details: (item['details'] as List<dynamic>).cast<String>(),
        visualKey: item['visualKey'] as String? ?? 'other',
        archived: item['archived'] as bool? ?? false,
      ),
  ];
}

Future<Map<String, dynamic>?> _loadCatalogJson(DatabaseExecutor db) async {
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'app_prefs'",
  );
  if (tables.isEmpty) return null;
  final rows = await db.query(
    'app_prefs',
    where: 'key = ?',
    whereArgs: [_catalogPrefKey],
    limit: 1,
  );
  if (rows.isEmpty) return null;
  final raw = rows.first['value'] as String?;
  if (raw == null || raw.isEmpty) return null;
  return jsonDecode(raw) as Map<String, dynamic>;
}

Future<void> _saveCatalogJson(
  DatabaseExecutor db,
  Map<String, dynamic>? stored,
  List<ChiChoCategory> categories,
) async {
  final payload = <String, dynamic>{
    'version': stored?['version'] ?? 1,
    'categories': [
      for (final category in categories)
        {
          'id': category.id,
          'name': category.name,
          'details': category.details,
          'visualKey': category.visualKey,
          'archived': category.archived,
        },
    ],
    'payments': stored?['payments'] ?? _defaultPaymentsJson(),
  };
  await db.insert('app_prefs', {
    'key': _catalogPrefKey,
    'value': jsonEncode(payload),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

List<Map<String, dynamic>> _defaultPaymentsJson() {
  return [
    for (final payment in PaymentOptionCatalog.all)
      {
        'id': payment.source.id,
        'name': payment.source.name,
        'method': payment.source.method.storageValue,
        'typeLabel': payment.typeLabel,
        'archived': payment.archived,
      },
  ];
}

String foldKey(String raw) {
  const marks = {
    'à': 'a',
    'á': 'a',
    'ả': 'a',
    'ã': 'a',
    'ạ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'ặ': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ậ': 'a',
    'è': 'e',
    'é': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ẹ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ệ': 'e',
    'ì': 'i',
    'í': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ị': 'i',
    'ò': 'o',
    'ó': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ọ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ộ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ợ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ụ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ự': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'ỵ': 'y',
    'đ': 'd',
  };
  final buffer = StringBuffer();
  for (final rune in raw.trim().toLowerCase().runes) {
    if (rune >= 0x300 && rune <= 0x36F) continue;
    final ch = String.fromCharCode(rune);
    buffer.write(marks[ch] ?? ch);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
