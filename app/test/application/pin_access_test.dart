import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/session_sensitive_access.dart';

import '../support/memory_finance_repository.dart';

void main() {
  late MemoryPinRepository repo;
  late SessionSensitiveAccess access;

  setUp(() {
    repo = MemoryPinRepository();
    access = SessionSensitiveAccess(repository: repo, saltFactory: () => 'salt-a');
  });

  test('has no default PIN including 1234', () async {
    expect(await access.hasPin(), isFalse);
    expect(await access.unlock('1234'), isFalse);
    expect(access.lastError, isNotNull);
    expect(await access.isUnlocked(), isFalse);
  });

  test('setup requires 4 digits then unlocks the session', () async {
    expect(await access.setupPin('12'), isFalse);
    expect(await access.setupPin('5820'), isTrue);
    expect(await access.hasPin(), isTrue);
    expect(await access.isUnlocked(), isTrue);
  });

  test('wrong PIN does not unlock', () async {
    await access.setupPin('5820');
    await access.lock();
    expect(await access.unlock('0000'), isFalse);
    expect(access.lastError, 'Mật khẩu không đúng');
    expect(await access.unlock('5820'), isTrue);
  });

  test('change PIN persists the new hash', () async {
    await access.setupPin('5820');
    expect(await access.changePin(current: '5820', next: '2468'), isTrue);
    await access.lock();
    expect(await access.unlock('5820'), isFalse);
    expect(await access.unlock('2468'), isTrue);
  });
}
