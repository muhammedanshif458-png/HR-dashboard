import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/attendance/attendance_view.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  // ─── 1. ApiService.getAttendancePage ───────────────────────────────────────
  group('ApiService.getAttendancePage', () {
    test('calls GET /api/hr/attendance with token, pagination, and filters',
        () async {
      String? authHeader;
      String? requestedPath;
      Map<String, String>? queryParams;

      ApiService.setToken('test_jwt_attendance_token');
      ApiService.client = MockClient((request) async {
        authHeader = request.headers['Authorization'];
        requestedPath = request.url.path;
        queryParams = request.url.queryParameters;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Attendance records fetched successfully',
            'data': [
              {
                '_id': 'att_001',
                'employee': {
                  '_id': 'emp_001',
                  'employeeId': 'EMP1001',
                  'firstName': 'Anita',
                  'lastName': 'Rao',
                  'department': 'Tech',
                  'designation': 'Lead HR Manager'
                },
                'date': '2026-10-15T00:00:00.000Z',
                'checkIn': '2026-10-15T09:00:00.000Z',
                'checkOut': '2026-10-15T17:30:00.000Z',
                'status': 'PRESENT',
                'workingHours': 8.5,
                'remarks': 'On-time punch',
                'late': false,
              },
              {
                '_id': 'att_002',
                'employee': {
                  '_id': 'emp_002',
                  'employeeId': 'EMP1002',
                  'firstName': 'Arjun',
                  'lastName': 'Desai',
                  'department': 'Tech',
                  'designation': 'Senior Frontend Engineer'
                },
                'date': '2026-10-15T00:00:00.000Z',
                'checkIn': '2026-10-15T10:15:00.000Z',
                'checkOut': null,
                'status': 'HALF_DAY',
                'workingHours': 3.5,
                'remarks': 'Morning transit delay',
                'late': true,
                'scheduledCheckIn': '09:00',
                'scheduleTimeZone': 'Asia/Kolkata',
              }
            ],
            'pagination': {
              'page': 2,
              'limit': 10,
              'total': 45,
              'totalPages': 5,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final page = await ApiService.getAttendancePage(
        page: 2,
        limit: 10,
        employeeId: 'EMP1001',
        startDate: '2026-10-01',
        endDate: '2026-10-15',
        status: 'PRESENT',
        department: 'Tech',
        search: 'Anita Rao',
        workMode: 'WFH',
      );

      expect(authHeader, 'Bearer test_jwt_attendance_token');
      expect(requestedPath, '/api/hr/attendance');
      expect(queryParams?['page'], '2');
      expect(queryParams?['limit'], '10');
      expect(queryParams?['employeeId'], 'EMP1001');
      expect(queryParams?['startDate'], '2026-10-01');
      expect(queryParams?['endDate'], '2026-10-15');
      expect(queryParams?['status'], 'PRESENT');
      expect(queryParams?['department'], 'Tech');
      expect(queryParams?['search'], 'Anita Rao');
      expect(queryParams?['workMode'], 'WFH');

      expect(page.page, 2);
      expect(page.limit, 10);
      expect(page.total, 45);
      expect(page.totalPages, 5);
      expect(page.records.length, 2);

      final first = page.records.first;
      expect(first.id, 'att_001');
      expect(first.employeeName, 'Anita Rao');
      expect(first.staffId, 'EMP1001');
      expect(first.department, 'Tech');
      expect(first.date, '2026-10-15');
      expect(first.workingHours, 8.5);
      expect(first.workedDuration, '8h 30m');
      expect(first.status, 'Checked Out'); // Present with checkOut populated
      expect(first.remarks, 'On-time punch');

      final second = page.records[1];
      expect(second.id, 'att_002');
      expect(second.employeeName, 'Arjun Desai');
      expect(second.status, 'Late'); // backend late=true, independent of status
      expect(second.isLate, true);
      expect(second.scheduledCheckIn, '09:00');
      expect(second.scheduleTimeZone, 'Asia/Kolkata');
    });

    test('throws Exception on HTTP 401 Unauthorized', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Authentication token is expired or invalid',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.getAttendancePage(),
        throwsA(predicate(
            (e) => e.toString().contains('Authentication token is expired'))),
      );
    });

    test('throws Exception on HTTP 403 Forbidden', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Access restricted to HR role',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.getAttendancePage(),
        throwsA(
            predicate((e) => e.toString().contains('Access restricted to HR'))),
      );
    });

    test('throws FormatException on malformed server response envelope',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
            '<!DOCTYPE html><html>502 Bad Gateway</html>', 502);
      });

      expect(
        () => ApiService.getAttendancePage(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── 2. ApiService.getAttendanceByEmployee ─────────────────────────────────
  group('ApiService.getAttendanceByEmployee', () {
    test('calls GET /api/hr/attendance/:employeeId with encoded id and query',
        () async {
      String? requestedPath;
      Map<String, String>? queryParams;

      ApiService.setToken('test_jwt_attendance_token');
      ApiService.client = MockClient((request) async {
        requestedPath = request.url.path;
        queryParams = request.url.queryParameters;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Employee attendance records fetched successfully',
            'data': [
              {
                '_id': 'att_emp_01',
                'employee': {
                  '_id': 'emp_999',
                  'employeeId': 'EMP999',
                  'firstName': 'Pooja',
                  'lastName': 'Verma',
                  'department': 'Telecalling'
                },
                'date': '2026-10-14T00:00:00.000Z',
                'status': 'ABSENT',
                'remarks': 'Sick leave'
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 1,
              'totalPages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.getAttendanceByEmployee(
        employeeId: 'emp/999 space',
        page: 1,
        limit: 20,
        startDate: '2026-10-01',
        endDate: '2026-10-14',
      );

      expect(requestedPath, '/api/hr/attendance/emp%2F999%20space');
      expect(queryParams?['startDate'], '2026-10-01');
      expect(queryParams?['endDate'], '2026-10-14');
      expect(result.records.length, 1);
      expect(result.records.first.status, 'Absent');
      expect(result.records.first.employeeName, 'Pooja Verma');
    });

    test('throws Exception on 404 Employee Not Found', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Employee not found',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.getAttendanceByEmployee(employeeId: 'NON_EXISTENT'),
        throwsA(predicate((e) => e.toString().contains('Employee not found'))),
      );
    });
  });

  // ─── 3. Model Parsing & Status Normalization ────────────────────────────────
  group('Attendance.fromJson Robust Parsing', () {
    test('parses reported late fields and nullable schedule snapshot', () {
      final attendance = Attendance.fromJson({
        '_id': 'late-contract',
        'isLate': true,
        'minutesLate': 105,
        'gracePeriodMinutes': 5,
        'scheduleSnapshot': {
          'scheduledCheckIn': '09:00',
          'timeZone': 'Asia/Kolkata',
        },
        'checkIn': '2026-10-23T05:45:00.000Z',
        'date': '2026-10-23T00:00:00.000Z',
        'employee': {
          'firstName': 'Anita',
          'lastName': 'Rao',
          'department': 'Tech',
        },
      });
      expect(attendance.isLate, isTrue);
      expect(attendance.minutesLate, 105);
      expect(attendance.gracePeriodMinutes, 5);
      expect(attendance.scheduledCheckIn, '09:00');
      expect(attendance.scheduleTimeZone, 'Asia/Kolkata');

      final absentOptionalFields = Attendance.fromJson({});
      expect(absentOptionalFields.isLate, isFalse);
      expect(absentOptionalFields.minutesLate, isNull);
      expect(absentOptionalFields.gracePeriodMinutes, isNull);
      expect(absentOptionalFields.scheduleSnapshot, isNull);
      expect(absentOptionalFields.scheduledCheckIn, isNull);
    });

    test(
        'reads actual work mode and shows unavailable fields without invention',
        () {
      final attendance = Attendance.fromJson({
        '_id': 'wfh-live',
        'date': '2026-10-26T00:00:00.000Z',
        'status': 'PRESENT',
        'employee': {
          'employeeId': 'EMP1001',
          'firstName': 'Anita',
          'lastName': 'Rao',
          'department': 'Tech',
          'workMode': 'WFH',
        },
      });
      expect(attendance.staffId, 'EMP1001');
      expect(attendance.workMode, 'WFH');
      expect(attendance.location, '—');
      expect(attendance.breakDuration, '—');
      expect(attendance.scheduledCheckIn, isNull);
    });

    test('normalizes attendance enums without treating HALF_DAY as Late', () {
      final leaveAtt = Attendance.fromJson({
        '_id': 'a1',
        'status': 'LEAVE',
        'employeeName': 'Sam',
      });
      expect(leaveAtt.status, 'On Leave');

      final absentAtt = Attendance.fromJson({
        '_id': 'a2',
        'status': 'ABSENT',
        'employeeName': 'Alex',
      });
      expect(absentAtt.status, 'Absent');

      final lateAtt = Attendance.fromJson({
        '_id': 'a3',
        'status': 'HALF_DAY',
        'late': false,
        'employeeName': 'Dave',
      });
      expect(lateAtt.status, 'Half Day');
      expect(lateAtt.isLate, false);

      final checkedOutAtt = Attendance.fromJson({
        '_id': 'a4',
        'status': 'PRESENT',
        'checkOut': '2026-10-15T18:00:00.000Z',
        'employeeName': 'Sara',
      });
      expect(checkedOutAtt.status, 'Checked Out');

      final presentActiveAtt = Attendance.fromJson({
        '_id': 'a5',
        'status': 'PRESENT',
        'checkOut': null,
        'employeeName': 'Kiran',
      });
      expect(presentActiveAtt.status, 'Present');
    });

    test('preserves backend late flag independently of attendance status', () {
      final latePresent = Attendance.fromJson({
        '_id': 'a6',
        'status': 'PRESENT',
        'late': true,
        'employee': {
          'firstName': 'Anita',
          'lastName': 'Rao',
          'department': 'Department A',
        },
      });
      final onTimePresent = Attendance.fromJson({
        '_id': 'a7',
        'status': 'PRESENT',
        'late': false,
        'employee': {
          'firstName': 'Dev',
          'lastName': 'Patel',
          'department': 'Department B',
        },
      });

      expect(latePresent.status, 'Late');
      expect(latePresent.isLate, isTrue);
      expect(onTimePresent.status, 'Present');
      expect(onTimePresent.isLate, isFalse);
    });

    test('extracts workingHours and formats workedDuration accurately', () {
      final att = Attendance.fromJson({
        '_id': 'a6',
        'workingHours': 7.75,
      });
      expect(att.workingHours, 7.75);
      expect(att.workedDuration, '7h 45m');
    });
  });

  // ─── 4. HRProvider Attendance State Management ──────────────────────────────
  group('HRProvider Attendance Integration', () {
    test('loads authoritative lateArrivals from dashboard summary', () async {
      String? authHeader;
      ApiService.setToken('summary-token');
      ApiService.client = MockClient((request) async {
        authHeader = request.headers['Authorization'];
        expect(request.url.path, '/api/hr/dashboard');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'totalEmployees': 12,
              'activeEmployees': 12,
              'todayPresent': 8,
              'lateArrivals': 3,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();
      await provider.loadLateArrivalsSummary();
      expect(authHeader, 'Bearer summary-token');
      expect(provider.lateArrivalsSummaryCount, 3);
      expect(provider.lateArrivalsDisplayValue, '3');
      expect(provider.dashboardMetrics.lateCheckIns, 3);
      expect(provider.presentTodayCount, 8);
      expect(provider.presentTodayDisplayValue, '8');
      expect(provider.lateArrivalsError, isNull);
    });

    test('summary API errors remain visible instead of becoming zero',
        () async {
      ApiService.client = MockClient((request) async => http.Response(
            jsonEncode({'success': false, 'message': 'Token expired'}),
            401,
            headers: {'content-type': 'application/json'},
          ));
      final provider = HRProvider();
      await provider.loadLateArrivalsSummary();
      expect(provider.lateArrivalsSummaryCount, isNull);
      expect(provider.lateArrivalsDisplayValue, '—');
      expect(provider.lateArrivalsError, 'Token expired');
    });

    test('summary errors preserve previously loaded summary metrics', () async {
      var fail = false;
      ApiService.client = MockClient((request) async => http.Response(
            jsonEncode(fail
                ? {'success': false, 'message': 'Temporary failure'}
                : {
                    'success': true,
                    'data': {'todayPresent': 9, 'lateArrivals': 2},
                  }),
            fail ? 503 : 200,
            headers: {'content-type': 'application/json'},
          ));
      final provider = HRProvider();
      await provider.loadLateArrivalsSummary();
      fail = true;
      await provider.loadLateArrivalsSummary();
      expect(provider.presentTodayCount, 9);
      expect(provider.presentTodayDisplayValue, '9');
      expect(provider.lateTodayCount, 2);
      expect(provider.lateArrivalsDisplayValue, '2');
      expect(provider.lateArrivalsError, 'Temporary failure');
    });

    test('refresh replaces the dashboard lateArrivals count', () async {
      var count = 2;
      ApiService.client = MockClient((request) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {'todayPresent': 8, 'lateArrivals': count},
            }),
            200,
            headers: {'content-type': 'application/json'},
          ));
      final provider = HRProvider();
      await provider.loadLateArrivalsSummary();
      expect(provider.lateArrivalsSummaryCount, 2);
      count = 4;
      await provider.loadLateArrivalsSummary();
      expect(provider.lateArrivalsSummaryCount, 4);
    });

    test('Late status and department are both sent to attendance API',
        () async {
      Map<String, String>? query;
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/dashboard') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'todayPresent': 7,
                'lateArrivals': 2,
                'todayAbsent': 1,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        query = request.url.queryParameters;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'late-a',
                'status': 'PRESENT',
                'late': true,
                'employee': {
                  'firstName': 'Sam',
                  'lastName': 'Lee',
                  'employeeId': 'EMP7',
                  'department': 'Department A',
                },
              }
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final provider = HRProvider();
      await provider.loadLateArrivalsSummary();
      await provider.loadAttendance();
      expect(provider.presentTodayCount, 7);
      expect(provider.lateTodayCount, 2);
      provider.setAttendanceDeptFilter('Department A');
      provider.setAttendanceStatusFilter('Late');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(query?['status'], 'LATE');
      expect(query?['department'], 'Department A');
      expect(provider.filteredAttendanceList.single.isLate, isTrue);
      expect(provider.attendanceTotal, 1);
      expect(provider.presentTodayCount, 7);
      expect(provider.presentTodayDisplayValue, '7');
      expect(provider.lateTodayCount, 2);
      expect(provider.lateArrivalsDisplayValue, '2');
    });

    test('historical date and pagination are sent to attendance API', () async {
      Map<String, String>? query;
      ApiService.client = MockClient((request) async {
        query = request.url.queryParameters;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [],
            'pagination': {
              'page': 2,
              'limit': 20,
              'total': 25,
              'totalPages': 2
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final provider = HRProvider()
        ..attendanceTab = 'history'
        ..attendanceSelectedDate = DateTime(2026, 10, 15);

      await provider.loadAttendance(page: 2);
      expect(query?['startDate'], '2026-10-15');
      expect(query?['endDate'], '2026-10-15');
      expect(query?['page'], '2');
      expect(provider.attendancePage, 2);
      expect(provider.attendanceTotal, 25);
    });

    test('loadAttendance updates api records, pagination, and live status',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Attendance loaded',
            'data': [
              {
                '_id': 'att_live_1',
                'employee': {
                  '_id': 'emp_live_1',
                  'employeeId': 'EMP501',
                  'firstName': 'Dev',
                  'lastName': 'Patel',
                  'department': 'Tech'
                },
                'date': '2026-10-15T00:00:00.000Z',
                'status': 'PRESENT',
                'workingHours': 8.0,
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 1,
              'totalPages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();
      expect(provider.hasLoadedApiAttendance, false);

      await provider.loadAttendance();

      expect(provider.hasLoadedApiAttendance, true);
      expect(provider.isAttendanceLoading, false);
      expect(provider.attendanceError, isNull);
      expect(provider.apiAttendanceRecords.length, 1);
      expect(provider.attendanceTotal, 1);
      // Present Today is an independent summary value, not this page's row count.
      expect(provider.presentTodayDisplayValue, '—');
      expect(provider.filteredAttendanceList.first.employeeName, 'Dev Patel');
    });

    test('loadAttendance captures errors without breaking provider', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Database connection timed out',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();
      await provider.loadAttendance();

      expect(provider.isAttendanceLoading, false);
      expect(provider.attendanceError, 'Database connection timed out');
      expect(provider.hasLoadedApiAttendance, false);
    });

    test('filter setters map UI status to backend query parameters', () async {
      String? sentStatus;
      ApiService.client = MockClient((request) async {
        sentStatus = request.url.queryParameters['status'];
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [],
            'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 1}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();
      await provider.loadAttendance(); // Mark as live

      provider.setAttendanceStatusFilter('Late');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(sentStatus, 'LATE');

      provider.setAttendanceStatusFilter('On Leave');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(sentStatus, 'LEAVE');

      provider.setAttendanceStatusFilter('Absent');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(sentStatus, 'ABSENT');

      provider.setAttendanceStatusFilter('Present');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(sentStatus, 'PRESENT');
    });
  });

  // ─── 5. AttendanceView UI Rendering & Interaction ───────────────────────────
  group('AttendanceView UI States', () {
    testWidgets('renders authoritative 105, 178, and 255 minute durations',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      ApiService.client = MockClient((request) async => http.Response(
            jsonEncode({
              'success': true,
              'data': [
                for (final minutes in [105, 178, 255])
                  {
                    '_id': 'late-$minutes',
                    'isLate': true,
                    'minutesLate': minutes,
                    'scheduleSnapshot': {'scheduledCheckIn': '09:00'},
                    'date': '2026-10-23T00:00:00Z',
                    'checkIn': '2026-10-23T05:45:00Z',
                    'employee': {
                      'firstName': 'Late',
                      'lastName': '$minutes',
                      'department': 'Tech',
                    },
                  },
              ],
              'pagination': {
                'page': 1,
                'limit': 20,
                'total': 3,
                'totalPages': 1
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          ));
      final provider = HRProvider();
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const AttendanceView(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Late Arrivals'));
      await tester.pumpAndSettle();
      expect(find.text('1 hr 45 min late'), findsOneWidget);
      expect(find.text('2 hr 58 min late'), findsOneWidget);
      expect(find.text('4 hr 15 min late'), findsOneWidget);
      expect(find.text('09:00 AM'), findsNWidgets(3));
    });

    testWidgets('summary card taps change filters without changing metrics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      var summaryRequests = 0;
      var presentSummary = 11;
      var lateSummary = 3;
      final attendanceStatuses = <String?>[];
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/dashboard') {
          summaryRequests++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'todayPresent': presentSummary,
                'lateArrivals': lateSummary,
                'todayAbsent': 2,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        attendanceStatuses.add(request.url.queryParameters['status']);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [],
            'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final provider = HRProvider();

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const AttendanceView(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('11'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Late Arrivals'));
      await tester.pumpAndSettle();
      expect(provider.attendanceStatusFilter, 'Late');
      expect(attendanceStatuses.last, 'LATE');
      expect(provider.presentTodayCount, 11);
      expect(provider.lateTodayCount, 3);

      await tester.tap(find.text('Present Today'));
      await tester.pumpAndSettle();
      expect(provider.attendanceStatusFilter, 'Present');
      expect(provider.presentTodayCount, 11);
      expect(provider.lateTodayCount, 3);

      await tester.tap(find.text('On Leave Today'));
      await tester.pumpAndSettle();
      expect(provider.attendanceStatusFilter, 'On Leave');
      expect(provider.presentTodayCount, 11);
      expect(provider.lateTodayCount, 3);

      await tester.tap(find.text('Work From Home (WFH)'));
      await tester.pumpAndSettle();
      expect(provider.attendanceWorkModeFilter, 'WFH');
      expect(provider.presentTodayCount, 11);
      expect(provider.lateTodayCount, 3);
      expect(summaryRequests, 1);

      await tester.tap(find.text('Late Arrivals'));
      await tester.pumpAndSettle();
      expect(attendanceStatuses.last, 'LATE');
      presentSummary = 12;
      lateSummary = 4;
      await tester.tap(find.text('Sync Attendance'));
      await tester.pumpAndSettle();
      expect(summaryRequests, 2);
      expect(attendanceStatuses.last, 'LATE');
      expect(provider.presentTodayCount, 12);
      expect(provider.lateTodayCount, 4);
    });

    testWidgets('renders loading state when fetching attendance records',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.isAttendanceLoading = true;
      provider.apiAttendanceRecords = [];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(
        find.text('Fetching attendance records from server...'),
        findsOneWidget,
      );
    });

    testWidgets('renders error state with Retry button on API failure',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.attendanceError = 'Network connection failed. HTTP 503.';
      provider.apiAttendanceRecords = [];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );

      expect(find.text('Failed to load attendance records'), findsOneWidget);
      expect(find.text('Network connection failed. HTTP 503.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('renders empty state when no records found',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiAttendance = true;
      provider.apiAttendanceRecords = [];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );

      expect(find.text('No attendance records found'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Refresh'), findsOneWidget);
    });

    testWidgets('renders table and pagination when live records exist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiAttendance = true;
      provider.attendancePage = 1;
      provider.attendanceLimit = 20;
      provider.attendanceTotal = 25;
      provider.attendanceTotalPages = 2;
      provider.apiAttendanceRecords = [
        Attendance(
          id: 'live_att_1',
          staffId: 'EMP777',
          date: '2026-10-15',
          checkInTime: '09:10 AM',
          checkOutTime: '06:00 PM',
          workedDuration: '8h 50m',
          breakDuration: '30m',
          isLate: false,
          employeeName: 'Rohan Gupta',
          department: 'Tech',
          status: 'Checked Out',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );

      expect(find.text('Rohan Gupta'), findsOneWidget);
      expect(find.text('09:10 AM'), findsOneWidget);
      expect(find.text('06:00 PM'), findsOneWidget);
      expect(find.text('8h 50m'), findsOneWidget);
      expect(find.text('Checked Out'), findsWidgets);
      expect(find.text('Live Server Attendance Active'), findsOneWidget);
      expect(find.text('Showing 1 to 1 of 25 records'), findsOneWidget);
      expect(find.text('Page 1 of 2'), findsOneWidget);
    });

    testWidgets('renders active break status and late arrival after checkout',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiAttendance = true;
      provider.attendancePage = 1;
      provider.attendanceLimit = 20;
      provider.attendanceTotal = 2;
      provider.attendanceTotalPages = 1;
      provider.apiAttendanceRecords = [
        Attendance(
          id: 'live_att_break',
          staffId: 'EMP888',
          date: '2026-10-26',
          checkInTime: '09:00 AM',
          checkOutTime: null,
          workedDuration: '4h 00m',
          breakDuration: '25m',
          breakStartedAt: '2026-10-26T07:30:00.000Z',
          isLate: false,
          employeeName: 'Kavita Sen',
          department: 'Tech',
          status: 'Present',
        ),
        Attendance(
          id: 'live_att_late_checkout',
          staffId: 'EMP999',
          date: '2026-10-26',
          checkInTime: '10:15 AM',
          checkOutTime: '06:45 PM',
          workedDuration: '8h 30m',
          breakDuration: '45m',
          isLate: true,
          minutesLate: 45,
          employeeName: 'Vikram Seth',
          department: 'Telecalling',
          status: 'Checked Out',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );

      // Verify active break indicator in break duration column
      expect(find.text('On Break'), findsOneWidget);
      expect(find.text('(25m)'), findsOneWidget);

      // Verify late arrival badge persists after checkout
      expect(find.text('Vikram Seth'), findsOneWidget);
      expect(find.text('45 min late'), findsOneWidget);
      expect(find.text('LATE'), findsWidgets);
      expect(find.text('06:45 PM'), findsOneWidget);

      // Verify Late status filtering includes late checkout record
      provider.setAttendanceStatusFilter('Late');
      expect(provider.filteredAttendanceList.length, 1);
      expect(provider.filteredAttendanceList.first.employeeName, 'Vikram Seth');
      expect(provider.filteredAttendanceList.first.isLate, isTrue);
    });
  });
}
