import '../../domain/entities/app_settings.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/notifications/reminder_schedule.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datasources/finance_local_datasource.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  AppSettingsRepositoryImpl(this._prefs);

  static const darkKey = 'settings_dark_mode';
  static const hiddenKey = 'settings_balance_hidden';
  static const notifKey = 'settings_notifications';
  static const tutorialKey = 'settings_has_completed_tutorial';
  static const financeTutorialKey = 'settings_has_completed_finance_tutorial';
  static const backupTutorialKey = 'settings_has_completed_backup_tutorial';
  static const transactionsTutorialKey =
      'settings_has_completed_transactions_tutorial';
  static const statisticsTutorialKey =
      'settings_has_completed_statistics_tutorial';
  static const addTutorialKey = 'settings_has_completed_add_tutorial';
  static const transactionReminderEnabledKey =
      'settings_transaction_reminder_enabled';
  static const transactionReminderHourKey =
      'settings_transaction_reminder_hour';
  static const transactionReminderMinuteKey =
      'settings_transaction_reminder_minute';
  static const financialSummaryEnabledKey =
      'settings_financial_summary_enabled';
  static const financialSummaryWeekdayKey =
      'settings_financial_summary_weekday';
  static const financialSummaryHourKey = 'settings_financial_summary_hour';
  static const financialSummaryMinuteKey = 'settings_financial_summary_minute';

  final PrefsLocalDataSource _prefs;

  @override
  Future<Result<AppSettings>> load() async {
    try {
      return Ok(
        AppSettings(
          darkMode: await _flag(darkKey, false),
          balanceHidden: await _flag(hiddenKey, false),
          notificationsEnabled: await _flag(notifKey, true),
          hasCompletedTutorial: await _flag(tutorialKey, false),
          hasCompletedFinanceTutorial: await _flag(financeTutorialKey, false),
          hasCompletedBackupTutorial: await _flag(backupTutorialKey, false),
          hasCompletedTransactionsTutorial: await _flag(
            transactionsTutorialKey,
            false,
          ),
          hasCompletedStatisticsTutorial: await _flag(
            statisticsTutorialKey,
            false,
          ),
          hasCompletedAddTutorial: await _flag(addTutorialKey, false),
          transactionReminderEnabled: await _flag(
            transactionReminderEnabledKey,
            false,
          ),
          transactionReminderHour: await _boundedInt(
            transactionReminderHourKey,
            ReminderDefaults.transactionHour,
            0,
            23,
          ),
          transactionReminderMinute: await _boundedInt(
            transactionReminderMinuteKey,
            ReminderDefaults.transactionMinute,
            0,
            59,
          ),
          financialSummaryEnabled: await _flag(
            financialSummaryEnabledKey,
            false,
          ),
          financialSummaryWeekday: await _boundedInt(
            financialSummaryWeekdayKey,
            ReminderDefaults.summaryWeekday,
            DateTime.monday,
            DateTime.sunday,
          ),
          financialSummaryHour: await _boundedInt(
            financialSummaryHourKey,
            ReminderDefaults.summaryHour,
            0,
            23,
          ),
          financialSummaryMinute: await _boundedInt(
            financialSummaryMinuteKey,
            ReminderDefaults.summaryMinute,
            0,
            59,
          ),
        ),
      );
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<void>> save(AppSettings settings) async {
    try {
      await _prefs.set(darkKey, settings.darkMode ? '1' : '0');
      await _prefs.set(hiddenKey, settings.balanceHidden ? '1' : '0');
      await _prefs.set(notifKey, settings.notificationsEnabled ? '1' : '0');
      await _prefs.set(tutorialKey, settings.hasCompletedTutorial ? '1' : '0');
      await _prefs.set(
        financeTutorialKey,
        settings.hasCompletedFinanceTutorial ? '1' : '0',
      );
      await _prefs.set(
        backupTutorialKey,
        settings.hasCompletedBackupTutorial ? '1' : '0',
      );
      await _prefs.set(
        transactionsTutorialKey,
        settings.hasCompletedTransactionsTutorial ? '1' : '0',
      );
      await _prefs.set(
        statisticsTutorialKey,
        settings.hasCompletedStatisticsTutorial ? '1' : '0',
      );
      await _prefs.set(
        addTutorialKey,
        settings.hasCompletedAddTutorial ? '1' : '0',
      );
      await _prefs.set(
        transactionReminderEnabledKey,
        settings.transactionReminderEnabled ? '1' : '0',
      );
      await _prefs.set(
        transactionReminderHourKey,
        '${normalizeReminderHour(settings.transactionReminderHour)}',
      );
      await _prefs.set(
        transactionReminderMinuteKey,
        '${normalizeReminderMinute(settings.transactionReminderMinute)}',
      );
      await _prefs.set(
        financialSummaryEnabledKey,
        settings.financialSummaryEnabled ? '1' : '0',
      );
      await _prefs.set(
        financialSummaryWeekdayKey,
        '${normalizeReminderWeekday(settings.financialSummaryWeekday)}',
      );
      await _prefs.set(
        financialSummaryHourKey,
        '${normalizeReminderHour(settings.financialSummaryHour, fallback: ReminderDefaults.summaryHour)}',
      );
      await _prefs.set(
        financialSummaryMinuteKey,
        '${normalizeReminderMinute(settings.financialSummaryMinute)}',
      );
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  Future<bool> _flag(String key, bool fallback) async {
    final raw = await _prefs.get(key);
    if (raw == null) return fallback;
    return raw == '1';
  }

  Future<int> _boundedInt(String key, int fallback, int min, int max) async {
    final raw = await _prefs.get(key);
    final value = int.tryParse(raw ?? '');
    if (value == null || value < min || value > max) return fallback;
    return value;
  }
}
