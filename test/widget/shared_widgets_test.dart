import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:allo_coursier_app/widgets/empty_state.dart';
import 'package:allo_coursier_app/widgets/error_banner.dart';
import 'package:allo_coursier_app/widgets/filter_chip_bar.dart';
import 'package:allo_coursier_app/widgets/lazy_indexed_stack.dart';
import 'package:allo_coursier_app/widgets/order_list_card.dart';
import 'package:allo_coursier_app/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatusChip shows localized status label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusChip(status: 'En cours'))),
    );
    expect(find.text('جارٍ'), findsOneWidget);
  });

  testWidgets('EmptyState shows message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyState(message: 'لا توجد طلبات'))),
    );
    expect(find.text('لا توجد طلبات'), findsOneWidget);
  });

  testWidgets('ErrorBanner retry callback', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorBanner(message: 'خطأ في الشبكة', onRetry: () => retried = true),
        ),
      ),
    );
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retried, isTrue);
  });

  testWidgets('OrderListCard stays usable in RTL', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: OrderListCard(
              commande: const CommandeModel(
                id: '12',
                clientNom: 'علي',
                status: 'En cours',
                produitPrixTotal: 40,
                fraisLivraison: 8,
              ),
              onView: () {},
              onPrint: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('طلب HT12'), findsOneWidget);
    expect(find.text('سعر الطرد'), findsOneWidget);
    expect(find.text('40.00 د.ت'), findsOneWidget);
    expect(find.text('رسوم التوصيل'), findsOneWidget);
    expect(find.text('8.00 د.ت'), findsOneWidget);
    expect(find.text('المجموع'), findsOneWidget);
    expect(find.text('48.00 د.ت'), findsOneWidget);
    expect(find.byTooltip('عرض'), findsOneWidget);
    expect(find.byTooltip('طباعة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FilterChipBar selects a chip', (tester) async {
    var selected = 'Tous';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterChipBar(
            values: const ['Tous', 'En cours'],
            selected: selected,
            labelOf: (value) => value,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('En cours'));
    expect(selected, 'En cours');
  });

  testWidgets('LazyIndexedStack builds only the selected child first', (tester) async {
    var builtSecond = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LazyIndexedStack(
          index: 0,
          children: [
            const Text('first-tab'),
            Builder(
              builder: (context) {
                builtSecond = true;
                return const Text('second-tab');
              },
            ),
          ],
        ),
      ),
    );

    expect(find.text('first-tab'), findsOneWidget);
    expect(builtSecond, isFalse);
  });
}
