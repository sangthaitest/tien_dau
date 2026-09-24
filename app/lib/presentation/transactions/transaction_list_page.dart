import 'package:flutter/material.dart';

import '../../application/transaction_list_query.dart';
import '../../domain/catalog/chi_cho_catalog.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/time/clock_format.dart';
import '../catalog/transaction_catalog_scope.dart';
import '../format/money_format.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../home/widgets/home_transaction_tile.dart';
import '../settings/settings_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_progress.dart';
import '../theme/app_typography.dart';
import '../tutorial/tutorial_targets.dart';
import 'transaction_date_carousel.dart';
import 'transaction_list_controller.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({
    super.key,
    required this.controller,
    this.embedNavigation = true,
    this.onAddPressed,
    this.onTabSelected,
    this.onTransactionTap,
    this.summaryTargetKey,
    this.filtersTargetKey,
  });

  final TransactionListController controller;
  final bool embedNavigation;
  final VoidCallback? onAddPressed;
  final ValueChanged<AppTab>? onTabSelected;
  final ValueChanged<Transaction>? onTransactionTap;
  final GlobalKey? summaryTargetKey;
  final GlobalKey? filtersTargetKey;

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  late final ScrollController _scrollController;

  static const _switchDuration = Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    widget.controller.load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      widget.controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final isDay = c.mode == TxListMode.day;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.paddingOf(context).top + 12,
                      20,
                      12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Giao dịch',
                            style: AppTypography.screenTitle(
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        tutorialAnchor(
                          key: widget.filtersTargetKey,
                          child: _ModeSwitch(
                            mode: c.mode,
                            onChanged: c.setMode,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: _switchDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: isDay
                        ? TransactionDateCarousel(
                            key: const ValueKey('day-carousel'),
                            selectedDay: c.selectedDay,
                            onSelected: c.selectDay,
                          )
                        : _MonthSelector(
                            key: const ValueKey('month-selector'),
                            month: c.selectedMonth,
                            onPrevious: () => c.shiftMonth(-1),
                            onNext: () => c.shiftMonth(1),
                          ),
                  ),
                  if (!isDay) ...[
                    tutorialAnchor(
                      key: widget.summaryTargetKey,
                      child: _MonthSummary(controller: c),
                    ),
                    _ChipRow(
                      children: [
                        _FilterChip(
                          key: const Key('cat-all'),
                          label: 'Tất cả',
                          selected: c.filter.categoryId == 'all',
                          onTap: () => c.setCategory('all'),
                        ),
                        for (final category
                            in (TransactionCatalogScope.maybeOf(
                                  context,
                                )?.categories ??
                                ChiChoCatalog.all))
                          _FilterChip(
                            key: Key('cat-${category.id}'),
                            label: category.name,
                            selected: c.filter.categoryId == category.id,
                            onTap: () => c.setCategory(category.id),
                          ),
                      ],
                    ),
                  ],
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (isDay)
                          tutorialAnchor(
                            key: widget.summaryTargetKey,
                            child: _DaySummary(controller: c),
                          ),
                        if (c.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              c.error!,
                              key: const Key('tx-list-error'),
                              style: TextStyle(
                                color: AppColors.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else if (c.loading)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: AppCircularProgress()),
                          )
                        else if (c.snapshot.isEmpty)
                          _Empty(isDay: isDay)
                        else if (isDay)
                          for (final tx in c.snapshot.items)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: HomeTransactionTile(
                                transaction: tx,
                                onTap: widget.onTransactionTap == null
                                    ? null
                                    : () => widget.onTransactionTap!(tx),
                              ),
                            )
                        else
                          for (final group in c.snapshot.groups)
                            _MonthDayGroup(
                              key: ValueKey(group.date),
                              group: group,
                              onOpenDay: () => c.selectDay(group.date),
                              onTap: widget.onTransactionTap,
                            ),
                        if (c.loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: AppCircularProgress(
                                size: AppProgress.compactSize,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.embedNavigation)
              HomeBottomNav(
                tab: AppTab.transactions,
                onAddPressed: widget.onAddPressed,
                onTabSelected: widget.onTabSelected,
              ),
          ],
        );
      },
    );

    return Scaffold(backgroundColor: AppColors.bg, body: body);
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final TxListMode mode;
  final ValueChanged<TxListMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeTab(
              key: const Key('mode-day'),
              label: 'Theo ngày',
              selected: mode == TxListMode.day,
              onTap: () => onChanged(TxListMode.day),
            ),
            _ModeTab(
              key: const Key('mode-month'),
              label: 'Theo tháng',
              selected: mode == TxListMode.month,
              onTap: () => onChanged(TxListMode.month),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: selected
                  ? AppTypography.strongWeight
                  : AppTypography.titleWeight,
              color: selected ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('month-prev'),
            onPressed: onPrevious,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ),
          Expanded(
            child: Text(
              formatMonthYear(month),
              key: const Key('month-label'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: AppTypography.strongWeight,
                color: AppColors.text,
              ),
            ),
          ),
          IconButton(
            key: const Key('month-next'),
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.controller});

  final TransactionListController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: _SpendSummaryCard(
        label: 'CHI TIÊU NGÀY ${formatDayMonth(controller.selectedDay)}',
        amount: controller.snapshot.expenseSum,
        count: controller.snapshot.items.length,
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.controller});

  final TransactionListController controller;

  @override
  Widget build(BuildContext context) {
    final month = controller.selectedMonth;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: _SpendSummaryCard(
        label:
            'CHI TIÊU THÁNG ${month.month.toString().padLeft(2, '0')}/${month.year}',
        amount: controller.snapshot.expenseSum,
        count: controller.snapshot.items.length,
      ),
    );
  }
}

