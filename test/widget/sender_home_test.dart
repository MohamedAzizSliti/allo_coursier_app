import 'package:allo_coursier_app/screens/business_client/dashboard_screen.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sender hero matches the web espresso card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SenderHeroCard(
            dateLabel: 'jeudi 22 octobre',
            greeting: 'Bonjour, verona',
            total: 12,
            circulation: 4,
            deliveredPct: '50.0 %',
            paidPct: '25.0 %',
          ),
        ),
      ),
    );

    expect(find.text('Bonjour, verona'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('طرداً إجمالاً'), findsOneWidget);
  });
}
