abstract final class ReminderDefaults {
  static const transactionHour = 21;
  static const transactionMinute = 0;
  static const summaryWeekday = DateTime.sunday;
  static const summaryHour = 20;
  static const summaryMinute = 0;
}

abstract final class NotificationIds {
  static const transactionReminder = 2101;
  static const financialSummary = 2102;
}

abstract final class NotificationCopy {
  static const title = 'Tiền đâu nè';
  static const transactionReminderBody =
      'Hôm nay bạn đã ghi lại các giao dịch chưa?';
  static const financialSummaryBody =
      'Đã đến lúc xem lại tình hình tài chính tuần này.';
}

const reminderWeekdayLabels = <int, String>{
  DateTime.monday: 'Thứ hai',
  DateTime.tuesday: 'Thứ ba',
  DateTime.wednesday: 'Thứ tư',
  DateTime.thursday: 'Thứ năm',
  DateTime.friday: 'Thứ sáu',
  DateTime.saturday: 'Thứ bảy',
  DateTime.sunday: 'Chủ nhật',
};

int normalizeReminderHour(
  int value, {
  int fallback = ReminderDefaults.transactionHour,
}) {
  if (value < 0 || value > 23) return fallback;
  return value;
}

int normalizeReminderMinute(int value) {
  if (value < 0 || value > 59) return 0;
  return value;
}

int normalizeReminderWeekday(int value) {
  if (value < DateTime.monday || value > DateTime.sunday) {
    return ReminderDefaults.summaryWeekday;
  }
  return value;
}

String formatReminderClock(int hour, int minute) {
  final h = normalizeReminderHour(hour).toString().padLeft(2, '0');
  final m = normalizeReminderMinute(minute).toString().padLeft(2, '0');
  return '$h:$m';
}

String formatWeeklyReminder(int weekday, int hour, int minute) {
  final day =
      reminderWeekdayLabels[normalizeReminderWeekday(weekday)] ?? 'Chủ nhật';
  return '$day · ${formatReminderClock(hour, minute)}';
}

/// Next local wall-clock time for a daily reminder. The returned instant is
/// strictly after [now].
DateTime nextDailyOccurrence(DateTime now, int hour, int minute) {
  final scheduled = DateTime(
    now.year,
    now.month,
    now.day,
    normalizeReminderHour(hour),
    normalizeReminderMinute(minute),
  );
  if (scheduled.isAfter(now)) return scheduled;
  return scheduled.add(const Duration(days: 1));
}

/// Next local wall-clock time for a weekly reminder. [weekday] uses
/// [DateTime.monday] through [DateTime.sunday].
DateTime nextWeeklyOccurrence(DateTime now, int weekday, int hour, int minute) {
  final target = normalizeReminderWeekday(weekday);
  var scheduled = DateTime(
    now.year,
    now.month,
    now.day,
    normalizeReminderHour(hour, fallback: ReminderDefaults.summaryHour),
    normalizeReminderMinute(minute),
  );
  var days = (target - scheduled.weekday) % 7;
  if (days < 0) days += 7;
  scheduled = scheduled.add(Duration(days: days));
  if (scheduled.isAfter(now)) return scheduled;
  return scheduled.add(const Duration(days: 7));
}
