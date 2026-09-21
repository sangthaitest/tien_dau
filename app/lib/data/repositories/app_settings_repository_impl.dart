import '../../domain/entities/app_settings.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
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
}
