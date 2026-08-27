import '../domain/entities/user_profile.dart';
import '../domain/failures/result.dart';
import '../domain/repositories/user_profile_repository.dart';

class UserProfileService {
  UserProfileService(this._repository);

  final UserProfileRepository _repository;

  Future<Result<UserProfile>> load() => _repository.load();

  Future<Result<void>> save(UserProfile profile) => _repository.save(profile);
}
