import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/app_settings_service.dart';
import 'package:tien_day/application/notification_service.dart';
import 'package:tien_day/domain/entities/app_settings.dart';
import 'package:tien_day/domain/notifications/reminder_schedule.dart';
import 'package:tien_day/presentation/settings/app_settings_controller.dart';

import '../support/fake_notification_scheduler.dart';
import '../support/memory_app_settings_repository.dart';

void main() {
  test('sync replaces the same ids and cancels disabled reminders', () async {
    final scheduler = FakeNotificationScheduler();
    final service = NotificationService(scheduler);
    const enabled = AppSettings(
      transactionReminderEnabled: true,
      transactionReminderHour: 21,
      transactionReminderMinute: 5,
      financialSummaryEnabled: true,
      financialSummaryWeekday: DateTime.sunday,
      financialSummaryHour: 20,
      financialSummaryMinute: 0,
    );

    await service.sync(enabled);
    await service.sync(
      enabled.copyWith(
        transactionReminderHour: 22,
        financialSummaryWeekday: DateTime.monday,
      ),
    );

    expect(scheduler.requestCount, 0);
    expect(scheduler.ops.where((op) => op.startsWith('daily:')), [
      'daily:2101:21:5:false:${NotificationCopy.title}:${NotificationCopy.transactionReminderBody}',
      'daily:2101:22:5:false:${NotificationCopy.title}:${NotificationCopy.transactionReminderBody}',
    ]);
    expect(
      scheduler.ops.where((op) => op.startsWith('weekly:')).last,
      'weekly:2102:1:20:0:false:${NotificationCopy.title}:${NotificationCopy.financialSummaryBody}',
    );
    expect(
      scheduler.ops.where((op) => op == 'cancel:2101').length,
      greaterThanOrEqualTo(2),
    );
  });

  test('disabled reminders are cancelled and not scheduled', () async {
    final scheduler = FakeNotificationScheduler();
    final service = NotificationService(scheduler);
    await service.sync(AppSettings.defaults);
    expect(scheduler.ops, ['cancel:2101', 'cancel:2102']);
  });

  test('missing permission cancels instead of scheduling', () async {
    final scheduler = FakeNotificationScheduler(permission: false);
    final service = NotificationService(scheduler);
    await service.sync(
      const AppSettings(
        transactionReminderEnabled: true,
        financialSummaryEnabled: true,
      ),
    );
    expect(scheduler.ops, ['cancel:2101', 'cancel:2102']);
    expect(scheduler.requestCount, 0);
  });

  test('enabling asks once, schedules, and disabling cancels', () async {
    final scheduler = FakeNotificationScheduler()..permission = false;
    final controller = AppSettingsController(
      AppSettingsService(MemoryAppSettingsRepository()),
      notifications: NotificationService(scheduler),
    );
    addTearDown(controller.dispose);

    final denied = await controller.setTransactionReminderEnabled(true);
    expect(denied, NotificationChange.permissionDenied);
    expect(controller.settings.transactionReminderEnabled, isFalse);
    expect(scheduler.requestCount, 1);
    expect(scheduler.ops, isEmpty);

    scheduler.permission = true;
    final enabled = await controller.setTransactionReminderEnabled(true);
    expect(enabled, NotificationChange.applied);
    expect(controller.settings.transactionReminderEnabled, isTrue);
    expect(scheduler.requestCount, 1);
    expect(
      scheduler.ops,
      contains(
        'daily:2101:21:0:true:${NotificationCopy.title}:${NotificationCopy.transactionReminderBody}',
      ),
    );

    await controller.setTransactionReminderTime(hour: 8, minute: 30);
    expect(controller.settings.transactionReminderHour, 8);
    expect(controller.settings.transactionReminderMinute, 30);
    expect(scheduler.ops.last, 'cancel:2102');
    expect(
      scheduler.ops,
      contains(
        'daily:2101:8:30:false:${NotificationCopy.title}:${NotificationCopy.transactionReminderBody}',
      ),
    );

    await controller.setTransactionReminderEnabled(false);
    expect(controller.settings.transactionReminderEnabled, isFalse);
    expect(scheduler.ops.where((op) => op.startsWith('daily:')).length, 2);
    expect(scheduler.ops.last, 'cancel:2102');
    expect(scheduler.ops.contains('cancel:2101'), isTrue);
  });

  test('weekly schedule change keeps the stable id', () async {
    final scheduler = FakeNotificationScheduler();
    final controller = AppSettingsController(
      AppSettingsService(MemoryAppSettingsRepository()),
      notifications: NotificationService(scheduler),
    );
    addTearDown(controller.dispose);

    await controller.setFinancialSummaryEnabled(true);
    await controller.setFinancialSummarySchedule(
      weekday: DateTime.friday,
      hour: 19,
      minute: 15,
    );

    expect(controller.settings.financialSummaryWeekday, DateTime.friday);
    expect(controller.settings.financialSummaryHour, 19);
    expect(controller.settings.financialSummaryMinute, 15);
    expect(
      scheduler.ops.where((op) => op.startsWith('weekly:')).last,
      'weekly:2102:5:19:15:false:${NotificationCopy.title}:${NotificationCopy.financialSummaryBody}',
    );
  });

  test('rapid toggles leave a single cancelled reminder', () async {
    final scheduler = FakeNotificationScheduler();
    final controller = AppSettingsController(
      AppSettingsService(MemoryAppSettingsRepository()),
      notifications: NotificationService(scheduler),
    );
    addTearDown(controller.dispose);

    final turningOn = controller.setTransactionReminderEnabled(true);
    final turningOff = controller.setTransactionReminderEnabled(false);
    await Future.wait([turningOn, turningOff]);

    expect(controller.settings.transactionReminderEnabled, isFalse);
    expect(scheduler.ops.last, 'cancel:2102');
    expect(
      scheduler.ops.where((op) => op.startsWith('daily:')).length,
      lessThanOrEqualTo(1),
    );
  });
}
