import 'package:tien_day/domain/entities/user_profile.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/domain/repositories/user_profile_repository.dart';

class MemoryUserProfileRepository implements UserProfileRepository {
  MemoryUserProfileRepository({
    this.stored = UserProfile.defaults,
    this.fail = false,
  });

  UserProfile stored;
  bool fail;

  @override
  Future<Result<UserProfile>> load() async {
    if (fail) return const Err(PersistenceFailure('read failed'));
    return Ok(stored);
  }

  @override
  Future<Result<void>> save(UserProfile profile) async {
    if (fail) return const Err(PersistenceFailure('write failed'));
    stored = profile;
    return const Ok(null);
  }
}
