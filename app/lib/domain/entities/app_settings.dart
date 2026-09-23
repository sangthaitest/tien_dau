import '../notifications/reminder_schedule.dart';

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
    this.transactionReminderEnabled = false,
    this.transactionReminderHour = ReminderDefaults.transactionHour,
    this.transactionReminderMinute = ReminderDefaults.transactionMinute,
    this.financialSummaryEnabled = false,
    this.financialSummaryWeekday = ReminderDefaults.summaryWeekday,
    this.financialSummaryHour = ReminderDefaults.summaryHour,
    this.financialSummaryMinute = ReminderDefaults.summaryMinute,
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
  final bool transactionReminderEnabled;
  final int transactionReminderHour;
  final int transactionReminderMinute;
  final bool financialSummaryEnabled;
  final int financialSummaryWeekday;
  final int financialSummaryHour;
  final int financialSummaryMinute;

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
    bool? transactionReminderEnabled,
    int? transactionReminderHour,
    int? transactionReminderMinute,
    bool? financialSummaryEnabled,
    int? financialSummaryWeekday,
    int? financialSummaryHour,
    int? financialSummaryMinute,
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
      transactionReminderEnabled:
          transactionReminderEnabled ?? this.transactionReminderEnabled,
      transactionReminderHour:
          transactionReminderHour ?? this.transactionReminderHour,
      transactionReminderMinute:
          transactionReminderMinute ?? this.transactionReminderMinute,
      financialSummaryEnabled:
          financialSummaryEnabled ?? this.financialSummaryEnabled,
      financialSummaryWeekday:
          financialSummaryWeekday ?? this.financialSummaryWeekday,
      financialSummaryHour: financialSummaryHour ?? this.financialSummaryHour,
      financialSummaryMinute:
          financialSummaryMinute ?? this.financialSummaryMinute,
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
        other.hasCompletedAddTutorial == hasCompletedAddTutorial &&
        other.transactionReminderEnabled == transactionReminderEnabled &&
        other.transactionReminderHour == transactionReminderHour &&
        other.transactionReminderMinute == transactionReminderMinute &&
        other.financialSummaryEnabled == financialSummaryEnabled &&
        other.financialSummaryWeekday == financialSummaryWeekday &&
        other.financialSummaryHour == financialSummaryHour &&
        other.financialSummaryMinute == financialSummaryMinute;
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
    transactionReminderEnabled,
    transactionReminderHour,
    transactionReminderMinute,
    financialSummaryEnabled,
    financialSummaryWeekday,
    financialSummaryHour,
    financialSummaryMinute,
  );
}
