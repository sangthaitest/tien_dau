import 'package:flutter/material.dart';

import '../../domain/time/clock_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TransactionDateCarousel extends StatefulWidget {
  const TransactionDateCarousel({
    super.key,
    required this.selectedDay,
    required this.onSelected,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  @override
  State<TransactionDateCarousel> createState() =>
      _TransactionDateCarouselState();
}

class _TransactionDateCarouselState extends State<TransactionDateCarousel> {
  static final _minDate = DateTime(2020, 1, 1);
  static const _dayCount = 365 * 16;
  static const _anim = Duration(milliseconds: 260);

  late final PageController _pages;
  late int _centerIndex;

  int _indexOf(DateTime day) {
    final index = dateOnly(day).difference(_minDate).inDays;
    return index.clamp(0, _dayCount - 1);
  }

  DateTime _dateOf(int index) => addCalendarDays(_minDate, index);

  @override
  void initState() {
    super.initState();
    _centerIndex = _indexOf(widget.selectedDay);
    _pages = PageController(initialPage: _centerIndex, viewportFraction: 0.2);
  }

  @override
  void didUpdateWidget(covariant TransactionDateCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _indexOf(widget.selectedDay);
    if (next == _centerIndex) return;
    _centerIndex = next;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pages.hasClients) return;
      if (_pages.page?.round() == next) return;
      _pages.animateToPage(next, duration: _anim, curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final clamped = index.clamp(0, _dayCount - 1);
    if (_pages.hasClients && _pages.page?.round() != clamped) {
      _pages.animateToPage(
        clamped,
        duration: _anim,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    if (_centerIndex == index) return;
    setState(() => _centerIndex = index);
  }

  bool _onScrollEnd(ScrollNotification notification) {
    if (notification is! ScrollEndNotification) return false;
    if (notification.depth != 0) return false;
    final index = _pages.hasClients
        ? (_pages.page ?? _centerIndex.toDouble()).round()
        : _centerIndex;
    final day = _dateOf(index.clamp(0, _dayCount - 1));
    if (dateOnly(day) != dateOnly(widget.selectedDay)) {
      widget.onSelected(day);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          _ArrowButton(
            key: const Key('date-prev'),
            icon: Icons.chevron_left_rounded,
            onTap: () {
              final next = (_centerIndex - 1).clamp(0, _dayCount - 1);
              _goTo(next);
              widget.onSelected(_dateOf(next));
            },
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollEnd,
              child: PageView.builder(
                key: const Key('date-carousel'),
                controller: _pages,
                itemCount: _dayCount,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(
                  parent: PageScrollPhysics(),
                ),
                itemBuilder: (context, index) {
                  final day = _dateOf(index);
                  return _DayCell(
                    day: day,
                    selected: index == _centerIndex,
                    onTap: () {
                      _goTo(index);
                      widget.onSelected(day);
                    },
                  );
                },
              ),
            ),
          ),
          _ArrowButton(
            key: const Key('date-next'),
            icon: Icons.chevron_right_rounded,
            onTap: () {
              final next = (_centerIndex + 1).clamp(0, _dayCount - 1);
              _goTo(next);
              widget.onSelected(_dateOf(next));
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('date-cell-${formatIsoDate(day)}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatWeekdayShort(day),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: AppTypography.metadataWeight,
                  color: selected
                      ? AppColors.onPrimary.withValues(alpha: 0.9)
                      : AppColors.textTertiary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 17,
                  fontWeight: selected
                      ? AppTypography.extraWeight
                      : AppTypography.strongWeight,
                  color: selected ? AppColors.onPrimary : AppColors.text,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: AppColors.textSecondary, size: 28),
      ),
    );
  }
}
