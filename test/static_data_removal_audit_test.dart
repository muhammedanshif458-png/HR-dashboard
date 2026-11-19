import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

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

  group('Production HRProvider Zero-Mock Initial State', () {
    test('HRProvider initializes with empty collections in production mode',
        () {
      final provider = HRProvider();

      expect(provider.staffList, isEmpty);
      expect(provider.attendanceList, isEmpty);
      expect(provider.tasksList, isEmpty);
      expect(provider.leaveRequests, isEmpty);
      expect(provider.documentsList, isEmpty);
      expect(provider.departments, isEmpty);
      expect(provider.todayBirthdays, isEmpty);
      expect(provider.upcomingBirthdays, isEmpty);
    });

    test('DashboardMetrics returns zero values when no API data has loaded',
        () {
      final provider = HRProvider();
      final metrics = provider.dashboardMetrics;

      expect(metrics.totalStaff, 0);
      expect(metrics.activeStaff, 0);
      expect(metrics.presentToday, 0);
      expect(metrics.lateCheckIns, 0);
      expect(metrics.openTasks, 0);
      expect(metrics.onLeaveToday, 0);
      expect(metrics.resignedLast30Days, 0);
      expect(metrics.pendingLeaves, 0);
      expect(metrics.notCheckedIn, 0);
    });

    test(
        'Filtered getters return empty collections in production initial state',
        () {
      final provider = HRProvider();

      expect(provider.filteredStaffList, isEmpty);
      expect(provider.filteredAttendanceList, isEmpty);
      expect(provider.filteredLeaveRequests, isEmpty);
      expect(provider.filteredTasksList, isEmpty);
      expect(provider.filteredPayrollRecords, isEmpty);
      expect(provider.effectivePayrollSummary.totalEmployees, 0);
      expect(provider.effectiveAttendanceReport.departmentSummary, isEmpty);
      expect(provider.effectiveLeaveReport.statusSummary, isEmpty);
      expect(provider.presentTodayCount, 0);
      expect(provider.lateTodayCount, 0);
      expect(provider.pendingLeavesCount, 0);
      expect(provider.approvedLeavesCount, 0);
      expect(provider.rejectedLeavesCount, 0);
      expect(provider.onLeaveTodayCount, 0);
    });
  });

  group('No Static Fallback After API Failure', () {
    test('Dashboard API failure does not fall back to static metrics',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Internal Server Error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.fetchDashboardData();

      expect(success, false);
      expect(provider.dashboardError, isNotNull);
      expect(provider.hasLoadedApiDashboard, false);
      expect(provider.dashboardMetrics.totalStaff, 0);
      expect(provider.dashboardMetrics.presentToday, 0);
    });

    test(
        'Employee directory API failure sets error and does not substitute mock staff',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode(
              {'success': false, 'message': 'Database connection timeout'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      await provider.loadEmployeeDirectory();

      expect(provider.apiStaffError, contains('Database connection timeout'));
      expect(provider.employeeDirectory, isEmpty);
      expect(provider.filteredStaffList, isEmpty);
    });

    test(
        'Attendance API failure sets error and does not return hardcoded records',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode(
              {'success': false, 'message': 'Attendance service unavailable'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      await provider.loadAttendance();

      expect(provider.attendanceError, isNotNull);
      expect(provider.apiAttendanceRecords, isEmpty);
      expect(provider.filteredAttendanceList, isEmpty);
      expect(provider.presentTodayCount, 0);
    });

    test('Leave API failure sets error and does not return mock leaves',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Leaves table locked'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      await provider.loadLeaves();

      expect(provider.leavesError, isNotNull);
      expect(provider.apiLeaveRecords, isEmpty);
      expect(provider.filteredLeaveRequests, isEmpty);
      expect(provider.pendingLeavesCount, 0);
    });

    test(
        'Payroll API failure sets error and does not return mock payroll calculations',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Payroll ledger offline'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      await provider.loadPayroll();

      expect(provider.payrollError, isNotNull);
      expect(provider.apiPayrollRecords, isEmpty);
      expect(provider.filteredPayrollRecords, isEmpty);
      expect(provider.effectivePayrollSummary.totalEmployees, 0);
      expect(provider.effectivePayrollSummary.totalPayrollExpenditure, 0.0);
    });

    test(
        'Reports API failure sets error and does not return hardcoded department numbers',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Analytics engine error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      await provider.loadReports();

      expect(provider.reportsError, isNotNull);
      expect(provider.effectiveAttendanceReport.departmentSummary, isEmpty);
      expect(provider.effectiveLeaveReport.statusSummary, isEmpty);
    });

    test(
        'Department detail API failure sets error and returns null without local fallback',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Department not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final detail = await provider.fetchDepartmentDetail('tech');

      expect(detail, isNull);
      expect(provider.selectedDepartmentDetail, isNull);
      expect(provider.departmentDetailError, isNotNull);
    });

    test('Birthdays API failure sets error and does not fabricate birthdays',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Birthdays endpoint error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      await provider.fetchBirthdays();

      expect(provider.birthdaysError, isNotNull);
      expect(provider.todayBirthdays, isEmpty);
      expect(provider.upcomingBirthdays, isEmpty);
    });
  });

  group('Prevention of Fabricated Success Messages on Mutation Failures', () {
    test('addStaff returns false on API failure and sets apiStaffError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Email already registered'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.addStaff({
        'name': 'Duplicate User',
        'email': 'duplicate@company.com',
        'department': 'Tech',
      });

      expect(success, false);
      expect(provider.apiStaffError, contains('Email already registered'));
      expect(provider.staffList, isEmpty);
    });

    test('updateStaff returns false on API failure and sets apiStaffError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Employee not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.updateStaff('invalid_id', {
        'name': 'Changed Name',
      });

      expect(success, false);
      expect(provider.apiStaffError, isNotEmpty);
    });

    test('editSalary returns false on API failure and sets apiStaffError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode(
              {'success': false, 'message': 'Unauthorized salary update'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.editSalary(
        staffId: 'emp_1',
        newSalary: 90000,
        effectiveDate: '2026-11-01',
      );

      expect(success, false);
      expect(provider.apiStaffError, isNotEmpty);
    });

    test('approveLeave returns false on API failure and sets leavesError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Leave approval conflict'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.approveLeave('leave_101');

      expect(success, false);
      expect(provider.leavesError, contains('Leave approval conflict'));
    });

    test('rejectLeave returns false on API failure and sets leavesError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Leave already processed'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success =
          await provider.rejectLeave('leave_101', 'Invalid date range');

      expect(success, false);
      expect(provider.leavesError, contains('Leave already processed'));
    });

    test('assignTask returns false on API failure and sets tasksError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Invalid assignee ID'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.assignTask(
        'invalid_staff',
        'Tech',
        'Build feature',
        '2026-10-25',
      );

      expect(success, false);
      expect(provider.tasksError, contains('Invalid assignee ID'));
      expect(provider.tasksList, isEmpty);
    });

    test('updateTaskStatus returns false on API failure and sets tasksError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Task not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.updateTaskStatus('task_404', 'done');

      expect(success, false);
      expect(provider.tasksError, contains('Task not found'));
    });

    test('deleteTask returns false on API failure and sets tasksError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Permission denied'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.deleteTask('task_locked');

      expect(success, false);
      expect(provider.tasksError, contains('Permission denied'));
    });

    test(
        'uploadDocument returns false on API failure and sets employeeDocumentsError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'File exceeds size limit'}),
          413,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.uploadDocument(
        employeeId: 'emp_1',
        title: 'Large Document',
        category: 'Contract',
        fileName: 'huge.pdf',
        fileBytes: [1, 2, 3],
      );

      expect(success, false);
      expect(provider.employeeDocumentsError, isNotNull);
      expect(provider.documentsList, isEmpty);
    });

    test(
        'replaceDocument returns false on API failure and sets employeeDocumentsError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Document not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.replaceDocument(
        docId: 'doc_404',
        employeeId: 'emp_1',
        title: 'Updated Contract',
        fileName: 'contract_v2.pdf',
        fileBytes: [1, 2, 3],
      );

      expect(success, false);
      expect(provider.employeeDocumentsError, isNotNull);
    });

    test(
        'archiveDocument returns false on API failure and sets employeeDocumentsError',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode(
              {'success': false, 'message': 'Document already archived'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.archiveDocument('doc_1', 'emp_1');

      expect(success, false);
      expect(provider.employeeDocumentsError, isNotNull);
    });
  });

  group('Successful Mutations Trigger API Data Refresh', () {
    test('approveLeave success reloads leaves from backend API', () async {
      int getLeavesCount = 0;
      ApiService.client = MockClient((request) async {
        if (request.url.path.contains('/approve')) {
          expect(request.method, 'PUT');
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Leave approved successfully',
              'data': {
                '_id': 'leave_live_1',
                'employeeId': {
                  '_id': 'emp_1',
                  'firstName': 'John',
                  'lastName': 'Doe',
                  'department': 'Tech'
                },
                'leaveType': 'CASUAL',
                'startDate': '2026-10-20',
                'endDate': '2026-10-21',
                'days': 2,
                'reason': 'Travel',
                'status': 'APPROVED',
                'createdAt': '2026-10-10T00:00:00Z',
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/hr/leaves') {
          getLeavesCount++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'leaves': [
                  {
                    '_id': 'leave_live_1',
                    'employeeId': {
                      '_id': 'emp_1',
                      'firstName': 'John',
                      'lastName': 'Doe',
                      'department': 'Tech'
                    },
                    'leaveType': 'CASUAL',
                    'startDate': '2026-10-20',
                    'endDate': '2026-10-21',
                    'days': 2,
                    'reason': 'Travel',
                    'status': 'APPROVED',
                    'createdAt': '2026-10-10T00:00:00Z',
                  }
                ],
                'pagination': {'total': 1, 'page': 1, 'pages': 1, 'limit': 20}
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.approveLeave('leave_live_1');

      expect(success, true);
      expect(getLeavesCount, greaterThanOrEqualTo(1));
      expect(provider.hasLoadedApiLeaves, true);
      expect(provider.apiLeaveRecords.length, 1);
      expect(provider.apiLeaveRecords.first.status, 'Approved');
    });

    test('deleteTask success reloads tasks from backend API', () async {
      int getTasksCount = 0;
      ApiService.client = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path.contains('/tasks/')) {
          return http.Response(
            jsonEncode(
                {'success': true, 'message': 'Task deleted successfully'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && request.url.path == '/api/hr/tasks') {
          getTasksCount++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {
                'total': 0,
                'page': 1,
                'totalPages': 0,
                'limit': 20
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      final success = await provider.deleteTask('task_del_1');

      expect(success, true);
      expect(getTasksCount, greaterThanOrEqualTo(1));
      expect(provider.apiTasksList, isEmpty);
    });

    test('deleteTask failure preserves tasks already loaded from API', () async {
      ApiService.client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/hr/tasks') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                  {
                    '_id': 'task_locked',
                    'staffId': 'staff_1',
                    'department': 'Tech',
                    'description': 'Existing task',
                    'status': 'pending',
                    'date': '2026-10-23',
                    'dueDate': '2026-10-25',
                  }
              ],
              'pagination': {
                'total': 1,
                'page': 1,
                'totalPages': 1,
                'limit': 20
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE') {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Permission denied'}),
            403,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });
      ApiService.setTokens(accessToken: 'token');

      final provider = HRProvider();
      await provider.loadTasks();
      expect(provider.apiTasksList, hasLength(1));

      final success = await provider.deleteTask('task_locked');

      expect(success, false);
      expect(provider.tasksError, contains('Permission denied'));
      expect(provider.apiTasksList.map((task) => task.id), ['task_locked']);
    });
  });
}
