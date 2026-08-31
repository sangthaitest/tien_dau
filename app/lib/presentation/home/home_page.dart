import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/transaction_service.dart';
import '../../domain/entities/transaction.dart';
import '../add_transaction/add_transaction_controller.dart';
import '../add_transaction/add_transaction_page.dart';
import '../catalog/transaction_catalog_controller.dart';
import '../format/money_format.dart';
import '../profile/user_profile_scope.dart';
import '../profile/widgets/profile_avatar.dart';
import '../settings/settings_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_progress.dart';
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
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
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
    final profile = UserProfileScope.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
      child: Column(
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
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: AppTypography.metadataWeight,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.displayName,
                      key: const Key('home-user-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: AppTypography.strongWeight,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('btn-avatar'),
                  onTap: page.onAvatarTap,
                  customBorder: const CircleBorder(),
                  child: ProfileAvatar(
                    initials: profile.initials,
                    avatarPath: profile.avatarPath,
                    size: 44,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      key: const Key('home-month-calendar-icon'),
                      size: 16,
                      color: AppColors.yellow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      monthLabel(
                        snapshot.month.year == 1970
                            ? DateTime.now()
                            : snapshot.month,
                      ),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: AppTypography.titleWeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SpendCard(
            loading: controller.loading,
            error: controller.error,
            amount: snapshot.monthExpense,
            hidden: hidden,
          ),
        ],
      ),
    );
  }
}

class _SpendCard extends StatelessWidget {
  const _SpendCard({
    required this.loading,
    required this.error,
    required this.amount,
    required this.hidden,
  });

  final bool loading;
  final String? error;
  final int amount;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mascotWidth = (constraints.maxWidth * 0.28).clamp(76.0, 108.0);
        // Mascot sits a little low in the card; nudge copy down to match.
        final textNudge = (mascotWidth * 0.04).clamp(3.0, 5.0);
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 110),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00B67A), Color(0xFF009963), Color(0xFF00855A)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: 5,
                  top: -mascotWidth * 0.08,
                  bottom: -mascotWidth * 0.16,
                  width: mascotWidth,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0xB3FFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.0, 0.22, 0.48],
                          ).createShader(rect);
                        },
                        child: Image.asset(
                          'assets/brand/app_icon.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.centerRight,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    15,
                    13 + textNudge,
                    11,
                    13 - textNudge,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tháng này tiền đi đâu rồi?',
                              style: TextStyle(
                                color: Color(0xE6FFFFFF),
                                fontSize: 14,
                                fontWeight: AppTypography.titleWeight,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                loading
                                    ? '…'
                                    : error != null
                                    ? '—'
                                    : displayVnd(amount, hidden: hidden),
                                key: const Key('home-month-spend'),
                                maxLines: 1,
                                style: moneyStyle(
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: mascotWidth * 0.55),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 15, color: AppColors.yellow),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Đây nè',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: AppTypography.strongWeight,
                    letterSpacing: -0.3,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton(
                key: const Key('see-all'),
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.only(left: 8),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: AppTypography.titleWeight,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              child: Center(child: AppCircularProgress()),
            )
          else if (recent.isEmpty)
            Text(
              'Hiện tại tiền chưa đi đâu cả. Nhấn + để thêm nhé!',
              style: TextStyle(
                fontSize: 13,
                fontWeight: AppTypography.bodyWeight,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...recent.map(
              (tx) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HomeTransactionTile(
                  transaction: tx,
                  unsignedNeutralAmount: true,
                  onTap: () => onTransactionTap(tx),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
