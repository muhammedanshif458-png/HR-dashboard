import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';

void main() {
  group('Late Arrivals ID Matching & Model Preservation', () {
    test('Staff and Attendance preserve both MongoDB _id and business employeeId', () {
      final staffJson = {
        '_id': '671df89b940e4f2a1b948c12',
        'employeeId': 'EMP1001',
        'name': 'Rahul Sharma',
        'email': 'rahul@example.com',
        'department': 'Technology',
        'role': 'Developer',
        'status': 'active',
      };

      final staff = Staff.fromJson(staffJson);
      expect(staff.id, equals('671df89b940e4f2a1b948c12'));
      expect(staff.employeeId, equals('EMP1001'));
      expect(staff.name, equals('Rahul Sharma'));

      final attendanceJson = {
        '_id': '672000000000000000000001',
        'staffId': '671df89b940e4f2a1b948c12',
        'employeeId': 'EMP1001',
        'employeeName': 'Rahul Sharma',
        'department': 'Technology',
        'status': 'LATE',
        'isLate': true,
        'late': true,
        'minutesLate': 25,
        'checkIn': '2026-10-27T10:25:00.000Z',
      };

      final attendance = Attendance.fromJson(attendanceJson);
      expect(attendance.id, equals('672000000000000000000001'));
      expect(attendance.staffId, equals('671df89b940e4f2a1b948c12'));
      expect(attendance.employeeId, equals('EMP1001'));
      expect(attendance.isLate, isTrue);
      expect(attendance.minutesLate, equals(25));
      expect(attendance.status, equals('Late'));

      // Verify matching by DB ID and by Business ID
      expect(attendance.matchesStaff(staff), isTrue);
    });

    test('Attendance.matchesStaff matches when populated employee subdocument is present', () {
      final staff = Staff.fromJson({
        '_id': '671df89b940e4f2a1b948c12',
        'employeeId': 'TECH42',
        'name': 'Priya Patel',
      });

      final attendanceFromPopulated = Attendance.fromJson({
        '_id': '672000000000000000000099',
        'employee': {
          '_id': '671df89b940e4f2a1b948c12',
          'employeeId': 'TECH42',
          'firstName': 'Priya',
          'lastName': 'Patel',
        },
        'status': 'PRESENT',
        'isLate': true,
        'minutesLate': 15,
      });

      expect(attendanceFromPopulated.staffId, equals('671df89b940e4f2a1b948c12'));
      expect(attendanceFromPopulated.employeeId, equals('TECH42'));
      expect(attendanceFromPopulated.matchesStaff(staff), isTrue);
    });

    test('HRProvider filteredStaffList includes late employee when dashboardFilter is late', () {
      final provider = HRProvider();

      final staff1 = Staff.fromJson({
        '_id': '671df89b940e4f2a1b948c12',
        'employeeId': 'TECH42',
        'name': 'Priya Patel',
        'status': 'active',
      });
      final staff2 = Staff.fromJson({
        '_id': '671df89b940e4f2a1b948c99',
        'employeeId': 'TELE99',
        'name': 'On-time Bob',
        'status': 'active',
      });

      provider.employeeDirectory = [staff1, staff2];

      final lateAtt = Attendance.fromJson({
        '_id': 'att1',
        'staffId': '671df89b940e4f2a1b948c12',
        'employeeId': 'TECH42',
        'isLate': true,
        'minutesLate': 15,
      });
      final onTimeAtt = Attendance.fromJson({
        '_id': 'att2',
        'staffId': '671df89b940e4f2a1b948c99',
        'employeeId': 'TELE99',
        'isLate': false,
        'minutesLate': 0,
      });

      provider.apiAttendanceRecords = [lateAtt, onTimeAtt];
      provider.hasLoadedApiAttendance = true;

      // Filter by 'late'
      provider.dashboardFilter = 'late';
      final lateList = provider.filteredStaffList;

      expect(lateList.length, equals(1));
      expect(lateList.first.id, equals('671df89b940e4f2a1b948c12'));
      expect(lateList.first.employeeId, equals('TECH42'));
    });

    test('HRProvider parses late counts from both lateArrivals and todayLate metrics keys', () {
      final provider = HRProvider();

      provider.apiDashboardMetrics = {
        'totalEmployees': 50,
        'todayPresent': 40,
        'todayLate': 5,
        'lateArrivals': 5,
      };

      expect(provider.lateArrivalsDisplayValue, equals('5'));
      expect(provider.lateTodayCount, equals(5));
    });
  });
}
