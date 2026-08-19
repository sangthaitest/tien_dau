import 'package:flutter/material.dart';

import '../../application/finance_service.dart';
import '../../application/statistics_query.dart';
import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/result.dart';
import '../../domain/security/sensitive_access_port.dart';
import '../add_transaction/add_transaction_controller.dart';
import '../add_transaction/add_transaction_page.dart';
import '../catalog/transaction_catalog_controller.dart';
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
import '../view_month/view_month_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.transactionService,
    required this.homeController,
    required this.financeService,
    required this.sensitiveAccess,
    required this.catalogController,
    required this.viewMonthController,
    this.clock = DateTime.now,
  });

  final TransactionService transactionService;
  final HomeController homeController;
  final FinanceService financeService;
  final SensitiveAccessPort sensitiveAccess;
  final TransactionCatalogController catalogController;
  final ViewMonthController viewMonthController;
  final DateTime Function() clock;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _tab = AppTab.home;
  bool _showFinance = false;
  bool _openingAdd = false;
  bool _openingSensitive = false;
  bool _openingDetail = false;
  late final TransactionListController _listController;
  late final FinanceController _financeController;
  late final StatisticsController _statsController;

  @override
  void initState() {
    super.initState();
    _listController = TransactionListController(
      widget.transactionService,
      clock: widget.clock,
      viewMonth: () => widget.viewMonthController.month,
    );
    _financeController = FinanceController(
      widget.financeService,
      month: () => widget.viewMonthController.month,
    );
    _statsController = StatisticsController(
      StatisticsQuery(
        widget.transactionService,
        clock: () => widget.viewMonthController.month,
      ),
      clock: () => widget.viewMonthController.month,
    );
    widget.viewMonthController.addListener(_onViewMonthChanged);
  }

  @override
  void dispose() {
    widget.viewMonthController.removeListener(_onViewMonthChanged);
    _listController.dispose();
    _financeController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  void _onViewMonthChanged() {
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.homeController.load(month: widget.viewMonthController.month),
      _listController.load(),
      if (_showFinance) _financeController.load(),
      if (_tab == AppTab.statistics) _statsController.load(),
    ]);
  }

  Future<void> _openAdd() async {
    if (_openingAdd) return;
    _openingAdd = true;
    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AddTransactionPage(
            controller: AddTransactionController(
              service: widget.transactionService,
              catalogController: widget.catalogController,
              clock: widget.clock,
            ),
          ),
        ),
      );
      if (saved == true && mounted) await _refresh();
    } finally {
      _openingAdd = false;
    }
  }

  Future<void> _openDetail(Transaction tx) async {
    if (_openingDetail) return;
    _openingDetail = true;
    try {
      final changed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          final height = MediaQuery.sizeOf(ctx).height;
          final inset = MediaQuery.viewInsetsOf(ctx).bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: SizedBox(
              height: height * 0.85 - inset,
              child: TransactionDetailSheet(
                controller: TransactionDetailController(
                  widget.transactionService,
                ),
                transactionService: widget.transactionService,
                catalogController: widget.catalogController,
                clock: widget.clock,
                transactionId: tx.id,
              ),
            ),
          );
        },
      );
      if (changed == true && mounted) await _refresh();
    } finally {
      _openingDetail = false;
    }
  }

  Future<bool> _deleteTransaction(Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: const Text('Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    final result = await widget.transactionService.remove(tx.id);
    if (result is Ok && mounted) {
      await _refresh();
    }
    return false;
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
    if (_openingSensitive) return;
    _openingSensitive = true;
    try {
      final ok = await _ensureUnlocked();
      if (!ok || !mounted) return;
      await _financeController.load();
      setState(() {
        _tab = AppTab.settings;
        _showFinance = true;
      });
    } finally {
      _openingSensitive = false;
    }
  }

  Future<void> _changePin() async {
    if (_openingSensitive) return;
    _openingSensitive = true;
    try {
      final unlocked = await _ensureUnlocked();
      if (!unlocked || !mounted) return;
      final hasPin = await widget.sensitiveAccess.hasPin();
      if (!mounted) return;
      await PinSheet.show(
        context,
        access: widget.sensitiveAccess,
        mode: hasPin ? PinSheetMode.change : PinSheetMode.setup,
      );
    } finally {
      _openingSensitive = false;
    }
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã khóa khu vực tài chính')));
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
                        catalogController: widget.catalogController,
                        viewMonthController: widget.viewMonthController,
                        clock: widget.clock,
                        embedNavigation: false,
                        onSeeAll: () => _selectTab(AppTab.transactions),
                        onTransactionTap: _openDetail,
                        onAvatarTap: () => _selectTab(AppTab.settings),
                      ),
                      TransactionListPage(
                        controller: _listController,
                        clock: widget.clock,
                        embedNavigation: false,
                        onAddPressed: _openAdd,
                        onTransactionTap: _openDetail,
                        onDelete: _deleteTransaction,
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
            tab: _tab == AppTab.settings || _showFinance
                ? AppTab.settings
                : _tab,
            onAddPressed: _openAdd,
            onTabSelected: _selectTab,
          ),
        ],
      ),
    );
  }
}
