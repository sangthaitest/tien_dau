import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notifications/notification_scheduler.dart';
import '../../domain/notifications/reminder_schedule.dart';

class FlutterLocalNotificationScheduler implements NotificationScheduler {
  FlutterLocalNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'tien_dau_reminders';
  static const channelName = 'Nhắc nhở';
  static const channelDescription = 'Nhắc ghi giao dịch và tổng kết tài chính';

  final FlutterLocalNotificationsPlugin _plugin;
  var _ready = false;
  var _zonesReady = false;
  var _askedExactAlarm = false;

  @override
  Future<void> initialize() async {
    if (_ready) return;
    await _configureLocalTimeZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.defaultImportance,
            playSound: true,
            enableVibration: false,
          ),
        );
    _ready = true;
  }

  @override
  Future<bool> hasPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _android;
      return await android?.areNotificationsEnabled() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _ios;
      final options = await ios?.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _ios?.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
      return granted ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _android?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
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
    await initialize();
    final when = nextDailyOccurrence(tz.TZDateTime.now(tz.local), hour, minute);
    await _schedule(
      id: id,
      title: title,
      body: body,
      when: _zoned(when),
      match: DateTimeComponents.time,
      requestExactAlarm: requestExactAlarm,
    );
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
    await initialize();
    final when = nextWeeklyOccurrence(
      tz.TZDateTime.now(tz.local),
      weekday,
      hour,
      minute,
    );
    await _schedule(
      id: id,
      title: title,
      body: body,
      when: _zoned(when),
      match: DateTimeComponents.dayOfWeekAndTime,
      requestExactAlarm: requestExactAlarm,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> openSystemSettings() {
    return AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Future<void> _configureLocalTimeZone() async {
    if (!_zonesReady) {
      tzdata.initializeTimeZones();
      _zonesReady = true;
    }
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on ArgumentError catch (error) {
      debugPrint('Timezone setup skipped: $error');
    } on PlatformException catch (error) {
      debugPrint('Timezone setup skipped: ${error.message}');
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required DateTimeComponents match,
    required bool requestExactAlarm,
  }) async {
    final mode = await _scheduleMode(requestExactAlarm: requestExactAlarm);
    await _plugin.cancel(id: id);
    try {
      await _zonedSchedule(
        id: id,
        title: title,
        body: body,
        when: when,
        match: match,
        mode: mode,
      );
    } on PlatformException catch (error) {
      if (error.code != 'exact_alarms_not_permitted') rethrow;
      await _zonedSchedule(
        id: id,
        title: title,
        body: body,
        when: when,
        match: match,
        mode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required DateTimeComponents match,
    required AndroidScheduleMode mode,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          icon: 'ic_stat_notification',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
          enableVibration: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          presentBadge: false,
        ),
      ),
      androidScheduleMode: mode,
      matchDateTimeComponents: match,
    );
  }

  /// Uses an exact idle-capable alarm when Android already allows it.
  /// The special exact-alarm screen is opened at most once per process, and
  /// only when the user has just turned a reminder on. Otherwise the reminder
  /// is still scheduled with an inexact idle-capable alarm.
  Future<AndroidScheduleMode> _scheduleMode({
    required bool requestExactAlarm,
  }) async {
    final android = _android;
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    if (await android.canScheduleExactNotifications() != false) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    if (requestExactAlarm && !_askedExactAlarm) {
      _askedExactAlarm = true;
      try {
        await android.requestExactAlarmsPermission();
      } on PlatformException catch (error) {
        debugPrint('Exact alarm request skipped: ${error.code}');
      }
      if (await android.canScheduleExactNotifications() == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  tz.TZDateTime _zoned(DateTime local) {
    return tz.TZDateTime(
      tz.local,
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
  }
}
