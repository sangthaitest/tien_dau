import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/statistics_query.dart';
import '../format/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/category_look.dart';
import 'statistics_controller.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key, required this.controller});

  final StatisticsController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final snap = controller.snapshot;
          return ListView(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 24),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else ...[
                _InsightCard(snapshot: snap),
                const SizedBox(height: 16),
                _CategoryChart(snapshot: snap),
                const SizedBox(height: 20),
                const Text(
                  'Danh mục chi nhiều nhất',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                _TopSpending(snapshot: snap),
              ],
            ],
          );
        },
      ),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                      fontWeight: FontWeight.w800,
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
  const _InsightCard({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
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
          Text(
            'Chi tiêu ${monthLabel(snapshot.month)}',
            key: const Key('stats-month-label'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatVnd(snapshot.totalExpense),
            key: const Key('stats-expense-total'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: moneyStyle(size: 28),
          ),
        ],
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0D1A1D26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiêu theo danh mục',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 18),
          if (snapshot.isEmpty)
            Text(
              'Chưa có chi tiêu tháng này.',
              key: const Key('stats-empty'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pie(snapshot: snapshot),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      for (final row in snapshot.categories) _LegendRow(row: row),
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

class _Pie extends StatelessWidget {
  const _Pie({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final slices = [
      for (final row in snapshot.categories)
        (color: categoryLook(row.categoryId).color, fraction: row.amount / snapshot.totalExpense),
    ];
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(148, 148),
            painter: _PiePainter(slices: slices),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
  bool shouldRepaint(covariant _PiePainter oldDelegate) => oldDelegate.slices != slices;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.row});

  final CategorySpend row;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(row.categoryId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: look.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  look.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formatVndShort(row.amount),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${row.percent}%',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TopSpending extends StatelessWidget {
  const _TopSpending({required this.snapshot});

  final StatisticsSnapshot snapshot;

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
            _RankRow(index: i, row: snapshot.topCategories[i]),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.index, required this.row});

  final int index;
  final CategorySpend row;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(row.categoryId);
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
    return Padding(
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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: rankColor),
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
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Text(
                  '${row.percent}% chi tiêu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatVnd(row.amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}
