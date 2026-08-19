import '../entities/app_settings.dart';
import '../failures/result.dart';

abstract class AppSettingsRepository {
  Future<Result<AppSettings>> load();

  Future<Result<void>> save(AppSettings settings);
}
