import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/domain/notifications/reminder_schedule.dart';

void main() {
  final wednesday = DateTime(2026, 9, 23, 16);

  test('daily reminder stays today when the time is still ahead', () {
    final next = nextDailyOccurrence(wednesday, 21, 0);
    expect(next, DateTime(2026, 9, 23, 21));
  });

  test('daily reminder rolls to tomorrow after the time has passed', () {
    final next = nextDailyOccurrence(DateTime(2026, 9, 23, 21, 0, 1), 21, 0);
    expect(next, DateTime(2026, 9, 24, 21));
  });

  test('weekly reminder lands on the selected weekday', () {
    final next = nextWeeklyOccurrence(wednesday, DateTime.sunday, 20, 0);
    expect(next.weekday, DateTime.sunday);
    expect(next, DateTime(2026, 9, 27, 20));
  });

  test('weekly reminder waits a week when that weekday time has passed', () {
    final sundayEvening = DateTime(2026, 9, 27, 20, 30);
    final next = nextWeeklyOccurrence(sundayEvening, DateTime.sunday, 20, 0);
    expect(next, DateTime(2026, 10, 4, 20));
  });

  test('labels match the settings copy', () {
    expect(formatReminderClock(21, 0), '21:00');
    expect(formatWeeklyReminder(DateTime.sunday, 20, 0), 'Chủ nhật · 20:00');
    expect(NotificationIds.transactionReminder, 2101);
    expect(NotificationIds.financialSummary, 2102);
    expect(NotificationCopy.title, 'Tiền đâu nè');
    expect(
      NotificationCopy.transactionReminderBody,
      'Hôm nay bạn đã ghi lại các giao dịch chưa?',
    );
    expect(
      NotificationCopy.financialSummaryBody,
      'Đã đến lúc xem lại tình hình tài chính tuần này.',
    );
  });
}
