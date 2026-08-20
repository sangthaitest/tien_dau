import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../add_transaction/add_transaction_controller.dart';
import '../add_transaction/add_transaction_page.dart';
import '../catalog/transaction_catalog_controller.dart';
import '../format/money_format.dart';
import '../settings/settings_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../transactions/transaction_detail_sheet.dart';
import '../transactions/transaction_list_controller.dart';
import '../transactions/transaction_list_page.dart';
import '../view_month/month_picker_sheet.dart';
import '../view_month/view_month_controller.dart';
import 'home_controller.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_transaction_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.transactionService,
    required this.catalogController,
    this.viewMonthController,
    this.clock = DateTime.now,
    this.userName = 'Minh Khuê',
    this.userInitials = 'MK',
    this.embedNavigation = true,
    this.onSeeAll,
    this.onTransactionTap,
    this.onTabSelected,
    this.onAvatarTap,
  });

  final HomeController controller;
  final TransactionService transactionService;
  final TransactionCatalogController catalogController;
  final ViewMonthController? viewMonthController;
  final DateTime Function() clock;
  final String userName;
  final String userInitials;
  final bool embedNavigation;
  final VoidCallback? onSeeAll;
  final ValueChanged<Transaction>? onTransactionTap;
  final ValueChanged<AppTab>? onTabSelected;
  final VoidCallback? onAvatarTap;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _openingAdd = false;

  @override
  void initState() {
    super.initState();
    widget.controller.load(month: widget.viewMonthController?.month);
  }

  Future<void> _openAdd(BuildContext context) async {
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
      if (!context.mounted) return;
      if (saved == true) {
        await widget.controller.load(month: widget.viewMonthController?.month);
      }
    } finally {
      _openingAdd = false;
    }
  }

  Future<void> _openList(BuildContext context) async {
    if (widget.onSeeAll != null) {
      widget.onSeeAll!();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionListPage(
          controller: TransactionListController(
            widget.transactionService,
            clock: widget.clock,
          ),
          clock: widget.clock,
          onAddPressed: () => _openAdd(context),
          onTabSelected: (tab) {
            if (tab == AppTab.home) Navigator.of(context).pop();
          },
          onTransactionTap: (tx) => _openDetail(context, tx.id),
        ),
      ),
    );
    if (context.mounted) {
      await widget.controller.load(month: widget.viewMonthController?.month);
    }
  }

  Future<void> _openDetail(BuildContext context, String id) async {
    if (widget.onTransactionTap != null) {
      final match = widget.controller.snapshot.recent.where((e) => e.id == id);
      if (match.isNotEmpty) widget.onTransactionTap!(match.first);
      return;
    }
    final changed = await TransactionDetailSheet.show(
      context: context,
      transactionService: widget.transactionService,
      catalogController: widget.catalogController,
      clock: widget.clock,
      transactionId: id,
    );
    if (changed == true && context.mounted) {
      await widget.controller.load(month: widget.viewMonthController?.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            final hide = SettingsScope.hideMoney(context);
            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _Header(
                          controller: c,
                          page: widget,
                          hidden: hide,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _Recent(
                          controller: c,
                          onSeeAll: () => _openList(context),
                          onTransactionTap: (tx) => _openDetail(context, tx.id),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.embedNavigation)
                  HomeBottomNav(
                    tab: AppTab.home,
                    onAddPressed: () => _openAdd(context),
                    onTabSelected: (tab) {
                      if (widget.onTabSelected != null) {
                        widget.onTabSelected!(tab);
                        return;
                      }
                      if (tab == AppTab.transactions) _openList(context);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.page,
    required this.hidden,
  });

  final HomeController controller;
  final HomePage page;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final snapshot = controller.snapshot;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B67A), Color(0xFF009963), Color(0xFF00855A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: _Blob(size: 180, opacity: 0.10),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: _Blob(size: 120, opacity: 0.07),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greetingFor(page.clock()),
                          style: const TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontWeight: AppTypography.bodyWeight,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          page.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: AppTypography.strongWeight,
                            height: 1.2,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('btn-avatar'),
                      onTap: page.onAvatarTap,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x38FFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x73FFFFFF),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          page.userInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: AppTypography.titleWeight,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('home-month-chip'),
                  onTap: page.viewMonthController == null
                      ? null
                      : () => showMonthPickerSheet(
                          context,
                          page.viewMonthController!,
                        ),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          monthLabel(
                            snapshot.month.year == 1970
                                ? DateTime.now()
                                : snapshot.month,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: AppTypography.metadataWeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0x29FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi tiêu tháng này',
                      style: TextStyle(
                        color: Color(0xC7FFFFFF),
                        fontSize: 12,
                        fontWeight: AppTypography.metadataWeight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        controller.loading
                            ? '…'
                            : controller.error != null
                            ? '—'
                            : displayVnd(snapshot.monthExpense, hidden: hidden),
                        key: const Key('home-month-spend'),
                        style: moneyStyle(size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({
    required this.controller,
    required this.onSeeAll,
    required this.onTransactionTap,
  });

  final HomeController controller;
  final VoidCallback onSeeAll;
  final ValueChanged<Transaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final recent = controller.snapshot.recent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gần đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: AppTypography.titleWeight,
                    letterSpacing: -0.2,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton(
                key: const Key('see-all'),
                onPressed: onSeeAll,
                child: Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: AppTypography.titleWeight,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (controller.error != null)
            Text(
              controller.error!,
              key: const Key('home-error'),
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (controller.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recent.isEmpty)
            Text(
              'Chưa có giao dịch. Nhấn + để thêm.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: AppTypography.bodyWeight,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...recent.map(
              (tx) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: HomeTransactionTile(
                  transaction: tx,
                  onTap: () => onTransactionTap(tx),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
