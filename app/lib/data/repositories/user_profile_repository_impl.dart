import '../../domain/entities/user_profile.dart';
import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/finance_local_datasource.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._prefs);

  static const displayNameKey = 'profile_display_name';
  static const emailKey = 'profile_email';
  static const avatarPathKey = 'profile_avatar_path';

  final PrefsLocalDataSource _prefs;

  @override
  Future<Result<UserProfile>> load() async {
    try {
      final displayName =
          await _prefs.get(displayNameKey) ?? UserProfile.defaults.displayName;
      final email = await _prefs.get(emailKey) ?? UserProfile.defaults.email;
      final avatarPath = await _prefs.get(avatarPathKey);
      return Ok(
        UserProfile(
          displayName: displayName,
          email: email,
          avatarPath: (avatarPath == null || avatarPath.isEmpty)
              ? null
              : avatarPath,
        ),
      );
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<void>> save(UserProfile profile) async {
    try {
      await _prefs.set(displayNameKey, profile.displayName);
      await _prefs.set(emailKey, profile.email);
      await _prefs.set(avatarPathKey, profile.avatarPath ?? '');
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }
}
