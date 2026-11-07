import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:allo_coursier_app/widgets/scan_manual_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('manual entry submits a typed parcel number', (tester) async {
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ScanManualEntry(
            enabled: true,
            onSubmit: (code) => submitted = code,
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' 83682 ');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(submitted, '83682');
  });

  testWidgets('manual entry ignores empty submit', (tester) async {
    var called = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ScanManualEntry(
            enabled: true,
            onSubmit: (_) => called = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(called, isFalse);
  });
}
