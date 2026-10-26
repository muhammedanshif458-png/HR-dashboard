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

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
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
