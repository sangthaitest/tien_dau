import '../../domain/catalog/chi_cho_catalog.dart';
import 'package:flutter/material.dart';

import '../../application/transaction_list_query.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/time/clock_format.dart';
import '../format/money_format.dart';
import '../catalog/transaction_catalog_scope.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../home/widgets/home_transaction_tile.dart';
import '../theme/app_colors.dart';
import '../theme/app_progress.dart';
import '../theme/app_typography.dart';
import 'transaction_list_controller.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({
    super.key,
    required this.controller,
    this.embedNavigation = true,
    this.onAddPressed,
    this.onTabSelected,
    this.onTransactionTap,
    this.onDelete,
    this.clock = DateTime.now,
  });

  final TransactionListController controller;
  final bool embedNavigation;
  final VoidCallback? onAddPressed;
  final ValueChanged<AppTab>? onTabSelected;
  final ValueChanged<Transaction>? onTransactionTap;
  final Future<bool> Function(Transaction tx)? onDelete;
  final DateTime Function() clock;

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  late final ScrollController _scrollController;

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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 12,
                  bottom: 24,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(
                      'Giao dịch',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x0D1A1D26)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHI TIÊU',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '−${formatVndShort(c.snapshot.expenseSum)}',
                            key: const Key('tx-sum-expense'),
                            style: moneyStyle(
                              size: 17,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  _ChipRow(
                    children: [
                      _FilterChip(
                        key: const Key('date-thisMonth'),
                        label: 'Tháng này',
                        selected: c.filter.date == TxDateFilter.thisMonth,
                        onTap: () => c.setDateFilter(TxDateFilter.thisMonth),
                      ),
                      _FilterChip(
                        key: const Key('date-lastMonth'),
                        label: 'Tháng trước',
                        selected: c.filter.date == TxDateFilter.lastMonth,
                        onTap: () => c.setDateFilter(TxDateFilter.lastMonth),
                      ),
                      _FilterChip(
                        key: const Key('date-custom'),
                        label: 'Tùy chọn',
                        selected: c.filter.date == TxDateFilter.custom,
                        onTap: () => c.setDateFilter(TxDateFilter.custom),
                      ),
                    ],
                  ),
                  if (c.filter.date == TxDateFilter.custom)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DateBox(
                              label: c.filter.customFrom == null
                                  ? 'Từ ngày'
                                  : formatIsoDate(c.filter.customFrom!),
                              onTap: () => _pickFrom(c),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateBox(
                              label: c.filter.customTo == null
                                  ? 'Đến ngày'
                                  : formatIsoDate(c.filter.customTo!),
                              onTap: () => _pickTo(c),
                            ),
                          ),
                        ],
                      ),
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
                    _Empty(onAdd: widget.onAddPressed)
                  else
                    for (final group in c.snapshot.groups)
                      _DayGroup(
                        group: group,
                        onTap: widget.onTransactionTap,
                        onDelete: widget.onDelete,
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

  Future<void> _pickFrom(TransactionListController c) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: c.filter.customFrom ?? widget.clock(),
      firstDate: DateTime(widget.clock().year - 5),
      lastDate: DateTime(widget.clock().year + 1),
    );
    if (picked != null) c.setCustomFrom(picked);
  }

  Future<void> _pickTo(TransactionListController c) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: c.filter.customTo ?? widget.clock(),
      firstDate: DateTime(widget.clock().year - 5),
      lastDate: DateTime(widget.clock().year + 1),
    );
    if (picked != null) c.setCustomTo(picked);
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({this.onAdd});
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có giao dịch',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn + để thêm giao dịch đầu tiên.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('tx-empty-add'),
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              textStyle: AppTypography.button(),
            ),
            child: const Text('Thêm giao dịch'),
          ),
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.group, this.onTap, this.onDelete});

  final TransactionDayGroup group;
  final ValueChanged<Transaction>? onTap;
  final Future<bool> Function(Transaction tx)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '−${formatVndShort(group.dayExpense)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          for (final tx in group.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: onDelete == null
                  ? HomeTransactionTile(
                      transaction: tx,
                      onTap: onTap == null ? null : () => onTap!(tx),
                    )
                  : Dismissible(
                      key: Key('tx-swipe-${tx.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.expense,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) => onDelete!(tx),
                      child: HomeTransactionTile(
                        transaction: tx,
                        onTap: onTap == null ? null : () => onTap!(tx),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
