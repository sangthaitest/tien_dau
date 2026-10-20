import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/statistics_query.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/result.dart';
import '../../domain/time/clock_format.dart';
import '../../domain/transaction_display.dart';
import '../finance/finance_month_picker.dart';
import '../format/money_format.dart';
import '../catalog/transaction_catalog_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_progress.dart';
import '../theme/category_look.dart';
import '../tutorial/tutorial_targets.dart';
import 'statistics_controller.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({
    super.key,
    required this.controller,
    required this.onSeeAllCategory,
    this.insightTargetKey,
    this.chartTargetKey,
  });

  final StatisticsController controller;
  final ValueChanged<String> onSeeAllCategory;
  final GlobalKey? insightTargetKey;
  final GlobalKey? chartTargetKey;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final snap = controller.snapshot;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _Header(
                  snapshot: snap,
                  showTrend: controller.error == null && !controller.loading,
                ),
                const SizedBox(height: 8),
                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      controller.error!,
                      key: const Key('stats-error'),
                      style: TextStyle(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else if (controller.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: AppCircularProgress()),
                  )
                else ...[
                  tutorialAnchor(
                    key: insightTargetKey,
                    child: _InsightCard(
                      snapshot: snap,
                      onPrevious: () => controller.shiftMonth(-1),
                      onNext: () => controller.shiftMonth(1),
                      onOpenPicker: () => _openMonthPicker(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  tutorialAnchor(
                    key: chartTargetKey,
                    child: _CategoryChart(snapshot: snap),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Danh mục chi nhiều nhất',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  _TopSpending(
                    snapshot: snap,
                    loadExpenses: controller.latestCategoryExpenses,
                    onSeeAll: onSeeAllCategory,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openMonthPicker(BuildContext context) async {
    final picked = await showFinanceMonthPicker(
      context: context,
      selectedMonth: controller.selectedMonth,
      now: controller.now(),
    );
    if (picked != null) await controller.selectMonth(picked);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.snapshot, required this.showTrend});

  final StatisticsSnapshot snapshot;
  final bool showTrend;

  @override
  Widget build(BuildContext context) {
    final delta = snapshot.deltaPercent;
    final Color badgeColor;
    final Color badgeBg;
    final IconData icon;
    final String text;
    if (delta < 0) {
      badgeColor = AppColors.income;
      badgeBg = AppColors.incomeContainer;
      icon = Icons.trending_down;
      text = '$delta%';
    } else if (delta > 0) {
      badgeColor = AppColors.expense;
      badgeBg = AppColors.expenseContainer;
      icon = Icons.trending_up;
      text = '+$delta%';
    } else {
      badgeColor = AppColors.textSecondary;
      badgeBg = AppColors.surfaceVariant;
      icon = Icons.trending_flat;
      text = '0%';
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Text(
            'Thống kê',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (showTrend)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      text,
                      key: const Key('trend-text'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'so với tháng trước',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.snapshot,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenPicker,
  });

  final StatisticsSnapshot snapshot;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B67A), Color(0xFF009963)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4700B67A),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MonthStep(
                stepKey: const Key('stats-month-prev'),
                icon: Icons.chevron_left_rounded,
                onTap: onPrevious,
              ),
              Flexible(
                fit: FlexFit.loose,
                child: InkWell(
                  onTap: onOpenPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Text(
                      'Chi tiêu ${monthLabel(snapshot.month)}',
                      key: const Key('stats-month-label'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              _MonthStep(
                stepKey: const Key('stats-month-next'),
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
              ),
            ],
          ),
          Align(
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              key: const Key('stats-expense-total'),
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Text(
                formatVnd(snapshot.totalExpense),
                key: ValueKey(
                  '${snapshot.month.year}-${snapshot.month.month}-${snapshot.totalExpense}',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: moneyStyle(size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthStep extends StatelessWidget {
  const _MonthStep({
    required this.stepKey,
    required this.icon,
    required this.onTap,
  });

  final Key stepKey;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: stepKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 40,
        height: 36,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0D1A1D26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Chi tiêu theo danh mục',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          if (snapshot.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Chưa có chi tiêu tháng này.',
              key: const Key('stats-empty'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final side = math.min(152.0, constraints.maxWidth);
                return Center(
                  child: _Pie(snapshot: snapshot, size: side),
                );
              },
            ),
            const SizedBox(height: 10),
            _CategoryGrid(categories: snapshot.categories),
          ],
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<CategorySpend> categories;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('stats-category-grid'),
      child: Column(
        children: [
          for (var i = 0; i < categories.length; i += 2)
            Padding(
              padding: EdgeInsets.only(
                bottom: i + 2 < categories.length ? 8 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _LegendRow(row: categories[i])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < categories.length
                        ? _LegendRow(row: categories[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({required this.snapshot, required this.size});

  final StatisticsSnapshot snapshot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final slices = [
      for (final row in snapshot.categories)
        (
          color: _catalogLook(context, row.categoryId).color,
          fraction: row.amount / snapshot.totalExpense,
        ),
    ];
    final hole = size * 0.59;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _PiePainter(slices: slices),
          ),
          Container(
            width: hole,
            height: hole,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tổng chi',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    formatVndShort(snapshot.totalExpense),
                    key: const Key('pie-total'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.slices});

  final List<({Color color, double fraction})> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (slices.isEmpty) {
      canvas.drawOval(rect, Paint()..color = AppColors.surfaceVariant);
      return;
    }
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = slice.fraction.clamp(0, 1) * 2 * math.pi;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.row});

  final CategorySpend row;

  @override
  Widget build(BuildContext context) {
    final look = _catalogLook(context, row.categoryId);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: look.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      look.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatVndShort(row.amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              Text(
                '${row.percent}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopSpending extends StatefulWidget {
  const _TopSpending({
    required this.snapshot,
    required this.loadExpenses,
    required this.onSeeAll,
  });

  final StatisticsSnapshot snapshot;
  final Future<Result<List<Transaction>>> Function(String categoryId)
  loadExpenses;
  final ValueChanged<String> onSeeAll;

  @override
  State<_TopSpending> createState() => _TopSpendingState();
}

class _TopSpendingState extends State<_TopSpending> {
  String? _expandedId;
  final Map<String, List<Transaction>> _cache = {};
  final Map<String, String> _errors = {};
  String? _loadingId;
  int _request = 0;

  @override
  void didUpdateWidget(covariant _TopSpending oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.month != widget.snapshot.month) {
      _request++;
      _expandedId = null;
      _loadingId = null;
      _cache.clear();
      _errors.clear();
    }
  }

  Future<void> _toggle(String categoryId) async {
    if (_expandedId == categoryId) {
      setState(() => _expandedId = null);
      return;
    }
    if (_cache.containsKey(categoryId)) {
      setState(() => _expandedId = categoryId);
      return;
    }
    final token = ++_request;
    final month = widget.snapshot.month;
    setState(() {
      _expandedId = categoryId;
      _loadingId = categoryId;
      _errors.remove(categoryId);
    });
    final result = await widget.loadExpenses(categoryId);
    if (!mounted || token != _request || widget.snapshot.month != month) {
      return;
    }
    setState(() {
      if (_loadingId == categoryId) _loadingId = null;
      switch (result) {
        case Ok(:final value):
          _cache[categoryId] = value;
          _errors.remove(categoryId);
        case Err(:final failure):
          _errors[categoryId] = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    if (snapshot.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Chưa có dữ liệu.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0D1A1D26)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < snapshot.topCategories.length; i++)
            _RankRow(
              index: i,
              row: snapshot.topCategories[i],
              expanded: _expandedId == snapshot.topCategories[i].categoryId,
              loading: _loadingId == snapshot.topCategories[i].categoryId,
              error: _errors[snapshot.topCategories[i].categoryId],
              transactions:
                  _cache[snapshot.topCategories[i].categoryId] ?? const [],
              onToggle: () => _toggle(snapshot.topCategories[i].categoryId),
              onSeeAll: () =>
                  widget.onSeeAll(snapshot.topCategories[i].categoryId),
            ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.index,
    required this.row,
    required this.expanded,
    required this.loading,
    required this.error,
    required this.transactions,
    required this.onToggle,
    required this.onSeeAll,
  });

  final int index;
  final CategorySpend row;
  final bool expanded;
  final bool loading;
  final String? error;
  final List<Transaction> transactions;
  final VoidCallback onToggle;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final look = _catalogLook(context, row.categoryId);
    final rankBg = switch (index) {
      0 => const Color(0xFFFFF3E0),
      1 => const Color(0xFFECEFF1),
      2 => const Color(0xFFFBE9E7),
      _ => AppColors.surfaceVariant,
    };
    final rankColor = switch (index) {
      0 => const Color(0xFFF57C00),
      1 => const Color(0xFF546E7A),
      2 => const Color(0xFFD84315),
      _ => AppColors.textSecondary,
    };
    return Column(
      key: Key('stats-top-cluster-${row.categoryId}'),
      children: [
        InkWell(
          key: Key('stats-top-${row.categoryId}'),
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rankBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: rankColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: look.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(look.icon, color: look.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        look.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${row.percent}% chi tiêu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RankAmount(categoryId: row.categoryId, amount: row.amount),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  key: Key('stats-top-chevron-${row.categoryId}'),
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? _CategoryPreview(
                  categoryId: row.categoryId,
                  look: look,
                  loading: loading,
                  error: error,
                  transactions: transactions,
                  onSeeAll: onSeeAll,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _RankAmount extends StatelessWidget {
  const _RankAmount({required this.categoryId, required this.amount});

  final String categoryId;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final style = moneyStyle(
      size: 14,
      color: AppColors.expense,
    ).copyWith(letterSpacing: 0);
    final digitWidth = _widestDigitWidth(style);
    return Row(
      key: Key('stats-top-amount-$categoryId'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final rune in formatVnd(amount).runes)
          _AmountGlyph(
            char: String.fromCharCode(rune),
            style: style,
            digitWidth: digitWidth,
          ),
      ],
    );
  }
}

class _AmountGlyph extends StatelessWidget {
  const _AmountGlyph({
    required this.char,
    required this.style,
    required this.digitWidth,
  });

  final String char;
  final TextStyle style;
  final double digitWidth;

  bool get _isDigit {
    final unit = char.codeUnitAt(0);
    return unit >= 48 && unit <= 57;
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(char, maxLines: 1, style: style);
    if (!_isDigit) return text;
    return SizedBox(
      width: digitWidth,
      child: Align(alignment: Alignment.center, child: text),
    );
  }
}

double _widestDigitWidth(TextStyle style) {
  var width = 0.0;
  for (var digit = 0; digit <= 9; digit++) {
    final painter = TextPainter(
      text: TextSpan(text: '$digit', style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (painter.width > width) width = painter.width;
    painter.dispose();
  }
  return width;
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({
    required this.categoryId,
    required this.look,
    required this.loading,
    required this.error,
    required this.transactions,
    required this.onSeeAll,
  });

  final String categoryId;
  final CategoryLook look;
  final bool loading;
  final String? error;
  final List<Transaction> transactions;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key('stats-top-preview-$categoryId'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '5 giao dịch gần nhất',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                key: Key('stats-top-see-all-$categoryId'),
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: AppCircularProgress()),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                error!,
                key: Key('stats-top-error-$categoryId'),
                style: TextStyle(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          else if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Chưa có giao dịch trong tháng này.',
                key: Key('stats-top-empty-$categoryId'),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          else
            for (var i = 0; i < transactions.length; i++) ...[
              if (i > 0) Divider(height: 1, color: AppColors.divider),
              _PreviewTransaction(transaction: transactions[i], look: look),
            ],
        ],
      ),
    );
  }
}

class _PreviewTransaction extends StatelessWidget {
  const _PreviewTransaction({required this.transaction, required this.look});

  final Transaction transaction;
  final CategoryLook look;

  @override
  Widget build(BuildContext context) {
    final title = transactionTitle(transaction, categoryName: look.name);
    return Padding(
      key: Key('stats-top-tx-${transaction.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            formatDayMonth(transaction.occurredOn),
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: look.background,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(look.icon, color: look.color, size: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: math.max(0, constraints.maxWidth - 32),
                      ),
                      child: Text(
                        formatVnd(transaction.amount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.expense,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

CategoryLook _catalogLook(BuildContext context, String categoryId) {
  final category = TransactionCatalogScope.maybeOf(
    context,
  )?.categoryById(categoryId);
  return categoryLook(
    categoryId,
    name: category?.name,
    visualKey: category?.visualKey,
  );
}
