import 'package:flutter/foundation.dart';

import '../../application/user_profile_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/result.dart';

class UserProfileController extends ChangeNotifier {
  UserProfileController(this._service);

  final UserProfileService _service;

  UserProfile profile = UserProfile.defaults;
  String? error;

  Future<void> load() async {
    final result = await _service.load();
    switch (result) {
      case Ok(:final value):
        profile = value;
        error = null;
      case Err(:final failure):
        error = failure.message;
    }
    notifyListeners();
  }

  Future<void> setDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      error = 'Tên hiển thị không được trống';
      notifyListeners();
      return Future.value();
    }
    return _update(profile.copyWith(displayName: trimmed));
  }

  Future<void> setEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      error = 'Email không được trống';
      notifyListeners();
      return Future.value();
    }
    return _update(profile.copyWith(email: trimmed));
  }

  Future<void> setAvatarPath(String? path) {
    if (path == null || path.isEmpty) {
      return _update(profile.copyWith(clearAvatarPath: true));
    }
    return _update(profile.copyWith(avatarPath: path));
  }

  Future<void> _update(UserProfile next) async {
    final previous = profile;
    profile = next;
    error = null;
    notifyListeners();
    final result = await _service.save(next);
    if (result is Err) {
      profile = previous;
      error = result.failure.message;
      notifyListeners();
    }
  }
}
