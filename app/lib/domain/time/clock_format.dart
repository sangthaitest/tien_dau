String formatHHmm(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatIsoDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime monthStart(DateTime value) => DateTime(value.year, value.month);

String monthKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  return '${value.year}-$month';
}

DateTime? parseMonthKey(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split('-');
  if (parts.length != 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return null;
  return DateTime(year, month);
}

List<DateTime> lastTwelveMonths(DateTime now) {
  final start = monthStart(now);
  return [for (var i = 0; i < 12; i++) DateTime(start.year, start.month - i)];
}

DateTime previousMonthStart(DateTime value) {
  if (value.month == 1) return DateTime(value.year - 1, 12);
  return DateTime(value.year, value.month - 1);
}

DateTime nextMonthStart(DateTime value) =>
    DateTime(value.year, value.month + 1);

DateTime addCalendarDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

DateTime addCalendarMonths(DateTime value, int months) =>
    DateTime(value.year, value.month + months);

/// Exclusive end of a calendar day for range queries.
DateTime dayToExclusive(DateTime value) => addCalendarDays(dateOnly(value), 1);

String formatWeekdayVi(DateTime date) {
  const names = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ];
  return names[date.weekday - 1];
}

String formatWeekdayShort(DateTime date) {
  const names = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
  return names[date.weekday - 1];
}

String formatDayMonth(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String formatMonthYear(DateTime month) {
  final padded = month.month.toString().padLeft(2, '0');
  return 'Tháng $padded/${month.year}';
}

bool inMonth(DateTime date, DateTime month) {
  final d = dateOnly(date);
  return d.year == month.year && d.month == month.month;
}

/// V3 date group labels: Hôm nay / Hôm qua / T2, 18/8
String formatDateLabel(DateTime date, DateTime today) {
  final d = dateOnly(date);
  final t = dateOnly(today);
  if (d == t) return 'Hôm nay';
  if (d == t.subtract(const Duration(days: 1))) return 'Hôm qua';
  const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  return '${weekdays[d.weekday % 7]}, ${d.day}/${d.month}';
}
