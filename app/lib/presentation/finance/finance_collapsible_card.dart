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
    this.note,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  final String id;
  final String name;
  final String dateLabel;
  final int amount;
  final String? note;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  String get displayTitle {
    final extra = note?.trim();
    if (extra == null || extra.isEmpty) return name;
    return extra;
  }

  String get metaLabel {
    final extra = note?.trim();
    if (extra == null || extra.isEmpty || extra == name) return dateLabel;
    return '$name · $dateLabel';
  }
}

class FinanceCollapsibleCard extends StatelessWidget {
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
    required this.lines,
    required this.managedCount,
    required this.manageKey,
    required this.onManage,
    required this.onAdd,
    required this.addLabel,
    required this.addKey,
    required this.rowKeyPrefix,
    this.emptyMessage,
    this.emptyHint,
    this.monthEmptyMessage,
    this.emptyKey,
    this.showAmountWhenEmpty = false,
    this.previewLimit = 3,
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
  final List<FinanceLine> lines;
  final int managedCount;
  final String? emptyMessage;
  final String? emptyHint;
  final String? monthEmptyMessage;
  final Key? emptyKey;
  final Key manageKey;
  final VoidCallback onManage;
  final VoidCallback onAdd;
  final String addLabel;
  final Key addKey;
  final String rowKeyPrefix;
  final bool showAmountWhenEmpty;
  final int previewLimit;

  bool get _hasLines => lines.isNotEmpty;

  List<FinanceLine> get _preview => lines.take(previewLimit).toList();

  @override
  Widget build(BuildContext context) {
    final hidden = SettingsScope.hideMoney(context);
    final showAmount = _hasLines || showAmountWhenEmpty;
    return DecoratedBox(
      key: sectionKey,
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
        child: InkWell(
          onTap: onManage,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderTap(
                  summaryKey: summaryKey,
                  manageKey: _hasLines ? null : manageKey,
                  onTap: onManage,
                  child: Row(
                    children: [
                      _Badge(
                        icon: icon,
                        foreground: iconColor,
                        background: iconBackground,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_hasLines)
                        _AddChip(key: addKey, label: 'Thêm', onPressed: onAdd)
                      else
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                        ),
                    ],
                  ),
                ),
                if (showAmount) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Text(
                      displayVnd(amount, hidden: hidden),
                      key: amountKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: moneyStyle(
                        size: 24,
                        color: amountColor,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                if (!_hasLines) ...[
                  if (_emptyText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _emptyText!,
                      key: emptyKey,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (_showHint) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            emptyHint!,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  _EmptyAddButton(
                    key: addKey,
                    label: addLabel,
                    onPressed: onAdd,
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  for (var i = 0; i < _preview.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: AppColors.divider),
                    _LineRow(
                      line: _preview[i],
                      rowKey: Key('$rowKeyPrefix-${_preview[i].id}'),
                      hidden: hidden,
                    ),
                  ],
                  Divider(height: 1, color: AppColors.divider),
                  InkWell(
                    key: manageKey,
                    onTap: onManage,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Xem tất cả (${lines.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _showHint =>
      lines.isEmpty &&
      managedCount == 0 &&
      (emptyHint?.trim().isNotEmpty ?? false);

  String? get _emptyText {
    if (lines.isNotEmpty) return null;
    if (managedCount == 0) return emptyMessage;
    return monthEmptyMessage ?? emptyMessage;
  }
}

class _HeaderTap extends StatelessWidget {
  const _HeaderTap({
    required this.summaryKey,
    required this.manageKey,
    required this.onTap,
    required this.child,
  });

  final Key summaryKey;
  final Key? manageKey;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final well = InkWell(
      key: summaryKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
    if (manageKey == null) return well;
    return KeyedSubtree(key: manageKey, child: well);
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.primaryContainer,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.45)),
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _EmptyAddButton extends StatelessWidget {
  const _EmptyAddButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.primaryContainer,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.45)),
          minimumSize: const Size.fromHeight(44),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: const StadiumBorder(),
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
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (line.icon != null) ...[
              Icon(
                line.icon,
                size: 20,
                color: line.iconColor ?? AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                line.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
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
      ),
    );
    if (line.onTap == null) {
      return KeyedSubtree(key: rowKey, child: row);
    }
    return InkWell(key: rowKey, onTap: line.onTap, child: row);
  }
}
