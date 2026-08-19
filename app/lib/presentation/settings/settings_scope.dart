import 'package:flutter/material.dart';

import 'app_settings_controller.dart';

class SettingsScope extends InheritedNotifier<AppSettingsController> {
  const SettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SettingsScope>()?.notifier;
  }

  static bool hideMoney(BuildContext context) {
    return maybeOf(context)?.settings.balanceHidden ?? false;
  }
}
