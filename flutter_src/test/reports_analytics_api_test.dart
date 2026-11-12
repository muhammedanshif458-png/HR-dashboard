import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/reports/reports_view.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  // ─── 1. ApiService Reports Endpoints ─────────────────────────────────────
  group('ApiService Reports Endpoints', () {
    test('Total Present includes PRESENT and HALF_DAY summary statuses', () {
      final report = AttendanceReportData.fromJson({
        'statusSummary': [
          {'_id': 'PRESENT', 'count': 4},
          {'_id': 'HALF_DAY', 'count': 2},
          {'_id': 'LATE', 'count': 3},
        ],
      });

      expect(report.presentCount, 6);
    });

    test('getAttendanceReport parses response envelope and fields correctly',
        () async {
      ApiService.setToken('test_reports_token');
      ApiService.client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/hr/reports/attendance');
        expect(request.url.queryParameters['department'], 'Tech');
        expect(request.url.queryParameters['startDate'], '2026-10-01');
        expect(request.url.queryParameters['endDate'], '2026-10-31');
        expect(request.headers['Authorization'], 'Bearer test_reports_token');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Attendance report generated successfully',
            'data': {
              'statusSummary': [
                {
                  '_id': 'PRESENT',
                  'count': 18,
                  'avgWorkingHours': 8.2,
                },
                {
                  '_id': 'LATE',
                  'count': 3,
                  'avgWorkingHours': 7.1,
                },
                {
                  '_id': 'ABSENT',
                  'count': 1,
                  'avgWorkingHours': 0.0,
                },
              ],
              'departmentSummary': [
                {
                  'department': 'Tech',
                  'status': 'PRESENT',
                  'count': 18,
                  'totalHours': 147.6,
                },
              ],
              'lateArrivals': 3,
              'onTimeArrivals': 15,
              'totalAbsent': 1,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final report = await ApiService.getAttendanceReport(
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        department: 'Tech',
      );

      expect(report.statusSummary.length, 3);
      expect(report.totalPunches, 22);
      expect(report.presentCount, 18);
      expect(report.lateCount, 3);
      expect(report.onTimeCount, 15);
      expect(report.totalAbsent, 1);
      expect(report.overallAvgWorkingHours, closeTo(8.04, 0.05));
      expect(report.departmentSummary.length, 1);
      expect(report.departmentSummary.first.department, 'Tech');
      expect(report.departmentSummary.first.totalHours, 147.6);
    });

    test('getAttendanceReport throws descriptive exception on HTTP error',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid report parameters',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.getAttendanceReport(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Invalid report parameters'))),
      );
    });

    test('getLeavesReport parses statusSummary and typeSummary correctly',
        () async {
      ApiService.setToken('test_reports_token');
      ApiService.client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/hr/reports/leaves');
        expect(request.url.queryParameters['startDate'], '2026-10-01');
        expect(request.url.queryParameters['department'], 'Tech');
        expect(request.url.queryParameters['status'], 'APPROVED');
        expect(request.url.queryParameters['leaveType'], 'CASUAL');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Leave report generated successfully',
            'data': {
              'statusSummary': [
                {'_id': 'APPROVED', 'count': 8},
                {'_id': 'PENDING', 'count': 4},
                {'_id': 'REJECTED', 'count': 2},
              ],
              'typeSummary': [
                {'_id': 'SICK', 'count': 5},
                {'_id': 'CASUAL', 'count': 6},
                {'_id': 'ANNUAL', 'count': 3},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final report = await ApiService.getLeavesReport(
        startDate: '2026-10-01', department: 'Tech', status: 'APPROVED', leaveType: 'CASUAL');

      expect(report.totalApplications, 14);
      expect(report.approvedCount, 8);
      expect(report.pendingCount, 4);
      expect(report.rejectedCount, 2);
      expect(report.medicalCount, 5);
      expect(report.casualCount, 6);
      expect(report.earnedCount, 3);
    });

    test('getLeavesReport throws descriptive exception on 500 error', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Database aggregation timeout',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.getLeavesReport(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Database aggregation timeout'))),
      );
    });
  });

  group('Reports drill-down filter contracts', () {
    test('attendance detail sends status, dates, department and pagination', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/attendance');
        expect(request.url.queryParameters, containsPair('status', 'ON_TIME'));
        expect(request.url.queryParameters, containsPair('department', 'Tech'));
        expect(request.url.queryParameters, containsPair('startDate', '2026-10-01'));
        expect(request.url.queryParameters, containsPair('endDate', '2026-10-31'));
        expect(request.url.queryParameters, containsPair('page', '2'));
        expect(request.url.queryParameters, containsPair('limit', '25'));
        return http.Response(jsonEncode({'success': true, 'data': [], 'pagination': {'page': 2, 'limit': 25, 'total': 27, 'totalPages': 2}}), 200);
      });
      final result = await ApiService.getAttendancePage(page: 2, limit: 25, status: 'ON_TIME', department: 'Tech', startDate: '2026-10-01', endDate: '2026-10-31');
      expect(result.total, 27);
      expect(result.totalPages, 2);
    });

    test('leave report and detail both accept department, status and leave type', () async {
      var calls = 0;
      ApiService.client = MockClient((request) async {
        expect(request.url.queryParameters['department'], 'Tech');
        expect(request.url.queryParameters['status'], 'APPROVED');
        expect(request.url.queryParameters['leaveType'], 'CASUAL');
        if (request.url.path.endsWith('/reports/leaves')) {
          calls++;
          return http.Response(jsonEncode({'success': true, 'data': {'statusSummary': [{'_id': 'APPROVED', 'count': 1}], 'typeSummary': [{'_id': 'CASUAL', 'count': 1}]}}), 200);
        }
        expect(request.url.path, '/api/hr/leaves');
        expect(request.url.queryParameters['page'], '1');
        return http.Response(jsonEncode({'success': true, 'data': [], 'pagination': {'page': 1, 'limit': 25, 'total': 1, 'totalPages': 1}}), 200);
      });
      final summary = await ApiService.getLeavesReport(department: 'Tech', status: 'APPROVED', leaveType: 'CASUAL');
      final detail = await ApiService.getLeavesPage(department: 'Tech', status: 'APPROVED', leaveType: 'CASUAL', limit: 25);
      expect(calls, 1);
      expect(summary.approvedCount, detail.total);
      expect(detail.totalPages, 1);
    });
  });

  // ─── 2. HRProvider Reports State & Calculations ──────────────────────────
  group('HRProvider Reports State & Loaders', () {
    test(
        'loadReports populates attendance and leave reports and flags hasLoadedApiReports',
        () async {
      final provider = HRProvider();
      expect(provider.hasLoadedApiReports, false);

      ApiService.client = MockClient((request) async {
        if (request.url.path.contains('/reports/attendance')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'statusSummary': [
                  {'_id': 'PRESENT', 'count': 20, 'avgWorkingHours': 8.0},
                  {'_id': 'LATE', 'count': 2, 'avgWorkingHours': 7.5},
                ],
                'departmentSummary': [
                  {
                    'department': 'Tech',
                    'status': 'PRESENT',
                    'count': 12,
                    'totalHours': 96.0
                  },
                  {
                    'department': 'Telecalling',
                    'status': 'PRESENT',
                    'count': 8,
                    'totalHours': 64.0
                  },
                ],
                'lateArrivals': 2,
                'onTimeArrivals': 18,
                'totalAbsent': 0,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.contains('/reports/leaves')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'statusSummary': [
                  {'_id': 'APPROVED', 'count': 6},
                  {'_id': 'PENDING', 'count': 3},
                ],
                'typeSummary': [
                  {'_id': 'SICK', 'count': 4},
                  {'_id': 'CASUAL', 'count': 5},
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      await provider.loadReports();

      expect(provider.hasLoadedApiReports, true);
      expect(provider.isReportsLoading, false);
      expect(provider.reportsError, isNull);

      final att = provider.effectiveAttendanceReport;
      expect(att.totalPunches, 22);
      expect(att.presentCount, 20);
      expect(att.lateCount, 2);
      expect(att.onTimeCount, 18);
      expect(att.departmentSummary.length, 2);

      final lvs = provider.effectiveLeaveReport;
      expect(lvs.totalApplications, 9);
      expect(lvs.approvedCount, 6);
      expect(lvs.pendingCount, 3);
      expect(lvs.medicalCount, 4);
      expect(lvs.casualCount, 5);
    });

    test(
        'loadReports failure sets reportsError and isolates from presenting mock data as live',
        () async {
      final provider = HRProvider();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Failed to aggregate report data',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.loadReports();

      expect(provider.hasLoadedApiReports, false);
      expect(provider.isReportsLoading, false);
      expect(provider.reportsError, 'Failed to aggregate report data');

      // Stale mock data must NOT be shown when live API failed
      expect(provider.effectiveAttendanceReport.totalPunches, 0);
      expect(provider.effectiveLeaveReport.totalApplications, 0);
    });

    test(
        'setReportsDepartmentFilter and setReportsDateRange trigger load when live',
        () async {
      final provider = HRProvider();
      provider.hasLoadedApiReports = true;

      int callCount = 0;
      ApiService.client = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'statusSummary': [], 'departmentSummary': []},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      provider.setReportsDepartmentFilter('Tech');
      await pumpEventQueue();
      expect(provider.reportsDepartmentFilter, 'Tech');
      expect(callCount, 2); // 1 attendance + 1 leaves

      provider.setReportsDateRange(
          DateTime(2026, 10, 1), DateTime(2026, 10, 15));
      await pumpEventQueue();
      expect(callCount, 4);
    });
  });

  // ─── 3. ReportsView Widget Tests ─────────────────────────────────────────
  group('ReportsView Widget Tests', () {
    testWidgets('renders live metric drill-down overview and export action',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      String? exportedCsv;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            exportedCsv = (call.arguments as Map)['text']?.toString();
          }
          return null;
        },
      );

      ApiService.client = MockClient((request) async {
        if (request.url.path.contains('/reports/attendance')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'statusSummary': [
                  {'_id': 'PRESENT', 'count': 16, 'avgWorkingHours': 8.0},
                  {'_id': 'LATE', 'count': 2, 'avgWorkingHours': 7.0},
                ],
                'departmentSummary': [
                  {
                    'department': 'Tech',
                    'status': 'PRESENT',
                    'count': 10,
                    'totalHours': 80.0
                  },
                ],
                'lateArrivals': 2,
                'onTimeArrivals': 14,
                'totalAbsent': 0,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.contains('/reports/leaves')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'statusSummary': [
                  {'_id': 'APPROVED', 'count': 7},
                  {'_id': 'PENDING', 'count': 3},
                ],
                'typeSummary': [
                  {'_id': 'SICK', 'count': 4},
                  {'_id': 'CASUAL', 'count': 6},
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const Scaffold(
              body: ReportsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('HR Reports & Workforce Analytics'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Leave requests'), findsOneWidget);
      expect(find.textContaining('Total Present'), findsOneWidget);
      expect(find.textContaining('Total Leave Requests'), findsOneWidget);
      expect(find.textContaining('Late Arrivals'), findsOneWidget);
      expect(find.text('Export Report'), findsOneWidget);

      // Export writes actual report data as CSV to the clipboard.
      await tester.tap(find.text('Export Report'));
      await tester.pumpAndSettle();
      expect(exportedCsv, contains('Attendance status'));
      expect(exportedCsv, contains('PRESENT'));
    });

    testWidgets('Total Present drill-down combines PRESENT and HALF_DAY pages',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      final requestedStatuses = <String>{};
      String? exportedCsv;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            exportedCsv = (call.arguments as Map)['text']?.toString();
          }
          return null;
        },
      );
      ApiService.client = MockClient((request) async {
        if (request.url.path.endsWith('/reports/attendance')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'statusSummary': [
                  {'_id': 'PRESENT', 'count': 25},
                  {'_id': 'HALF_DAY', 'count': 1},
                ],
                'departmentSummary': [],
                'lateArrivals': 0,
                'onTimeArrivals': 1,
                'totalAbsent': 0,
              },
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/reports/leaves')) {
          return http.Response(
            jsonEncode({'success': true, 'data': {'statusSummary': [], 'typeSummary': []}}),
            200,
          );
        }
        expect(request.url.path, '/api/hr/attendance');
        final status = request.url.queryParameters['status']!;
        requestedStatuses.add(status);
        final rows = status == 'PRESENT'
            ? List.generate(
                25,
                (index) => [
                  'EMP${1001 + index}',
                  'Employee${index + 1}',
                  'Test',
                  'PRESENT',
                  DateTime.utc(2026, 10, 15, 9)
                      .subtract(Duration(days: index))
                      .toIso8601String(),
                ],
              )
            : [
                ['EMP1003', 'Maya', 'Rao', 'HALF_DAY', '2026-08-13T09:00:00Z'],
              ];
        return http.Response(
          jsonEncode({
            'success': true,
            'data': rows
                .map((row) => {
                      '_id': 'att_${row[0]}',
                      'employee': {
                        '_id': 'id_${row[0]}',
                        'employeeId': row[0],
                        'firstName': row[1],
                        'lastName': row[2],
                        'department': 'Tech',
                      },
                      'date': row[4],
                      'checkIn': row[4],
                      'status': row[3],
                      'workingHours': 4.0,
                    })
                .toList(),
            'pagination': {
              'page': 1,
              'limit': 100,
              'total': rows.length,
              'totalPages': 1,
            },
          }),
          200,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const ReportsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Total Present'));
      await tester.pumpAndSettle();

      expect(requestedStatuses, {'PRESENT', 'HALF_DAY'});
      expect(find.textContaining('26 records'), findsOneWidget);
      expect(find.text('Employee1 Test'), findsOneWidget);
      expect(find.text('Maya Rao'), findsNothing);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Maya Rao'), findsOneWidget);
      await tester.tap(find.text('Export Report'));
      await tester.pumpAndSettle();
      expect(exportedCsv, contains('HALF_DAY'));
      expect(exportedCsv, contains('Maya'));
    });

    testWidgets('renders error container and retry button on load failure',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Server reports service unavailable',
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const Scaffold(
              body: ReportsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Server reports service unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Verify Retry Connection button triggers reload
      bool retryAttempted = false;
      ApiService.client = MockClient((request) async {
        retryAttempted = true;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'statusSummary': [], 'departmentSummary': []},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryAttempted, true);
    });
  });
}
