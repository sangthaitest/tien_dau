abstract class NotificationScheduler {
  Future<void> initialize();

  Future<bool> hasPermission();

  Future<bool> requestPermission();

  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    bool requestExactAlarm = false,
  });

  Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    bool requestExactAlarm = false,
  });

  Future<void> cancel(int id);

  Future<void> openSystemSettings();
}
