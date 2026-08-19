import '../domain/entities/app_settings.dart';
import '../domain/failures/result.dart';
import '../domain/repositories/app_settings_repository.dart';

class AppSettingsService {
  AppSettingsService(this._repository);

  final AppSettingsRepository _repository;

  Future<Result<AppSettings>> load() => _repository.load();

  Future<Result<void>> save(AppSettings settings) => _repository.save(settings);
}
