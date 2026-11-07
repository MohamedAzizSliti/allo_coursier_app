import 'package:allo_coursier_app/screens/agent/agent_dashboard.dart';
import 'package:allo_coursier_app/services/api_client.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('API_TEST_EMAIL');
  const password = String.fromEnvironment('API_TEST_PASSWORD');

  testWidgets('admin dashboard loads stats without a hard error', (tester) async {
    await AlloApi.instance.login(email, password);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const AgentDashboard(role: 'admin'),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 20));

    expect(find.text('Tableau de Bord'), findsWidgets);
    expect(find.textContaining('Impossible de charger le tableau de bord.'), findsNothing);
  }, skip: email.isEmpty || password.isEmpty);
}