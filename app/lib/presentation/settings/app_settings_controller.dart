import 'package:flutter/foundation.dart';

import '../../application/app_settings_service.dart';
import '../../application/notification_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/failures/result.dart';
import '../../domain/notifications/reminder_schedule.dart';
import '../theme/app_colors.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(
    this._service, {
    AppSettings? initial,
    NotificationService? notifications,
  }) : _notifications = notifications {
    if (initial != null) settings = initial;
    AppColors.dark = settings.darkMode;
  }

  final AppSettingsService _service;
  final NotificationService? _notifications;

  AppSettings settings = AppSettings.defaults;
  String? error;
  bool notificationPermissionGranted = true;

  Future<void> _queue = Future<void>.value();

  bool get notificationsNeedSystemAccess =>
      !notificationPermissionGranted &&
      (settings.transactionReminderEnabled || settings.financialSummaryEnabled);

  @override
  void dispose() {
    AppColors.dark = false;
    super.dispose();
  }

  Future<void> load() async {
    final result = await _service.load();
    switch (result) {
      case Ok(:final value):
        settings = value;
        error = null;
      case Err(:final failure):
        error = failure.message;
    }
    AppColors.dark = settings.darkMode;
    notifyListeners();
    await syncScheduledNotifications();
  }

  Future<void> syncScheduledNotifications() {
    return _enqueue(_syncQuietly);
  }

  Future<void> setDarkMode(bool value) =>
      _update(settings.copyWith(darkMode: value));

  Future<void> setBalanceHidden(bool value) =>
      _update(settings.copyWith(balanceHidden: value));

  Future<void> setNotificationsEnabled(bool value) =>
      _update(settings.copyWith(notificationsEnabled: value));

  Future<NotificationChange> setTransactionReminderEnabled(bool value) {
    return _enqueue(() => _setTransactionReminderEnabled(value));
  }

  Future<NotificationChange> setTransactionReminderTime({
    required int hour,
    required int minute,
  }) {
    return _enqueue(
      () => _commit(
        settings.copyWith(
          transactionReminderHour: normalizeReminderHour(hour),
          transactionReminderMinute: normalizeReminderMinute(minute),
        ),
      ),
    );
  }

  Future<NotificationChange> setFinancialSummaryEnabled(bool value) {
    return _enqueue(() => _setFinancialSummaryEnabled(value));
  }

  Future<NotificationChange> setFinancialSummarySchedule({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    return _enqueue(
      () => _commit(
        settings.copyWith(
          financialSummaryWeekday: normalizeReminderWeekday(weekday),
          financialSummaryHour: normalizeReminderHour(
            hour,
            fallback: ReminderDefaults.summaryHour,
          ),
          financialSummaryMinute: normalizeReminderMinute(minute),
        ),
      ),
    );
  }

  Future<void> openNotificationSettings() async {
    await _notifications?.openSystemSettings();
  }

  Future<void> setTutorialCompleted(bool value) =>
      _update(settings.copyWith(hasCompletedTutorial: value));

  Future<void> setFinanceTutorialCompleted(bool value) =>
      _update(settings.copyWith(hasCompletedFinanceTutorial: value));

  Future<void> setBackupTutorialCompleted(bool value) =>
      _update(settings.copyWith(hasCompletedBackupTutorial: value));

  Future<void> setTransactionsTutorialCompleted(bool value) =>
      _update(settings.copyWith(hasCompletedTransactionsTutorial: value));

  Future<void> setStatisticsTutorialCompleted(bool value) =>
      _update(settings.copyWith(hasCompletedStatisticsTutorial: value));

  Future<void> setAddTutorialCompleted(bool value) =>
      _update(settings.copyWith(hasCompletedAddTutorial: value));

  Future<void> completeAllTutorials() => _update(
    settings.copyWith(
      hasCompletedTutorial: true,
      hasCompletedFinanceTutorial: true,
      hasCompletedBackupTutorial: true,
      hasCompletedTransactionsTutorial: true,
      hasCompletedStatisticsTutorial: true,
      hasCompletedAddTutorial: true,
    ),
  );

  Future<void> toggleBalanceHidden() =>
      setBalanceHidden(!settings.balanceHidden);

  Future<NotificationChange> _setTransactionReminderEnabled(bool value) async {
    if (value && !await _grantPermission()) {
      return NotificationChange.permissionDenied;
    }
    return _commit(
      settings.copyWith(transactionReminderEnabled: value),
      requestExactAlarm: value,
    );
  }

  Future<NotificationChange> _setFinancialSummaryEnabled(bool value) async {
    if (value && !await _grantPermission()) {
      return NotificationChange.permissionDenied;
    }
    return _commit(
      settings.copyWith(financialSummaryEnabled: value),
      requestExactAlarm: value,
    );
  }

  Future<bool> _grantPermission() async {
    final granted = await _notifications?.ensurePermission() ?? true;
    notificationPermissionGranted = granted;
    if (!granted) notifyListeners();
    return granted;
  }

  Future<NotificationChange> _commit(
    AppSettings next, {
    bool requestExactAlarm = false,
  }) async {
    final previous = settings;
    await _update(next);
    if (settings != next) return NotificationChange.failed;
    final notifications = _notifications;
    if (notifications == null) return NotificationChange.applied;
    try {
      await notifications.sync(settings, requestExactAlarm: requestExactAlarm);
    } catch (error, stackTrace) {
      debugPrint('Notification schedule failed: $error\n$stackTrace');
      await _update(previous);
      try {
        await notifications.sync(settings);
      } catch (restoreError, restoreStack) {
        debugPrint('Notification restore failed: $restoreError\n$restoreStack');
      }
      return NotificationChange.failed;
    }
    await _refreshPermission();
    return NotificationChange.applied;
  }

  Future<void> _syncQuietly() async {
    try {
      await _notifications?.sync(settings);
    } catch (error, stackTrace) {
      debugPrint('Notification sync failed: $error\n$stackTrace');
    }
    await _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final granted = await _notifications?.hasPermission() ?? true;
    if (granted == notificationPermissionGranted) return;
    notificationPermissionGranted = granted;
    notifyListeners();
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_, _) {});
    return result;
  }

  Future<void> _update(AppSettings next) async {
    final previous = settings;
    settings = next;
    AppColors.dark = next.darkMode;
    notifyListeners();
    final result = await _service.save(next);
    if (result is Err) {
      settings = previous;
      AppColors.dark = previous.darkMode;
      error = result.failure.message;
      notifyListeners();
    }
  }
}
