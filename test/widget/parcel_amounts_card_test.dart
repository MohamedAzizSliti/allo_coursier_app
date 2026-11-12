import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:allo_coursier_app/widgets/parcel_amounts_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows colis price, delivery tarif and total', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ParcelAmountsCard(colisPrice: 103, deliveryFee: 8),
        ),
      ),
    );

    expect(find.text('سعر الطرد'), findsOneWidget);
    expect(find.text('رسوم التوصيل'), findsOneWidget);
    expect(find.text('المجموع'), findsOneWidget);
    expect(find.text('103.00 د.ت'), findsOneWidget);
    expect(find.text('8.00 د.ت'), findsOneWidget);
    expect(find.text('111.00 د.ت'), findsOneWidget);
  });

  testWidgets('expéditeur view hides delivery fee', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ParcelAmountsCard(
            colisPrice: 103,
            deliveryFee: 8,
            showDeliveryFee: false,
          ),
        ),
      ),
    );

    expect(find.text('سعر الطرد'), findsOneWidget);
    expect(find.text('103.00 د.ت'), findsOneWidget);
    expect(find.text('رسوم التوصيل'), findsNothing);
    expect(find.text('المجموع'), findsNothing);
    expect(find.text('8.00 د.ت'), findsNothing);
  });
}
