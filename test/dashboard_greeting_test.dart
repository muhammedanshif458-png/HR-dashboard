import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:ly_hr_dashboard_flutter/features/dashboard/hr_dashboard_view.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

void main() {
  group('HRDashboardView.getGreeting - Unit Tests', () {
    test('5:00 AM – 11:59 AM returns Good Morning', () {
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 5, 0, 0)),
        'Good Morning',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 9, 0, 0)),
        'Good Morning',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 11, 59, 59)),
        'Good Morning',
      );
    });

    test('12:00 PM – 4:59 PM returns Good Afternoon', () {
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 12, 0, 0)),
        'Good Afternoon',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 13, 30, 0)),
        'Good Afternoon',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 16, 59, 59)),
        'Good Afternoon',
      );
    });

    test('5:00 PM – 4:59 AM returns Good Evening', () {
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 17, 0, 0)),
        'Good Evening',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 18, 30, 0)),
        'Good Evening',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 23, 59, 59)),
        'Good Evening',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 0, 0, 0)),
        'Good Evening',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 2, 0, 0)),
        'Good Evening',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 4, 59, 59)),
        'Good Evening',
      );
    });

    test('Exact boundary transitions', () {
      // 4:59:59 AM -> Good Evening vs 5:00:00 AM -> Good Morning
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 4, 59, 59)),
        'Good Evening',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 5, 0, 0)),
        'Good Morning',
      );

      // 11:59:59 AM -> Good Morning vs 12:00:00 PM -> Good Afternoon
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 11, 59, 59)),
        'Good Morning',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 12, 0, 0)),
        'Good Afternoon',
      );

      // 4:59:59 PM -> Good Afternoon vs 5:00:00 PM -> Good Evening
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 16, 59, 59)),
        'Good Afternoon',
      );
      expect(
        HRDashboardView.getGreeting(DateTime(2026, 11, 25, 17, 0, 0)),
        'Good Evening',
      );
    });

    test('Default parameter uses current local time', () {
      final nowGreeting = HRDashboardView.getGreeting();
      final expectedGreeting = HRDashboardView.getGreeting(DateTime.now());
      expect(nowGreeting, expectedGreeting);
    });
  });

  group('HRDashboardView.getNextGreetingBoundary - Unit Tests', () {
    test('Calculates next boundary correctly', () {
      // At 2:00 AM, next boundary is 5:00 AM today
      expect(
        HRDashboardView.getNextGreetingBoundary(DateTime(2026, 11, 25, 2, 0)),
        DateTime(2026, 11, 25, 5, 0),
      );

      // At 9:00 AM, next boundary is 12:00 PM today
      expect(
        HRDashboardView.getNextGreetingBoundary(DateTime(2026, 11, 25, 9, 0)),
        DateTime(2026, 11, 25, 12, 0),
      );

      // At 1:30 PM, next boundary is 5:00 PM today
      expect(
        HRDashboardView.getNextGreetingBoundary(DateTime(2026, 11, 25, 13, 30)),
        DateTime(2026, 11, 25, 17, 0),
      );

      // At 6:00 PM, next boundary is 5:00 AM tomorrow
      expect(
        HRDashboardView.getNextGreetingBoundary(DateTime(2026, 11, 25, 18, 0)),
        DateTime(2026, 11, 26, 5, 0),
      );
    });
  });

  group('HRDashboardView - Widget Tests', () {
    late HRProvider provider;

    setUp(() {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      provider = HRProvider();
    });

    Widget createWidget(
      WidgetTester tester, {
      DateTime Function()? currentTimeProvider,
    }) {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      return MaterialApp(
        theme: ThemeData(fontFamily: 'Plus Jakarta Sans'),
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: HRDashboardView(currentTimeProvider: currentTimeProvider),
        ),
      );
    }

    testWidgets('Renders Good Morning at 9:00 AM with exact styling & Hello Admin!',
        (tester) async {
      await tester.pumpWidget(createWidget(
        tester,
        currentTimeProvider: () => DateTime(2026, 11, 25, 9, 0, 0),
      ));
      await tester.pump();

      // Verify Hello Admin! greeting is preserved
      expect(find.text('Hello Admin!'), findsOneWidget);
      expect(find.text('👋'), findsOneWidget);

      // Verify greeting text
      final greetingFinder = find.text('Good Morning');
      expect(greetingFinder, findsOneWidget);

      // Verify exact TextStyle
      final textWidget = tester.widget<Text>(greetingFinder);
      expect(textWidget.style?.fontFamily, 'Plus Jakarta Sans');
      expect(textWidget.style?.fontSize, 28);
      expect(textWidget.style?.fontWeight, FontWeight.w800);
      expect(textWidget.style?.color, const Color(0xFF0F172A));
      expect(textWidget.style?.letterSpacing, -0.5);
    });

    testWidgets('Renders Good Afternoon at 1:30 PM', (tester) async {
      await tester.pumpWidget(createWidget(
        tester,
        currentTimeProvider: () => DateTime(2026, 11, 25, 13, 30, 0),
      ));
      await tester.pump();

      expect(find.text('Hello Admin!'), findsOneWidget);
      expect(find.text('Good Afternoon'), findsOneWidget);
      expect(find.text('Good Morning'), findsNothing);
      expect(find.text('Good Evening'), findsNothing);
    });

    testWidgets('Renders Good Evening at 6:30 PM', (tester) async {
      await tester.pumpWidget(createWidget(
        tester,
        currentTimeProvider: () => DateTime(2026, 11, 25, 18, 30, 0),
      ));
      await tester.pump();

      expect(find.text('Hello Admin!'), findsOneWidget);
      expect(find.text('Good Evening'), findsOneWidget);
      expect(find.text('Good Morning'), findsNothing);
      expect(find.text('Good Afternoon'), findsNothing);
    });

    testWidgets('Renders Good Evening at 2:00 AM', (tester) async {
      await tester.pumpWidget(createWidget(
        tester,
        currentTimeProvider: () => DateTime(2026, 11, 25, 2, 0, 0),
      ));
      await tester.pump();

      expect(find.text('Hello Admin!'), findsOneWidget);
      expect(find.text('Good Evening'), findsOneWidget);
      expect(find.text('Good Morning'), findsNothing);
      expect(find.text('Good Afternoon'), findsNothing);
    });

    testWidgets(
        'Automatically transitions from Good Morning to Good Afternoon across 12:00 PM boundary',
        (tester) async {
      var simulatedTime = DateTime(2026, 11, 25, 11, 59, 58); // 2 seconds before 12 PM

      await tester.pumpWidget(createWidget(
        tester,
        currentTimeProvider: () => simulatedTime,
      ));
      await tester.pump();

      expect(find.text('Good Morning'), findsOneWidget);
      expect(find.text('Good Afternoon'), findsNothing);

      // Advance time past 12:00 PM
      simulatedTime = DateTime(2026, 11, 25, 12, 0, 1);
      await tester.pump(const Duration(seconds: 3));

      // Greeting should automatically update without page reload
      expect(find.text('Good Morning'), findsNothing);
      expect(find.text('Good Afternoon'), findsOneWidget);
    });

    testWidgets(
        'Automatically transitions from Good Afternoon to Good Evening across 5:00 PM boundary',
        (tester) async {
      var simulatedTime = DateTime(2026, 11, 25, 16, 59, 58); // 2 seconds before 5 PM

      await tester.pumpWidget(createWidget(
        tester,
        currentTimeProvider: () => simulatedTime,
      ));
      await tester.pump();

      expect(find.text('Good Afternoon'), findsOneWidget);
      expect(find.text('Good Evening'), findsNothing);

      // Advance time past 5:00 PM
      simulatedTime = DateTime(2026, 11, 25, 17, 0, 1);
      await tester.pump(const Duration(seconds: 3));

      // Greeting should automatically update
      expect(find.text('Good Afternoon'), findsNothing);
      expect(find.text('Good Evening'), findsOneWidget);
    });

    testWidgets(
        'Automatically transitions from Good Evening to Good Morning across 5:00 AM boundary',
        (tester) async {
      var simulatedTime = DateTime(2026, 11, 25, 4, 59, 58); // 2 seconds before 5 AM

      await tester.pumpWidget(createWidget(
        tester,
        currentTimeProvider: () => simulatedTime,
      ));
      await tester.pump();

      expect(find.text('Good Evening'), findsOneWidget);
      expect(find.text('Good Morning'), findsNothing);

      // Advance time past 5:00 AM
      simulatedTime = DateTime(2026, 11, 25, 5, 0, 1);
      await tester.pump(const Duration(seconds: 3));

      // Greeting should automatically update
      expect(find.text('Good Evening'), findsNothing);
      expect(find.text('Good Morning'), findsOneWidget);
    });
  });
}
