import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:allo_coursier_app/screens/livreur/driver_home_view.dart';
import 'package:allo_coursier_app/screens/livreur/driver_parcel_card.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('driver home shows greeting, stats and scanner', (tester) async {
    String? opened;
    var scanned = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DriverHomeView(
              name: 'Ahmed',
              dateLabel: 'vendredi 23 octobre',
              total: 12,
              inRoute: 4,
              delivered: 6,
              cancelled: 1,
              redeliver: 1,
              earnings: 245.5,
              onOpenStatus: (status) => opened = status,
              onScan: () => scanned = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('مرحباً، Ahmed'), findsOneWidget);
    expect(find.text('موصّل'), findsOneWidget);
    expect(find.text('12'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    expect(find.text('6'), findsWidgets);
    expect(find.text('في الطريق'), findsWidgets);
    expect(find.text('تم التسليم'), findsWidgets);
    expect(find.text('مسح رمز QR'), findsOneWidget);
    expect(find.textContaining('245.50'), findsOneWidget);

    await tester.tap(find.text('في الطريق').first);
    await tester.tap(find.text('مسح رمز QR'));
    expect(opened, 'En route');
    expect(scanned, isTrue);
  });

  testWidgets('driver parcel card shows HT id and destination', (tester) async {
    var opened = false;
    const parcel = CommandeModel(
      id: '83681',
      clientNom: 'Sami',
      clientVille: 'Gabes',
      produitNom: 'kaak',
      produitPrixTotal: 209,
      fraisLivraison: 8,
      status: 'En route',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DriverParcelCard(
            commande: parcel,
            onOpen: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text('HT83681'), findsOneWidget);
    expect(find.textContaining('Sami'), findsOneWidget);
    expect(find.textContaining('Gabes'), findsOneWidget);
    expect(find.text('kaak'), findsOneWidget);
    expect(find.text('سعر الطرد'), findsOneWidget);
    expect(find.text('209.00 د.ت'), findsOneWidget);
    expect(find.text('رسوم التوصيل'), findsOneWidget);
    expect(find.text('8.00 د.ت'), findsOneWidget);
    expect(find.text('المجموع'), findsOneWidget);
    expect(find.text('217.00 د.ت'), findsOneWidget);

    await tester.tap(find.text('HT83681'));
    expect(opened, isTrue);
  });
}
