/// Boundary for salary / budget / savings access.
/// PIN and biometric will plug in here later. No default PIN. No UI in Phase 02.
abstract class SensitiveAccessPort {
  Future<bool> isUnlocked();

  Future<void> lock();
}

/// Locked until a later phase implements real unlock. Never uses Demo PIN `1234`.
class LockedSensitiveAccess implements SensitiveAccessPort {
  const LockedSensitiveAccess();

  @override
  Future<bool> isUnlocked() async => false;

  @override
  Future<void> lock() async {}
}
