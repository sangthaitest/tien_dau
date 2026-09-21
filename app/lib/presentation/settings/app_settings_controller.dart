import 'package:flutter/foundation.dart';

import '../../application/app_settings_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/failures/result.dart';
import '../theme/app_colors.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._service, {AppSettings? initial}) {
    if (initial != null) settings = initial;
    AppColors.dark = settings.darkMode;
  }

  final AppSettingsService _service;

  AppSettings settings = AppSettings.defaults;
  String? error;

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
  }

  Future<void> setDarkMode(bool value) =>
      _update(settings.copyWith(darkMode: value));

  Future<void> setBalanceHidden(bool value) =>
      _update(settings.copyWith(balanceHidden: value));

  Future<void> setNotificationsEnabled(bool value) =>
      _update(settings.copyWith(notificationsEnabled: value));

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
