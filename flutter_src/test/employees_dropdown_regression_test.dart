import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:ly_hr_dashboard_flutter/core/department_helper.dart';
import 'package:ly_hr_dashboard_flutter/features/employees/employees_view.dart';
import 'package:ly_hr_dashboard_flutter/models/department.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/widgets/modals.dart';

void main() {
  setUp(() {
    ApiService.setTokens(accessToken: 'mock_test_token_regression');
    ApiService.client = MockClient((request) async {
      if (request.url.path.contains('/api/hr/employees')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'emp_1',
                'name': 'Anita Rao',
                'email': 'anita@company.com',
                'phone': '9876543210',
                'department': 'Tech',
                'role': 'HR Manager',
                'designation': 'Lead HR Manager',
                'status': 'active',
                'workMode': 'Office',
                'salary': 85000,
                'salaryCurrency': 'INR',
                'joiningDate': '2024-01-15',
              },
              {
                'id': 'emp_2',
                'name': 'Vikram Patel',
                'email': 'vikram@company.com',
                'phone': '9876543211',
                'department': 'Telecalling',
                'role': 'Staff',
                'designation': 'Telecaller Specialist',
                'status': 'active',
                'workMode': 'Office',
                'salary': 35000,
                'salaryCurrency': 'INR',
                'joiningDate': '2024-02-01',
              },
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 2,
              'totalPages': 1,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/hr/departments') {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'deptKey': 'tech',
                'title': 'Tech',
                'subtitle': 'Frontend, Backend, Infrastructure & QA',
                'staffCount': 10,
                'activeCount': 9,
                'leadName': 'Anita Rao',
                'icon': 'computer',
                'color': '#2563EB',
              },
              {
                'deptKey': 'telecalling',
                'title': 'Telecalling',
                'subtitle': 'Outreach & Relations',
                'staffCount': 8,
                'activeCount': 8,
                'leadName': 'Neha Sharma',
                'icon': 'headset_mic',
                'color': '#DB2777',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"success": true}', 200,
          headers: {'content-type': 'application/json'});
    });
  });

  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  Widget buildTestableWidget(HRProvider provider, Widget child) {
    return ChangeNotifierProvider<HRProvider>.value(
      value: provider,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('DepartmentHelper Unit Tests', () {
    test('deduplicateDepartments eliminates duplicates by deptKey and title',
        () {
      final input = [
        const Department(deptKey: 'tech', title: 'Tech'),
        const Department(deptKey: 'tech', title: 'Tech'),
        const Department(deptKey: 'tech_dup', title: 'Tech'),
        const Department(deptKey: 'tech', title: 'Different Title'),
        const Department(deptKey: 'telecalling', title: 'Telecalling'),
      ];

      final result = DepartmentHelper.deduplicateDepartments(input);
      expect(result.length, 2);
      expect(result[0].deptKey, 'tech');
      expect(result[0].title, 'Tech');
      expect(result[1].deptKey, 'telecalling');
      expect(result[1].title, 'Telecalling');
    });

    test(
        'areSameDepartment normalizes Tech & Engineering and Telecalling variants',
        () {
      expect(DepartmentHelper.areSameDepartment('Tech', 'Tech & Engineering'),
          isTrue);
      expect(DepartmentHelper.areSameDepartment('tech & engineering', 'tech'),
          isTrue);
      expect(DepartmentHelper.areSameDepartment('Engineering', 'Tech'), isTrue);
      expect(
          DepartmentHelper.areSameDepartment(
              'Telecalling', 'Telecalling & Client Relations'),
          isTrue);
      expect(
          DepartmentHelper.areSameDepartment('Operations', 'Finance'), isFalse);
    });

    test('toSupportedCanonicalName canonicalizes variants and preserves legacy',
        () {
      expect(DepartmentHelper.toSupportedCanonicalName('Tech & Engineering'),
          'Tech');
      expect(DepartmentHelper.toSupportedCanonicalName('tech'), 'Tech');
      expect(
          DepartmentHelper.toSupportedCanonicalName(
              'Telecalling & Client Relations'),
          'Telecalling');
      expect(DepartmentHelper.toSupportedCanonicalName('telecalling'),
          'Telecalling');
      expect(DepartmentHelper.toSupportedCanonicalName('Operations'),
          'Operations');
      expect(DepartmentHelper.toSupportedCanonicalName('Finance'), 'Finance');
    });

    test(
        'buildFilterDropdown strictly contains only All Departments, Tech, and Telecalling',
        () {
      const depts = [
        Department(deptKey: 'tech', title: 'Tech'),
        Department(deptKey: 'telecalling', title: 'Telecalling'),
        Department(deptKey: 'design', title: 'Design'),
        Department(deptKey: 'marketing', title: 'Marketing'),
        Department(deptKey: 'hr', title: 'Human Resources'),
      ];

      final res = DepartmentHelper.buildFilterDropdown(
        currentValue: 'Tech',
        departments: depts,
      );
      expect(res.value, 'Tech');
      expect(res.items.map((i) => i.value).toList(),
          ['all', 'Tech', 'Telecalling']);
      expect(res.items.where((i) => i.value == res.value).length, 1);
    });

    test('buildFilterDropdown normalizes Tech & Engineering variant to Tech',
        () {
      const depts = [
        Department(deptKey: 'tech', title: 'Tech & Engineering'),
        Department(
            deptKey: 'telecalling', title: 'Telecalling & Client Relations'),
      ];

      final res = DepartmentHelper.buildFilterDropdown(
        currentValue: 'Tech & Engineering',
        departments: depts,
      );
      expect(res.value, 'Tech');
      expect(res.items.where((i) => i.value == res.value).length, 1);
    });

    test('buildFilterDropdown normalizes Telecalling variant to Telecalling',
        () {
      const depts = [
        Department(deptKey: 'tech', title: 'Tech'),
        Department(
            deptKey: 'telecalling', title: 'Telecalling & Client Relations'),
      ];

      final res = DepartmentHelper.buildFilterDropdown(
        currentValue: 'Telecalling & Client Relations',
        departments: depts,
      );
      expect(res.value, 'Telecalling');
      expect(res.items.where((i) => i.value == res.value).length, 1);
    });

    test(
        'buildFilterDropdown falls back safely to all on missing or unsupported department',
        () {
      final res = DepartmentHelper.buildFilterDropdown(
        currentValue: 'Custom Missing Dept',
        departments: const [],
      );
      expect(res.value, 'all');
      expect(res.items.map((i) => i.value).toList(),
          ['all', 'Tech', 'Telecalling']);
      expect(res.items.where((i) => i.value == res.value).length, 1);
    });

    test(
        'buildFormDepartmentDropdown offers strictly Tech and Telecalling for new staff',
        () {
      final res = DepartmentHelper.buildFormDepartmentDropdown(
        currentValue: 'Tech',
        departments: const [
          Department(deptKey: 'tech', title: 'Tech'),
          Department(deptKey: 'telecalling', title: 'Telecalling'),
          Department(deptKey: 'ops', title: 'Operations'),
        ],
      );
      expect(res.value, 'Tech');
      expect(res.items.map((i) => i.value).toList(), ['Tech', 'Telecalling']);
      expect(res.items.where((i) => i.value == res.value).length, 1);
    });

    test(
        'buildFormDepartmentDropdown preserves legacy department with (Legacy) label without mutating',
        () {
      final res = DepartmentHelper.buildFormDepartmentDropdown(
        currentValue: 'Operations',
        departments: const [],
      );
      expect(res.value, 'Operations');
      expect(res.items.map((i) => i.value).toList(),
          ['Tech', 'Telecalling', 'Operations']);
      expect(res.items.last.child, isA<Text>());
      expect((res.items.last.child as Text).data, 'Operations (Legacy)');
      expect(res.items.where((i) => i.value == res.value).length, 1);
    });
  });

  group('Employees Screen Dropdown Regression Tests', () {
    testWidgets(
        '1. Selected department that exists exactly once renders without assertion',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.departments = const [
        Department(deptKey: 'tech', title: 'Tech'),
        Department(deptKey: 'telecalling', title: 'Telecalling'),
      ];
      provider.setEmployeeDeptFilter('Tech');

      await tester
          .pumpWidget(buildTestableWidget(provider, const EmployeesView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Department'), findsWidgets);
      expect(find.text('Tech'), findsWidgets);
    });

    testWidgets(
        '2. Selected department missing from API response is handled safely without assertion',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      // API response only contains Telecalling, 'Tech' is missing from API
      provider.departments = const [
        Department(deptKey: 'telecalling', title: 'Telecalling'),
      ];
      provider.setEmployeeDeptFilter('Tech');

      await tester
          .pumpWidget(buildTestableWidget(provider, const EmployeesView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Department'), findsWidgets);
      expect(find.text('Tech'), findsWidgets);
    });

    testWidgets(
        '3. Duplicate department values from API are deduplicated without assertion',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      // Duplicate entries for Tech
      provider.departments = DepartmentHelper.deduplicateDepartments(const [
        Department(deptKey: 'tech', title: 'Tech'),
        Department(deptKey: 'tech', title: 'Tech'),
        Department(deptKey: 'tech_dup', title: 'Tech'),
        Department(deptKey: 'telecalling', title: 'Telecalling'),
      ]);
      expect(provider.departments.length, 2);

      provider.setEmployeeDeptFilter('Tech');

      await tester
          .pumpWidget(buildTestableWidget(provider, const EmployeesView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tech'), findsWidgets);
    });

    testWidgets(
        '4. Empty department lists fall back to valid selection without assertion',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.departments = const [];
      provider.setEmployeeDeptFilter('all');

      await tester
          .pumpWidget(buildTestableWidget(provider, const EmployeesView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('All Departments'), findsWidgets);
    });

    testWidgets(
        '5. Opening Employees screen after Super Admin login does not trigger assertion error',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'super_admin_jwt_token',
                'refreshToken': 'super_admin_refresh_token',
                'user': {
                  'id': 'super_admin_1',
                  'name': 'Super Administrator',
                  'email': 'lysoftware@gmail.com',
                  'role': 'SUPER_ADMIN',
                  'department': 'Tech',
                  'isActive': true,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/api/hr/departments')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'deptKey': 'tech',
                  'title': 'Tech',
                  'staffCount': 12,
                  'activeCount': 11,
                  'leadName': 'Anita Rao',
                  'icon': 'computer',
                  'color': '#2563EB',
                },
                {
                  'deptKey': 'telecalling',
                  'title': 'Telecalling',
                  'staffCount': 8,
                  'activeCount': 8,
                  'leadName': 'Neha Sharma',
                  'icon': 'headset_mic',
                  'color': '#DB2777',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/api/hr/employees')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'staff_1',
                  'name': 'Anita Rao',
                  'email': 'anita@company.com',
                  'phone': '9876543210',
                  'department': 'Tech',
                  'role': 'HR Manager',
                  'designation': 'Lead HR Manager',
                  'status': 'active',
                  'workMode': 'Office',
                  'salary': 85000,
                  'salaryCurrency': 'INR',
                  'joiningDate': '2024-01-15',
                },
              ],
              'pagination': {
                'page': 1,
                'limit': 20,
                'total': 1,
                'totalPages': 1
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": true}', 200,
            headers: {'content-type': 'application/json'});
      });

      final provider = HRProvider();
      final loginSuccess =
          await provider.loginWithApi('lysoftware@gmail.com', 'hrAdmin');
      expect(loginSuccess, isTrue);
      expect(provider.isSuperAdmin, isTrue);

      provider.navigateToEmployees(deptFilter: 'Tech');
      expect(provider.currentScreen, 'employees');
      expect(provider.employeeDeptFilter, 'Tech');

      await tester
          .pumpWidget(buildTestableWidget(provider, const EmployeesView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Employee Directory'), findsOneWidget);
      expect(find.text('LY SOFTWARE • PEOPLE DIRECTORY'), findsOneWidget);
      expect(find.text('Tech'), findsWidgets);
    });

    testWidgets(
        '6. Form dropdown in Add Staff modal offers strictly Tech and Telecalling',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.departments = const [
        Department(deptKey: 'tech', title: 'Tech'),
        Department(deptKey: 'telecalling', title: 'Telecalling'),
        Department(deptKey: 'ops', title: 'Operations'),
        Department(deptKey: 'fin', title: 'Finance'),
      ];

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showAddStaffModal(context),
                  child: const Text('Open Add Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Add Modal'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add New Staff Member'), findsOneWidget);
      expect(find.text('Tech'), findsOneWidget);
      // Ensure other departments like Operations/Finance/Design do not appear
      expect(find.text('Operations'), findsNothing);
      expect(find.text('Finance'), findsNothing);
      expect(find.text('Design'), findsNothing);
    });

    testWidgets('7. Selecting Tech sends Tech to API on employee creation',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late http.Request sentRequest;
      ApiService.setTokens(accessToken: 'mock_token');
      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/api/hr/employees')) {
          sentRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'new_1',
                'firstName': 'Tech',
                'lastName': 'Dev',
                'department': 'Tech'
              }
            }),
            201,
          );
        }
        return http.Response('{"success": true}', 200);
      });

      final provider = HRProvider();
      final success = await provider.addStaff({
        'name': 'Tech Developer',
        'email': 'tech.dev@company.com',
        'phoneNumber': '9876500099',
        'department': 'Tech',
        'designation': 'Software Engineer',
      });

      expect(success, isTrue);
      final body = jsonDecode(sentRequest.body);
      expect(body['department'], 'Tech');
    });

    testWidgets(
        '8. Selecting Telecalling sends Telecalling to API on employee creation',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late http.Request sentRequest;
      ApiService.setTokens(accessToken: 'mock_token');
      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/api/hr/employees')) {
          sentRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'new_2',
                'firstName': 'Tele',
                'lastName': 'Caller',
                'department': 'Telecalling'
              }
            }),
            201,
          );
        }
        return http.Response('{"success": true}', 200);
      });

      final provider = HRProvider();
      final success = await provider.addStaff({
        'name': 'Tele Caller',
        'email': 'tele.caller@company.com',
        'phoneNumber': '9876500098',
        'department': 'Telecalling',
        'designation': 'Support Agent',
      });

      expect(success, isTrue);
      final body = jsonDecode(sentRequest.body);
      expect(body['department'], 'Telecalling');
    });

    testWidgets(
        '9. Editing employee with legacy department preserves legacy department with (Legacy) label',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.departments = const [
        Department(deptKey: 'tech', title: 'Tech'),
        Department(deptKey: 'telecalling', title: 'Telecalling'),
      ];

      final legacyEmployee = Staff(
        id: 'emp_legacy_1',
        name: 'Legacy Member',
        email: 'legacy@company.com',
        phoneNumber: '9876543299',
        department: 'Operations',
        role: 'Staff',
        joinDate: '2024-01-15',
        status: 'active',
        onLeaveToday: false,
        designation: 'Operations Coordinator',
        workMode: 'Office',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      Modals.showEditStaffModal(context, legacyEmployee),
                  child: const Text('Open Edit Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Modal'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Edit Staff Details'), findsOneWidget);
      // Legacy department is preserved and clearly labeled
      expect(find.text('Operations (Legacy)'), findsOneWidget);
      // Existing employee record remains unmodified
      expect(legacyEmployee.department, 'Operations');
    });

    testWidgets(
        '10. Filtering by department does not mutate existing employee records',
        (tester) async {
      final provider = HRProvider();
      final employee1 = Staff(
        id: 'emp_1',
        name: 'Alice',
        email: 'alice@company.com',
        phoneNumber: '9111111111',
        department: 'Tech',
        role: 'Staff',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      );
      final employee2 = Staff(
        id: 'emp_2',
        name: 'Bob',
        email: 'bob@company.com',
        phoneNumber: '9222222222',
        department: 'Telecalling',
        role: 'Staff',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      );
      final employee3 = Staff(
        id: 'emp_3',
        name: 'Charlie',
        email: 'charlie@company.com',
        phoneNumber: '9333333333',
        department: 'Operations',
        role: 'Staff',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
      );

      provider.staffList = [employee1, employee2, employee3];

      // Switch filters between all, Tech, and Telecalling
      provider.setEmployeeDeptFilter('Tech');
      expect(provider.staffList[0].department, 'Tech');
      expect(provider.staffList[1].department, 'Telecalling');
      expect(provider.staffList[2].department, 'Operations');

      provider.setEmployeeDeptFilter('Telecalling');
      expect(provider.staffList[0].department, 'Tech');
      expect(provider.staffList[1].department, 'Telecalling');
      expect(provider.staffList[2].department, 'Operations');

      provider.setEmployeeDeptFilter('all');
      expect(provider.staffList[0].department, 'Tech');
      expect(provider.staffList[1].department, 'Telecalling');
      expect(provider.staffList[2].department, 'Operations');
    });
  });
}
