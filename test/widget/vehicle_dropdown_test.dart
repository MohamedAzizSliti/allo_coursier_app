import 'package:allo_coursier_app/models/vehicle_model.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:allo_coursier_app/widgets/vehicle_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('vehicle dropdown does not overflow in RTL with long labels',
      (tester) async {
    FlutterError.onError = (details) {
      fail(details.exceptionAsString());
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 320,
                child: VehicleDropdown(
                  vehicles: [
                    VehicleModel(
                      id: '29',
                      matricule: '249tunis5247 extra long plate',
                      model: 'Fiat/doblo Partner long model name',
                    ),
                  ],
                  value: '29',
                  hint: 'اختر المركبة',
                  onChanged: _noop,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(VehicleDropdown), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop(String? _) {}
