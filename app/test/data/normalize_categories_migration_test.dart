import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/db/migrations/normalize_categories.dart';
import 'package:tien_day/domain/catalog/chi_cho_catalog.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('adds Ăn vặt and Hóa đơn without duplicating, then recategorizes rows', () async {
    final dir = await Directory.systemTemp.createTemp('normalize_cat');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    final db = await _openV3(path);
    await _insertTx(
      db,
      id: 'cam',
      amount: 10000,
      categoryId: 'other',
      detail: 'Nước cam',
      note: 'Bà Dung',
    );
    await _insertTx(
      db,
      id: 'mia',
      amount: 12000,
      categoryId: 'other',
      detail: 'Nước mía',
    );
    await _insertTx(
      db,
      id: 'dua',
      amount: 20000,
      categoryId: 'other',
      detail: 'Nước dừa',
    );
    await _insertTx(
      db,
      id: 've-so',
      amount: 20000,
      categoryId: 'other',
      detail: 'Vé số',
    );
    await _insertTx(
      db,
      id: 'dien',
      amount: 1306195,
      categoryId: 'other',
      detail: 'Điện',
    );
    await _insertTx(
      db,
      id: 'cafe-29',
      amount: 29000,
      categoryId: 'cafe',
      detail: 'Cà phê sữa',
      note: 'Hightlands',
      createdAt: '2026-07-23T00:00:00.000Z',
      updatedAt: '2026-07-23T00:00:00.000Z',
    );
    await _insertTx(
      db,
      id: 'cafe-26',
      amount: 26000,
      categoryId: 'cafe',
      detail: 'Cà phê sữa',
      note: 'Ông Bầu',
      createdAt: '2026-07-24T00:00:00.000Z',
      updatedAt: '2026-07-24T00:00:00.000Z',
    );
    await _insertTx(
      db,
      id: 'cafe-other',
      amount: 31000,
      categoryId: 'cafe',
      detail: 'Cà phê sữa',
    );

    final report = await normalizeCategories(db, log: (_) {});
    expect(report.committed, isTrue);
    expect(report.allPass, isTrue);
    expect(report.summary, contains('Transaction count: PASS'));
    expect(report.summary, contains('Total amount: PASS'));
    expect(report.summary, contains('Mapping verification: PASS'));
    expect(
      report.planned.map((move) => move.before.transactionId),
      containsAll(['cam', 'mia', 'dua', 'dien', 'cafe-29', 'cafe-26']),
    );
    expect(report.planned.map((move) => move.before.transactionId), isNot(contains('ve-so')));
    expect(report.planned.map((move) => move.before.transactionId), isNot(contains('cafe-other')));
    expect(report.categoriesCreated, 2);
    expect(report.otherToSnacks, 3);
    expect(report.utilitiesToBills, 1);
    expect(report.cafeToHighlands, 1);
    expect(report.cafeToObau, 1);
    expect(report.otherUnchanged, 1);

    final cam = (await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: ['cam'],
    )).single;
    expect(cam['category_id'], 'snacks');
    expect(cam['detail'], 'Nước cam');
    expect(cam['amount'], 10000);

    final cafe29 = (await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: ['cafe-29'],
    )).single;
    expect(cafe29['category_id'], 'cafe');
    expect(cafe29['detail'], 'Highlands');
    expect(cafe29['amount'], 29000);
    expect(cafe29['note'], 'Hightlands');
    expect(cafe29['created_at'], '2026-07-23T00:00:00.000Z');
    expect(cafe29['updated_at'], '2026-07-23T00:00:00.000Z');

    final cafeOther = (await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: ['cafe-other'],
    )).single;
    expect(cafeOther['detail'], 'Cà phê sữa');

    final veSo = (await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: ['ve-so'],
    )).single;
    expect(veSo['category_id'], 'other');

    final second = await normalizeCategories(db, log: (_) {});
    expect(second.categoriesCreated, 0);
    expect(second.otherToSnacks, 0);
    expect(second.utilitiesToBills, 0);
    expect(second.cafeToHighlands, 0);
    expect(second.cafeToObau, 0);
    expect(second.otherUnchanged, 1);
    expect(await db.query('transactions'), hasLength(8));
    await db.close();
  });

  test('looks up categories by name and does not duplicate user ids', () async {
    final dir = await Directory.systemTemp.createTemp('normalize_named');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    final db = await _openV3(path);
    await db.execute('''
CREATE TABLE app_prefs (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
    await db.insert('app_prefs', {
      'key': 'transaction_catalog_v1',
      'value': jsonEncode({
        'version': 1,
        'categories': [
          {
            'id': 'user_an_vat',
            'name': 'Ăn vặt',
            'details': ['Khác'],
            'visualKey': 'other',
            'archived': false,
          },
          {
            'id': 'other',
            'name': 'Khác',
            'details': ['Khác'],
            'visualKey': 'other',
            'archived': false,
          },
        ],
        'payments': [
          {
            'id': 'cash',
            'name': 'Tiền mặt',
            'method': 'cash',
            'typeLabel': 'Tiền mặt',
            'archived': false,
          },
        ],
      }),
    });
    await _insertTx(
      db,
      id: 'cam',
      amount: 10000,
      categoryId: 'other',
      detail: 'Nước cam',
    );

    final report = await normalizeCategories(db, log: (_) {});
    expect(report.categoriesCreated, 1);
    expect(report.otherToSnacks, 1);

    final tx = (await db.query('transactions')).single;
    expect(tx['category_id'], 'user_an_vat');

    final raw =
        (await db.query(
              'app_prefs',
              where: 'key = ?',
              whereArgs: ['transaction_catalog_v1'],
            )).single['value']!
            as String;
    final cats = (jsonDecode(raw) as Map)['categories'] as List;
    expect(
      cats.where((item) => (item as Map)['name'] == 'Ăn vặt').length,
      1,
    );
    expect(cats.any((item) => (item as Map)['name'] == 'Hóa đơn'), isTrue);
    await db.close();
  });

  test('v3 to v4 keeps existing rows and is safe to open twice', () async {
    final dir = await Directory.systemTemp.createTemp('normalize_v3');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'legacy.db');
    final legacy = await _openV3(path);
    await _insertTx(
      legacy,
      id: 'keep-me',
      amount: 42000,
      categoryId: 'cafe',
      detail: 'Migration',
    );
    await legacy.close();

    final first = await AppDatabase.openPath(path);
    final rows = await first.raw.query('transactions');
    expect(rows, hasLength(1));
    expect(rows.single['id'], 'keep-me');
    expect(rows.single['amount'], 42000);
    expect(rows.single['detail'], 'Migration');
    await first.close();

    final second = await AppDatabase.openPath(path);
    expect(await second.raw.query('transactions'), hasLength(1));
    await second.close();
  });

  test('built-in catalog exposes Ăn vặt children and Hóa đơn', () {
    final snacks = ChiChoCatalog.byId('snacks');
    expect(snacks.name, 'Ăn vặt');
    expect(snacks.details, containsAll(['Nước cam', 'Nước dừa', 'Nước mía']));
    expect(ChiChoCatalog.byId('bills').name, 'Hóa đơn');
  });

  test('PRE-CHECK aborts and does not modify rows with unknown category', () async {
    final dir = await Directory.systemTemp.createTemp('normalize_abort');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    final db = await _openV3(path);
    await _insertTx(
      db,
      id: 'cam',
      amount: 10000,
      categoryId: 'other',
      detail: 'Nước cam',
    );
    await _insertTx(
      db,
      id: 'broken',
      amount: 1000,
      categoryId: 'ghost-category',
      detail: 'X',
    );

    await expectLater(
      normalizeCategories(db, log: (_) {}),
      throwsA(isA<CategoryNormalizeAborted>()),
    );

    final rows = {
      for (final row in await db.query('transactions')) row['id']: row,
    };
    expect(rows['cam']!['category_id'], 'other');
    expect(rows['cam']!['detail'], 'Nước cam');
    expect(rows['broken']!['category_id'], 'ghost-category');
    expect(await db.query('transactions'), hasLength(2));
    await db.close();
  });

  test('seeded ChiTieu rows recategorize without duplicating', () async {
    final source = File(
      p.normalize(
        p.join(
          Directory.current.path,
          '..',
          'scripts',
          'seed',
          'out',
          'tien_day.db',
        ),
      ),
    );
    if (!source.existsSync()) {
      return;
    }
    final dir = await Directory.systemTemp.createTemp('normalize_seed');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'tien_day.db');
    await source.copy(path);

    final db = await databaseFactory.openDatabase(path);
    final first = await normalizeCategories(db, log: (_) {});
    expect(first.otherToSnacks, 21);
    expect(first.utilitiesToBills, 2);
    expect(first.cafeToHighlands, 13);
    expect(first.cafeToObau, 4);
    expect(first.otherUnchanged, 34);
    expect(first.transactionsMigrated, 40);
    expect(first.committed, isTrue);
    expect(first.allPass, isTrue);
    expect(first.beforeCount, 148);
    expect(first.afterCount, 148);
    expect(first.beforeAmount, first.afterAmount);

    final second = await normalizeCategories(db, log: (_) {});
    expect(second.transactionsMigrated, 0);
    expect(second.otherUnchanged, 34);
    expect(
      (await db.rawQuery(
        'SELECT COUNT(*) AS c FROM transactions',
      )).first['c'],
      148,
    );
    await db.close();
  });
}

Future<Database> _openV3(String path) {
  return databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL,
  category_id TEXT NOT NULL,
  detail TEXT,
  occurred_date TEXT NOT NULL,
  occurred_time TEXT,
  payment_source_id TEXT NOT NULL,
  payment_source_name TEXT NOT NULL,
  payment_method TEXT NOT NULL,
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
      },
    ),
  );
}

Future<void> _insertTx(
  Database db, {
  required String id,
  required int amount,
  required String categoryId,
  String? detail,
  String? note,
  String createdAt = '2026-08-01T00:00:00.000Z',
  String updatedAt = '2026-08-01T00:00:00.000Z',
}) {
  return db.insert('transactions', {
    'id': id,
    'amount': amount,
    'type': 'expense',
    'category_id': categoryId,
    'detail': detail,
    'occurred_date': '2026-08-01',
    'occurred_time': null,
    'payment_source_id': 'cash',
    'payment_source_name': 'Tiền mặt',
    'payment_method': 'cash',
    'note': note,
    'created_at': createdAt,
    'updated_at': updatedAt,
  });
}
