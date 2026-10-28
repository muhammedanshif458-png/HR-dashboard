import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/attendance/attendance_view.dart';
import 'package:ly_hr_dashboard_flutter/utils/date_time_utils.dart';

void main() {
  // ─── Actual Sanitized API Responses from Live Backend (GET /api/hr/attendance) ───
  final Map<String, dynamic> techLateApiResponse = {
    '_id': '6ae1941a4ec7e8c28a00fed1',
    'employee': {
      '_id': '6ae194194ec7e8c28a00fec3',
      'employeeId': 'EMP1088',
      'firstName': 'DevLive',
      'lastName': 'Tech',
      'department': 'Tech',
      'designation': 'Software Developer',
      'workMode': 'Office',
      'status': 'ACTIVE'
    },
    'date': '2026-10-28T00:00:00.000Z',
    'checkIn': '2026-10-28T06:20:09.797Z',
    'late': true,
    'workMode': 'Office',
    'scheduleConfigured': true,
    'scheduledCheckIn': '10:00',
    'scheduledCheckOut': '18:00',
    'gracePeriodMinutes': 0,
    'scheduleTimeZone': 'Asia/Kolkata',
    'checkOut': null,
    'status': 'PRESENT',
    'workingHours': 0,
    'totalBreakMinutes': 0,
    'activeBreak': null,
    'breakStartedAt': null,
    'isLate': true,
    'minutesLate': 110,
    'scheduleStatus': 'CONFIGURED',
    'scheduleSnapshot': {
      'scheduleId': '6ae07d3e86e1aafcb1732ab8',
      'department': 'TECH',
      'scheduledCheckIn': '10:00',
      'scheduledCheckOut': '18:00',
      'gracePeriodMinutes': 0,
      'timezone': 'Asia/Kolkata'
    },
    'remarks': 'Live Tech check-in verification',
    'breaks': [],
    'id': '6ae1941a4ec7e8c28a00fed1',
    'staffId': '6ae194194ec7e8c28a00fec3',
    'employeeId': 'EMP1088',
    'checkInTime': '2026-10-28T06:20:09.797Z',
    'checkOutTime': null,
    'checkInAt': '2026-10-28T06:20:09.797Z',
    'workedDuration': '0h',
    'breakDuration': '0m',
    'totalBreakSeconds': 0,
    'timezone': 'Asia/Kolkata',
    'department': 'Tech'
  };

  final Map<String, dynamic> telecallingLateApiResponse = {
    '_id': '6ae1941a4ec7e8c28a00fee6',
    'employee': {
      '_id': '6ae1941a4ec7e8c28a00feda',
      'employeeId': 'EMP1089',
      'firstName': 'CallerLive',
      'lastName': 'Telecalling',
      'department': 'Telecalling',
      'designation': 'Outbound Agent',
      'workMode': 'Office',
      'status': 'ACTIVE'
    },
    'date': '2026-10-28T00:00:00.000Z',
    'checkIn': '2026-10-28T06:20:10.425Z',
    'late': true,
    'workMode': 'Office',
    'scheduleConfigured': true,
    'scheduledCheckIn': '09:00',
    'scheduledCheckOut': '18:00',
    'gracePeriodMinutes': 0,
    'scheduleTimeZone': 'Asia/Kolkata',
    'checkOut': null,
    'status': 'PRESENT',
    'workingHours': 0,
    'totalBreakMinutes': 0,
    'activeBreak': null,
    'breakStartedAt': null,
    'isLate': true,
    'minutesLate': 170,
    'scheduleStatus': 'CONFIGURED',
    'scheduleSnapshot': {
      'scheduleId': '6ae07d3e86e1aafcb1732abb',
      'department': 'TELECALLING',
      'scheduledCheckIn': '09:00',
      'scheduledCheckOut': '18:00',
      'gracePeriodMinutes': 0,
      'timezone': 'Asia/Kolkata'
    },
    'remarks': 'Live Telecalling check-in verification',
    'breaks': [],
    'id': '6ae1941a4ec7e8c28a00fee6',
    'staffId': '6ae1941a4ec7e8c28a00feda',
    'employeeId': 'EMP1089',
    'checkInTime': '2026-10-28T06:20:10.425Z',
    'checkOutTime': null,
    'checkInAt': '2026-10-28T06:20:10.425Z',
    'workedDuration': '0h',
    'breakDuration': '0m',
    'totalBreakSeconds': 0,
    'timezone': 'Asia/Kolkata',
    'department': 'Telecalling'
  };

  final Map<String, dynamic> techOnTimeApiResponse = {
    '_id': 'att_tech_ontime_001',
    'employee': {
      '_id': 'emp_tech_ontime_001',
      'employeeId': 'EMP1090',
      'firstName': 'Priya',
      'lastName': 'TechDev',
      'department': 'Tech',
      'designation': 'Frontend Engineer',
      'workMode': 'Office',
      'status': 'ACTIVE'
    },
    'date': '2026-10-28T00:00:00.000Z',
    'checkIn': '2026-10-28T04:25:00.000Z', // 09:55 AM IST (on time for 10:00 AM shift)
    'checkOut': '2026-10-28T12:30:00.000Z', // 06:00 PM IST
    'status': 'PRESENT',
    'isLate': false,
    'late': false,
    'minutesLate': 0,
    'scheduleConfigured': true,
    'scheduledCheckIn': '10:00',
    'scheduledCheckOut': '18:00',
    'gracePeriodMinutes': 0,
    'scheduleTimeZone': 'Asia/Kolkata',
    'scheduleStatus': 'CONFIGURED',
    'scheduleSnapshot': {
      'department': 'TECH',
      'scheduledCheckIn': '10:00',
      'scheduledCheckOut': '18:00',
      'gracePeriodMinutes': 0,
      'timezone': 'Asia/Kolkata'
    },
    'workedDuration': '8h 05m',
    'breakDuration': '0m',
    'department': 'Tech'
  };

  final Map<String, dynamic> unconfiguredScheduleApiResponse = {
    '_id': '6ad5f9328c4995472b211e2c',
    'employee': {
      '_id': '6ad5f9328c4995472b211df1',
      'employeeId': 'EMP1012',
      'firstName': 'AuditLive',
      'lastName': 'Mutation',
      'department': 'Tech',
      'designation': 'Senior QA Engineer',
      'status': 'INACTIVE'
    },
    'date': '2026-10-19T00:00:00.000Z',
    'checkIn': '2026-10-19T11:04:18.872Z',
    'checkOut': '2026-10-19T11:04:18.897Z',
    'status': 'HALF_DAY',
    'workingHours': 0,
    'remarks': '',
    'id': '6ad5f9328c4995472b211e2c',
    'staffId': '6ad5f9328c4995472b211df1',
    'employeeId': 'EMP1012',
    'isLate': false,
    'late': false,
    'minutesLate': 0,
    'scheduleConfigured': false,
    'scheduleStatus': 'UNCONFIGURED',
    'scheduledCheckIn': null,
    'scheduledCheckOut': '18:00',
    'scheduleTimeZone': 'Asia/Kolkata',
    'timezone': 'Asia/Kolkata',
    'gracePeriodMinutes': 0,
    'scheduleSnapshot': null,
    'department': 'Tech'
  };

  group('Attendance Model Schedule & Lateness Mapping Tests', () {
    test('Tech staff parses 10:00 scheduledCheckIn, 18:00 scheduledCheckOut, and authoritative lateness', () {
      final att = Attendance.fromJson(techLateApiResponse);

      expect(att.department, 'Tech');
      expect(att.scheduleConfigured, isTrue);
      expect(att.scheduledCheckIn, '10:00');
      expect(att.scheduledCheckOut, '18:00');
      expect(att.scheduleTimeZone, 'Asia/Kolkata');
      expect(att.gracePeriodMinutes, 0);
      expect(att.isLate, isTrue);
      expect(att.minutesLate, 110);
      expect(formatAttendanceTime(att.scheduledCheckIn), '10:00 AM');
      expect(formatAttendanceTime(att.scheduledCheckOut), '06:00 PM');
    });

    test('Telecalling staff parses 09:00 scheduledCheckIn, 18:00 scheduledCheckOut, and authoritative lateness', () {
      final att = Attendance.fromJson(telecallingLateApiResponse);

      expect(att.department, 'Telecalling');
      expect(att.scheduleConfigured, isTrue);
      expect(att.scheduledCheckIn, '09:00');
      expect(att.scheduledCheckOut, '18:00');
      expect(att.scheduleTimeZone, 'Asia/Kolkata');
      expect(att.gracePeriodMinutes, 0);
      expect(att.isLate, isTrue);
      expect(att.minutesLate, 170);
      expect(formatAttendanceTime(att.scheduledCheckIn), '09:00 AM');
      expect(formatAttendanceTime(att.scheduledCheckOut), '06:00 PM');
    });

    test('On-time check-in parses isLate as false and minutesLate as 0', () {
      final att = Attendance.fromJson(techOnTimeApiResponse);

      expect(att.department, 'Tech');
      expect(att.scheduleConfigured, isTrue);
      expect(att.scheduledCheckIn, '10:00');
      expect(att.scheduledCheckOut, '18:00');
      expect(att.isLate, isFalse);
      expect(att.minutesLate, 0);
      expect(formatAttendanceTime(att.scheduledCheckIn), '10:00 AM');
      expect(formatAttendanceTime(att.scheduledCheckOut), '06:00 PM');
    });

    test('Unconfigured schedule maps scheduledCheckIn, scheduledCheckOut, and scheduleTimeZone to null', () {
      final att = Attendance.fromJson(unconfiguredScheduleApiResponse);

      expect(att.scheduleConfigured, isFalse);
      expect(att.scheduledCheckIn, isNull);
      expect(att.scheduledCheckOut, isNull);
      expect(att.scheduleTimeZone, isNull);
      expect(att.isLate, isFalse);
      expect(att.minutesLate, 0);
    });
  });

  group('AttendanceView Widget Tests: Table & Modal Display', () {
    testWidgets('renders Tech at 10:00 AM, Telecalling at 09:00 AM, unconfigured as —, and correct Late By',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final records = [
        Attendance.fromJson(techLateApiResponse),
        Attendance.fromJson(telecallingLateApiResponse),
        Attendance.fromJson(techOnTimeApiResponse),
        Attendance.fromJson(unconfiguredScheduleApiResponse),
      ];

      final provider = HRProvider();
      provider.hasLoadedApiAttendance = true;
      provider.apiAttendanceRecords = records;
      provider.attendancePage = 1;
      provider.attendanceLimit = 20;
      provider.attendanceTotal = 4;
      provider.attendanceTotalPages = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Tech schedule check-in display: 10:00 AM (with Asia/Kolkata)
      expect(find.text('10:00 AM (Asia/Kolkata)'), findsNWidgets(2)); // DevLive Tech & Priya TechDev

      // Verify Telecalling schedule check-in display: 09:00 AM (with Asia/Kolkata)
      expect(find.text('09:00 AM (Asia/Kolkata)'), findsOneWidget); // CallerLive Telecalling

      // Verify authoritative lateness: 110 min -> 1 hr 50 min late
      expect(find.text('1 hr 50 min late'), findsOneWidget);

      // Verify authoritative lateness: 170 min -> 2 hr 50 min late
      expect(find.text('2 hr 50 min late'), findsOneWidget);

      // Verify unconfigured schedule and on-time check-in show '—'
      expect(find.text('—'), findsWidgets);

      // Ensure "0 min late" is never displayed for on-time check-ins
      expect(find.text('0 min late'), findsNothing);
    });

    testWidgets('Details modal displays Scheduled Check-in, Check-out, and Lateness correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final techRecord = Attendance.fromJson(techLateApiResponse);

      final provider = HRProvider();
      provider.hasLoadedApiAttendance = true;
      provider.apiAttendanceRecords = [techRecord];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open details modal
      await tester.tap(find.byIcon(Icons.info_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Attendance Record Details'), findsOneWidget);
      expect(find.text('Scheduled Check-in'), findsOneWidget);
      expect(find.text('10:00 AM (Asia/Kolkata)'), findsWidgets);
      expect(find.text('Scheduled Check-out'), findsOneWidget);
      expect(find.text('06:00 PM (Asia/Kolkata)'), findsOneWidget);
      expect(find.text('110 minutes late'), findsOneWidget);
    });

    testWidgets('Telecalling details modal displays 09:00 AM check-in and 06:00 PM check-out',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final teleRecord = Attendance.fromJson(telecallingLateApiResponse);

      final provider = HRProvider();
      provider.hasLoadedApiAttendance = true;
      provider.apiAttendanceRecords = [teleRecord];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open details modal
      await tester.tap(find.byIcon(Icons.info_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Attendance Record Details'), findsOneWidget);
      expect(find.text('Scheduled Check-in'), findsOneWidget);
      expect(find.text('09:00 AM (Asia/Kolkata)'), findsWidgets);
      expect(find.text('Scheduled Check-out'), findsOneWidget);
      expect(find.text('06:00 PM (Asia/Kolkata)'), findsOneWidget);
      expect(find.text('170 minutes late'), findsOneWidget);
    });
  });
}
