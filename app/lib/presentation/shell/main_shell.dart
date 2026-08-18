import 'package:flutter/material.dart';

import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../add_transaction/add_transaction_controller.dart';
import '../add_transaction/add_transaction_page.dart';
import '../home/home_controller.dart';
import '../home/home_page.dart';
import '../home/widgets/home_bottom_nav.dart';
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
    this.clock = DateTime.now,
  });

  final TransactionService transactionService;
  final HomeController homeController;
  final DateTime Function() clock;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _tab = AppTab.home;
  late final TransactionListController _listController;

  @override
  void initState() {
    super.initState();
    _listController = TransactionListController(
      widget.transactionService,
      clock: widget.clock,
    );
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.homeController.load(),
      _listController.load(),
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
    setState(() => _tab = tab);
    if (tab == AppTab.transactions) {
      _listController.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tab == AppTab.transactions ? 1 : 0,
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
              ],
            ),
          ),
          HomeBottomNav(
            tab: _tab,
            onAddPressed: _openAdd,
            onTabSelected: _selectTab,
          ),
        ],
      ),
    );
  }
}
