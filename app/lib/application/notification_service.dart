import '../domain/entities/app_settings.dart';
import '../domain/notifications/notification_scheduler.dart';
import '../domain/notifications/reminder_schedule.dart';

enum NotificationChange { applied, permissionDenied, failed }

class NotificationService {
  NotificationService(this._scheduler);

  final NotificationScheduler _scheduler;

  Future<void> initialize() => _scheduler.initialize();

  Future<bool> hasPermission() => _scheduler.hasPermission();

  Future<bool> ensurePermission() async {
    if (await _scheduler.hasPermission()) return true;
    return _scheduler.requestPermission();
  }

  Future<void> openSystemSettings() => _scheduler.openSystemSettings();

  /// Makes the OS schedules match [settings]. Safe to call more than once:
  /// each reminder uses a stable id, and a disabled reminder is cancelled.
  Future<void> sync(
    AppSettings settings, {
    bool requestExactAlarm = false,
  }) async {
    await _scheduler.initialize();
    final allowed = await _scheduler.hasPermission();
    var askExact = requestExactAlarm && allowed;
    askExact = await _apply(
      enabled: settings.transactionReminderEnabled && allowed,
      requestExactAlarm: askExact,
      id: NotificationIds.transactionReminder,
      schedule: () => _scheduler.scheduleDaily(
        id: NotificationIds.transactionReminder,
        hour: settings.transactionReminderHour,
        minute: settings.transactionReminderMinute,
        title: NotificationCopy.title,
        body: NotificationCopy.transactionReminderBody,
        requestExactAlarm: askExact,
      ),
    );
    await _apply(
      enabled: settings.financialSummaryEnabled && allowed,
      requestExactAlarm: askExact,
      id: NotificationIds.financialSummary,
      schedule: () => _scheduler.scheduleWeekly(
        id: NotificationIds.financialSummary,
        weekday: settings.financialSummaryWeekday,
        hour: settings.financialSummaryHour,
        minute: settings.financialSummaryMinute,
        title: NotificationCopy.title,
        body: NotificationCopy.financialSummaryBody,
        requestExactAlarm: askExact,
      ),
    );
  }

  Future<bool> _apply({
    required bool enabled,
    required bool requestExactAlarm,
    required int id,
    required Future<void> Function() schedule,
  }) async {
    await _scheduler.cancel(id);
    if (!enabled) return requestExactAlarm;
    await schedule();
    return false;
  }
}
