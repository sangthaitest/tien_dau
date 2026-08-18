import '../domain/failures/result.dart';
import '../domain/repositories/pin_repository.dart';
import '../domain/security/pin_hasher.dart';
import '../domain/security/sensitive_access_port.dart';

class SessionSensitiveAccess implements SensitiveAccessPort {
  SessionSensitiveAccess({
    required PinRepository repository,
    required String Function() saltFactory,
  })  : _repository = repository,
        _saltFactory = saltFactory;

  final PinRepository _repository;
  final String Function() _saltFactory;

  bool _unlocked = false;
  String? _error;

  @override
  String? get lastError => _error;

  @override
  Future<bool> hasPin() async {
    final result = await _repository.load();
    return switch (result) {
      Ok(:final value) => value != null,
      Err() => false,
    };
  }

  @override
  Future<bool> isUnlocked() async => _unlocked;

  @override
  Future<void> lock() async {
    _unlocked = false;
  }

  @override
  Future<bool> setupPin(String pin) async {
    _error = null;
    if (!PinHasher.isValid(pin)) {
      _error = 'Mật khẩu mới phải có 4 số';
      return false;
    }
    if (await hasPin()) {
      _error = 'Mật khẩu đã được tạo';
      return false;
    }
    final salt = _saltFactory();
    final saved = await _repository.save(
      PinRecord(hash: PinHasher.hash(pin, salt), salt: salt),
    );
    return switch (saved) {
      Ok() => _okUnlock(),
      Err(:final failure) => _fail(failure.message),
    };
  }

  @override
  Future<bool> unlock(String pin) async {
    _error = null;
    final loaded = await _repository.load();
    switch (loaded) {
      case Err(:final failure):
        return _fail(failure.message);
      case Ok(:final value):
        if (value == null) {
          _error = 'Chưa có mật khẩu';
          return false;
        }
        if (PinHasher.hash(pin, value.salt) != value.hash) {
          _error = 'Mật khẩu không đúng';
          return false;
        }
        return _okUnlock();
    }
  }

  @override
  Future<bool> changePin({required String current, required String next}) async {
    _error = null;
    if (!await unlock(current)) return false;
    if (!PinHasher.isValid(next)) {
      _error = 'Mật khẩu mới phải có 4 số';
      _unlocked = true;
      return false;
    }
    final salt = _saltFactory();
    final saved = await _repository.save(
      PinRecord(hash: PinHasher.hash(next, salt), salt: salt),
    );
    return switch (saved) {
      Ok() => _okUnlock(),
      Err(:final failure) => _fail(failure.message),
    };
  }

  bool _okUnlock() {
    _unlocked = true;
    _error = null;
    return true;
  }

  bool _fail(String message) {
    _error = message;
    return false;
  }
}
