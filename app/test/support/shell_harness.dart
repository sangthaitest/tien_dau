import 'package:flutter/widgets.dart';
import 'package:tien_day/application/app_settings_service.dart';
import 'package:tien_day/application/backup_service.dart';
import 'package:tien_day/application/finance_service.dart';
import 'package:tien_day/application/restore_service.dart';
import 'package:tien_day/application/session_sensitive_access.dart';
import 'package:tien_day/application/transaction_catalog_service.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/application/user_profile_service.dart';
import 'package:tien_day/data/backup/backup_ports.dart';
import 'package:tien_day/presentation/catalog/transaction_catalog_controller.dart';
import 'package:tien_day/presentation/catalog/transaction_catalog_scope.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/profile/user_profile_controller.dart';
import 'package:tien_day/presentation/profile/user_profile_scope.dart';
import 'package:tien_day/presentation/settings/app_settings_controller.dart';
import 'package:tien_day/presentation/settings/settings_scope.dart';
import 'package:tien_day/presentation/shell/main_shell.dart';
import 'package:tien_day/presentation/view_month/view_month_controller.dart';

import 'memory_app_settings_repository.dart';
import 'memory_finance_repository.dart';
import 'memory_recurring_transaction_repository.dart';
import 'memory_transaction_catalog_repository.dart';
import 'memory_user_profile_repository.dart';
import 'memory_view_month_repository.dart';

({
  Widget shell,
  SessionSensitiveAccess access,
  MemoryFinanceRepository finance,
  MemoryRecurringTransactionRepository recurring,
  AppSettingsController settings,
  UserProfileController profile,
  TransactionCatalogController catalog,
  ViewMonthController viewMonth,
})
buildShell({
  required TransactionService transactions,
  required HomeController home,
  DateTime Function()? clock,
  MemoryPinRepository? pinRepo,
  MemoryFinanceRepository? financeRepo,
  MemoryRecurringTransactionRepository? recurringRepo,
  MemoryAppSettingsRepository? settingsRepo,
  MemoryUserProfileRepository? profileRepo,
  ViewMonthController? viewMonth,
  BackupService? backupService,
  RestoreService? restoreService,
  BackupSharePort? backupShare,
  BackupPickPort? backupPicker,
}) {
  final pins = pinRepo ?? MemoryPinRepository();
  final money = financeRepo ?? MemoryFinanceRepository();
  final recurring = recurringRepo ?? MemoryRecurringTransactionRepository();
  final now = clock ?? DateTime.now;
  final access = SessionSensitiveAccess(
    repository: pins,
    saltFactory: () => 'test-salt',
  );
  final settings = AppSettingsController(
    AppSettingsService(settingsRepo ?? MemoryAppSettingsRepository()),
  );
  final profile = UserProfileController(
    UserProfileService(profileRepo ?? MemoryUserProfileRepository()),
  );
  var nextCatalogId = 0;
  var nextFinanceId = 0;
  final catalog = TransactionCatalogController(
    TransactionCatalogService(
      MemoryTransactionCatalogRepository(),
      idFactory: () => 'test-${nextCatalogId++}',
    ),
  );
  final month = viewMonth ?? buildTestViewMonthController(clock: now);
  final shell = MainShell(
    transactionService: transactions,
    homeController: home,
    financeService: FinanceService(
      money,
      transactions,
      recurring,
      idFactory: () => 'finance-${nextFinanceId++}',
      clock: now,
    ),
    sensitiveAccess: access,
    catalogController: catalog,
    viewMonthController: month,
    backupService: backupService,
    restoreService: restoreService,
    backupShare: backupShare,
    backupPicker: backupPicker,
    clock: now,
  );
  return (
    shell: SettingsScope(
      controller: settings,
      child: UserProfileScope(
        controller: profile,
        child: TransactionCatalogScope(controller: catalog, child: shell),
      ),
    ),
    access: access,
    finance: money,
    recurring: recurring,
    settings: settings,
    profile: profile,
    catalog: catalog,
    viewMonth: month,
  );
}
