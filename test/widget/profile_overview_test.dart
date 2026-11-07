import 'package:allo_coursier_app/models/user_model.dart';
import 'package:allo_coursier_app/screens/profile_screen.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = UserModel(
    id: '8',
    email: 'exp-1560@expediteur.allocoursier.tn',
    name: 'verona',
    role: 'business_client',
    phone: '55555555',
    address: 'EZREZREZER',
    city: 'zaghouan',
    gouvernorat: 'Zaghouan',
    company: 'verona',
    cin: '111111111',
    montantDisponible: 12.5,
  );

  testWidgets('profile overview shows locally saved sender fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileOverview(user: user, onEdit: () {}),
          ),
        ),
      ),
    );

    expect(find.text('verona'), findsWidgets);
    expect(find.text('exp-1560@expediteur.allocoursier.tn'), findsOneWidget);
    expect(find.text('مرسِل'), findsOneWidget);
    expect(find.text('الهاتف'), findsOneWidget);
    expect(find.text('العنوان'), findsOneWidget);
    expect(find.text('المدينة'), findsOneWidget);
    expect(find.text('الولاية'), findsOneWidget);
    expect(find.text('55555555'), findsOneWidget);
    expect(find.text('EZREZREZER'), findsOneWidget);
    expect(find.text('zaghouan'), findsOneWidget);
    expect(find.text('زغوان'), findsOneWidget);
    expect(find.text('111111111'), findsOneWidget);
    expect(find.text('تعديل الملف'), findsOneWidget);
    expect(find.text('غير متوفر'), findsNothing);
  });

  testWidgets('finance card shows available and held amounts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ProfileFinanceCard(available: 12.5, unavailable: 4),
        ),
      ),
    );

    expect(find.text('الإحصائيات المالية'), findsOneWidget);
    expect(find.text('12.50 د.ت'), findsOneWidget);
    expect(find.text('4.00 د.ت'), findsOneWidget);
    expect(find.text('المبلغ المتاح'), findsOneWidget);
    expect(find.text('المبلغ غير المتاح'), findsOneWidget);
  });
}
