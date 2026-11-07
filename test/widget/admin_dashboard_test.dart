import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:allo_coursier_app/screens/agent/dashboard_screen.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const counts = {
    'Tous': 20,
    'En cours': 4,
    'En dépôt': 2,
    'En route': 1,
    'Relivrer': 0,
    'Livré': 6,
    'Payé': 4,
    'Annuler': 3,
  };

  Widget host({required bool isAdmin}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: ListView(
          children: [
            AdminDashboardView(
          isAdmin: isAdmin,
          counts: counts,
          expediteurs: 8,
          livreurs: 3,
          vehicles: 5,
          today: 7,
          weekDeliveries: 11,
          enRouteAmount: 40,
          topPlaces: const [PlaceCount('Sfax', 6)],
          recent: const [
            CommandeModel(
              id: '99',
              produitNom: 'Huile',
              expediteurName: 'Verona',
              clientGouvernorat: 'Sfax',
              produitPrixTotal: 28,
              status: 'Livrer',
              paid: true,
            ),
          ],
          onOpenUsers: (_) {},
          onOpenVehicles: () {},
          onOpenToday: () {},
          onOpenOrders: (_) {},
          onOpenPayments: () {},
          onOpenOrder: (_) {},
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('admin dashboard matches the web summary', (tester) async {
    await tester.pumpWidget(host(isAdmin: true));

    expect(find.text('20'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.text('طرود اليوم'), findsOneWidget);
    expect(find.text('المعاملات'), findsOneWidget);
    expect(find.text('6 غير مدفوعة · 4 مدفوعة. مبلغ الطرود ورسوم التوصيل.'), findsOneWidget);
    expect(find.text('الوجهات'), findsOneWidget);
    expect(find.text('Sfax'), findsWidgets);
    expect(find.textContaining('HT99'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
  });

  testWidgets('an agent does not see the transactions card', (tester) async {
    await tester.pumpWidget(host(isAdmin: false));
    expect(find.text('المعاملات'), findsNothing);
  });
}
