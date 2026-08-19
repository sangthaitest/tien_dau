import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/application/view_month_service.dart';
import 'package:tien_day/data/datasources/finance_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/repositories/view_month_repository_impl.dart';
import 'package:tien_day/domain/time/clock_format.dart';
import 'package:tien_day/presentation/view_month/view_month_controller.dart';

import '../support/memory_view_month_repository.dart';

void main() {
  final august = DateTime(2026, 8, 18, 9);

  test('parseMonthKey accepts YYYY-MM and rejects junk', () {
    expect(parseMonthKey('2026-07'), DateTime(2026, 7));
    expect(parseMonthKey('2026-13'), isNull);
    expect(parseMonthKey('nope'), isNull);
    expect(parseMonthKey(null), isNull);
  });

  test('lastTwelveMonths starts at the current month', () {
    final months = lastTwelveMonths(august);
    expect(months, hasLength(12));
    expect(months.first, DateTime(2026, 8));
    expect(months.last, DateTime(2025, 9));
  });

  test('defaults to the clock month when nothing is stored', () async {
    final service = ViewMonthService(MemoryViewMonthRepository());
    final month = (await service.load(fallback: august)).unwrapOrThrow();
    expect(month, DateTime(2026, 8));
  });

  test('persists the selected month across reload', () async {
    final repository = MemoryViewMonthRepository();
    final service = ViewMonthService(repository);
    expect((await service.save(DateTime(2026, 7, 20))).isOk, isTrue);
    expect(repository.stored, '2026-07');
    final month = (await service.load(fallback: august)).unwrapOrThrow();
    expect(month, DateTime(2026, 7));
  });

  test('controller select notifies and writes prefs', () async {
    final repository = MemoryViewMonthRepository();
    final controller = ViewMonthController(
      ViewMonthService(repository),
      clock: () => august,
    );
    await controller.select(DateTime(2026, 6));
    expect(controller.month, DateTime(2026, 6));
    expect(repository.stored, '2026-06');
  });

  test('SQLite prefs persist the viewed month across reload', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('tien_day_view_month');
    final database = await AppDatabase.openPath(p.join(dir.path, 'view.db'));
    final service = ViewMonthService(
      ViewMonthRepositoryImpl(PrefsLocalDataSource(database)),
    );
    expect((await service.save(DateTime(2026, 4, 9))).isOk, isTrue);
    final reloaded = ViewMonthService(
      ViewMonthRepositoryImpl(PrefsLocalDataSource(database)),
    );
    final month = (await reloaded.load(fallback: august)).unwrapOrThrow();
    expect(month, DateTime(2026, 4));
    await database.close();
    await dir.delete(recursive: true);
  });
}
