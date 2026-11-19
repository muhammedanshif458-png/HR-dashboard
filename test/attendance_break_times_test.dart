import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/attendance/attendance_view.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  group('Attendance Break Times Model Parsing', () {
    test('Scenario 1: No breaks returns empty list and clean shift totals without fabrication', () {
      final json = {
        '_id': 'att_no_breaks',
        'employee': {
          '_id': 'emp_mongo_001',
          'employeeId': 'EMP1001',
          'firstName': 'Anita',
          'lastName': 'Rao',
          'department': 'Tech',
          'designation': 'Software Engineer'
        },
        'date': '2026-10-27T00:00:00.000Z',
        'checkIn': '2026-10-27T03:30:00.000Z',
        'checkOut': null,
        'status': 'PRESENT',
        'workingHours': 4.0,
        'workedDuration': '4h',
        'breakDuration': '0m',
        'totalBreakMinutes': 0,
        'breaks': [],
        'activeBreak': null,
      };

      final att = Attendance.fromJson(json);

      expect(att.id, 'att_no_breaks');
      expect(att.employeeName, 'Anita Rao');
      expect(att.employeeId, 'EMP1001');
      expect(att.staffId, 'EMP1001');
      expect(att.department, 'Tech');
      expect(att.breaks, isEmpty);
      expect(att.isOnBreak, isFalse);
      expect(att.totalBreakMinutes, 0);
      expect(att.breakDuration, '0m');
      expect(att.hasBreakDataContract, isTrue);
    });

    test('Scenario 2: One completed break formats Asia/Kolkata timestamps and duration correctly', () {
      final json = {
        '_id': 'att_one_break',
        'employee': {
          '_id': 'emp_mongo_002',
          'employeeId': 'EMP1002',
          'firstName': 'Priya',
          'lastName': 'Sharma',
          'department': 'Telecalling',
          'designation': 'Telecalling Executive'
        },
        'date': '2026-10-27T00:00:00.000Z',
        'checkIn': '2026-10-27T03:30:00.000Z',
        'status': 'PRESENT',
        'breakDuration': '15m',
        'totalBreakMinutes': 15,
        'breaks': [
          {
            '_id': 'brk_001',
            'breakType': 'Tea Break 1',
            'startTime': '2026-10-27T04:30:00.000Z', // 10:00 AM IST
            'endTime': '2026-10-27T04:45:00.000Z',   // 10:15 AM IST
            'durationMinutes': 15,
            'remarks': 'Morning tea'
          }
        ],
        'activeBreak': null,
      };

      final att = Attendance.fromJson(json);

      expect(att.breaks.length, 1);
      final brk = att.breaks.first;
      expect(brk.breakType, 'Tea Break 1');
      expect(brk.isActive, isFalse);
      expect(brk.durationMinutes, 15);
      expect(brk.durationDisplay, '15m');
      expect(brk.remarks, 'Morning tea');
      expect(att.isOnBreak, isFalse);
      expect(att.totalBreakMinutes, 15);
      expect(att.breakDuration, '15m');
    });

    test('Scenario 3: Multiple completed breaks (Tea Break 1, Lunch Break, Tea Break 2) preserves all break entries', () {
      final json = {
        '_id': 'att_multi_breaks',
        'employee': {
          '_id': 'emp_mongo_003',
          'employeeId': 'EMP1003',
          'firstName': 'Rahul',
          'lastName': 'Verma',
          'department': 'Tech',
          'designation': 'Backend Developer'
        },
        'date': '2026-10-27T00:00:00.000Z',
        'checkIn': '2026-10-27T03:30:00.000Z',
        'status': 'PRESENT',
        'breakDuration': '1h 15m',
        'totalBreakMinutes': 75,
        'breaks': [
          {
            '_id': 'brk_01',
            'breakType': 'Tea Break 1',
            'startTime': '2026-10-27T04:30:00.000Z', // 10:00 AM IST
            'endTime': '2026-10-27T04:45:00.000Z',   // 10:15 AM IST
            'durationMinutes': 15,
          },
          {
            '_id': 'brk_02',
            'breakType': 'Lunch Break',
            'startTime': '2026-10-27T07:30:00.000Z', // 01:00 PM IST
            'endTime': '2026-10-27T08:15:00.000Z',   // 01:45 PM IST
            'durationMinutes': 45,
          },
          {
            '_id': 'brk_03',
            'breakType': 'Tea Break 2',
            'startTime': '2026-10-27T10:30:00.000Z', // 04:00 PM IST
            'endTime': '2026-10-27T10:45:00.000Z',   // 04:15 PM IST
            'durationMinutes': 15,
          }
        ],
        'activeBreak': null,
      };

      final att = Attendance.fromJson(json);

      expect(att.breaks.length, 3);
      expect(att.breaks[0].breakType, 'Tea Break 1');
      expect(att.breaks[0].durationMinutes, 15);
      expect(att.breaks[1].breakType, 'Lunch Break');
      expect(att.breaks[1].durationMinutes, 45);
      expect(att.breaks[2].breakType, 'Tea Break 2');
      expect(att.breaks[2].durationMinutes, 15);
      expect(att.totalBreakMinutes, 75);
      expect(att.breakDuration, '1h 15m');
      expect(att.isOnBreak, isFalse);
    });

    test('Scenario 4: Active break correctly parsed with In Progress status', () {
      final json = {
        '_id': 'att_active_break',
        'employee': {
          '_id': 'emp_mongo_004',
          'employeeId': 'EMP1004',
          'firstName': 'Farhan',
          'lastName': 'Ali',
          'department': 'Telecalling',
          'designation': 'Telecalling Team Lead'
        },
        'date': '2026-10-27T00:00:00.000Z',
        'checkIn': '2026-10-27T03:30:00.000Z',
        'status': 'PRESENT',
        'breakDuration': '15m',
        'totalBreakMinutes': 15,
        'breaks': [
          {
            '_id': 'brk_past',
            'breakType': 'Tea Break 1',
            'startTime': '2026-10-27T04:30:00.000Z',
            'endTime': '2026-10-27T04:45:00.000Z',
            'durationMinutes': 15,
          },
          {
            '_id': 'brk_current',
            'breakType': 'Lunch Break',
            'startTime': '2026-10-27T07:30:00.000Z',
            'endTime': null,
            'durationMinutes': 0,
          }
        ],
        'activeBreak': {
          'breakType': 'Lunch Break',
          'startTime': '2026-10-27T07:30:00.000Z',
          'breakId': 'brk_current'
        },
        'breakStartedAt': '2026-10-27T07:30:00.000Z'
      };

      final att = Attendance.fromJson(json);

      expect(att.isOnBreak, isTrue);
      expect(att.breaks.length, 2);
      expect(att.breaks[1].isActive, isTrue);
      expect(att.breaks[1].durationDisplay, 'In Progress');
      expect(att.currentActiveBreak?.breakType, 'Lunch Break');
      expect(att.currentActiveBreak?.isActive, isTrue);
    });

    test('Scenario 5: Missing optional break fields flags hasBreakDataContract false without fabricating fake values', () {
      final json = {
        '_id': 'att_no_contract',
        'employee': {
          '_id': 'emp_mongo_005',
          'employeeId': 'EMP1005',
          'firstName': 'Suresh',
          'lastName': 'K',
          'department': 'Tech',
        },
        'date': '2026-10-27T00:00:00.000Z',
        'checkIn': '2026-10-27T03:30:00.000Z',
        'status': 'PRESENT',
      };

      final att = Attendance.fromJson(json);

      expect(att.hasBreakDataContract, isFalse);
      expect(att.breaks, isEmpty);
      expect(att.activeBreak, isNull);
      expect(att.isOnBreak, isFalse);
      expect(att.breakDuration, '—');
    });

    test('Scenario 6: Never correlates business employee code against MongoDB ObjectId in matchesStaff', () {
      final att = Attendance(
        id: 'att_001',
        staffId: '6adb0c5148f27e4ebf3a1eaa', // MongoDB ObjectId
        employeeId: 'EMP1001',                 // Business code
        date: '2026-10-27',
        workedDuration: '8h',
        breakDuration: '30m',
        isLate: false,
      );

      // Matches exact employeeId business code
      final staffMatchingBusinessId = Staff(
        id: 'different_mongo_id_999',
        name: 'Anita Rao',
        email: 'anita@example.com',
        phoneNumber: '9999999999',
        department: 'Tech',
        role: 'Staff',
        employeeId: 'EMP1001',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      );
      expect(att.matchesStaff(staffMatchingBusinessId), isTrue);

      // Matches exact database ObjectId
      final staffMatchingDbId = Staff(
        id: '6adb0c5148f27e4ebf3a1eaa',
        name: 'Anita Rao',
        email: 'anita@example.com',
        phoneNumber: '9999999999',
        department: 'Tech',
        role: 'Staff',
        employeeId: 'OTHER_CODE',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      );
      expect(att.matchesStaff(staffMatchingDbId), isTrue);

      // Does NOT match when business code is mistakenly compared to MongoDB ObjectId
      final staffWithClashingId = Staff(
        id: 'EMP1001', // ObjectId accidentally equals business code of another staff
        name: 'Wrong Staff',
        email: 'wrong@example.com',
        phoneNumber: '8888888888',
        department: 'Tech',
        role: 'Staff',
        employeeId: 'EMP9999',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      );
      expect(att.matchesStaff(staffWithClashingId), isFalse);
    });
  });

  group('Attendance Details Modal UI Tests', () {
    testWidgets('displays employee name, employee ID, department, and break details for completed breaks', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      final att = Attendance.fromJson({
        '_id': 'att_test_ui_1',
        'employee': {
          '_id': 'emp_id_001',
          'employeeId': 'EMP1024',
          'firstName': 'Kavita',
          'lastName': 'Nair',
          'department': 'Telecalling',
          'designation': 'Senior Telecaller'
        },
        'date': '2026-10-27T00:00:00.000Z',
        'checkIn': '2026-10-27T03:30:00.000Z', // 09:00 AM IST
        'checkOut': '2026-10-27T12:00:00.000Z',
        'status': 'PRESENT',
        'workedDuration': '7h 30m',
        'breakDuration': '1h 0m',
        'totalBreakMinutes': 60,
        'breaks': [
          {
            '_id': 'b1',
            'breakType': 'Morning Break',
            'startTime': '2026-10-27T05:30:00.000Z', // 11:00 AM IST
            'endTime': '2026-10-27T05:45:00.000Z',   // 11:15 AM IST
            'durationMinutes': 15,
          },
          {
            '_id': 'b2',
            'breakType': 'Lunch Break',
            'startTime': '2026-10-27T07:30:00.000Z', // 01:00 PM IST
            'endTime': '2026-10-27T08:15:00.000Z',   // 01:45 PM IST
            'durationMinutes': 45,
          }
        ],
        'activeBreak': null,
      });

      hrProvider.apiAttendanceRecords = [att];
      hrProvider.hasLoadedApiAttendance = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: hrProvider,
            child: const AttendanceView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the record details button and tap it
      expect(find.byIcon(Icons.info_outline), findsWidgets);
      await tester.tap(find.byTooltip('View break details').first);
      await tester.pumpAndSettle();

      // Verify modal headers and required fields
      expect(find.text('Attendance Record Details'), findsOneWidget);
      expect(find.text('Kavita Nair'), findsWidgets);
      expect(find.text('EMP1024'), findsOneWidget);
      expect(find.text('Telecalling'), findsWidgets);
      expect(find.text('1h 0m'), findsWidgets);
      expect(find.text('60 min'), findsOneWidget);

      // Verify individual breaks are listed with start, end, and duration
      expect(find.text('Break Times & History'), findsOneWidget);
      expect(find.text('Morning Break'), findsOneWidget);
      expect(find.text('Lunch Break'), findsOneWidget);
      expect(find.textContaining('11:00 AM'), findsOneWidget);
      expect(find.textContaining('11:15 AM'), findsOneWidget);
      expect(find.textContaining('01:00 PM'), findsOneWidget);
      expect(find.textContaining('01:45 PM'), findsOneWidget);
      expect(find.textContaining('15 min'), findsWidgets);
      expect(find.textContaining('45 min'), findsWidgets);
    });

    testWidgets('displays ACTIVE BREAK in progress with In Progress status', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      final att = Attendance.fromJson({
        '_id': 'att_test_ui_2',
        'employee': {
          '_id': 'emp_id_002',
          'employeeId': 'EMP1088',
          'firstName': 'Aditya',
          'lastName': 'Kulkarni',
          'department': 'Tech',
          'designation': 'Frontend Engineer'
        },
        'date': '2026-10-27T00:00:00.000Z',
        'checkIn': '2026-10-27T03:30:00.000Z',
        'status': 'PRESENT',
        'breakDuration': '15m',
        'totalBreakMinutes': 15,
        'breaks': [
          {
            '_id': 'b1',
            'breakType': 'Tea Break 1',
            'startTime': '2026-10-27T05:30:00.000Z',
            'endTime': '2026-10-27T05:45:00.000Z',
            'durationMinutes': 15,
          },
          {
            '_id': 'b2',
            'breakType': 'Lunch Break',
            'startTime': '2026-10-27T07:30:00.000Z', // 01:00 PM IST
            'endTime': null,
            'durationMinutes': 0,
          }
        ],
        'activeBreak': {
          'breakType': 'Lunch Break',
          'startTime': '2026-10-27T07:30:00.000Z'
        },
        'breakStartedAt': '2026-10-27T07:30:00.000Z'
      });

      hrProvider.apiAttendanceRecords = [att];
      hrProvider.hasLoadedApiAttendance = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: hrProvider,
            child: const AttendanceView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open details modal
      await tester.tap(find.byTooltip('View break details').first);
      await tester.pumpAndSettle();

      // Verify active break indicators
      expect(find.text('ACTIVE BREAK'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.textContaining('01:00 PM'), findsWidgets);
      expect(find.text('Aditya Kulkarni'), findsWidgets);
      expect(find.text('EMP1088'), findsOneWidget);
      expect(find.text('Tech'), findsWidgets);
    });

    testWidgets('displays contract missing message when break fields are omitted from response', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      final att = Attendance.fromJson({
        '_id': 'att_test_ui_3',
        'employee': {
          '_id': 'emp_id_003',
          'employeeId': 'EMP1099',
          'firstName': 'Manish',
          'lastName': 'P',
          'department': 'Tech',
        },
        'date': '2026-10-27T00:00:00.000Z',
        'checkIn': '2026-10-27T03:30:00.000Z',
        'status': 'PRESENT',
      });

      hrProvider.apiAttendanceRecords = [att];
      hrProvider.hasLoadedApiAttendance = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: hrProvider,
            child: const AttendanceView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('View break details').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Break tracking data contract was not returned'), findsOneWidget);
      expect(find.text('Manish P'), findsWidgets);
      expect(find.text('EMP1099'), findsOneWidget);
    });
  });

  group('Date and Department Filters Integration', () {
    test('ApiService.getAttendancePage sends date, startDate, endDate, and department query parameters', () async {
      Map<String, String>? queryParams;

      ApiService.setToken('test_token');
      ApiService.client = MockClient((request) async {
        queryParams = request.url.queryParameters;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [
              {
                '_id': 'att_tele_01',
                'employee': {
                  'employeeId': 'EMP2001',
                  'firstName': 'Sara',
                  'lastName': 'Khan',
                  'department': 'Telecalling'
                },
                'date': '2026-10-27T00:00:00.000Z',
                'breakDuration': '20m',
                'totalBreakMinutes': 20,
                'breaks': [
                  {
                    'breakType': 'Morning Break',
                    'startTime': '2026-10-27T04:30:00.000Z',
                    'endTime': '2026-10-27T04:50:00.000Z',
                    'durationMinutes': 20,
                  }
                ],
                'status': 'PRESENT'
              }
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.getAttendancePage(
        date: '2026-10-27',
        department: 'Telecalling',
      );

      expect(queryParams?['date'], '2026-10-27');
      expect(queryParams?['department'], 'Telecalling');
      expect(result.records.length, 1);
      expect(result.records.first.department, 'Telecalling');
      expect(result.records.first.breaks.length, 1);
      expect(result.records.first.breaks.first.breakType, 'Morning Break');
    });
  });
}
