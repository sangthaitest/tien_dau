import 'package:flutter/material.dart';

import '../../domain/entities/user_profile.dart';
import 'user_profile_controller.dart';

class UserProfileScope extends InheritedNotifier<UserProfileController> {
  const UserProfileScope({
    super.key,
    required UserProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  static UserProfileController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<UserProfileScope>()
        ?.notifier;
  }

  static UserProfile of(BuildContext context) {
    return maybeOf(context)?.profile ?? UserProfile.defaults;
  }
}
