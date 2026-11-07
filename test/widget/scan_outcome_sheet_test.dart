import 'package:allo_coursier_app/screens/scan/scan_outcome_sheet.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scan outcome sheet lists delivery results and confirms Livrer',
      (tester) async {
    ScanOutcome? picked;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                picked = await ScanOutcomeSheet.show(
                  context,
                  displayId: 'HT83682',
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

    expect(find.text('طرد HT83682'), findsOneWidget);
    expect(find.text('اختر نتيجة التوصيل'), findsOneWidget);
    expect(find.text('تم التسليم'), findsOneWidget);
    expect(find.text('إعادة التسليم'), findsOneWidget);
    expect(find.text('ملغى'), findsOneWidget);

    await tester.tap(find.text('تم التسليم'));
    await tester.pump();
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(picked?.action, 'Livrer');
    expect(picked?.reason, isEmpty);
  });

  testWidgets('scan outcome sheet requires a reason before relivrer',
      (tester) async {
    ScanOutcome? picked;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                picked = await ScanOutcomeSheet.show(
                  context,
                  displayId: 'HT83682',
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
    await tester.tap(find.text('إعادة التسليم'));
    await tester.pump();
    await tester.tap(find.text('تأكيد'));
    await tester.pump();

    expect(picked, isNull);
    expect(find.text('يرجى إدخال السبب.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Client absent');
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(picked?.action, 'Relivrer');
    expect(picked?.reason, 'Client absent');
  });
}
