import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/attendance/attendance_view.dart';
import 'package:ly_hr_dashboard_flutter/utils/date_time_utils.dart';

void main() {
  group('Date & Time Formatter Utilities (Asia/Kolkata)', () {
    test('converts UTC ISO timestamps to Asia/Kolkata 12-hour AM/PM format', () {
      // 05:33 UTC + 05:30 = 11:03 AM IST
      expect(
        formatAttendanceTime('2026-10-26T05:33:16.627Z'),
        '11:03 AM',
      );

      // 04:52 UTC + 05:30 = 10:22 AM IST
      expect(
        formatAttendanceTime('2026-10-26T04:52:04.747Z'),
        '10:22 AM',
      );

      // 05:45 UTC + 05:30 = 11:15 AM IST
      expect(
        formatAttendanceTime('2026-10-23T05:45:00Z'),
        '11:15 AM',
      );

      // 18:30 UTC + 05:30 = 00:00 AM (midnight next day in IST)
      expect(
        formatAttendanceTime('2026-10-26T18:30:00.000Z'),
        '12:00 AM',
      );

      // 06:30 UTC + 05:30 = 12:00 PM (noon in IST)
      expect(
        formatAttendanceTime('2026-10-26T06:30:00.000Z'),
        '12:00 PM',
      );

      // 12:30 UTC + 05:30 = 06:00 PM IST
      expect(
        formatAttendanceTime('2026-10-26T12:30:00.000Z'),
        '06:00 PM',
      );
    });

    test('handles timestamps with explicit offsets without double conversion', () {
      // Already in IST (+05:30)
      expect(
        formatAttendanceTime('2026-10-26T11:03:16.627+05:30'),
        '11:03 AM',
      );

      // UTC offset +00:00
      expect(
        formatAttendanceTime('2026-10-26T05:33:16.627+00:00'),
        '11:03 AM',
      );

      // Different timezone offset (-04:00): 01:33 EDT is 05:33 UTC -> 11:03 AM IST
      expect(
        formatAttendanceTime('2026-10-26T01:33:16.627-04:00'),
        '11:03 AM',
      );

      // Local timestamp without timezone suffix is not shifted
      expect(
        formatAttendanceTime('2026-10-26T11:03:16'),
        '11:03 AM',
      );
    });

    test('normalizes and preserves existing AM/PM formatted strings', () {
      expect(formatAttendanceTime('11:03 AM'), '11:03 AM');
      expect(formatAttendanceTime('9:10 am'), '09:10 AM');
      expect(formatAttendanceTime('05:30 PM'), '05:30 PM');
      expect(formatAttendanceTime('12:00 pm'), '12:00 PM');
      expect(formatAttendanceTime('12:00 am'), '12:00 AM');
    });

    test('formats schedule-only times without treating them as UTC timestamps', () {
      // 10:00 should format as 10:00 AM (NOT 03:30 PM!)
      expect(formatAttendanceTime('10:00'), '10:00 AM');

      // 09:00 should format as 09:00 AM
      expect(formatAttendanceTime('09:00'), '09:00 AM');

      // 17:30 should format as 05:30 PM (24h to 12h)
      expect(formatAttendanceTime('17:30'), '05:30 PM');

      // With seconds
      expect(formatAttendanceTime('09:00:00'), '09:00 AM');
      expect(formatAttendanceTime('18:00:00'), '06:00 PM');

      // Midnight and noon in 24h
      expect(formatAttendanceTime('00:00'), '12:00 AM');
      expect(formatAttendanceTime('12:00'), '12:00 PM');
    });

    test('returns fallback for null, empty, or invalid timestamps', () {
      expect(formatAttendanceTime(null), '—');
      expect(formatAttendanceTime(''), '—');
      expect(formatAttendanceTime('   '), '—');
      expect(formatAttendanceTime('—'), '—');
      expect(formatAttendanceTime('null'), '—');
      expect(formatAttendanceTime('invalid_timestamp'), '—');
      expect(formatAttendanceTime('2026-99-99T99:99:99'), '—');

      // Custom fallback
      expect(formatAttendanceTime(null, fallback: 'Not recorded'), 'Not recorded');
      expect(formatAttendanceTime('invalid', fallback: 'N/A'), 'N/A');

      // Nullable version
      expect(formatAttendanceTimeNullable(null), isNull);
      expect(formatAttendanceTimeNullable(''), isNull);
      expect(formatAttendanceTimeNullable('invalid'), isNull);
    });

    test('formats attendance date as YYYY-MM-DD without timestamp', () {
      expect(formatAttendanceDate('2026-10-26'), '2026-10-26');
      expect(formatAttendanceDate('2026-10-26T05:33:16.627Z'), '2026-10-26');
      expect(formatAttendanceDate('2026-10-26T00:00:00.000Z'), '2026-10-26');
      expect(formatAttendanceDate(null), '—');
      expect(formatAttendanceDate(''), '—');
      expect(formatAttendanceDate('invalid'), '—');
    });
  });

  group('Attendance Model Parsing with Date/Time Formatting', () {
    test('Attendance.fromJson parses UTC ISO timestamps into Asia/Kolkata formatted times', () {
      final json = {
        '_id': 'att_utc_1',
        'staffId': 'EMP1001',
        'date': '2026-10-26T00:00:00.000Z',
        'checkInTime': '2026-10-26T05:33:16.627Z',
        'checkOutTime': '2026-10-26T12:30:00.000Z',
        'status': 'CHECKED_OUT',
        'employee': {
          'firstName': 'Anita',
          'lastName': 'Rao',
          'department': 'Tech',
        },
      };

      final att = Attendance.fromJson(json);
      expect(att.date, '2026-10-26');
      expect(att.checkInTime, '11:03 AM');
      expect(att.checkOutTime, '06:00 PM');
      expect(att.status, 'Checked Out');
    });

    test('Attendance.fromJson formats checkIn and checkInAt fields correctly', () {
      final json = {
        '_id': 'att_utc_2',
        'staffId': 'EMP1002',
        'checkIn': '2026-10-26T04:52:04.747Z',
        'checkOut': null,
        'status': 'PRESENT',
      };

      final att = Attendance.fromJson(json);
      expect(att.checkInTime, '10:22 AM');
      expect(att.checkOutTime, isNull);
      expect(att.checkInAt, '2026-10-26T04:52:04.747Z');
    });

    test('Attendance.fromJson preserves Active label when checkOutTime is Active', () {
      final json = {
        '_id': 'att_active',
        'staffId': 'EMP1003',
        'checkInTime': '2026-10-26T05:33:16.627Z',
        'checkOutTime': 'Active',
      };

      final att = Attendance.fromJson(json);
      expect(att.checkInTime, '11:03 AM');
      expect(att.checkOutTime, 'Active');
    });

    test('Attendance.fromJson parses scheduledCheckIn and scheduledCheckOut', () {
      final json = {
        '_id': 'att_sched',
        'scheduleSnapshot': {
          'scheduledCheckIn': '10:00',
          'scheduledCheckOut': '19:00',
          'timeZone': 'Asia/Kolkata',
        },
      };

      final att = Attendance.fromJson(json);
      expect(att.scheduledCheckIn, '10:00');
      expect(att.scheduledCheckOut, '19:00');
      expect(att.scheduleTimeZone, 'Asia/Kolkata');
    });
  });

  group('AttendanceView Table Rendering Tests', () {
    testWidgets('renders readable times, dates, active shift, and scheduled times',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final records = [
        // 1. Shift with full check-in and check-out timestamps
        Attendance(
          id: 'test_1',
          staffId: 'EMP001',
          date: '2026-10-26T00:00:00.000Z',
          checkInTime: '2026-10-26T05:33:16.627Z',
          checkOutTime: '2026-10-26T12:30:00.000Z',
          workedDuration: '6h 57m',
          breakDuration: '30m',
          isLate: false,
          employeeName: 'Priya Sharma',
          department: 'Tech',
          status: 'Checked Out',
          scheduledCheckIn: '10:00',
          scheduleTimeZone: 'Asia/Kolkata',
        ),
        // 2. Active shift: checked in, no check-out yet
        Attendance(
          id: 'test_2',
          staffId: 'EMP002',
          date: '2026-10-26',
          checkInTime: '2026-10-26T04:52:04.747Z',
          checkOutTime: null,
          workedDuration: '3h 10m',
          breakDuration: '0m',
          isLate: true,
          minutesLate: 22,
          employeeName: 'Rahul Verma',
          department: 'Telecalling',
          status: 'Late',
          scheduledCheckIn: '10:00',
        ),
        // 3. Absent employee: neither checked in nor checked out
        Attendance(
          id: 'test_3',
          staffId: 'EMP003',
          date: '2026-10-26',
          checkInTime: null,
          checkOutTime: null,
          workedDuration: '—',
          breakDuration: '—',
          isLate: false,
          employeeName: 'Neha Patel',
          department: 'Tech',
          status: 'Absent',
          scheduledCheckIn: null,
        ),
      ];

      final provider = HRProvider();
      provider.hasLoadedApiAttendance = true;
      provider.apiAttendanceRecords = records;
      provider.attendancePage = 1;
      provider.attendanceLimit = 20;
      provider.attendanceTotal = 3;
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

      // Check dates: only YYYY-MM-DD should appear, no raw ISO timestamps
      expect(find.text('2026-10-26'), findsWidgets);
      expect(find.textContaining('2026-10-26T00:00:00.000Z'), findsNothing);

      // Check-in times formatted in hh:mm AM/PM (Asia/Kolkata)
      expect(find.text('11:03 AM'), findsOneWidget); // 05:33 UTC
      expect(find.text('10:22 AM'), findsOneWidget); // 04:52 UTC
      expect(find.textContaining('2026-10-26T05:33:16'), findsNothing);
      expect(find.textContaining('2026-10-26T04:52:04'), findsNothing);

      // Check-out times
      expect(find.text('06:00 PM'), findsOneWidget); // 12:30 UTC
      expect(find.text('Active'), findsOneWidget); // active shift for Rahul Verma

      // Scheduled times: formatted without treating 10:00 as UTC (not 03:30 PM!)
      expect(find.text('10:00 AM (Asia/Kolkata)'), findsOneWidget);
      expect(find.text('10:00 AM'), findsOneWidget);
      expect(find.textContaining('03:30 PM'), findsNothing);

      // Missing values show '—'
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('details modal formats attendance date and times properly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2560, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final att = Attendance(
        id: 'test_modal',
        staffId: 'EMP001',
        date: '2026-10-26T00:00:00.000Z',
        checkInTime: '2026-10-26T05:33:16.627Z',
        checkOutTime: null,
        workedDuration: '4h 15m',
        breakDuration: '15m',
        isLate: false,
        employeeName: 'Priya Sharma',
        department: 'Tech',
        status: 'Present',
        scheduledCheckIn: '10:00',
        scheduleTimeZone: 'Asia/Kolkata',
      );

      final provider = HRProvider();
      provider.hasLoadedApiAttendance = true;
      provider.apiAttendanceRecords = [att];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Action "info" icon to open the details modal
      await tester.ensureVisible(find.byIcon(Icons.info_outline));
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('Attendance Record Details'), findsOneWidget);
      expect(find.text('11:03 AM'), findsWidgets);
      expect(find.text('Active / Still working on premise / remote'), findsOneWidget);
      expect(find.text('10:00 AM (Asia/Kolkata)'), findsWidgets);
    });
  });
}