class _SpendSummaryCard extends StatelessWidget {
  const _SpendSummaryCard({
    required this.label,
    required this.amount,
    required this.count,
  });

  final String label;
  final int amount;
  final int count;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hidden ? kHiddenMoney : '−${formatVnd(amount)}',
                  key: const Key('tx-sum-expense'),
                  style: moneyStyle(size: 24, color: AppColors.expense),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _TxCountBadge(count: count),
        ],
      ),
    );
  }
}

class _TxCountBadge extends StatelessWidget {
  const _TxCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 14,
              color: AppColors.primaryDeep,
            ),
            const SizedBox(width: 4),
            Text(
              '$count giao dịch',
              key: const Key('tx-count'),
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: AppTypography.titleWeight,
                color: AppColors.primaryDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.isDay});

  final bool isDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDay ? 'Chưa có giao dịch hôm nay' : 'Chưa có giao dịch tháng này',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 16,
              fontWeight: AppTypography.titleWeight,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn + để thêm giao dịch',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: AppTypography.metadataWeight,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthDayGroup extends StatefulWidget {
  const _MonthDayGroup({
    super.key,
    required this.group,
    required this.onOpenDay,
    this.onTap,
  });

  final TransactionDayGroup group;
  final VoidCallback onOpenDay;
  final ValueChanged<Transaction>? onTap;

  @override
  State<_MonthDayGroup> createState() => _MonthDayGroupState();
}

class _MonthDayGroupState extends State<_MonthDayGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    final group = widget.group;
    final label =
        '${formatWeekdayShort(group.date)}, ${formatDayMonth(group.date)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('month-day-${formatIsoDate(group.date)}'),
                    onTap: widget.onOpenDay,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: AppTypography.strongWeight,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('month-toggle-${formatIsoDate(group.date)}'),
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          hidden
                              ? kHiddenMoneyShort
                              : '−${formatVnd(group.dayExpense)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: moneyStyle(size: 13, color: AppColors.expense),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      for (final tx in group.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HomeTransactionTile(
                            transaction: tx,
                            onTap: widget.onTap == null
                                ? null
                                : () => widget.onTap!(tx),
                          ),
                        ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
