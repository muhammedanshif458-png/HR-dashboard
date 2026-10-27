import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/core/config.dart';
import 'package:ly_hr_dashboard_flutter/features/attendance/attendance_view.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:provider/provider.dart';

class RealHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = RealHttpOverrides();
  });

  setUp(() {
    AppConfig.setApiBaseUrl('http://localhost:5000');
  });

  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
    AppConfig.resetApiBaseUrl();
  });

  group('Live Backend End-to-End Verification (Step 5)', () {
    test('1. Authenticate with live backend, load live attendance and metrics', () async {
      // Authenticate directly against live backend port 5000
      final authResult = await ApiService.login('lysoftware@gmail.com', 'hrAdmin');
      expect(authResult['success'], isTrue);
      expect(authResult['token'], isNotNull);
      final token = authResult['token'] as String;
      expect(token.isNotEmpty, isTrue);

      ApiService.setToken(token);
      final provider = HRProvider();

      // Load live dashboard summary metrics
      await provider.loadLateArrivalsSummary();
      expect(provider.lateArrivalsDisplayValue, '3', reason: 'Dashboard late arrivals metric must be 3');

      final directResult = await ApiService.getAttendancePage(
        date: '2026-10-27',
        department: 'Tech',
      );
      print('DEBUG: Direct ApiService.getAttendancePage records: ${directResult.records.length}');
      for (final r in directResult.records) {
        print('DEBUG:   - ${r.employeeName} (${r.staffId}): isLate=${r.isLate}, minutesLate=${r.minutesLate}, dept=${r.department}');
      }

      // Load live attendance for testDate=2026-10-27 and department=Tech
      provider.attendanceDeptFilter = 'Tech';
      provider.attendanceStatusFilter = 'all';
      provider.attendanceSelectedDate = DateTime(2026, 10, 27);
      await provider.loadAttendance(page: 1);

      print('DEBUG: provider.apiAttendanceRecords: ${provider.apiAttendanceRecords.length}');
      print('DEBUG: provider.filteredAttendanceList: ${provider.filteredAttendanceList.length}');
      print('DEBUG: provider.attendanceError: ${provider.attendanceError}');

      expect(provider.attendanceError, isNull);
      expect(provider.filteredAttendanceList.isNotEmpty, isTrue);
      expect(provider.filteredAttendanceList.length, greaterThanOrEqualTo(3));

      // Find E2E_LATE
      final lateRecord = provider.filteredAttendanceList.firstWhere(
        (a) => a.staffId == 'E2E_LATE' || a.employeeName.contains('Karan'),
      );
      expect(lateRecord.isLate, isTrue);
      expect(lateRecord.minutesLate, 20);
      expect(lateRecord.scheduledCheckIn, '10:00');
      expect(lateRecord.scheduleConfigured, isTrue);

      // Find E2E_ONTIME
      final onTimeRecord = provider.filteredAttendanceList.firstWhere(
        (a) => a.staffId == 'E2E_ONTIME' || a.employeeName.contains('Aarav'),
      );
      expect(onTimeRecord.isLate, isFalse);
      expect(onTimeRecord.minutesLate ?? 0, 0);

      // Find E2E_GRACE
      final graceRecord = provider.filteredAttendanceList.firstWhere(
        (a) => a.staffId == 'E2E_GRACE' || a.employeeName.contains('Priya'),
      );
      expect(graceRecord.isLate, isFalse);
      expect(graceRecord.minutesLate ?? 0, 0);
    });

    testWidgets('2. Render AttendanceView with live-matched state and verify UI indicators', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.client = MockClient((request) async {
        if (request.url.path.contains('/api/hr/dashboard')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'todayPresent': 6, 'lateArrivals': 3, 'todayLate': 3}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/api/hr/attendance')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'pagination': {'total': 5, 'page': 1, 'limit': 20, 'pages': 1},
              'data': [
                {
                  '_id': 'att_e2e_01',
                  'employee': {
                    'employeeId': 'E2E_LATE',
                    'firstName': 'Karan',
                    'lastName': 'AfterGrace',
                    'department': 'Technology'
                  },
                  'date': '2026-10-27T00:00:00.000Z',
                  'checkIn': '2026-10-27T05:05:00.000Z',
                  'status': 'PRESENT',
                  'isLate': true,
                  'late': true,
                  'minutesLate': 20,
                  'scheduledCheckIn': '10:00',
                  'scheduleTimeZone': 'Asia/Kolkata',
                  'scheduleConfigured': true,
                  'workedDuration': '0h',
                  'breakDuration': '—'
                },
                {
                  '_id': 'att_e2e_02',
                  'employee': {
                    'employeeId': 'E2E_ONTIME',
                    'firstName': 'Aarav',
                    'lastName': 'OnTime',
                    'department': 'Tech'
                  },
                  'date': '2026-10-27T00:00:00.000Z',
                  'checkIn': '2026-10-27T04:20:00.000Z',
                  'status': 'PRESENT',
                  'isLate': false,
                  'late': false,
                  'minutesLate': 0,
                  'scheduledCheckIn': '10:00',
                  'scheduleTimeZone': 'Asia/Kolkata',
                  'scheduleConfigured': true,
                  'workedDuration': '0h',
                  'breakDuration': '—'
                },
                {
                  '_id': 'att_e2e_03',
                  'employee': {
                    'employeeId': 'E2E_GRACE',
                    'firstName': 'Priya',
                    'lastName': 'WithinGrace',
                    'department': 'Tech'
                  },
                  'date': '2026-10-27T00:00:00.000Z',
                  'checkIn': '2026-10-27T04:40:00.000Z',
                  'status': 'PRESENT',
                  'isLate': false,
                  'late': false,
                  'minutesLate': 0,
                  'scheduledCheckIn': '10:00',
                  'scheduleTimeZone': 'Asia/Kolkata',
                  'scheduleConfigured': true,
                  'workedDuration': '0h',
                  'breakDuration': '—'
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": true, "data": []}', 200, headers: {'content-type': 'application/json'});
      });

      final provider = HRProvider();
      await provider.loadLateArrivalsSummary();

      provider.attendanceDeptFilter = 'Tech';
      provider.attendanceStatusFilter = 'all';
      provider.attendanceSelectedDate = DateTime(2026, 10, 27);
      await provider.loadAttendance(page: 1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: provider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AttendanceView(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify employee names rendered in UI
      expect(find.text('Karan AfterGrace'), findsWidgets);
      expect(find.text('Aarav OnTime'), findsWidgets);
      expect(find.text('Priya WithinGrace'), findsWidgets);

      // Verify LATE badge rendered in table
      expect(find.text('LATE'), findsWidgets);

      // Verify Late By duration '20 min late' rendered in table
      expect(find.text('20 min late'), findsWidgets);

      // Verify Check-in time '10:35 AM' rendered
      expect(find.text('10:35 AM'), findsWidgets);

      // Verify Scheduled Check-in '10:00 AM (Asia/Kolkata)' rendered
      expect(find.text('10:00 AM (Asia/Kolkata)'), findsWidgets);

      // Verify summary card metric 3 for Late Arrivals
      expect(find.text('3'), findsWidgets);
    });
  });
}
