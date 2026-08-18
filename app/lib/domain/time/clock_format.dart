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

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime monthStart(DateTime value) => DateTime(value.year, value.month);

String monthKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  return '${value.year}-$month';
}

DateTime previousMonthStart(DateTime value) {
  if (value.month == 1) return DateTime(value.year - 1, 12);
  return DateTime(value.year, value.month - 1);
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
