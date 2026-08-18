import 'package:flutter/material.dart';

import '../application/finance_service.dart';
import '../application/home_query.dart';
import '../application/transaction_service.dart';
import '../domain/security/sensitive_access_port.dart';
import 'home/home_controller.dart';
import 'shell/main_shell.dart';
import 'theme/app_theme.dart';

class TienDayApp extends StatefulWidget {
  const TienDayApp({
    super.key,
    required this.transactionService,
    required this.financeService,
    required this.sensitiveAccess,
  });

  final TransactionService transactionService;
  final FinanceService financeService;
  final SensitiveAccessPort sensitiveAccess;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiền Đây',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: MainShell(
        transactionService: widget.transactionService,
        homeController: _homeController,
        financeService: widget.financeService,
        sensitiveAccess: widget.sensitiveAccess,
      ),
    );
  }
}
