import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/statistics_query.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/time/clock_format.dart';
import '../../domain/transaction_display.dart';
import '../finance/finance_month_picker.dart';
import '../format/money_format.dart';
import '../catalog/transaction_catalog_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_progress.dart';
import '../theme/category_look.dart';
import '../theme/payment_look.dart';
import '../tutorial/tutorial_targets.dart';
import 'statistics_controller.dart';
import 'statistics_payment_section.dart';

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
                  _StatisticsBody(
                    snapshot: snap,
                    chartTargetKey: chartTargetKey,
                    onSeeAllCategory: onSeeAllCategory,
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
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
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

enum _StatsTab { categories, payments }

class _StatisticsBody extends StatefulWidget {
  const _StatisticsBody({
    required this.snapshot,
    required this.chartTargetKey,
    required this.onSeeAllCategory,
  });

  final StatisticsSnapshot snapshot;
  final GlobalKey? chartTargetKey;
  final ValueChanged<String> onSeeAllCategory;

  @override
  State<_StatisticsBody> createState() => _StatisticsBodyState();
}

class _StatisticsBodyState extends State<_StatisticsBody> {
  _StatsTab _tab = _StatsTab.categories;
  final Set<String> _expandedPayments = {};
  final Set<String> _expandedCategories = {};

  void _togglePayment(String token) {
    setState(() {
      if (!_expandedPayments.add(token)) _expandedPayments.remove(token);
    });
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (!_expandedCategories.add(categoryId)) {
        _expandedCategories.remove(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SegmentedControl(
          tab: _tab,
          onChanged: (tab) {
            if (tab == _tab) return;
            setState(() => _tab = tab);
          },
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) {
            return ClipRect(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
            );
          },
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: _tab == _StatsTab.categories
              ? _CategorySection(
                  key: const ValueKey('stats-categories'),
                  snapshot: widget.snapshot,
                  chartTargetKey: widget.chartTargetKey,
                  expandedKeys: _expandedCategories,
                  onToggle: _toggleCategory,
                  onSeeAllCategory: widget.onSeeAllCategory,
                )
              : StatisticsPaymentSection(
                  key: const ValueKey('stats-payments'),
                  snapshot: widget.snapshot,
                  expandedKeys: _expandedPayments,
                  onToggle: _togglePayment,
                ),
        ),
      ],
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.tab, required this.onChanged});

  final _StatsTab tab;
  final ValueChanged<_StatsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('stats-segmented'),
      children: [
        Expanded(
          child: _Segment(
            tabKey: const Key('stats-tab-categories'),
            label: 'Danh mục',
            icon: Icons.pie_chart_outline,
            selected: tab == _StatsTab.categories,
            onTap: () => onChanged(_StatsTab.categories),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Segment(
            tabKey: const Key('stats-tab-payments'),
            label: 'Thanh toán bằng',
            icon: Icons.account_balance_wallet_outlined,
            selected: tab == _StatsTab.payments,
            onTap: () => onChanged(_StatsTab.payments),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.tabKey,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final Key tabKey;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : AppColors.textSecondary;
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: tabKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    super.key,
    required this.snapshot,
    required this.chartTargetKey,
    required this.expandedKeys,
    required this.onToggle,
    required this.onSeeAllCategory,
  });

  final StatisticsSnapshot snapshot;
  final GlobalKey? chartTargetKey;
  final Set<String> expandedKeys;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onSeeAllCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tutorialAnchor(
          key: chartTargetKey,
          child: _CategoryChart(snapshot: snapshot),
        ),
        const SizedBox(height: 10),
        const Text(
          'Danh mục chi nhiều nhất',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 4),
        _TopSpending(
          snapshot: snapshot,
          expandedKeys: expandedKeys,
          onToggle: onToggle,
          onSeeAll: onSeeAllCategory,
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

class _Pie extends StatefulWidget {
  const _Pie({required this.snapshot, required this.size});

  final StatisticsSnapshot snapshot;
  final double size;

  @override
  State<_Pie> createState() => _PieState();
}

class _PieState extends State<_Pie> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 360);

  late final AnimationController _draw;
  var _tickerEnabled = true;
  var _boundTicker = false;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(vsync: this, duration: _duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.of(context);
    final first = !_boundTicker;
    final resumed = enabled && !_tickerEnabled;
    _boundTicker = true;
    _tickerEnabled = enabled;
    if (enabled && (first || resumed)) {
      _draw.forward(from: 0);
    } else if (!enabled) {
      _draw.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _Pie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tickerEnabled &&
        _chartKey(oldWidget.snapshot) != _chartKey(widget.snapshot)) {
      _draw.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  String _chartKey(StatisticsSnapshot snapshot) {
    final parts = snapshot.categories
        .map((row) => '${row.categoryId}:${row.amount}')
        .join('|');
    return '${snapshot.month.year}-${snapshot.month.month}-${snapshot.totalExpense}|$parts';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final slices = [
      for (final row in snapshot.categories)
        (
          color: _catalogLook(context, row.categoryId).color,
          fraction: snapshot.totalExpense == 0
              ? 0.0
              : row.amount / snapshot.totalExpense,
        ),
    ];
    final hole = widget.size * 0.59;
    return AnimatedBuilder(
      animation: _draw,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_draw.value);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _PiePainter(slices: slices, progress: progress),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
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
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.slices, required this.progress});

  final List<({Color color, double fraction})> slices;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (slices.isEmpty) {
      canvas.drawOval(rect, Paint()..color = AppColors.surfaceVariant);
      return;
    }
    final turn = progress.clamp(0.0, 1.0);
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = slice.fraction.clamp(0.0, 1.0) * turn * 2 * math.pi;
      if (sweep <= 0) continue;
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
      oldDelegate.progress != progress || oldDelegate.slices != slices;
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

class _TopSpending extends StatelessWidget {
  const _TopSpending({
    required this.snapshot,
    required this.expandedKeys,
    required this.onToggle,
    required this.onSeeAll,
  });

  final StatisticsSnapshot snapshot;
  final Set<String> expandedKeys;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onSeeAll;

  @override
  Widget build(BuildContext context) {
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
              expanded: expandedKeys.contains(
                snapshot.topCategories[i].categoryId,
              ),
              onToggle: () => onToggle(snapshot.topCategories[i].categoryId),
              onSeeAll: () => onSeeAll(snapshot.topCategories[i].categoryId),
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
    required this.onToggle,
    required this.onSeeAll,
  });

  final int index;
  final CategorySpend row;
  final bool expanded;
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
    final canExpand = row.transactions.isNotEmpty;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('stats-category-rank-${row.categoryId}'),
            onTap: canExpand ? onToggle : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final amountMax = (constraints.maxWidth - 168).clamp(
                    0.0,
                    140.0,
                  );
                  return Row(
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
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: amountMax),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatVnd(row.amount),
                            maxLines: 1,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.expense,
                            ),
                          ),
                        ),
                      ),
                      if (canExpand) ...[
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: Icon(
                            Icons.expand_more_rounded,
                            key: Key('stats-category-expand-${row.categoryId}'),
                            size: 22,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        if (expanded && canExpand)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              key: Key('stats-category-txs-${row.categoryId}'),
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.card,
                  AppColors.surfaceVariant,
                  0.4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    for (final tx in row.transactions)
                      _CategoryTransactionRow(transaction: tx),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: Key('stats-top-see-all-${row.categoryId}'),
                        onPressed: onSeeAll,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryTransactionRow extends StatelessWidget {
  const _CategoryTransactionRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final category = TransactionCatalogScope.maybeOf(
      context,
    )?.categoryById(transaction.categoryId);
    final categoryName = categoryLook(
      transaction.categoryId,
      name: category?.name,
      visualKey: category?.visualKey,
    ).name;
    final pay = paymentLook(
      sourceId: transaction.paymentSourceId,
      name: transaction.paymentSourceName,
      method: transaction.paymentMethod,
    );
    final title = transactionTitle(transaction, categoryName: categoryName);
    final date = formatDayMonth(transaction.occurredOn);
    final payName = transaction.paymentSourceName.trim();
    final subtitle = payName.isEmpty ? date : '$payName · $date';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: pay.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(pay.icon, color: pay.color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: Key('stats-category-tx-${transaction.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatVnd(transaction.amount),
            maxLines: 1,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.expense,
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
