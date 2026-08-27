import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tien_day/application/user_profile_service.dart';
import 'package:tien_day/data/datasources/finance_local_datasource.dart';
import 'package:tien_day/data/db/app_database.dart';
import 'package:tien_day/data/repositories/user_profile_repository_impl.dart';
import 'package:tien_day/domain/entities/user_profile.dart';
import 'package:tien_day/presentation/profile/user_profile_controller.dart';

import '../support/memory_user_profile_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('defaults match V3 seed profile', () {
    expect(UserProfile.defaults.displayName, 'Minh Khuê');
    expect(UserProfile.defaults.email, 'minhkhue@email.com');
    expect(UserProfile.defaults.initials, 'MK');
    expect(UserProfile.defaults.avatarPath, isNull);
  });

  test('initialsFromDisplayName covers single and multi word names', () {
    expect(initialsFromDisplayName('Minh Khuê'), 'MK');
    expect(initialsFromDisplayName('Nguyễn Văn An'), 'NA');
    expect(initialsFromDisplayName('Minh'), 'MI');
    expect(initialsFromDisplayName('A'), 'A');
    expect(initialsFromDisplayName('  '), '?');
  });

  test('displayName persists across a fresh controller load', () async {
    final repo = MemoryUserProfileRepository();
    final first = UserProfileController(UserProfileService(repo));
    await first.load();
    expect(first.profile, UserProfile.defaults);

    await first.setDisplayName('Nguyễn Văn A');
    expect(first.profile.displayName, 'Nguyễn Văn A');
    expect(first.profile.initials, 'NA');
    first.dispose();

    final second = UserProfileController(UserProfileService(repo));
    await second.load();
    expect(second.profile.displayName, 'Nguyễn Văn A');
    expect(second.profile.email, 'minhkhue@email.com');
    expect(second.profile.initials, 'NA');
    second.dispose();
  });

  test('empty displayName is rejected', () async {
    final repo = MemoryUserProfileRepository();
    final controller = UserProfileController(UserProfileService(repo));
    await controller.load();
    await controller.setDisplayName('   ');
    expect(controller.profile.displayName, 'Minh Khuê');
    expect(controller.error, isNotNull);
    controller.dispose();
  });

  test('email persists across a fresh controller load', () async {
    final repo = MemoryUserProfileRepository();
    final first = UserProfileController(UserProfileService(repo));
    await first.load();
    await first.setEmail('nguyenvana@email.com');
    first.dispose();

    final second = UserProfileController(UserProfileService(repo));
    await second.load();
    expect(second.profile.email, 'nguyenvana@email.com');
    second.dispose();
  });

  test('missing stored prefs keep V3 defaults', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_profile');
    final db = await AppDatabase.openPath(p.join(dir.path, 'tien_day.db'));
    addTearDown(db.close);
    final repo = UserProfileRepositoryImpl(PrefsLocalDataSource(db));
    final controller = UserProfileController(UserProfileService(repo));
    await controller.load();
    expect(controller.profile, UserProfile.defaults);
    controller.dispose();
  });

  test('SQLite prefs persist profile across reload', () async {
    final dir = await Directory.systemTemp.createTemp('tien_day_profile');
    final db = await AppDatabase.openPath(p.join(dir.path, 'tien_day.db'));
    addTearDown(db.close);
    final repo = UserProfileRepositoryImpl(PrefsLocalDataSource(db));
    final first = UserProfileController(UserProfileService(repo));
    await first.load();
    await first.setDisplayName('Nguyễn Văn A');
    first.dispose();

    final second = UserProfileController(UserProfileService(repo));
    await second.load();
    expect(second.profile.displayName, 'Nguyễn Văn A');
    expect(second.profile.email, 'minhkhue@email.com');
    second.dispose();
  });
}
