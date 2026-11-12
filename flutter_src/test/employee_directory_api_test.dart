import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/features/employees/employees_view.dart';
import 'package:ly_hr_dashboard_flutter/utils/date_time_utils.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  test(
      'joining date formatter preserves calendar date and rejects invalid values',
      () {
    expect(
        formatEmployeeJoiningDate('2026-11-12T07:17:54.059Z'), '12 Nov 2026');
    expect(
        formatEmployeeJoiningDate('2026-11-12T23:59:59.999Z'), '12 Nov 2026');
    expect(formatEmployeeJoiningDate(null), '—');
    expect(formatEmployeeJoiningDate('not-a-date'), '—');
    expect(formatEmployeeJoiningDate('2026-02-30T07:00:00Z'), '—');
  });

  test('list parsing, query parameters and bearer token', () async {
    late http.Request request;
    ApiService.setToken('employee-token');
    ApiService.client = MockClient((r) async {
      request = r;
      return http.Response(
          jsonEncode({
            'data': [
              {
                '_id': 'db-1',
                'employeeId': 'EMP-1',
                'firstName': 'Alice',
                'lastName': 'Rao',
                'status': 'ACTIVE',
                'phone': null,
                'salary': '42000'
              }
            ],
            'pagination': {'page': 2, 'limit': 10, 'total': 21, 'totalPages': 3}
          }),
          200);
    });

    final result = await ApiService.getEmployeePage(
        page: 2,
        limit: 10,
        search: 'alice',
        department: 'Tech',
        status: 'active');
    expect(request.url.path, '/api/hr/employees');
    expect(request.url.queryParameters, {
      'page': '2',
      'limit': '10',
      'search': 'alice',
      'department': 'Tech',
      'status': 'ACTIVE'
    });
    expect(request.headers['authorization'], 'Bearer employee-token');
    expect(result.total, 21);
    expect(result.totalPages, 3);
    expect(result.employees.single.id, 'db-1');
    expect(result.employees.single.name, 'Alice Rao');
    expect(result.employees.single.phoneNumber, '');
    expect(result.employees.single.salary, 42000);
  });

  test('detail, create, edit, status, salary and deactivate use exact routes',
      () async {
    final requests = <http.Request>[];
    ApiService.client = MockClient((r) async {
      requests.add(r);
      if (r.method == 'GET') {
        return http.Response(
            jsonEncode({
              'data': {'_id': 'db-1', 'firstName': 'Alice'}
            }),
            200);
      }
      return http.Response('{}', 200);
    });
    final detail = await ApiService.getEmployee('db-1');
    expect(detail.name, 'Alice');
    await ApiService.addEmployee({'firstName': 'Alice'});
    await ApiService.updateEmployee('db-1', {'department': 'Tech'});
    await ApiService.updateEmployeeStatus('db-1', 'on_leave');
    await ApiService.updateEmployeeSalary('db-1', {
      'salary': 5,
      'salaryCurrency': 'INR',
      'salaryEffectiveDate': '2026-10-15',
      'reason': 'Review'
    });
    await ApiService.deleteEmployee('db-1');
    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'GET /api/hr/employees/db-1',
      'POST /api/hr/employees',
      'PUT /api/hr/employees/db-1',
      'PATCH /api/hr/employees/db-1/status',
      'PUT /api/hr/employees/db-1/salary',
      'DELETE /api/hr/employees/db-1'
    ]);
    expect(jsonDecode(requests[3].body), {'status': 'ON_LEAVE'});
  });

  test('malformed list and server validation failures surface as errors',
      () async {
    ApiService.client =
        MockClient((_) async => http.Response('{"data":[]}', 200));
    expect(() => ApiService.getEmployeePage(), throwsA(isA<FormatException>()));
    ApiService.client = MockClient((_) async =>
        http.Response(jsonEncode({'message': 'Email already exists'}), 422));
    await expectLater(
        ApiService.addEmployee({}),
        throwsA(
            predicate((e) => e.toString().contains('Email already exists'))));
  });

  test('failed directory requests do not replace existing directory data',
      () async {
    final provider = HRProvider();
    provider.employeeDirectory = [
      Staff(
          id: 'existing',
          name: 'Existing',
          email: '',
          phoneNumber: '',
          department: '',
          role: '',
          joinDate: '',
          status: 'active',
          onLeaveToday: false)
    ];
    ApiService.client =
        MockClient((_) async => http.Response('server error', 500));
    await provider.loadEmployeeDirectory();
    expect(provider.employeeDirectory.single.id, 'existing');
    expect(provider.apiStaffError, contains('HTTP 500'));
    expect(provider.isApiStaffLoading, isFalse);
  });

  test('work mode filter composes with the existing directory filters', () {
    final provider = HRProvider()
      ..employeeDirectory = [
        Staff(
            id: 'office',
            name: 'Office',
            email: '',
            phoneNumber: '',
            department: 'Tech',
            role: '',
            joinDate: '',
            status: 'active',
            onLeaveToday: false,
            workMode: 'Office'),
        Staff(
            id: 'home',
            name: 'Home',
            email: '',
            phoneNumber: '',
            department: 'Tech',
            role: '',
            joinDate: '',
            status: 'active',
            onLeaveToday: false,
            workMode: 'WFH'),
        Staff(
            id: 'other',
            name: 'Other',
            email: '',
            phoneNumber: '',
            department: 'Design',
            role: '',
            joinDate: '',
            status: 'inactive',
            onLeaveToday: false,
            workMode: 'WFH'),
        Staff(
            id: 'leave',
            name: 'Leave',
            email: '',
            phoneNumber: '',
            department: 'Tech',
            role: '',
            joinDate: '',
            status: 'on_leave',
            onLeaveToday: true,
            workMode: 'WFH'),
        Staff(
            id: 'resigned',
            name: 'Resigned',
            email: '',
            phoneNumber: '',
            department: 'Tech',
            role: '',
            joinDate: '',
            status: 'resigned',
            onLeaveToday: false,
            workMode: 'WFH'),
      ];

    expect(provider.filteredEmployeeList, hasLength(5));
    provider.setEmployeeWorkModeFilter('WFH');
    expect(provider.filteredEmployeeList.map((staff) => staff.id),
        ['home', 'other', 'leave', 'resigned']);
    provider.employeeDeptFilter = 'Tech';
    provider.employeeStatusFilter = 'active';
    expect(provider.filteredEmployeeList.map((staff) => staff.id), ['home']);
    provider.setEmployeeWorkModeFilter('Office');
    expect(provider.filteredEmployeeList.map((staff) => staff.id), ['office']);

    provider.employeeDeptFilter = 'all';
    provider.employeeStatusFilter = 'on_leave';
    provider.setEmployeeWorkModeFilter('WFH');
    expect(provider.filteredEmployeeList.map((staff) => staff.id), ['leave']);
    provider.employeeStatusFilter = 'resigned';
    expect(
        provider.filteredEmployeeList.map((staff) => staff.id), ['resigned']);
    provider.employeeStatusFilter = 'inactive';
    expect(provider.filteredEmployeeList.map((staff) => staff.id), ['other']);
    provider.employeeStatusFilter = 'active';
    provider.employeeSearchQuery = 'hom';
    provider.employeeDeptFilter = 'Tech';
    expect(provider.filteredEmployeeList.map((staff) => staff.id), ['home']);
  });

  testWidgets(
      'directory renders readable joining dates and five status choices',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());

    ApiService.client = MockClient((request) async {
      if (request.url.path == '/api/hr/departments') {
        return http.Response('{"data":[]}', 200);
      }
      return http.Response(
        jsonEncode({
          'data': [
            {
              '_id': 'join-iso',
              'firstName': 'ISO',
              'lastName': 'Employee',
              'department': 'Tech',
              'status': 'ACTIVE',
              'workMode': 'WFH',
              'joiningDate': '2026-11-12T07:17:54.059Z',
            },
            {
              '_id': 'join-null',
              'firstName': 'Null',
              'lastName': 'Employee',
              'department': 'Tech',
              'status': 'INACTIVE',
              'workMode': 'Office',
              'joiningDate': null,
            },
            {
              '_id': 'join-invalid',
              'firstName': 'Invalid',
              'lastName': 'Employee',
              'department': 'Tech',
              'status': 'ON_LEAVE',
              'workMode': 'WFH',
              'joiningDate': 'not-a-date',
            },
          ],
          'pagination': {'page': 1, 'limit': 20, 'total': 3, 'totalPages': 1}
        }),
        200,
      );
    });

    final provider = HRProvider();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: EmployeesView()),
    ));
    await tester.pumpAndSettle();

    final directoryTable = tester.widget<DataTable>(find.byType(DataTable));
    expect((directoryTable.rows[0].cells[5].child as Text).data, '12 Nov 2026');
    expect((directoryTable.rows[1].cells[5].child as Text).data, '—');
    expect((directoryTable.rows[2].cells[5].child as Text).data, '—');
    expect(
        provider.employeeDirectory.first.joinDate, '2026-11-12T07:17:54.059Z');
    expect(find.text('12 Nov 2026'), findsOneWidget);
    expect(find.text('2026-11-12T07:17:54.059Z'), findsNothing);
    expect(find.text('not-a-date'), findsNothing);

    final statusDropdown = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byKey(const ValueKey('employee_status_filter_all')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(statusDropdown.items, hasLength(5));
    expect(statusDropdown.items!.map((item) => item.value), [
      'all',
      'active',
      'inactive',
      'on_leave',
      'resigned',
    ]);
    expect(statusDropdown.items!.any((item) => item.value == 'terminated'),
        isFalse);
  });

  testWidgets('directory displays server empty state after loading',
      (tester) async {
    ApiService.client = MockClient((_) async => http.Response(
        jsonEncode({
          'data': [],
          'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0}
        }),
        200));
    final provider = HRProvider();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: EmployeesView()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No employees match criteria'), findsOneWidget);
  });

  test(
      'GET API success correctly parses real Audit Tester records from database',
      () async {
    ApiService.setToken('test-auth-token');
    ApiService.client = MockClient((r) async {
      return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Employees fetched successfully',
            'data': [
              {
                '_id': '6ad1ce90e73a4bf0f8532f6c',
                'employeeId': 'AUDIT5730',
                'firstName': 'Audit',
                'lastName': 'Tester',
                'email': 'audit.test.1792134799901@hrmanagement.com',
                'phone': '+19876543210',
                'department': 'Tech',
                'designation': 'Lead QA Automation Engineer',
                'status': 'ACTIVE',
                'salary': 82000,
                'salaryCurrency': 'INR',
                'workMode': 'Office',
              },
              {
                '_id': '6ad1ce09e73a4bf0f8532f00',
                'employeeId': 'AUDIT6443',
                'firstName': 'Audit',
                'lastName': 'Tester',
                'email': 'audit.test.1792134664878@hrmanagement.com',
                'phone': '+19876543210',
                'department': 'Tech',
                'designation': 'Lead QA Automation Engineer',
                'status': 'ACTIVE',
                'salary': 82000,
                'salaryCurrency': 'INR',
                'workMode': 'Office',
              },
              {
                '_id': '6ad1cda5e73a4bf0f8532ea7',
                'employeeId': 'AUDIT4725',
                'firstName': 'Audit',
                'lastName': 'Tester',
                'email': 'audit.test.1792134565233@hrmanagement.com',
                'phone': '+19876543210',
                'department': 'Tech',
                'designation': 'Lead QA Automation Engineer',
                'status': 'ACTIVE',
                'salary': 82000,
                'salaryCurrency': 'INR',
                'workMode': 'Office',
              }
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 3, 'totalPages': 1}
          }),
          200);
    });

    final page = await ApiService.getEmployeePage();
    expect(page.total, 3);
    expect(page.employees.length, 3);
    expect(page.employees.every((e) => e.name == 'Audit Tester'), isTrue);
    expect(page.employees[0].id, '6ad1ce90e73a4bf0f8532f6c');
    expect(page.employees[0].department, 'Tech');
    expect(page.employees[0].salary, 82000.0);
  });

  testWidgets(
      'API failure displays error and Retry button without falling back to mock employees',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool shouldFail = true;
    ApiService.setToken('test-auth-token');
    ApiService.client = MockClient((r) async {
      if (shouldFail) {
        return http.Response(
            jsonEncode({'message': 'Database connection refused'}), 503);
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'rec-1',
                'firstName': 'Real',
                'lastName': 'Employee',
                'email': 'real@lysoftware.com',
                'department': 'Tech',
                'designation': 'Engineer',
                'status': 'ACTIVE',
                'salary': 50000,
              }
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1}
          }),
          200);
    });

    final provider = HRProvider();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: EmployeesView()),
    ));
    await tester.pumpAndSettle();

    // Must NOT show mock employees (Anita Rao, Arjun Desai)
    expect(find.text('Anita Rao'), findsNothing);
    expect(find.text('Arjun Desai'), findsNothing);
    expect(provider.filteredEmployeeList, isEmpty);

    // Must show error message and Retry action
    expect(find.text('Database connection refused'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Tap Retry after server recovers
    shouldFail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    // Now renders the recovered real API employee
    expect(find.text('Real Employee'), findsOneWidget);
    expect(find.text('real@lysoftware.com'), findsOneWidget);
    expect(find.text('Anita Rao'), findsNothing);
  });

  test('mutation failure in editStaff does not report success or fake update',
      () async {
    ApiService.setToken('test-token');
    ApiService.client = MockClient((r) async {
      if (r.method == 'PUT') {
        return http.Response(
            jsonEncode({'message': 'Invalid department for employee'}), 400);
      }
      return http.Response(
          jsonEncode({
            'data': [
              {
                '_id': 'emp-1',
                'firstName': 'John',
                'lastName': 'Doe',
                'department': 'Tech',
                'status': 'ACTIVE',
              }
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1}
          }),
          200);
    });

    final provider = HRProvider();
    await provider.loadEmployeeDirectory();
    expect(provider.employeeDirectory.single.name, 'John Doe');

    // Attempt invalid edit
    final success = await provider.updateStaff('emp-1', {
      'name': 'John Doe Changed',
      'department': 'UnsupportedDept',
    });

    expect(success, isFalse);
    expect(provider.apiStaffError, contains('Invalid department'));
  });
}
