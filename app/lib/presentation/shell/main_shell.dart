import 'package:flutter/material.dart';

import '../../application/finance_service.dart';
import '../../application/statistics_query.dart';
import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/security/sensitive_access_port.dart';
import '../add_transaction/add_transaction_controller.dart';
import '../add_transaction/add_transaction_page.dart';
import '../finance/finance_controller.dart';
import '../finance/finance_page.dart';
import '../finance/pin_sheet.dart';
import '../home/home_controller.dart';
import '../home/home_page.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../settings/settings_page.dart';
import '../settings/settings_scope.dart';
import '../statistics/statistics_controller.dart';
import '../statistics/statistics_page.dart';
import '../theme/app_colors.dart';
import '../transactions/transaction_detail_controller.dart';
import '../transactions/transaction_detail_sheet.dart';
import '../transactions/transaction_list_controller.dart';
import '../transactions/transaction_list_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.transactionService,
    required this.homeController,
    required this.financeService,
    required this.sensitiveAccess,
    this.clock = DateTime.now,
  });

  final TransactionService transactionService;
  final HomeController homeController;
  final FinanceService financeService;
  final SensitiveAccessPort sensitiveAccess;
  final DateTime Function() clock;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _tab = AppTab.home;
  bool _showFinance = false;
  late final TransactionListController _listController;
  late final FinanceController _financeController;
  late final StatisticsController _statsController;

  @override
  void initState() {
    super.initState();
    _listController = TransactionListController(
      widget.transactionService,
      clock: widget.clock,
    );
    _financeController = FinanceController(widget.financeService);
    _statsController = StatisticsController(
      StatisticsQuery(widget.transactionService, clock: widget.clock),
      clock: widget.clock,
    );
  }

  @override
  void dispose() {
    _listController.dispose();
    _financeController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.homeController.load(),
      _listController.load(),
      if (_showFinance) _financeController.load(),
      if (_tab == AppTab.statistics) _statsController.load(),
    ]);
  }

  Future<void> _openAdd() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddTransactionPage(
          controller: AddTransactionController(
            service: widget.transactionService,
            clock: widget.clock,
          ),
        ),
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _openDetail(Transaction tx) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TransactionDetailSheet(
        controller: TransactionDetailController(widget.transactionService),
        transactionService: widget.transactionService,
        clock: widget.clock,
        transactionId: tx.id,
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  void _selectTab(AppTab tab) {
    setState(() {
      _tab = tab;
      if (tab != AppTab.settings) _showFinance = false;
    });
    if (tab == AppTab.transactions) _listController.load();
    if (tab == AppTab.statistics) _statsController.load();
  }

  Future<bool> _ensureUnlocked() async {
    if (await widget.sensitiveAccess.isUnlocked()) return true;
    final hasPin = await widget.sensitiveAccess.hasPin();
    final mode = hasPin ? PinSheetMode.unlock : PinSheetMode.setup;
    if (!mounted) return false;
    return PinSheet.show(context, access: widget.sensitiveAccess, mode: mode);
  }

  Future<void> _openFinance() async {
    final ok = await _ensureUnlocked();
    if (!ok || !mounted) return;
    await _financeController.load();
    setState(() {
      _tab = AppTab.settings;
      _showFinance = true;
    });
  }

  Future<void> _changePin() async {
    final unlocked = await _ensureUnlocked();
    if (!unlocked || !mounted) return;
    final hasPin = await widget.sensitiveAccess.hasPin();
    if (!mounted) return;
    await PinSheet.show(
      context,
      access: widget.sensitiveAccess,
      mode: hasPin ? PinSheetMode.change : PinSheetMode.setup,
    );
  }

  int get _stackIndex {
    return switch (_tab) {
      AppTab.home => 0,
      AppTab.transactions => 1,
      AppTab.statistics => 2,
      AppTab.settings => 3,
    };
  }

  Future<void> _logout() async {
    await widget.sensitiveAccess.lock();
    if (!mounted) return;
    setState(() => _showFinance = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã khóa khu vực tài chính')),
    );
  }

  @override
  Widget build(BuildContext context) {
    SettingsScope.maybeOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: _showFinance
                ? FinancePage(
                    controller: _financeController,
                    onBack: () => setState(() => _showFinance = false),
                  )
                : IndexedStack(
                    index: _stackIndex,
                    children: [
                      HomePage(
                        controller: widget.homeController,
                        transactionService: widget.transactionService,
                        clock: widget.clock,
                        embedNavigation: false,
                        onSeeAll: () => _selectTab(AppTab.transactions),
                        onTransactionTap: _openDetail,
                      ),
                      TransactionListPage(
                        controller: _listController,
                        clock: widget.clock,
                        embedNavigation: false,
                        onAddPressed: _openAdd,
                        onTransactionTap: _openDetail,
                      ),
                      StatisticsPage(controller: _statsController),
                      SettingsPage(
                        onOpenFinance: _openFinance,
                        onChangePin: _changePin,
                        onLogout: _logout,
                      ),
                    ],
                  ),
          ),
          HomeBottomNav(
            tab: _tab == AppTab.settings || _showFinance ? AppTab.settings : _tab,
            onAddPressed: _openAdd,
            onTabSelected: _selectTab,
          ),
        ],
      ),
    );
  }
}
