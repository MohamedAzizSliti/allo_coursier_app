import 'package:allo_coursier_app/models/user_model.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:allo_coursier_app/widgets/livreur_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('livreur picker lists drivers and returns the tapped one',
      (tester) async {
    UserModel? picked;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                picked = await LivreurPickerSheet.show(
                  context,
                  drivers: const [
                    UserModel(
                      id: '824',
                      email: 'a@test.com',
                      name: 'Ahmed Manai',
                      role: 'delivery_person',
                    ),
                    UserModel(
                      id: '877',
                      email: 'b@test.com',
                      name: 'Nouveau Livreur',
                      role: 'delivery_person',
                    ),
                  ],
                  selectedId: '824',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed Manai'), findsOneWidget);
    expect(find.text('Nouveau Livreur'), findsOneWidget);
    await tester.tap(find.text('Nouveau Livreur'));
    await tester.pumpAndSettle();
    expect(picked?.id, '877');
  });

  testWidgets('livreur picker shows empty copy when there are no drivers',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                LivreurPickerSheet.show(context, drivers: const []);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد موصّلون.'), findsOneWidget);
  });
}
