import '../../domain/failures/app_failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/repositories/view_month_repository.dart';
import '../datasources/finance_local_datasource.dart';

class ViewMonthRepositoryImpl implements ViewMonthRepository {
  ViewMonthRepositoryImpl(this._prefs);

  static const key = 'view_month';
  final PrefsLocalDataSource _prefs;

  @override
  Future<Result<String?>> load() async {
    try {
      return Ok(await _prefs.get(key));
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }

  @override
  Future<Result<void>> save(String monthKey) async {
    try {
      await _prefs.set(key, monthKey);
      return const Ok(null);
    } on PersistenceFailure catch (e) {
      return Err(e);
    }
  }
}
