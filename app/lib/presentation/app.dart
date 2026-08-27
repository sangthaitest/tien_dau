import 'package:flutter/material.dart';

import '../application/backup_service.dart';
import '../application/finance_service.dart';
import '../application/home_query.dart';
import '../application/restore_service.dart';
import '../application/transaction_service.dart';
import '../data/backup/backup_ports.dart';
import '../domain/security/sensitive_access_port.dart';
import 'catalog/transaction_catalog_controller.dart';
import 'catalog/transaction_catalog_scope.dart';
import 'home/home_controller.dart';
import 'profile/user_profile_controller.dart';
import 'profile/user_profile_scope.dart';
import 'settings/app_settings_controller.dart';
import 'settings/settings_scope.dart';
import 'shell/main_shell.dart';
import 'theme/app_theme.dart';
import 'view_month/view_month_controller.dart';

class TienDayApp extends StatefulWidget {
  const TienDayApp({
    super.key,
    required this.transactionService,
    required this.financeService,
    required this.sensitiveAccess,
    required this.settingsController,
    required this.profileController,
    required this.catalogController,
    required this.viewMonthController,
    this.backupService,
    this.restoreService,
    this.backupShare,
    this.backupPicker,
  });

  final TransactionService transactionService;
  final FinanceService financeService;
  final SensitiveAccessPort sensitiveAccess;
  final AppSettingsController settingsController;
  final UserProfileController profileController;
  final TransactionCatalogController catalogController;
  final ViewMonthController viewMonthController;
  final BackupService? backupService;
  final RestoreService? restoreService;
  final BackupSharePort? backupShare;
  final BackupPickPort? backupPicker;

  @override
  State<TienDayApp> createState() => _TienDayAppState();
}

class _TienDayAppState extends State<TienDayApp> {
  late final HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController(HomeQuery(widget.transactionService));
  }

  @override
  void dispose() {
    _homeController.dispose();
    widget.settingsController.dispose();
    widget.profileController.dispose();
    widget.catalogController.dispose();
    widget.viewMonthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (context, _) {
        final dark = widget.settingsController.settings.darkMode;
        return MaterialApp(
          title: 'Tiền đâu nè',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: SettingsScope(
            controller: widget.settingsController,
            child: UserProfileScope(
              controller: widget.profileController,
              child: TransactionCatalogScope(
                controller: widget.catalogController,
                child: MainShell(
                  transactionService: widget.transactionService,
                  homeController: _homeController,
                  financeService: widget.financeService,
                  sensitiveAccess: widget.sensitiveAccess,
                  catalogController: widget.catalogController,
                  viewMonthController: widget.viewMonthController,
                  backupService: widget.backupService,
                  restoreService: widget.restoreService,
                  backupShare: widget.backupShare,
                  backupPicker: widget.backupPicker,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
