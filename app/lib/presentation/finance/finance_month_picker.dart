import 'package:flutter/material.dart';

import '../../domain/time/clock_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

Future<DateTime?> showFinanceMonthPicker({
  required BuildContext context,
  required DateTime selectedMonth,
  required DateTime now,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _FinanceMonthPicker(selectedMonth: monthStart(selectedMonth), now: now),
  );
}

class _FinanceMonthPicker extends StatefulWidget {
  const _FinanceMonthPicker({required this.selectedMonth, required this.now});

  final DateTime selectedMonth;
  final DateTime now;

  @override
  State<_FinanceMonthPicker> createState() => _FinanceMonthPickerState();
}

class _FinanceMonthPickerState extends State<_FinanceMonthPicker> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.selectedMonth.year;
    _month = widget.selectedMonth.month;
  }

  bool _isCurrent(int month) =>
      _year == widget.now.year && month == widget.now.month;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chọn tháng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  key: const Key('finance-month-close'),
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _YearStep(
                  stepKey: const Key('finance-month-year-prev'),
                  icon: Icons.chevron_left_rounded,
                  onTap: () => setState(() => _year -= 1),
                ),
                SizedBox(
                  width: 88,
                  child: Text(
                    '$_year',
                    key: const Key('finance-month-year'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                _YearStep(
                  stepKey: const Key('finance-month-year-next'),
                  icon: Icons.chevron_right_rounded,
                  onTap: () => setState(() => _year += 1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.1,
              children: [
                for (var month = 1; month <= 12; month++)
                  _MonthCell(
                    cellKey: Key('finance-month-cell-$_year-$month'),
                    label: 'Tháng $month',
                    selected: month == _month,
                    current: _isCurrent(month),
                    onTap: () => setState(() => _month = month),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: const Key('finance-month-confirm'),
                onPressed: () =>
                    Navigator.pop(context, DateTime(_year, _month)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  textStyle: AppTypography.button(),
                ),
                child: const Text('Xác nhận'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearStep extends StatelessWidget {
  const _YearStep({
    required this.stepKey,
    required this.icon,
    required this.onTap,
  });

  final Key stepKey;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: stepKey,
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.primary, size: 28),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.cellKey,
    required this.label,
    required this.selected,
    required this.current,
    required this.onTap,
  });

  final Key cellKey;
  final String label;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.text;
    return Material(
      color: selected ? AppColors.primaryContainer : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: cellKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
            if (current)
              Text(
                'Tháng này',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
