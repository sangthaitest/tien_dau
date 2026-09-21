class AppSettings {
  const AppSettings({
    this.darkMode = false,
    this.balanceHidden = false,
    this.notificationsEnabled = true,
    this.hasCompletedTutorial = false,
    this.hasCompletedFinanceTutorial = false,
    this.hasCompletedBackupTutorial = false,
    this.hasCompletedTransactionsTutorial = false,
    this.hasCompletedStatisticsTutorial = false,
    this.hasCompletedAddTutorial = false,
  });

  final bool darkMode;
  final bool balanceHidden;
  final bool notificationsEnabled;
  final bool hasCompletedTutorial;
  final bool hasCompletedFinanceTutorial;
  final bool hasCompletedBackupTutorial;
  final bool hasCompletedTransactionsTutorial;
  final bool hasCompletedStatisticsTutorial;
  final bool hasCompletedAddTutorial;

  static const defaults = AppSettings();

  AppSettings copyWith({
    bool? darkMode,
    bool? balanceHidden,
    bool? notificationsEnabled,
    bool? hasCompletedTutorial,
    bool? hasCompletedFinanceTutorial,
    bool? hasCompletedBackupTutorial,
    bool? hasCompletedTransactionsTutorial,
    bool? hasCompletedStatisticsTutorial,
    bool? hasCompletedAddTutorial,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      balanceHidden: balanceHidden ?? this.balanceHidden,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hasCompletedTutorial: hasCompletedTutorial ?? this.hasCompletedTutorial,
      hasCompletedFinanceTutorial:
          hasCompletedFinanceTutorial ?? this.hasCompletedFinanceTutorial,
      hasCompletedBackupTutorial:
          hasCompletedBackupTutorial ?? this.hasCompletedBackupTutorial,
      hasCompletedTransactionsTutorial:
          hasCompletedTransactionsTutorial ??
          this.hasCompletedTransactionsTutorial,
      hasCompletedStatisticsTutorial:
          hasCompletedStatisticsTutorial ?? this.hasCompletedStatisticsTutorial,
      hasCompletedAddTutorial:
          hasCompletedAddTutorial ?? this.hasCompletedAddTutorial,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.darkMode == darkMode &&
        other.balanceHidden == balanceHidden &&
        other.notificationsEnabled == notificationsEnabled &&
        other.hasCompletedTutorial == hasCompletedTutorial &&
        other.hasCompletedFinanceTutorial == hasCompletedFinanceTutorial &&
        other.hasCompletedBackupTutorial == hasCompletedBackupTutorial &&
        other.hasCompletedTransactionsTutorial ==
            hasCompletedTransactionsTutorial &&
        other.hasCompletedStatisticsTutorial ==
            hasCompletedStatisticsTutorial &&
        other.hasCompletedAddTutorial == hasCompletedAddTutorial;
  }

  @override
  int get hashCode => Object.hash(
    darkMode,
    balanceHidden,
    notificationsEnabled,
    hasCompletedTutorial,
    hasCompletedFinanceTutorial,
    hasCompletedBackupTutorial,
    hasCompletedTransactionsTutorial,
    hasCompletedStatisticsTutorial,
    hasCompletedAddTutorial,
  );
}
