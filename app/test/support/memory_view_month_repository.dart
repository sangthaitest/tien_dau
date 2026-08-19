import 'package:tien_day/application/view_month_service.dart';
import 'package:tien_day/domain/failures/app_failure.dart';
import 'package:tien_day/domain/failures/result.dart';
import 'package:tien_day/domain/repositories/view_month_repository.dart';
import 'package:tien_day/presentation/view_month/view_month_controller.dart';

class MemoryViewMonthRepository implements ViewMonthRepository {
  MemoryViewMonthRepository({this.stored, this.fail = false});

  String? stored;
  bool fail;

  @override
  Future<Result<String?>> load() async {
    if (fail) return const Err(PersistenceFailure('read failed'));
    return Ok(stored);
  }

  @override
  Future<Result<void>> save(String monthKey) async {
    if (fail) return const Err(PersistenceFailure('write failed'));
    stored = monthKey;
    return const Ok(null);
  }
}

ViewMonthController buildTestViewMonthController({
  DateTime Function()? clock,
  MemoryViewMonthRepository? repository,
}) {
  return ViewMonthController(
    ViewMonthService(repository ?? MemoryViewMonthRepository()),
    clock: clock ?? () => DateTime(2026, 8, 18, 9),
  );
}
