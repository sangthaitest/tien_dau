import '../entities/user_profile.dart';
import '../failures/result.dart';

abstract class UserProfileRepository {
  Future<Result<UserProfile>> load();

  Future<Result<void>> save(UserProfile profile);
}
