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

  final PrefsLocalDataSource _prefs;

  @override
  Future<Result<AppSettings>> load() async {
    try {
      return Ok(
        AppSettings(
          darkMode: await _flag(darkKey, false),
          balanceHidden: await _flag(hiddenKey, false),
          notificationsEnabled: await _flag(notifKey, true),
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
