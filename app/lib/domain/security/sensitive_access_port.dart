/// Boundary for salary / budget / savings access.
/// No default PIN. Never ships Demo `1234`.
abstract class SensitiveAccessPort {
  Future<bool> hasPin();

  Future<bool> isUnlocked();

  Future<bool> unlock(String pin);

  Future<bool> setupPin(String pin);

  Future<bool> changePin({required String current, required String next});

  Future<void> lock();

  String? get lastError;
}

/// Locked until a PIN is created in a later session. Never uses Demo PIN `1234`.
class LockedSensitiveAccess implements SensitiveAccessPort {
  const LockedSensitiveAccess();

  @override
  Future<bool> hasPin() async => false;

  @override
  Future<bool> isUnlocked() async => false;

  @override
  Future<bool> unlock(String pin) async => false;

  @override
  Future<bool> setupPin(String pin) async => false;

  @override
  Future<bool> changePin({required String current, required String next}) async =>
      false;

  @override
  Future<void> lock() async {}

  @override
  String? get lastError => null;
}
