import '../domain/failures/result.dart';
import '../domain/repositories/view_month_repository.dart';
import '../domain/time/clock_format.dart';

class ViewMonthService {
  ViewMonthService(this._repository);

  final ViewMonthRepository _repository;

  Future<Result<DateTime>> load({required DateTime fallback}) async {
    final result = await _repository.load();
    return switch (result) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => Ok(parseMonthKey(value) ?? monthStart(fallback)),
    };
  }

  Future<Result<void>> save(DateTime month) {
    return _repository.save(monthKey(monthStart(month)));
  }
}
