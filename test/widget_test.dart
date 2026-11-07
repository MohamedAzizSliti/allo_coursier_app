import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppTheme builds Material 3 light theme', (tester) async {
    final theme = AppTheme.light();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.primary);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: Text('Allo Coursier')),
      ),
    );
    expect(find.text('Allo Coursier'), findsOneWidget);
  });
}
