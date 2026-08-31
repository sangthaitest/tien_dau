import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/presentation/home/widgets/home_bottom_nav.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding.zero;
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
}

Future<void> _pumpNav(
  WidgetTester tester, {
  ValueChanged<AppTab>? onTabSelected,
  VoidCallback? onAddPressed,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: HomeBottomNav(
            tab: AppTab.home,
            onTabSelected: onTabSelected,
            onAddPressed: onAddPressed,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('idle has no focus overlay', (tester) async {
    _phone(tester);
    await _pumpNav(tester, onTabSelected: (_) {});
    expect(find.byKey(const Key('nav-focus-capsule')), findsNothing);
  });

  testWidgets('tap still selects the tab', (tester) async {
    _phone(tester);
    AppTab? selected;
    await _pumpNav(tester, onTabSelected: (tab) => selected = tab);

    await tester.tap(find.byKey(const Key('nav-statistics')));
    await tester.pump();

    expect(selected, AppTab.statistics);
    expect(find.byKey(const Key('nav-focus-capsule')), findsNothing);
  });

  testWidgets('hold bubble sits on the pressed item, not the left edge', (
    tester,
  ) async {
    _phone(tester);
    AppTab? selected;
    await _pumpNav(tester, onTabSelected: (tab) => selected = tab);

    final settings = find.byKey(const Key('nav-settings'));
    final home = find.byKey(const Key('nav-home'));
    final gesture = await tester.startGesture(tester.getCenter(settings));
    await tester.pump();
    expect(find.byKey(const Key('nav-focus-capsule')), findsNothing);

    await tester.pump(const Duration(milliseconds: 130));
    await tester.pump();
    expect(find.byKey(const Key('nav-focus-capsule')), findsOneWidget);

    final bubble = tester.getRect(find.byKey(const Key('nav-focus-capsule')));
    final settingsRect = tester.getRect(settings);
    final homeRect = tester.getRect(home);
    expect(bubble.center.dx, closeTo(settingsRect.center.dx, 20));
    expect(bubble.center.dx, isNot(closeTo(homeRect.center.dx, 24)));
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pump();
    expect(selected, AppTab.settings);
    expect(find.byKey(const Key('nav-focus-capsule')), findsNothing);
  });

  testWidgets('hold drag slides the bubble with the finger', (tester) async {
    _phone(tester);
    await _pumpNav(tester, onTabSelected: (_) {});

    final transactions = find.byKey(const Key('nav-transactions'));
    final statistics = find.byKey(const Key('nav-statistics'));
    final gesture = await tester.startGesture(tester.getCenter(transactions));
    await tester.pump(const Duration(milliseconds: 130));
    await tester.pump();

    var bubble = tester.getRect(find.byKey(const Key('nav-focus-capsule')));
    expect(
      bubble.center.dx,
      closeTo(tester.getRect(transactions).center.dx, 20),
    );

    await gesture.moveTo(tester.getCenter(statistics));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    bubble = tester.getRect(find.byKey(const Key('nav-focus-capsule')));
    expect(bubble.center.dx, closeTo(tester.getRect(statistics).center.dx, 20));
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pump();
    expect(find.byKey(const Key('nav-focus-capsule')), findsNothing);
  });

  testWidgets('press cancel does not select the tab', (tester) async {
    _phone(tester);
    AppTab? selected;
    await _pumpNav(tester, onTabSelected: (tab) => selected = tab);

    final center = tester.getCenter(find.byKey(const Key('nav-transactions')));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await gesture.cancel();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(selected, isNull);
  });

  testWidgets('press drag across items selects only the last focused tab', (
    tester,
  ) async {
    _phone(tester);
    final selected = <AppTab>[];
    await _pumpNav(tester, onTabSelected: selected.add);

    final home = tester.getCenter(find.byKey(const Key('nav-home')));
    final transactions = tester.getCenter(
      find.byKey(const Key('nav-transactions')),
    );
    final settings = tester.getCenter(find.byKey(const Key('nav-settings')));

    final gesture = await tester.startGesture(home);
    await tester.pump();
    expect(selected, isEmpty);

    await gesture.moveTo(transactions);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(selected, isEmpty);

    await gesture.moveTo(settings);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(selected, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(selected, [AppTab.settings]);
  });

  testWidgets('press drag does not shift sibling nav items', (tester) async {
    _phone(tester);
    await _pumpNav(tester, onTabSelected: (_) {});

    final homeBefore = tester.getRect(find.byKey(const Key('nav-home')));
    final statsBefore = tester.getRect(find.byKey(const Key('nav-statistics')));
    final navBefore = tester.getSize(find.byType(HomeBottomNav));

    final start = tester.getCenter(find.byKey(const Key('nav-home')));
    final end = tester.getCenter(find.byKey(const Key('nav-settings')));
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byKey(const Key('nav-home'))), homeBefore);
    expect(
      tester.getRect(find.byKey(const Key('nav-statistics'))),
      statsBefore,
    );
    expect(tester.getSize(find.byType(HomeBottomNav)), navBefore);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
  });

  testWidgets('tap add button still runs onAddPressed', (tester) async {
    _phone(tester);
    var added = 0;
    await _pumpNav(tester, onAddPressed: () => added++);

    expect(find.byKey(const Key('fab-glass-lens')), findsNothing);
    await tester.tap(find.byKey(const Key('fab-add')));
    await tester.pump();

    expect(added, 1);
  });

  testWidgets('press add shows a glass lens then hides it', (tester) async {
    _phone(tester);
    await _pumpNav(tester, onAddPressed: () {});

    expect(find.byKey(const Key('fab-glass-lens')), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('fab-add'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.byKey(const Key('fab-glass-lens')), findsOneWidget);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.byKey(const Key('fab-glass-lens')), findsNothing);
  });

  testWidgets('add button cancel does not run onAddPressed', (tester) async {
    _phone(tester);
    var added = 0;
    await _pumpNav(tester, onAddPressed: () => added++);

    final center = tester.getCenter(find.byKey(const Key('fab-add')));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await gesture.cancel();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    expect(added, 0);
  });

  testWidgets('drag from a tab onto add does not trigger add', (tester) async {
    _phone(tester);
    final selected = <AppTab>[];
    var added = 0;
    await _pumpNav(
      tester,
      onTabSelected: selected.add,
      onAddPressed: () => added++,
    );

    final start = tester.getCenter(find.byKey(const Key('nav-transactions')));
    final fab = tester.getCenter(find.byKey(const Key('fab-add')));
    final gesture = await tester.startGesture(start);
    await tester.pump();
    expect(selected, isEmpty);
    expect(added, 0);

    await gesture.moveTo(fab);
    await tester.pump();
    expect(selected, isEmpty);
    expect(added, 0);

    await gesture.up();
    await tester.pump();

    expect(added, 0);
    expect(selected, [AppTab.transactions]);
  });
}
