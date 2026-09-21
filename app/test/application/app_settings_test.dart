import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/application/app_settings_service.dart';
import 'package:tien_day/data/datasources/finance_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/repositories/app_settings_repository_impl.dart';
import 'package:tien_day/domain/entities/app_settings.dart';
import 'package:tien_day/presentation/format/money_format.dart';
import 'package:tien_day/presentation/settings/app_settings_controller.dart';
import 'package:tien_day/presentation/theme/app_colors.dart';

import '../support/memory_app_settings_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() {
    AppColors.dark = false;
  });

  test('defaults match V3 prefs', () {
    expect(AppSettings.defaults.darkMode, isFalse);
    expect(AppSettings.defaults.balanceHidden, isFalse);
    expect(AppSettings.defaults.notificationsEnabled, isTrue);
    expect(AppSettings.defaults.hasCompletedTutorial, isFalse);
    expect(AppSettings.defaults.hasCompletedFinanceTutorial, isFalse);
    expect(AppSettings.defaults.hasCompletedBackupTutorial, isFalse);
    expect(AppSettings.defaults.hasCompletedTransactionsTutorial, isFalse);
    expect(AppSettings.defaults.hasCompletedStatisticsTutorial, isFalse);
    expect(AppSettings.defaults.hasCompletedAddTutorial, isFalse);
  });

  test('displayVnd masks like Demo maskMoney', () {
    expect(displayVnd(45000, hidden: false), '45.000 ₫');
    expect(displayVnd(45000, hidden: true), '••••••••');
    expect(displayVnd(45000, hidden: true, short: true), '••••');
    expect(displayVnd(50000, hidden: false, short: true), '50k');
  });

  test('toggles persist across a fresh controller load', () async {
    final repo = MemoryAppSettingsRepository();
    final first = AppSettingsController(AppSettingsService(repo));
    await first.load();
    expect(first.settings, AppSettings.defaults);

    await first.setDarkMode(true);
    await first.setBalanceHidden(true);
    await first.setNotificationsEnabled(false);
    first.dispose();

    final second = AppSettingsController(AppSettingsService(repo));
    await second.load();
    expect(second.settings.darkMode, isTrue);
    expect(second.settings.balanceHidden, isTrue);
    expect(second.settings.notificationsEnabled, isFalse);
    expect(AppColors.dark, isTrue);
    second.dispose();
  });

  test('missing stored prefs keep V3 defaults', () async {
    final repo = MemoryAppSettingsRepository(stored: const AppSettings());
    final controller = AppSettingsController(AppSettingsService(repo));
    await controller.load();
    expect(controller.settings.darkMode, isFalse);
    expect(controller.settings.balanceHidden, isFalse);
    expect(controller.settings.notificationsEnabled, isTrue);
    controller.dispose();
  });

  test('tutorial completion persists across a fresh controller load', () async {
    final repo = MemoryAppSettingsRepository();
    final first = AppSettingsController(AppSettingsService(repo));
    await first.load();
    expect(first.settings.hasCompletedTutorial, isFalse);

    await first.setTutorialCompleted(true);
    await first.setFinanceTutorialCompleted(true);
    await first.setBackupTutorialCompleted(true);
    await first.setTransactionsTutorialCompleted(true);
    await first.setStatisticsTutorialCompleted(true);
    await first.setAddTutorialCompleted(true);
    first.dispose();

    final second = AppSettingsController(AppSettingsService(repo));
    await second.load();
    expect(second.settings.hasCompletedTutorial, isTrue);
    expect(second.settings.hasCompletedFinanceTutorial, isTrue);
    expect(second.settings.hasCompletedBackupTutorial, isTrue);
    expect(second.settings.hasCompletedTransactionsTutorial, isTrue);
    expect(second.settings.hasCompletedStatisticsTutorial, isTrue);
    expect(second.settings.hasCompletedAddTutorial, isTrue);
    second.dispose();
  });

  test('completeAllTutorials marks every section', () async {
    final repo = MemoryAppSettingsRepository();
    final controller = AppSettingsController(AppSettingsService(repo));
    await controller.load();
    await controller.completeAllTutorials();
    expect(controller.settings.hasCompletedTutorial, isTrue);
    expect(controller.settings.hasCompletedFinanceTutorial, isTrue);
    expect(controller.settings.hasCompletedBackupTutorial, isTrue);
    expect(controller.settings.hasCompletedTransactionsTutorial, isTrue);
    expect(controller.settings.hasCompletedStatisticsTutorial, isTrue);
    expect(controller.settings.hasCompletedAddTutorial, isTrue);
    controller.dispose();
  });

  test('SQLite prefs persist settings across reload', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_settings');
    final db = await AppDatabase.openPath(p.join(dir.path, 'tien_day.db'));
    addTearDown(db.close);
    final repo = AppSettingsRepositoryImpl(PrefsLocalDataSource(db));
    final first = AppSettingsController(AppSettingsService(repo));
    await first.load();
    expect(first.settings.notificationsEnabled, isTrue);
    await first.setDarkMode(true);
    await first.setBalanceHidden(true);
    await first.setNotificationsEnabled(false);
    await first.setTutorialCompleted(true);
    await first.setFinanceTutorialCompleted(true);
    await first.setBackupTutorialCompleted(true);
    await first.setTransactionsTutorialCompleted(true);
    await first.setStatisticsTutorialCompleted(true);
    await first.setAddTutorialCompleted(true);
    first.dispose();

    final second = AppSettingsController(AppSettingsService(repo));
    await second.load();
    expect(second.settings.darkMode, isTrue);
    expect(second.settings.balanceHidden, isTrue);
    expect(second.settings.notificationsEnabled, isFalse);
    expect(second.settings.hasCompletedTutorial, isTrue);
    expect(second.settings.hasCompletedFinanceTutorial, isTrue);
    expect(second.settings.hasCompletedBackupTutorial, isTrue);
    expect(second.settings.hasCompletedTransactionsTutorial, isTrue);
    expect(second.settings.hasCompletedStatisticsTutorial, isTrue);
    expect(second.settings.hasCompletedAddTutorial, isTrue);
    second.dispose();
  });
}
