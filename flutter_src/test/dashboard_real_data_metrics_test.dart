import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/features/dashboard/hr_dashboard_view.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/widgets/metric_card.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() {
    HRProvider.enableTestFixtures = false;
    ApiService.clearTokens();
  });

  tearDown(() {
    HRProvider.enableTestFixtures = false;
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  group('Dashboard Metrics Real Backend Mapping & Calculation', () {
    test('Maps all 9 cards from real backend aggregation response accurately',
        () async {
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/dashboard') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'HR dashboard statistics fetched successfully',
              'data': {
                'totalEmployees': 5,
                'activeEmployees': 4,
                'inactiveEmployees': 1,
                'eligibleEmployees': 3,
                'notCheckedIn': 1,
                'openTasks': 7,
                'resignedLast30Days': 1,
                'date': '2026-10-27',
                'todayPresent': 2,
                'todayAbsent': 0,
                'lateArrivals': 1,
                'onLeaveToday': 1,
                'todayWfh': 0,
                'todayLate': 1,
                'pendingLeaves': 3,
                'approvedLeaves': 1
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/hr/employees') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {'total': 0, 'page': 1, 'pages': 1, 'limit': 20}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/hr/attendance') {
          return http.Response(
            jsonEncode({'success': true, 'data': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/hr/tasks') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {'total': 0, 'page': 1, 'totalPages': 0, 'limit': 20}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/hr/leaves') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'leaves': [], 'pagination': {'total': 0, 'page': 1, 'pages': 1, 'limit': 20}}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/hr/departments') {
          return http.Response(
            jsonEncode({'success': true, 'data': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });
      ApiService.setTokens(accessToken: 'mock-valid-token');

      final provider = HRProvider();
      final ok = await provider.fetchDashboardData();

      expect(ok, true);
      final metrics = provider.dashboardMetrics;

      // 1. Total Staff
      expect(metrics.totalStaff, 5);
      // 2. Active Staff
      expect(metrics.activeStaff, 4);
      // 3. Present Today
      expect(metrics.presentToday, 2);
      // 4. Pending Leaves
      expect(metrics.pendingLeaves, 3);
      // 5. On Leave Today
      expect(metrics.onLeaveToday, 1);
      // 6. Late Check-ins
      expect(metrics.lateCheckIns, 1);
      // 7. Not Checked In
      expect(metrics.notCheckedIn, 1);
      // 8. Open Tasks
      expect(metrics.openTasks, 7);
      // 9. Resigned (30d)
      expect(metrics.resignedLast30Days, 1);
    });

    test('Computes Not Checked In correctly with approved leaves excluded from eligible pool',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'totalEmployees': 10,
              'activeEmployees': 8,
              'inactiveEmployees': 2,
              'todayPresent': 5,
              'lateArrivals': 2,
              'onLeaveToday': 2,
              'pendingLeaves': 1,
              'openTasks': 4,
              'resignedLast30Days': 1
              // notCheckedIn not returned by backend -> provider fallback formula:
              // eligible = max(0, active - onLeaveToday) = 8 - 2 = 6
              // notCheckedIn = max(0, eligible - present) = 6 - 5 = 1
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'mock-valid-token');

      final provider = HRProvider();
      await provider.fetchDashboardData();
      final metrics = provider.dashboardMetrics;

      expect(metrics.totalStaff, 10);
      expect(metrics.activeStaff, 8);
      expect(metrics.onLeaveToday, 2);
      expect(metrics.presentToday, 5);
      expect(metrics.notCheckedIn, 1);
    });

    test('Zero employee empty database handles 0 counts cleanly without negative values',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'totalEmployees': 0,
              'activeEmployees': 0,
              'inactiveEmployees': 0,
              'eligibleEmployees': 0,
              'notCheckedIn': 0,
              'openTasks': 0,
              'resignedLast30Days': 0,
              'todayPresent': 0,
              'lateArrivals': 0,
              'onLeaveToday': 0,
              'pendingLeaves': 0
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'mock-valid-token');

      final provider = HRProvider();
      await provider.fetchDashboardData();
      final metrics = provider.dashboardMetrics;

      expect(metrics.totalStaff, 0);
      expect(metrics.activeStaff, 0);
      expect(metrics.presentToday, 0);
      expect(metrics.lateCheckIns, 0);
      expect(metrics.notCheckedIn, 0);
      expect(metrics.openTasks, 0);
      expect(metrics.onLeaveToday, 0);
      expect(metrics.resignedLast30Days, 0);
      expect(metrics.pendingLeaves, 0);
    });
  });

  group('Dashboard UI State & MetricCard Placeholder Tests', () {
    test('metricDisplayPlaceholder returns "…" during loading', () {
      final provider = HRProvider();
      provider.isDashboardLoading = true;
      expect(provider.metricDisplayPlaceholder, '…');
    });

    test('metricDisplayPlaceholder returns "—" on API failure', () {
      final provider = HRProvider();
      provider.isDashboardLoading = false;
      provider.dashboardError = 'Server connection failed';
      provider.hasLoadedApiDashboard = false;
      expect(provider.metricDisplayPlaceholder, '—');
    });

    test('metricDisplayPlaceholder returns null when live data is loaded successfully', () {
      final provider = HRProvider();
      provider.isDashboardLoading = false;
      provider.dashboardError = null;
      provider.hasLoadedApiDashboard = true;
      expect(provider.metricDisplayPlaceholder, isNull);
    });

    testWidgets('MetricCard displays "…" while loading without showing hardcoded numbers',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Total Staff',
              value: 76, // even if an underlying int exists, displayValue overrides
              displayValue: '…',
              icon: Icons.badge_outlined,
              tone: 'blue',
              isActive: false,
              onClick: () {},
            ),
          ),
        ),
      );

      expect(find.text('…'), findsOneWidget);
      expect(find.text('76'), findsNothing);
      expect(find.text('Total Staff'), findsOneWidget);
    });

    testWidgets('MetricCard displays "—" on error without showing hardcoded numbers',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricCard(
              label: 'Active Staff',
              value: 53,
              displayValue: '—',
              icon: Icons.person_outline,
              tone: 'green',
              isActive: false,
              onClick: () {},
            ),
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
      expect(find.text('53'), findsNothing);
      expect(find.text('Active Staff'), findsOneWidget);
    });

    testWidgets('HRDashboardView renders real backend metrics into cards',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiDashboard = true;
      provider.apiDashboardMetrics = {
        'totalEmployees': 8,
        'activeEmployees': 8,
        'inactiveEmployees': 0,
        'eligibleEmployees': 8,
        'notCheckedIn': 2,
        'openTasks': 0,
        'resignedLast30Days': 0,
        'todayPresent': 6,
        'todayLate': 3,
        'lateArrivals': 3,
        'onLeaveToday': 0,
        'pendingLeaves': 0,
      };

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HRDashboardView(),
          ),
        ),
      );

      await tester.pump();

      // Check displayed metric texts
      expect(find.text('Total Staff'), findsOneWidget);
      expect(find.text('Active Staff'), findsOneWidget);
      expect(find.text('Present Today'), findsOneWidget);
      expect(find.text('Late Check-ins'), findsOneWidget);
      expect(find.text('Not Checked In'), findsOneWidget);
      expect(find.text('Open Tasks'), findsOneWidget);
      expect(find.text('Resigned (30d)'), findsOneWidget);

      // Verify actual counts displayed
      expect(find.text('8'), findsNWidgets(2)); // Total Staff (8) & Active Staff (8)
      expect(find.text('6'), findsOneWidget); // Present Today (6)
      expect(find.text('3'), findsOneWidget); // Late Check-ins (3)
      expect(find.text('2'), findsOneWidget); // Not Checked In (2)
      expect(find.text('0'), findsNWidgets(4)); // Pending Leaves, On Leave, Open Tasks, Resigned

      // Ensure no mock numbers 76, 53, 38 exist
      expect(find.text('76'), findsNothing);
      expect(find.text('53'), findsNothing);
      expect(find.text('38'), findsNothing);
    });
  });
}
