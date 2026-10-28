import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:ly_hr_dashboard_flutter/features/employees/employees_view.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

void main() {
  setUp(() {
    ApiService.setTokens(accessToken: 'mock_test_token_employees_header');
    ApiService.client = MockClient((request) async {
      if (request.url.path.contains('/api/hr/employees')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 0,
              'totalPages': 0,
            },
          }),
          200,
        );
      }
      return http.Response('{"success": true}', 200);
    });
  });

  Widget createTestWidget(HRProvider provider) {
    return ChangeNotifierProvider<HRProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: EmployeesView(),
      ),
    );
  }

  group('EmployeesView Header Tests - Assign Task Button Removal', () {
    testWidgets('Assign Task button is removed and Add Staff Member button is visible on Desktop (1920x1080)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      await tester.pumpWidget(createTestWidget(provider));
      await tester.pumpAndSettle();

      // Ensure Employee Directory header title is present
      expect(find.text('Employee Directory'), findsOneWidget);

      // Verify Assign Task button is no longer visible
      expect(find.text('Assign Task'), findsNothing);
      expect(find.byIcon(Icons.check_box_outlined), findsNothing);

      // Verify Add Staff Member button is visible and properly configured
      expect(find.text('Add Staff Member'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('Assign Task button is removed and Add Staff Member renders on Tablet (800x1000)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      await tester.pumpWidget(createTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Assign Task'), findsNothing);
      expect(find.text('Add Staff Member'), findsOneWidget);
    });

    testWidgets('Assign Task button is removed and Add Staff Member renders cleanly on Mobile (400x800)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      await tester.pumpWidget(createTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Assign Task'), findsNothing);
      expect(find.text('Add Staff Member'), findsOneWidget);
      // No assertion or overflow exceptions caught
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Add Staff Member button opens the Add Staff dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      await tester.pumpWidget(createTestWidget(provider));
      await tester.pumpAndSettle();

      final addStaffBtn = find.widgetWithText(ElevatedButton, 'Add Staff Member');
      expect(addStaffBtn, findsOneWidget);

      await tester.tap(addStaffBtn);
      await tester.pumpAndSettle();

      // Verify modal dialog opened
      expect(find.text('Add New Staff Member'), findsOneWidget);
    });
  });
}

