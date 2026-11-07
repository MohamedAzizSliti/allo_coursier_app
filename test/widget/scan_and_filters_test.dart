import 'package:allo_coursier_app/models/parcel_status.dart';
import 'package:allo_coursier_app/screens/scan/scan_confirm_dialog.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shipment filters include Livré and Payé', () {
    expect(shipmentFilters, containsAll(['Tous', 'Livré', 'Payé', 'Annuler']));
    expect(shipmentFilters, isNot(contains('Livrer')));
  });

  testWidgets('scanner confirm dialog shows colis and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ScanConfirmDialog(
          displayId: 'HT83678',
          status: 'En cours',
          message: 'Confirmer la réception au dépôt ?',
          confirmLabel: 'Continuer',
        ),
      ),
    );

    expect(find.text('طرد HT83678'), findsOneWidget);
    expect(find.text('الحالة الحالية : جارٍ'), findsOneWidget);
    expect(find.text('Confirmer la réception au dépôt ?'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
  });
}
