import 'package:flutter/material.dart';

import '../../domain/entities/recurring_transaction.dart';
import '../format/money_format.dart';
import '../settings/settings_scope.dart';
import '../theme/app_colors.dart';

String financeOccurrenceDate(RecurringTransaction rule, DateTime month) {
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final day = rule.dayOfMonth.clamp(1, lastDay);
  final dd = day.toString().padLeft(2, '0');
  final mm = month.month.toString().padLeft(2, '0');
  return '$dd/$mm/${month.year}';
}

class FinanceLine {
  const FinanceLine({
    required this.id,
    required this.name,
    required this.dateLabel,
    required this.amount,
    this.onTap,
  });

  final String id;
  final String name;
  final String dateLabel;
  final int amount;
  final VoidCallback? onTap;
}

class FinanceCollapsibleCard extends StatefulWidget {
  const FinanceCollapsibleCard({
    super.key,
    required this.sectionKey,
    required this.summaryKey,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.amount,
    required this.amountColor,
    required this.amountKey,
    required this.viewMonth,
    required this.lines,
    required this.managedCount,
    required this.manageLabel,
    required this.manageKey,
    required this.onManage,
    required this.rowKeyPrefix,
    this.emptyMessage,
    this.monthEmptyMessage,
    this.emptyKey,
    this.showAmountWhenEmpty = false,
  });

  final Key sectionKey;
  final Key summaryKey;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final int amount;
  final Color amountColor;
  final Key amountKey;
  final DateTime viewMonth;
  final List<FinanceLine> lines;
  final int managedCount;
  final String? emptyMessage;
  final String? monthEmptyMessage;
  final Key? emptyKey;
  final String manageLabel;
  final Key manageKey;
  final VoidCallback onManage;
  final String rowKeyPrefix;
  final bool showAmountWhenEmpty;

  @override
  State<FinanceCollapsibleCard> createState() => _FinanceCollapsibleCardState();
}

class _FinanceCollapsibleCardState extends State<FinanceCollapsibleCard> {
  bool _expanded = false;

  bool get _canToggle => widget.lines.length >= 2;

  bool get _showLines => widget.lines.length == 1 || (_canToggle && _expanded);

  bool get _showManage => widget.lines.isEmpty || _showLines;

  @override
  void didUpdateWidget(covariant FinanceCollapsibleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.viewMonth;
    final previous = oldWidget.viewMonth;
    if (next.year != previous.year || next.month != previous.month) {
      _expanded = false;
    }
  }

  void _toggle() {
    if (!_canToggle) return;
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    final showFigures = widget.lines.isNotEmpty || widget.showAmountWhenEmpty;
    return DecoratedBox(
      key: widget.sectionKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: widget.summaryKey,
              onTap: _canToggle ? _toggle : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Badge(
                          icon: widget.icon,
                          foreground: widget.iconColor,
                          background: widget.iconBackground,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (_canToggle && _expanded)
                          const _DetailAffordance(expanded: true),
                      ],
                    ),
                    if (showFigures) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayVnd(widget.amount, hidden: hidden),
                                key: widget.amountKey,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: moneyStyle(
                                  size: 24,
                                  color: widget.amountColor,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (_canToggle && !_expanded)
                              const _DetailAffordance(expanded: false),
                          ],
                        ),
                      ),
                      if (widget.lines.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 56, top: 2),
                          child: Text(
                            '${widget.lines.length} khoản',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _showLines || widget.lines.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.lines.isEmpty && _emptyText != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              _emptyText!,
                              key: widget.emptyKey,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        if (_showLines) ...[
                          Divider(height: 1, color: AppColors.divider),
                          for (var i = 0; i < widget.lines.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, color: AppColors.divider),
                            _LineRow(
                              line: widget.lines[i],
                              rowKey: Key(
                                '${widget.rowKeyPrefix}-${widget.lines[i].id}',
                              ),
                              hidden: hidden,
                            ),
                          ],
                          Divider(height: 1, color: AppColors.divider),
                        ],
                        if (_showManage)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              key: widget.manageKey,
                              onPressed: widget.onManage,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(48, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                widget.manageLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 2),
                      ],
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  String? get _emptyText {
    if (widget.lines.isNotEmpty) return null;
    if (widget.managedCount == 0) return widget.emptyMessage;
    return widget.monthEmptyMessage ?? widget.emptyMessage;
  }
}

class _DetailAffordance extends StatelessWidget {
  const _DetailAffordance({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        expanded ? 'Chi tiết ↑' : 'Chi tiết →',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: foreground),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.rowKey,
    required this.hidden,
  });

  final FinanceLine line;
  final Key rowKey;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line.dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            displayVnd(line.amount, hidden: hidden),
            maxLines: 1,
            textAlign: TextAlign.right,
            style: moneyStyle(size: 15, color: AppColors.text),
          ),
        ],
      ),
    );
    if (line.onTap == null) {
      return KeyedSubtree(key: rowKey, child: row);
    }
    return InkWell(key: rowKey, onTap: line.onTap, child: row);
  }
}
