import 'package:tien_day/domain/notifications/notification_scheduler.dart';

class FakeNotificationScheduler implements NotificationScheduler {
  FakeNotificationScheduler({this.permission = true});

  bool permission;
  var requestCount = 0;
  var openedSettings = false;
  final ops = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<bool> requestPermission() async {
    requestCount++;
    return permission;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    bool requestExactAlarm = false,
  }) async {
    ops.add('daily:$id:$hour:$minute:$requestExactAlarm:$title:$body');
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    bool requestExactAlarm = false,
  }) async {
    ops.add(
      'weekly:$id:$weekday:$hour:$minute:$requestExactAlarm:$title:$body',
    );
  }

  @override
  Future<void> cancel(int id) async {
    ops.add('cancel:$id');
  }

  @override
  Future<void> openSystemSettings() async {
    openedSettings = true;
  }
}
