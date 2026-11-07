import 'package:allo_coursier_app/screens/livreur/livreur_dashboard.dart';
import 'package:allo_coursier_app/screens/notifications_screen.dart';
import 'package:allo_coursier_app/services/notification_api_service.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_api.dart';

void main() {
  testWidgets('refetches notifications when the tab becomes visible', (tester) async {
    var calls = 0;
    final api = createMockApi((options) {
      expect(options.path, '/notifications');
      calls += 1;
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok([]),
      );
    });
    final service = NotificationApiService(api);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: NotificationsScreen(active: true, service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: NotificationsScreen(active: false, service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: NotificationsScreen(active: true, service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('tab refetch keeps content instead of a blocking spinner', (tester) async {
    var calls = 0;
    final api = createMockApi((options) {
      expect(options.path, '/notifications');
      calls += 1;
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok([
          {
            'id': '9',
            'title': 'Nouvelle Commande',
            'body': 'Une nouvelle commande a été placée!',
            'isRead': false,
            'sentAt': '2026-10-06T08:00:00.000Z',
            'orderId': '83678',
          },
        ]),
      );
    });
    final service = NotificationApiService(api);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: NotificationsScreen(active: true, service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle Commande'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: NotificationsScreen(active: false, service: service),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: NotificationsScreen(active: true, service: service),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Nouvelle Commande'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('driver dashboard has no notifications bell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LivreurDashboard(),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
