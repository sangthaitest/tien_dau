import '../failures/result.dart';

abstract class ViewMonthRepository {
  Future<Result<String?>> load();

  Future<Result<void>> save(String monthKey);
}
