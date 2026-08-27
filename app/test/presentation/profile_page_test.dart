import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/home_query.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/application/user_profile_service.dart';
import 'package:tien_day/domain/entities/user_profile.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/profile/user_profile_controller.dart';

import '../support/memory_transaction_repository.dart';
import '../support/memory_user_profile_repository.dart';
import '../support/shell_harness.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Profile rename updates Settings and Home from one source', (
    tester,
  ) async {
    _phone(tester);

    final service = TransactionService(MemoryTransactionRepository());
    final home = HomeController(
      HomeQuery(service, clock: () => DateTime(2026, 8, 18, 9)),
    );
    final profileRepo = MemoryUserProfileRepository();
    final harness = buildShell(
      transactions: service,
      home: home,
      profileRepo: profileRepo,
      clock: () => DateTime(2026, 8, 18, 9),
    );
    await harness.profile.load();

    await tester.pumpWidget(MaterialApp(home: harness.shell));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-user-name')), findsOneWidget);
    expect(find.text('Minh Khuê'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-profile-name')), findsOneWidget);
    expect(find.text('Minh Khuê'), findsWidgets);
    expect(find.text('minhkhue@email.com'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ'), findsWidgets);
    expect(find.byKey(const Key('profile-display-name')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-edit-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-name-field')),
      'Nguyễn Văn A',
    );
    await tester.tap(find.byKey(const Key('profile-name-save')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn A'), findsWidgets);
    expect(find.text('NA'), findsWidgets);
    expect(find.byKey(const Key('profile-email-note')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-edit-email')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('không dùng để thu thập thông tin cá nhân'),
      findsWidgets,
    );
    await tester.enterText(
      find.byKey(const Key('profile-email-field')),
      'nguyenvana@email.com',
    );
    await tester.tap(find.byKey(const Key('profile-email-save')));
    await tester.pumpAndSettle();
    expect(find.text('nguyenvana@email.com'), findsWidgets);

    await tester.tap(find.byKey(const Key('profile-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-profile-name')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('settings-profile-name'))).data,
      'Nguyễn Văn A',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('settings-profile-email'))).data,
      'nguyenvana@email.com',
    );

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('home-user-name'))).data,
      'Nguyễn Văn A',
    );
    expect(harness.profile.profile.displayName, 'Nguyễn Văn A');
    expect(harness.profile.profile.email, 'nguyenvana@email.com');
    expect(profileRepo.stored.displayName, 'Nguyễn Văn A');
    expect(profileRepo.stored.email, 'nguyenvana@email.com');
  });

  test('controller rejects blank email without mutating store', () async {
    final repo = MemoryUserProfileRepository(
      stored: const UserProfile(
        displayName: 'Minh Khuê',
        email: 'minhkhue@email.com',
      ),
    );
    final controller = UserProfileController(UserProfileService(repo));
    await controller.load();
    await controller.setEmail('   ');
    expect(repo.stored.email, 'minhkhue@email.com');
    expect(controller.error, isNotNull);
    controller.dispose();
  });

  test('controller rejects blank name without mutating store', () async {
    final repo = MemoryUserProfileRepository(
      stored: const UserProfile(
        displayName: 'Minh Khuê',
        email: 'minhkhue@email.com',
      ),
    );
    final controller = UserProfileController(UserProfileService(repo));
    await controller.load();
    await controller.setDisplayName('');
    expect(repo.stored.displayName, 'Minh Khuê');
    expect(controller.error, isNotNull);
    controller.dispose();
  });
}
