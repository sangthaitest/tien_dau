import 'package:flutter/material.dart';

import '../../domain/notifications/reminder_schedule.dart';
import '../theme/app_colors.dart';

Future<TimeOfDay?> pickReminderTime(
  BuildContext context, {
  required TimeOfDay initial,
}) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}

Future<void> showWeeklyReminderSheet(
  BuildContext context, {
  required int weekday,
  required int hour,
  required int minute,
  required Future<bool> Function({
    required int weekday,
    required int hour,
    required int minute,
  })
  onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _WeeklyReminderSheet(
      weekday: weekday,
      hour: hour,
      minute: minute,
      onChanged: onChanged,
    ),
  );
}

class _WeeklyReminderSheet extends StatefulWidget {
  const _WeeklyReminderSheet({
    required this.weekday,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int weekday;
  final int hour;
  final int minute;
  final Future<bool> Function({
    required int weekday,
    required int hour,
    required int minute,
  })
  onChanged;

  @override
  State<_WeeklyReminderSheet> createState() => _WeeklyReminderSheetState();
}

class _WeeklyReminderSheetState extends State<_WeeklyReminderSheet> {
  late int _weekday = widget.weekday;
  late int _hour = widget.hour;
  late int _minute = widget.minute;

  Future<void> _selectWeekday(int weekday) async {
    if (weekday == _weekday) return;
    final previous = _weekday;
    setState(() => _weekday = weekday);
    final applied = await widget.onChanged(
      weekday: weekday,
      hour: _hour,
      minute: _minute,
    );
    if (!mounted || applied) return;
    setState(() => _weekday = previous);
  }

  Future<void> _selectTime() async {
    final picked = await pickReminderTime(
      context,
      initial: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null || !mounted) return;
    final previousHour = _hour;
    final previousMinute = _minute;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
    final applied = await widget.onChanged(
      weekday: _weekday,
      hour: picked.hour,
      minute: picked.minute,
    );
    if (!mounted || applied) return;
    setState(() {
      _hour = previousHour;
      _minute = previousMinute;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      'Tổng kết tài chính',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.divider),
            InkWell(
              key: const Key('weekly-reminder-time'),
              onTap: _selectTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Thời gian',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Text(
                      formatReminderClock(_hour, _minute),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.divider),
            for (final weekday in reminderWeekdayLabels.keys)
              InkWell(
                key: Key('weekday-$weekday'),
                onTap: () => _selectWeekday(weekday),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminderWeekdayLabels[weekday]!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: weekday == _weekday
                                ? AppColors.primary
                                : AppColors.text,
                          ),
                        ),
                      ),
                      if (weekday == _weekday)
                        Icon(Icons.check, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
