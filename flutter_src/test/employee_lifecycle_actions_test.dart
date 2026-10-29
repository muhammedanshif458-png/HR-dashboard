import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/features/dashboard/staff_profile_view.dart';
import 'package:ly_hr_dashboard_flutter/features/employees/employees_view.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  Map<String, dynamic> staffJson({
    required String id,
    required String employeeId,
    required String name,
    required String status,
    String department = 'Tech',
    String role = 'Staff',
    bool onLeaveToday = false,
  }) =>
      {
        '_id': id,
        'employeeId': employeeId,
        'name': name,
        'email': '$employeeId@example.com',
        'phone': '9876543210',
        'department': department,
        'role': role,
        'status': status.toUpperCase(),
        'onLeaveToday': onLeaveToday,
        'designation': 'Developer',
        'salary': 50000,
        'joiningDate': '2025-01-01',
      };

  Map<String, dynamic> envelope(List<Map<String, dynamic>> list,
          {int page = 1, int limit = 20, int? total}) =>
      {
        'success': true,
        'message': 'Success',
        'data': list,
        'pagination': {
          'page': page,
          'limit': limit,
          'total': total ?? list.length,
          'totalPages': 1,
        }
      };

  group('ApiService Employee Lifecycle Actions', () {
    test('deactivateEmployee calls POST /api/hr/employees/:id/deactivate', () async {
      ApiService.setToken('hr-token');
      http.Request? captured;
      ApiService.client = MockClient((request) async {
        captured = request;
        return http.Response(
            jsonEncode({'success': true, 'message': 'Deactivated'}), 200);
      });

      final result = await ApiService.deactivateEmployee('emp_123', reason: 'Extended hiatus');
      expect(result, isTrue);
      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/hr/employees/emp_123/deactivate');
      expect(jsonDecode(captured!.body), {'reason': 'Extended hiatus'});
    });

    test('reactivateEmployee calls POST /api/hr/employees/:id/reactivate', () async {
      ApiService.setToken('hr-token');
      http.Request? captured;
      ApiService.client = MockClient((request) async {
        captured = request;
        return http.Response(
            jsonEncode({'success': true, 'message': 'Reactivated'}), 200);
      });

      final result = await ApiService.reactivateEmployee('emp_123');
      expect(result, isTrue);
      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/hr/employees/emp_123/reactivate');
    });

    test('resignEmployee calls POST /api/hr/employees/:id/resign', () async {
      ApiService.setToken('hr-token');
      http.Request? captured;
      ApiService.client = MockClient((request) async {
        captured = request;
        return http.Response(
            jsonEncode({'success': true, 'message': 'Resigned'}), 200);
      });

      final result = await ApiService.resignEmployee('emp_123',
          resignationDate: '2026-10-31', reason: 'Career opportunity');
      expect(result, isTrue);
      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/hr/employees/emp_123/resign');
      expect(jsonDecode(captured!.body), {
        'resignationDate': '2026-10-31',
        'reason': 'Career opportunity',
      });
    });

    test('deleteEmployee calls DELETE /api/hr/employees/:id', () async {
      ApiService.setToken('hr-token');
      http.Request? captured;
      ApiService.client = MockClient((request) async {
        captured = request;
        return http.Response(
            jsonEncode({'success': true, 'message': 'Deleted'}), 200);
      });

      final result = await ApiService.deleteEmployee('emp_123');
      expect(result, isTrue);
      expect(captured!.method, 'DELETE');
      expect(captured!.url.path, '/api/hr/employees/emp_123');
    });
  });

  group('EmployeesView Row Actions & Delete Button', () {
    testWidgets('displays Delete Employee button only for authorized HR/Admin', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.setToken('staff-token');
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode(envelope([
            staffJson(id: 's1', employeeId: 'EMP1', name: 'John Doe', status: 'ACTIVE'),
          ])),
          200,
        );
      });

      final provider = HRProvider();
      // Set non-admin user
      provider.setCurrentUserForTesting(Staff(
        id: 'user_staff',
        name: 'Regular Staff',
        email: 'staff@test.com',
        phoneNumber: '1234567890',
        department: 'Tech',
        role: 'Staff',
        joinDate: '2025-01-01',
        status: 'active',
        onLeaveToday: false,
      ));

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const EmployeesView(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      // Delete Employee icon should NOT be shown for normal staff
      expect(find.byTooltip('Delete Employee'), findsNothing);

      // Now set HR user
      provider.setCurrentUserForTesting(Staff(
        id: 'user_hr',
        name: 'HR Manager',
        email: 'hr@test.com',
        phoneNumber: '1234567890',
        department: 'HR',
        role: 'HR Manager',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      ));
      await tester.pumpAndSettle();

      // Delete Employee icon MUST now be visible
      expect(find.byTooltip('Delete Employee'), findsOneWidget);
    });

    testWidgets('clicking Delete Employee opens confirmation dialog and executes delete API', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      var deleteCalls = 0;
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(envelope(deleteCalls == 0
                ? [
                    staffJson(id: 's1', employeeId: 'EMP1', name: 'John Doe', status: 'ACTIVE'),
                  ]
                : [])),
            200,
          );
        }
        if (request.method == 'DELETE' && request.url.path == '/api/hr/employees/s1') {
          deleteCalls++;
          return http.Response(jsonEncode({'success': true, 'message': 'Deleted'}), 200);
        }
        return http.Response('Not found', 404);
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(Staff(
        id: 'user_admin',
        name: 'Super Admin',
        email: 'admin@test.com',
        phoneNumber: '1234567890',
        department: 'Management',
        role: 'Super Admin',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      ));

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const EmployeesView(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete Employee'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete Employee'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete John Doe?'), findsOneWidget);

      // Cancel button test
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(deleteCalls, 0);

      // Re-open and confirm
      await tester.tap(find.byTooltip('Delete Employee'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalls, 1);
      expect(find.text('John Doe has been deleted.'), findsOneWidget);
    });

    testWidgets('status column renders Active, Inactive, and Resigned correctly', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode(envelope([
            staffJson(id: 's1', employeeId: 'EMP1', name: 'Active Person', status: 'ACTIVE'),
            staffJson(id: 's2', employeeId: 'EMP2', name: 'Inactive Person', status: 'INACTIVE'),
            staffJson(id: 's3', employeeId: 'EMP3', name: 'Resigned Person', status: 'RESIGNED'),
          ])),
          200,
        );
      });

      final provider = HRProvider();
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const EmployeesView(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Active Person'), findsOneWidget);
      expect(find.text('Inactive Person'), findsOneWidget);
      expect(find.text('Resigned Person'), findsOneWidget);

      // Verify badges in table
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Resigned'), findsOneWidget);
    });
  });

  group('StaffProfileView Status Badge & Conditional Actions', () {
    testWidgets('Active employee displays Active badge, Deactivate, Mark as Resigned, and Delete', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/employees/s1') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': staffJson(id: 's1', employeeId: 'EMP1', name: 'Alice Smith', status: 'ACTIVE'),
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(Staff(
        id: 'admin_id',
        name: 'Admin',
        email: 'admin@test.com',
        phoneNumber: '111',
        department: 'HR',
        role: 'Super Admin',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      ));
      provider.employeeDirectory = [
        Staff.fromJson(staffJson(id: 's1', employeeId: 'EMP1', name: 'Alice Smith', status: 'ACTIVE')),
      ];
      provider.selectedStaffId = 's1';

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const StaffProfileView(),
        ),
      ));
      await tester.pumpAndSettle();

      // Badge must be Active
      final badgeFinder = find.byKey(const Key('staff_profile_status_badge'));
      expect(badgeFinder, findsOneWidget);
      expect(find.descendant(of: badgeFinder, matching: find.text('Active')), findsOneWidget);

      // Available actions for Active employee
      expect(find.text('Deactivate Employee'), findsOneWidget);
      expect(find.text('Mark as Resigned'), findsOneWidget);
      expect(find.text('Delete Employee'), findsOneWidget);

      // Must NOT show Reactivate Employee
      expect(find.text('Reactivate Employee'), findsNothing);
    });

    testWidgets('Inactive employee displays Inactive badge, Reactivate, Mark as Resigned, and Delete', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/employees/s2') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': staffJson(id: 's2', employeeId: 'EMP2', name: 'Bob Jones', status: 'INACTIVE'),
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(Staff(
        id: 'admin_id',
        name: 'Admin',
        email: 'admin@test.com',
        phoneNumber: '111',
        department: 'HR',
        role: 'Super Admin',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      ));
      provider.employeeDirectory = [
        Staff.fromJson(staffJson(id: 's2', employeeId: 'EMP2', name: 'Bob Jones', status: 'INACTIVE')),
      ];
      provider.selectedStaffId = 's2';

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const StaffProfileView(),
        ),
      ));
      await tester.pumpAndSettle();

      // Badge must be Inactive (NOT Active!)
      final badgeFinder = find.byKey(const Key('staff_profile_status_badge'));
      expect(badgeFinder, findsOneWidget);
      expect(find.descendant(of: badgeFinder, matching: find.text('Inactive')), findsOneWidget);
      expect(find.descendant(of: badgeFinder, matching: find.text('Active')), findsNothing);

      // Available actions for Inactive employee
      expect(find.text('Reactivate Employee'), findsOneWidget);
      expect(find.text('Mark as Resigned'), findsOneWidget);
      expect(find.text('Delete Employee'), findsOneWidget);

      // Must NOT show Deactivate Employee
      expect(find.text('Deactivate Employee'), findsNothing);
    });

    testWidgets('Resigned employee displays Resigned badge and Delete, but NOT Reactivate or Deactivate', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/employees/s3') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': staffJson(id: 's3', employeeId: 'EMP3', name: 'Charlie Ray', status: 'RESIGNED'),
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(Staff(
        id: 'admin_id',
        name: 'Admin',
        email: 'admin@test.com',
        phoneNumber: '111',
        department: 'HR',
        role: 'Super Admin',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      ));
      provider.employeeDirectory = [
        Staff.fromJson(staffJson(id: 's3', employeeId: 'EMP3', name: 'Charlie Ray', status: 'RESIGNED')),
      ];
      provider.selectedStaffId = 's3';

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const StaffProfileView(),
        ),
      ));
      await tester.pumpAndSettle();

      // Badge must be Resigned
      final badgeFinder = find.byKey(const Key('staff_profile_status_badge'));
      expect(badgeFinder, findsOneWidget);
      expect(find.descendant(of: badgeFinder, matching: find.text('Resigned')), findsOneWidget);

      // Allowed action
      expect(find.text('Delete Employee'), findsOneWidget);

      // Prohibited actions for resigned employee
      expect(find.text('Deactivate Employee'), findsNothing);
      expect(find.text('Reactivate Employee'), findsNothing);
      expect(find.text('Mark as Resigned'), findsNothing);
    });

    testWidgets('deactivate action triggers dialog and immediately updates badge to Inactive', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      var deactCalls = 0;
      ApiService.setToken('hr-token');
      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/hr/employees/s1/deactivate') {
          deactCalls++;
          return http.Response(jsonEncode({'success': true, 'message': 'Deactivated'}), 200);
        }
        if (request.method == 'GET' && request.url.path == '/api/hr/employees/s1') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': staffJson(
                id: 's1',
                employeeId: 'EMP1',
                name: 'Alice Smith',
                status: deactCalls > 0 ? 'INACTIVE' : 'ACTIVE',
              ),
            }),
            200,
          );
        }
        if (request.method == 'GET' && request.url.path == '/api/hr/employees') {
          return http.Response(
            jsonEncode(envelope([
              staffJson(
                id: 's1',
                employeeId: 'EMP1',
                name: 'Alice Smith',
                status: deactCalls > 0 ? 'INACTIVE' : 'ACTIVE',
              ),
            ])),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(Staff(
        id: 'admin_id',
        name: 'Admin',
        email: 'admin@test.com',
        phoneNumber: '111',
        department: 'HR',
        role: 'Super Admin',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      ));
      provider.employeeDirectory = [
        Staff.fromJson(staffJson(id: 's1', employeeId: 'EMP1', name: 'Alice Smith', status: 'ACTIVE')),
      ];
      provider.selectedStaffId = 's1';

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const StaffProfileView(),
        ),
      ));
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(const Key('staff_profile_status_badge'));
      expect(find.descendant(of: badgeFinder, matching: find.text('Active')), findsOneWidget);
      await tester.tap(find.text('Deactivate Employee'));
      await tester.pumpAndSettle();

      // Dialog checks
      expect(find.text('Deactivate Employee'), findsWidgets);
      expect(find.textContaining('Are you sure you want to deactivate Alice Smith?'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Deactivate'));
      await tester.pumpAndSettle();

      expect(deactCalls, 1);
      // Status badge updated immediately!
      expect(find.descendant(of: badgeFinder, matching: find.text('Inactive')), findsOneWidget);
      expect(find.text('Reactivate Employee'), findsOneWidget);
      expect(find.text('Deactivate Employee'), findsNothing);
    });
  });
}
