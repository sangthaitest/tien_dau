import 'package:tien_day/domain/entities/app_settings.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/domain/repositories/app_settings_repository.dart';

class MemoryAppSettingsRepository implements AppSettingsRepository {
  MemoryAppSettingsRepository({this.stored = AppSettings.defaults, this.fail = false});

  AppSettings stored;
  bool fail;

  @override
  Future<Result<AppSettings>> load() async {
    if (fail) return const Err(PersistenceFailure('read failed'));
    return Ok(stored);
  }

  @override
  Future<Result<void>> save(AppSettings settings) async {
    if (fail) return const Err(PersistenceFailure('write failed'));
    stored = settings;
    return const Ok(null);
  }
}
