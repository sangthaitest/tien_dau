import '../failures/result.dart';

class PinRecord {
  const PinRecord({required this.hash, required this.salt});
  final String hash;
  final String salt;
}

abstract class PinRepository {
  Future<Result<PinRecord?>> load();

  Future<Result<void>> save(PinRecord record);
}
