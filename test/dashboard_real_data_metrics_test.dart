import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/features/dashboard/hr_dashboard_view.dart';

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
      // 10. Work From Home (WFH)
      expect(metrics.todayWfh, 0);
      // 11. Inactive Staff
      expect(metrics.inactiveStaff, 1);
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
        'todayWfh': 1,
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
      expect(find.text('Work From Home (WFH)'), findsOneWidget);
      expect(find.text('Pending Leaves'), findsOneWidget);
      expect(find.text('Inactive Staff'), findsOneWidget);
      expect(find.text('Late Check-ins'), findsOneWidget);
      expect(find.text('Not Checked In'), findsOneWidget);
      expect(find.text('Open Tasks'), findsOneWidget);
      expect(find.text('Resigned (30d)'), findsOneWidget);
      expect(find.text('Checked Out'), findsOneWidget);

      // Verify actual counts displayed
      expect(find.text('8'), findsNWidgets(2)); // Total Staff (8) & Active Staff (8)
      expect(find.text('6'), findsOneWidget); // Present Today (6)
      expect(find.text('3'), findsOneWidget); // Late Check-ins (3)
      expect(find.text('2'), findsOneWidget); // Not Checked In (2)
      expect(find.text('1'), findsOneWidget); // Work From Home (WFH) (1)
      expect(find.text('0'), findsNWidgets(6)); // Pending Leaves, On Leave, Open Tasks, Resigned, Inactive Staff, Checked Out

      // Ensure no mock numbers 76, 53, 38 exist
      expect(find.text('76'), findsNothing);
      expect(find.text('53'), findsNothing);
      expect(find.text('38'), findsNothing);
    });

    testWidgets(
        'Work From Home (WFH) metric card navigates to Attendance screen with WFH filter',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiDashboard = true;
      provider.apiDashboardMetrics = {
        'totalEmployees': 12,
        'activeEmployees': 6,
        'todayPresent': 2,
        'todayWfh': 3,
        'pendingLeaves': 1,
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

      final wfhCardFinder = find.text('Work From Home (WFH)');
      expect(wfhCardFinder, findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.home_work_outlined), findsOneWidget);

      // Tap the WFH metric card
      await tester.tap(wfhCardFinder);
      await tester.pump();

      // Verify navigation to attendance screen with WFH workMode filter
      expect(provider.currentScreen, 'attendance');
      expect(provider.attendanceWorkModeFilter, 'WFH');
    });

    testWidgets(
        'Work From Home (WFH) count handles null and missing values safely without crashing',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiDashboard = true;
      provider.apiDashboardMetrics = {
        'totalEmployees': 10,
        'activeEmployees': 8,
        'todayPresent': 5,
        // todayWfh is missing
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

      expect(find.text('Work From Home (WFH)'), findsOneWidget);
      expect(provider.dashboardMetrics.todayWfh, 0);
    });

    testWidgets(
        'Work From Home (WFH) count matches Attendance page WFH count',
        (tester) async {
      final provider = HRProvider();
      provider.hasLoadedApiDashboard = true;
      provider.apiDashboardMetrics = {
        'totalEmployees': 12,
        'activeEmployees': 6,
        'todayPresent': 2,
        'todayWfh': 5,
      };

      expect(provider.dashboardMetrics.todayWfh, 5);
      expect(provider.attendanceWfhSummaryCount, 5);
      expect(provider.dashboardMetrics.todayWfh,
          provider.attendanceWfhSummaryCount);
    });

    testWidgets(
        'HRDashboardView responsive layout renders cleanly on tablet and desktop',
        (tester) async {
      final provider = HRProvider();
      provider.hasLoadedApiDashboard = true;
      provider.apiDashboardMetrics = {
        'totalEmployees': 10,
        'activeEmployees': 8,
        'todayPresent': 5,
        'todayWfh': 2,
      };

      // 1. Standard Desktop size (1280x800)
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HRDashboardView(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Verify WFH card renders on desktop
      expect(find.text('Work From Home (WFH)'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // 2. Large Desktop size (1600x900)
      tester.view.physicalSize = const Size(1600, 900);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Work From Home (WFH)'), findsOneWidget);
    });

    testWidgets(
        'Inactive Staff metric card navigates to Employees screen with inactive filter',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiDashboard = true;
      provider.apiDashboardMetrics = {
        'totalEmployees': 12,
        'activeEmployees': 8,
        'inactiveEmployees': 4,
        'resignedLast30Days': 1,
        'todayPresent': 5,
        'todayWfh': 2,
        'pendingLeaves': 1,
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

      final inactiveCardFinder = find.text('Inactive Staff');
      expect(inactiveCardFinder, findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(Icons.person_off_outlined), findsNWidgets(2)); // Inactive Staff & Resigned (30d)

      // Tap the Inactive Staff metric card
      await tester.tap(inactiveCardFinder);
      await tester.pump();

      // Verify navigation to employees screen with inactive statusFilter
      expect(provider.currentScreen, 'employees');
      expect(provider.employeeStatusFilter, 'inactive');
    });

    testWidgets(
        'Inactive Staff count handles null, missing, and alternative keys safely',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Missing keys defaults to 0
      final provider1 = HRProvider();
      provider1.hasLoadedApiDashboard = true;
      provider1.apiDashboardMetrics = {
        'totalEmployees': 10,
        'activeEmployees': 10,
      };

      expect(provider1.dashboardMetrics.inactiveStaff, 0);

      // 2. Reads inactiveStaff key
      final provider2 = HRProvider();
      provider2.hasLoadedApiDashboard = true;
      provider2.apiDashboardMetrics = {
        'totalEmployees': 10,
        'activeEmployees': 7,
        'inactiveStaff': 3,
      };

      expect(provider2.dashboardMetrics.inactiveStaff, 3);

      // 3. Reads inactiveEmployees key as fallback
      final provider3 = HRProvider();
      provider3.hasLoadedApiDashboard = true;
      provider3.apiDashboardMetrics = {
        'totalEmployees': 10,
        'activeEmployees': 5,
        'inactiveEmployees': 5,
      };

      expect(provider3.dashboardMetrics.inactiveStaff, 5);
    });

    test('ApiService.getCheckedOutCount fetches count or falls back to 0',
        () async {
      // Test successful response with data.count
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/attendance/checked-out') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'count': 7}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final count1 = await ApiService.getCheckedOutCount();
      expect(count1, 7);

      // Test fallback to 0 on 404/500/errors
      ApiService.client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final count2 = await ApiService.getCheckedOutCount();
      expect(count2, 0);
    });

    testWidgets(
        'Checked Out metric card renders next to Resigned (30d) and navigates to Attendance screen',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/attendance/checked-out') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'count': 9}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final provider = HRProvider();
      provider.hasLoadedApiDashboard = true;
      provider.apiDashboardMetrics = {
        'totalEmployees': 15,
        'activeEmployees': 12,
        'inactiveEmployees': 3,
        'resignedLast30Days': 2,
        'todayPresent': 8,
        'todayWfh': 2,
        'pendingLeaves': 1,
        'onLeaveToday': 2,
        'lateCheckIns': 1,
        'notCheckedIn': 2,
        'openTasks': 4,
      };

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: HRDashboardView(),
          ),
        ),
      );

      // Allow async _fetchCheckedOutCount to complete
      await tester.pumpAndSettle();

      final checkedOutFinder = find.text('Checked Out');
      expect(checkedOutFinder, findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

      // Ensure Resigned (30d) is also present alongside Checked Out
      expect(find.text('Resigned (30d)'), findsOneWidget);

      // Tap the Checked Out metric card
      await tester.tap(checkedOutFinder);
      await tester.pump();

      // Verify navigation to attendance screen with Checked Out statusFilter
      expect(provider.currentScreen, 'attendance');
      expect(provider.attendanceStatusFilter, 'Checked Out');
    });
  });
}
