import 'package:flutter/material.dart';

import '../application/finance_service.dart';
import '../application/home_query.dart';
import '../application/transaction_service.dart';
import '../domain/security/sensitive_access_port.dart';
import 'home/home_controller.dart';
import 'settings/app_settings_controller.dart';
import 'settings/settings_scope.dart';
import 'shell/main_shell.dart';
import 'theme/app_theme.dart';

class TienDayApp extends StatefulWidget {
  const TienDayApp({
    super.key,
    required this.transactionService,
    required this.financeService,
    required this.sensitiveAccess,
    required this.settingsController,
  });

  final TransactionService transactionService;
  final FinanceService financeService;
  final SensitiveAccessPort sensitiveAccess;
  final AppSettingsController settingsController;

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
            child: MainShell(
              transactionService: widget.transactionService,
              homeController: _homeController,
              financeService: widget.financeService,
              sensitiveAccess: widget.sensitiveAccess,
            ),
          ),
        );
      },
    );
  }
}
