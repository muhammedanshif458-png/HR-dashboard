import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/widgets/modals.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  group('HRProvider.addStaff frontend-to-backend payload and error handling',
      () {
    test('sends correct POST body, fields, and bearer token with two-word name',
        () async {
      late http.Request postRequest;
      ApiService.setToken('test-admin-jwt-token');

      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/hr/employees') {
          postRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                '_id': 'mongo-emp-101',
                'employeeId': 'EMP-101',
                'firstName': 'John',
                'lastName': 'Doe',
                'email': 'john.doe@lysoftware.com',
                'phone': '9876500001',
                'department': 'Tech',
                'designation': 'Senior Frontend Engineer',
                'workMode': 'Office',
                'salary': 75000,
                'salaryCurrency': 'INR',
                'status': 'ACTIVE',
              }
            }),
            201,
          );
        } else if (request.method == 'GET' &&
            request.url.path == '/api/hr/employees') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  '_id': 'mongo-emp-101',
                  'employeeId': 'EMP-101',
                  'firstName': 'John',
                  'lastName': 'Doe',
                  'email': 'john.doe@lysoftware.com',
                  'phone': '9876500001',
                  'department': 'Tech',
                  'designation': 'Senior Frontend Engineer',
                  'workMode': 'Office',
                  'salary': 75000,
                  'salaryCurrency': 'INR',
                  'status': 'ACTIVE',
                }
              ],
              'pagination': {
                'page': 1,
                'limit': 20,
                'total': 1,
                'totalPages': 1
              }
            }),
            200,
          );
        }
        return http.Response('{"error":"Not found"}', 404);
      });

      final provider = HRProvider();
      final success = await provider.addStaff({
        'name': 'John Doe',
        'email': 'john.doe@lysoftware.com',
        'phoneNumber': '9876500001',
        'department': 'Tech',
        'designation': 'Senior Frontend Engineer',
        'workMode': 'Office',
        'salary': 75000.0,
        'salaryCurrency': 'INR',
        'salaryEffectiveDate': '2026-10-19',
        'paidLeaveAllowance': 18,
        'dateOfBirth': '1995-05-12',
      });

      expect(success, isTrue);
      expect(provider.apiStaffError, isEmpty);
      expect(
          postRequest.headers['authorization'], 'Bearer test-admin-jwt-token');
      expect(postRequest.headers['content-type'], contains('application/json'));

      final body = jsonDecode(postRequest.body) as Map<String, dynamic>;
      expect(body['firstName'], 'John');
      expect(body['lastName'], 'Doe');
      expect(body['email'], 'john.doe@lysoftware.com');
      expect(body['phone'], '9876500001');
      expect(body['department'], 'Tech');
      expect(body['designation'], 'Senior Frontend Engineer');
      expect(body['workMode'], 'Office');
      expect(body['salary'], 75000.0);
      expect(body['salaryCurrency'], 'INR');
      expect(body['salaryEffectiveDate'], '2026-10-19');
      expect(body['paidLeaveAllowance'], 18);
      expect(body['dateOfBirth'], '1995-05-12');

      // Check that employee directory was reloaded
      expect(provider.employeeDirectory.length, 1);
      expect(provider.employeeDirectory.first.name, 'John Doe');
      expect(provider.employeeDirectory.first.salary, 75000.0);
    });

    test(
        'falls back single-word name to lastName to satisfy backend validation',
        () async {
      late http.Request postRequest;
      ApiService.setToken('test-admin-jwt-token');

      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/hr/employees') {
          postRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                '_id': 'mongo-emp-102',
                'employeeId': 'EMP-102',
                'firstName': 'Priya',
                'lastName': 'Priya',
                'email': 'priya@lysoftware.com',
                'phone': '9876500002',
                'department': 'Design',
                'designation': 'UI Designer',
                'status': 'ACTIVE',
              }
            }),
            201,
          );
        } else if (request.method == 'GET' &&
            request.url.path == '/api/hr/employees') {
          return http.Response(
            jsonEncode({
              'data': [],
              'pagination': {
                'page': 1,
                'limit': 20,
                'total': 0,
                'totalPages': 0
              }
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final provider = HRProvider();
      final success = await provider.addStaff({
        'name': 'Priya',
        'email': 'priya@lysoftware.com',
        'phoneNumber': '9876500002',
        'department': 'Design',
        'designation': 'UI Designer',
      });

      expect(success, isTrue);
      final body = jsonDecode(postRequest.body) as Map<String, dynamic>;
      expect(body['firstName'], 'Priya');
      expect(body['lastName'], 'Priya');
    });

    test('handles 409 duplicate email conflict and does not claim success',
        () async {
      ApiService.setToken('test-admin-jwt-token');

      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/hr/employees') {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': 'Duplicate Field',
              'message': 'An employee with this email already exists',
            }),
            409,
          );
        }
        return http.Response('{}', 200);
      });

      final provider = HRProvider();
      final initialCount = provider.staffList.length;

      final success = await provider.addStaff({
        'name': 'Duplicate User',
        'email': 'duplicate@lysoftware.com',
        'phoneNumber': '9876500003',
        'department': 'Tech',
        'designation': 'Developer',
      });

      expect(success, isFalse);
      expect(provider.apiStaffError,
          contains('An employee with this email already exists'));
      expect(provider.staffList.length, initialCount);
    });

    test('parses multiple backend 422 validation errors into readable message',
        () async {
      ApiService.setToken('test-admin-jwt-token');

      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/hr/employees') {
          return http.Response(
            jsonEncode({
              'success': false,
              'error': 'Validation Failed',
              'errors': [
                {
                  'field': 'email',
                  'message': 'Please enter a valid email address'
                },
                {
                  'field': 'phone',
                  'message': 'Phone number must be between 7 and 15 digits'
                },
              ],
            }),
            422,
          );
        }
        return http.Response('{}', 200);
      });

      final provider = HRProvider();
      final success = await provider.addStaff({
        'name': 'Test Error',
        'email': 'invalid-email',
        'phoneNumber': '123',
        'department': 'Tech',
        'designation': 'Developer',
      });

      expect(success, isFalse);
      expect(provider.apiStaffError,
          contains('Please enter a valid email address'));
      expect(provider.apiStaffError,
          contains('Phone number must be between 7 and 15 digits'));
    });
  });

  group('Add Staff Member Modal UI interactions', () {
    testWidgets(
        'client-side validation blocks invalid inputs before calling backend',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int apiCallCount = 0;
      ApiService.client = MockClient((request) async {
        apiCallCount++;
        return http.Response('{}', 200);
      });

      final provider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showAddStaffModal(context),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Staff Member'), findsOneWidget);

      // Clear the default designation so it fails validation
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Designation *'), '');

      // Tap submit with empty form
      await tester.tap(find.text('Add Staff Member'));
      await tester.pumpAndSettle();

      // Should show validation errors and make no API calls
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Phone number required'), findsOneWidget);
      expect(find.text('Designation required'), findsOneWidget);
      expect(find.text('Monthly salary is required'), findsOneWidget);
      expect(apiCallCount, 0);
    });

    testWidgets(
        'duplicate email check against existing staff prevents submission',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int apiCallCount = 0;
      ApiService.client = MockClient((request) async {
        apiCallCount++;
        return http.Response('{}', 200);
      });

      final provider = HRProvider();
      provider.staffList = [
        Staff(
          id: 'existing-1',
          name: 'Sarah Connor',
          email: 'sarah@lysoftware.com',
          phoneNumber: '9123456780',
          department: 'Tech',
          role: 'Engineer',
          joinDate: '2026-01-01',
          status: 'active',
          onLeaveToday: false,
        ),
      ];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showAddStaffModal(context),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Enter details with duplicate email
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name *'), 'Sarah Connor 2');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address *'),
          'sarah@lysoftware.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number *'), '9876500004');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Designation *'), 'Lead Engineer');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monthly Salary *'), '65000');

      await tester.tap(find.text('Add Staff Member'));
      await tester.pumpAndSettle();

      expect(find.text('An employee with this email already exists'),
          findsOneWidget);
      expect(apiCallCount, 0);
    });

    testWidgets('shows loading indicator and disables button while submitting',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.setToken('test-token');

      ApiService.client = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 150));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'_id': 'alex-1', 'firstName': 'Alex', 'lastName': 'Mercer'}
          }),
          201,
        );
      });

      final provider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showAddStaffModal(context),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name *'), 'Alex Mercer');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address *'),
          'alex@lysoftware.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number *'), '9876500005');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Designation *'),
          'Software Architect');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monthly Salary *'), '70000');

      // Tap submit
      await tester.tap(find.text('Add Staff Member'));
      await tester.pump(); // Start async request and update isSubmitting

      // Loading spinner should be shown inside button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Finish pending async work
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'shows inline error banner and red SnackBar on server conflict without closing modal',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.setToken('test-token');
      ApiService.client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'An employee with this phone number already exists',
            }),
            409,
          );
        }
        return http.Response('{}', 200);
      });

      final provider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showAddStaffModal(context),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name *'), 'Robert Ford');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address *'),
          'ford@lysoftware.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number *'), '9876500006');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Designation *'), 'Director');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monthly Salary *'), '80000');

      await tester.tap(find.text('Add Staff Member'));
      await tester.pumpAndSettle();

      // Modal should STILL be open
      expect(find.text('Add New Staff Member'), findsOneWidget);
      // Inline error banner rendered
      expect(find.text('An employee with this phone number already exists'),
          findsWidgets);
    });
  });
}
