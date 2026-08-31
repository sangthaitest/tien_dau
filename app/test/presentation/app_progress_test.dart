import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/presentation/theme/app_progress.dart';
import 'package:tien_day/presentation/theme/app_theme.dart';

void main() {
  testWidgets('busy overlay is a compact card, not a wide alert row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () =>
                  AppBusyDialog.show(context, message: 'Đang sao lưu…'),
              child: const Text('go'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.byKey(const Key('app-busy-dialog')), findsOneWidget);
    expect(find.text('Đang sao lưu…'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AppCircularProgress), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final spinner = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(spinner.strokeWidth, AppProgress.strokeWidth);
    expect(spinner.constraints, BoxConstraints.tight(const Size.square(40)));
  });

  testWidgets('linear progress is a rounded pill matching v3', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: AppLinearProgress(value: 0.4)),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
      BorderRadius.circular(4),
    );
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.4);
    expect(bar.minHeight, 8);
    expect(bar.trackGap, 0);
  });
}
