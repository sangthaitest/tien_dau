class AppSettings {
  const AppSettings({
    this.darkMode = false,
    this.balanceHidden = false,
    this.notificationsEnabled = true,
  });

  final bool darkMode;
  final bool balanceHidden;
  final bool notificationsEnabled;

  static const defaults = AppSettings();

  AppSettings copyWith({
    bool? darkMode,
    bool? balanceHidden,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      balanceHidden: balanceHidden ?? this.balanceHidden,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.darkMode == darkMode &&
        other.balanceHidden == balanceHidden &&
        other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode => Object.hash(darkMode, balanceHidden, notificationsEnabled);
}
