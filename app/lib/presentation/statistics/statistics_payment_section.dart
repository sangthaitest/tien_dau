import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/statistics_query.dart';
import '../format/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/payment_look.dart';

class StatisticsPaymentSection extends StatelessWidget {
  const StatisticsPaymentSection({
    super.key,
    required this.snapshot,
    required this.onOpen,
  });

  final StatisticsSnapshot snapshot;
  final void Function(String paymentKey, String title) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PaymentChart(snapshot: snapshot, onOpen: onOpen),
        const SizedBox(height: 10),
        const Text(
          'Phương thức chi nhiều nhất',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 4),
        _PaymentRanking(snapshot: snapshot, onOpen: onOpen),
      ],
    );
  }
}

class _PaymentChart extends StatelessWidget {
  const _PaymentChart({required this.snapshot, required this.onOpen});

  final StatisticsSnapshot snapshot;
  final void Function(String paymentKey, String title) onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = snapshot.paymentMethods;
    return Container(
      key: const Key('stats-payment-chart'),
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
            'Chi tiêu theo phương thức thanh toán',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          if (rows.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Chưa có chi tiêu tháng này.',
              key: const Key('stats-payment-empty'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _LollipopRow(
                index: i,
                row: rows[i],
                maxAmount: snapshot.maxPaymentAmount,
                onTap: () => onOpen(rows[i].key, rows[i].displayName),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LollipopRow extends StatelessWidget {
  const _LollipopRow({
    required this.index,
    required this.row,
    required this.maxAmount,
    required this.onTap,
  });

  final int index;
  final PaymentSpend row;
  final int maxAmount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = paymentLook(
      sourceId: row.sourceId,
      name: row.displayName,
      method: row.method,
    );
    final fraction = StatisticsQuery.markerFraction(row.amount, maxAmount);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('stats-payment-bar-${row.token}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: look.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(look.icon, color: look.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * 0.46,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  formatVnd(row.amount),
                                  key: Key('stats-payment-amount-${row.token}'),
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * 0.62,
                              ),
                              child: Text(
                                '${row.percent}% tổng chi tiêu',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LollipopTrack(
                                index: index,
                                trackKey: row.token,
                                fraction: fraction,
                                color: look.color,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LollipopTrack extends StatefulWidget {
  const _LollipopTrack({
    required this.index,
    required this.trackKey,
    required this.fraction,
    required this.color,
  });

  final int index;
  final String trackKey;
  final double fraction;
  final Color color;

  @override
  State<_LollipopTrack> createState() => _LollipopTrackState();
}

class _LollipopTrackState extends State<_LollipopTrack>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 360);
  static const _stagger = Duration(milliseconds: 40);

  late final AnimationController _draw;
  Timer? _delay;
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
      _play();
    } else if (!enabled) {
      _delay?.cancel();
      _draw.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _LollipopTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.fraction != widget.fraction ||
        oldWidget.trackKey != widget.trackKey;
    if (changed && _tickerEnabled) _play();
  }

  void _play() {
    _delay?.cancel();
    _draw.value = 0;
    final delay = _stagger * widget.index;
    if (delay == Duration.zero) {
      _draw.forward();
      return;
    }
    _delay = Timer(delay, () {
      if (!mounted || !_tickerEnabled) return;
      _draw.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('lollipop-${widget.trackKey}'),
      height: 16,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const marker = 12.0;
          final width = constraints.maxWidth;
          final travel = (width - marker).clamp(0.0, width);
          return AnimatedBuilder(
            animation: _draw,
            builder: (context, _) {
              final progress = Curves.easeOutCubic.transform(_draw.value);
              final shown = widget.fraction.clamp(0.0, 1.0) * progress;
              final dx = shown * travel;
              final reached = dx + marker / 2;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    width: reached.clamp(0.0, width),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Positioned(
                    left: dx,
                    child: Container(
                      key: Key('lollipop-marker-${widget.trackKey}'),
                      width: marker,
                      height: marker,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.32),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PaymentRanking extends StatelessWidget {
  const _PaymentRanking({required this.snapshot, required this.onOpen});

  final StatisticsSnapshot snapshot;
  final void Function(String paymentKey, String title) onOpen;

  @override
  Widget build(BuildContext context) {
    if (snapshot.paymentMethods.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Chưa có dữ liệu.',
          key: const Key('stats-payment-rank-empty'),
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
          for (var i = 0; i < snapshot.paymentMethods.length; i++)
            _PaymentRankRow(
              index: i,
              row: snapshot.paymentMethods[i],
              onOpen: () => onOpen(
                snapshot.paymentMethods[i].key,
                snapshot.paymentMethods[i].displayName,
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentRankRow extends StatelessWidget {
  const _PaymentRankRow({
    required this.index,
    required this.row,
    required this.onOpen,
  });

  final int index;
  final PaymentSpend row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final look = paymentLook(
      sourceId: row.sourceId,
      name: row.displayName,
      method: row.method,
    );
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('stats-payment-rank-${row.token}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final amountMax = (constraints.maxWidth - 168).clamp(0.0, 140.0);
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
                          row.displayName,
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
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
