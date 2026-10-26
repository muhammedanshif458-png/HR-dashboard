import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/widgets/modals.dart';
import 'package:provider/provider.dart';

void main() {
  group('Staff Account Creation & Authentication Tests', () {
    late HRProvider hrProvider;

    setUp(() {
      hrProvider = HRProvider();
      ApiService.clearTokens();
    });

    test('Staff login sets current user and routes to staff-portal', () {
      final staffUserMap = {
        'id': 'user_staff_01',
        'firstName': 'John',
        'lastName': 'Staff',
        'email': 'john.staff@company.com',
        'role': 'STAFF',
        'department': 'Tech',
        'designation': 'Software Engineer',
        'employee': {
          '_id': 'emp_staff_01',
          'department': 'Tech',
          'designation': 'Software Engineer',
          'phone': '9876543210',
          'salary': 60000.0,
          'salaryCurrency': 'INR',
          'workMode': 'Office',
        }
      };

      // Set user role as STAFF
      ApiService.setUserRole('STAFF');
      expect(ApiService.isStaffRole, isTrue);
      expect(ApiService.isHrAdminRole, isFalse);

      // Verify Staff model construction
      final empData = staffUserMap['employee'] as Map<String, dynamic>;
      final staff = Staff(
        id: empData['_id'] as String,
        name: '${staffUserMap['firstName']} ${staffUserMap['lastName']}',
        email: staffUserMap['email'] as String,
        phoneNumber: (empData['phone'] as String?) ?? '',
        department: empData['department'] as String,
        role: 'Staff',
        joinDate: '2026-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: empData['designation'] as String,
        workMode: empData['workMode'] as String,
        salary: empData['salary'] as double,
      );

      hrProvider.setCurrentUserForTesting(staff);
      expect(hrProvider.isStaffUser, isTrue);
      expect(hrProvider.isHRAdmin, isFalse);
      expect(hrProvider.isSuperAdmin, isFalse);

      // Staff cannot navigate to administrative screens
      hrProvider.setScreen('hr-dashboard');
      expect(hrProvider.currentScreen, equals('staff-portal'));

      hrProvider.setScreen('employees');
      expect(hrProvider.currentScreen, equals('staff-portal'));

      hrProvider.setScreen('payroll');
      expect(hrProvider.currentScreen, equals('staff-portal'));

      // Staff can navigate to allowed staff screens
      hrProvider.setScreen('dept-chat');
      expect(hrProvider.currentScreen, equals('dept-chat'));

      hrProvider.setScreen('chat');
      expect(hrProvider.currentScreen, equals('chat'));
    });

    test('Super Admin login sets Super Admin role and routes to hr-dashboard', () {
      final superAdmin = Staff(
        id: 'sa_user_01',
        name: 'Super Admin',
        email: 'lysoftware@gmail.com',
        phoneNumber: '9999999999',
        department: 'Executive Management',
        role: 'Super Admin',
        joinDate: '2026-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Super Administrator',
        workMode: 'Office',
      );

      ApiService.setUserRole('SUPER_ADMIN');
      hrProvider.setCurrentUserForTesting(superAdmin);

      expect(hrProvider.isSuperAdmin, isTrue);
      expect(hrProvider.isHRAdmin, isTrue);
      expect(hrProvider.isStaffUser, isFalse);

      hrProvider.setScreen('hr-dashboard');
      expect(hrProvider.currentScreen, equals('hr-dashboard'));

      hrProvider.setScreen('employees');
      expect(hrProvider.currentScreen, equals('employees'));
    });

    testWidgets('Add Staff Modal displays password fields with visibility toggle', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: hrProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showAddStaffModal(context),
                  child: const Text('Open Add Staff'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Add Staff'));
      await tester.pumpAndSettle();

      // Verify modal and password fields exist
      expect(find.text('Add New Staff Member'), findsOneWidget);
      final passwordFinder = find.byKey(const Key('add_staff_password_field'));
      final confirmPasswordFinder = find.byKey(const Key('add_staff_confirm_password_field'));

      expect(passwordFinder, findsOneWidget);
      expect(confirmPasswordFinder, findsOneWidget);

      // Verify fields are obscured by default
      final passwordEditable = find.descendant(of: passwordFinder, matching: find.byType(EditableText));
      expect(tester.widget<EditableText>(passwordEditable).obscureText, isTrue);

      final confirmPasswordEditable = find.descendant(of: confirmPasswordFinder, matching: find.byType(EditableText));
      expect(tester.widget<EditableText>(confirmPasswordEditable).obscureText, isTrue);

      // Test validation: enter short password
      await tester.enterText(passwordFinder, '123');
      await tester.tap(find.text('Add Staff Member'));
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Test validation: enter valid password but mismatching confirm
      await tester.enterText(passwordFinder, 'ValidPassword123');
      await tester.enterText(confirmPasswordFinder, 'DifferentPassword');
      await tester.tap(find.text('Add Staff Member'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Edit Staff Modal has empty password fields by default and preserves password', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final existingStaff = Staff(
        id: '673f1234567890abcdef1234',
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
        phoneNumber: '9876543210',
        department: 'Tech',
        role: 'Staff',
        joinDate: '2026-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Frontend Engineer',
        workMode: 'Office',
        salary: 70000,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: hrProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showEditStaffModal(context, existingStaff),
                  child: const Text('Open Edit Staff'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Edit Staff'));
      await tester.pumpAndSettle();

      // Verify modal opened
      expect(find.text('Edit Staff Details'), findsOneWidget);

      final editPasswordFinder = find.byKey(const Key('edit_staff_password_field'));
      expect(editPasswordFinder, findsOneWidget);

      // Confirm New Password field MUST NOT exist
      expect(find.byKey(const Key('edit_staff_confirm_password_field')), findsNothing);
      expect(find.text('Confirm New Password'), findsNothing);

      // Verify redesigned Staff Login Password section
      expect(find.text('Staff Login Password'), findsOneWidget);
      expect(find.text('Replace Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Set New Password'), findsNothing);
      expect(find.text('Leave blank to keep current password'), findsNothing);

      // Verify helper text is displayed
      expect(find.text('Enter a new password to replace the current password. Leave blank to keep the existing password.'), findsOneWidget);

      // Verify password is NOT retrieved or displayed
      final editPasswordEditable = find.descendant(of: editPasswordFinder, matching: find.byType(EditableText));
      expect(tester.widget<EditableText>(editPasswordEditable).obscureText, isTrue);

      // Test validation: enter short password
      await tester.enterText(editPasswordFinder, '123');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Test validation: clear password (empty) -> validation passes without requiring password or confirmation
      await tester.enterText(editPasswordFinder, '');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsNothing);
      expect(find.text('Passwords do not match'), findsNothing);

      // Test validation: enter valid password (>= 6 chars) -> validation passes without requiring confirmation
      await tester.enterText(editPasswordFinder, 'ValidPassword123');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsNothing);
      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets('Edit Staff submission sends non-empty password in request payload to PUT /api/hr/employees/:id', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final existingStaff = Staff(
        id: '673f1234567890abcdef1234',
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
        phoneNumber: '9876543210',
        department: 'Tech',
        role: 'Staff',
        joinDate: '2026-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Frontend Engineer',
        workMode: 'Office',
        salary: 70000,
      );

      Map<String, dynamic>? capturedPayload;
      String? capturedPath;
      String? capturedAuthHeader;

      ApiService.setTokens(accessToken: 'super_admin_jwt_token');
      ApiService.setUserRole('SUPER_ADMIN');
      ApiService.client = MockClient((request) async {
        if (request.method == 'PUT') {
          if (request.url.path.endsWith('/673f1234567890abcdef1234')) {
            capturedPath = request.url.path;
            capturedAuthHeader = request.headers['authorization'];
            capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Employee updated successfully',
                'data': {
                  '_id': '673f1234567890abcdef1234',
                  'name': 'Jane Doe',
                  'email': 'jane.doe@example.com',
                  'department': 'Tech',
                  'designation': 'Frontend Engineer',
                  'status': 'ACTIVE',
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.contains('/salary')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Salary updated successfully',
                'data': {'_id': '673f1234567890abcdef1234'}
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        if (request.method == 'GET') {
          if (request.url.path.endsWith('/673f1234567890abcdef1234')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  '_id': '673f1234567890abcdef1234',
                  'name': 'Jane Doe',
                  'email': 'jane.doe@example.com',
                  'department': 'Tech',
                  'designation': 'Frontend Engineer',
                  'status': 'ACTIVE',
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": true}', 200, headers: {'content-type': 'application/json'});
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: hrProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showEditStaffModal(context, existingStaff),
                  child: const Text('Open Edit Staff'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Staff'));
      await tester.pumpAndSettle();

      final editPasswordFinder = find.byKey(const Key('edit_staff_password_field'));
      await tester.enterText(editPasswordFinder, 'NewSuperSecret@456');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(capturedPath, equals('/api/hr/employees/673f1234567890abcdef1234'));
      expect(capturedAuthHeader, equals('Bearer super_admin_jwt_token'));
      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['password'], equals('NewSuperSecret@456'));
      expect(find.text('Staff details updated successfully!'), findsOneWidget);
    });

    testWidgets('Edit Staff submission omits password when field is empty or whitespace', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final existingStaff = Staff(
        id: '673f1234567890abcdef1234',
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
        phoneNumber: '9876543210',
        department: 'Tech',
        role: 'Staff',
        joinDate: '2026-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Frontend Engineer',
        workMode: 'Office',
        salary: 70000,
      );

      Map<String, dynamic>? capturedPayload;

      ApiService.setTokens(accessToken: 'super_admin_jwt_token');
      ApiService.setUserRole('SUPER_ADMIN');
      ApiService.client = MockClient((request) async {
        if (request.method == 'PUT') {
          if (request.url.path.endsWith('/673f1234567890abcdef1234')) {
            capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Employee updated successfully',
                'data': {
                  '_id': '673f1234567890abcdef1234',
                  'name': 'Jane Doe',
                  'email': 'jane.doe@example.com',
                  'department': 'Tech',
                  'designation': 'Frontend Engineer',
                  'status': 'ACTIVE',
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.contains('/salary')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Salary updated successfully',
                'data': {'_id': '673f1234567890abcdef1234'}
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        if (request.method == 'GET') {
          if (request.url.path.endsWith('/673f1234567890abcdef1234')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  '_id': '673f1234567890abcdef1234',
                  'name': 'Jane Doe',
                  'email': 'jane.doe@example.com',
                  'department': 'Tech',
                  'designation': 'Frontend Engineer',
                  'status': 'ACTIVE',
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": true}', 200, headers: {'content-type': 'application/json'});
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: hrProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showEditStaffModal(context, existingStaff),
                  child: const Text('Open Edit Staff'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Staff'));
      await tester.pumpAndSettle();

      final editPasswordFinder = find.byKey(const Key('edit_staff_password_field'));
      // Leave empty / whitespace
      await tester.enterText(editPasswordFinder, '   ');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!.containsKey('password'), isFalse);
      expect(find.text('Staff details updated successfully!'), findsOneWidget);
    });

    testWidgets('Edit Staff shows error from backend and stays open when update fails', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final existingStaff = Staff(
        id: '673f1234567890abcdef1234',
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
        phoneNumber: '9876543210',
        department: 'Tech',
        role: 'Staff',
        joinDate: '2026-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Frontend Engineer',
        workMode: 'Office',
        salary: 70000,
      );

      ApiService.setTokens(accessToken: 'staff_or_invalid_token');
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Only Super Admin is authorized to change employee credentials',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: hrProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Modals.showEditStaffModal(context, existingStaff),
                  child: const Text('Open Edit Staff'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Staff'));
      await tester.pumpAndSettle();

      final editPasswordFinder = find.byKey(const Key('edit_staff_password_field'));
      await tester.enterText(editPasswordFinder, 'ForbiddenPass123');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Modal should NOT close and should show the backend error message
      expect(find.text('Edit Staff Details'), findsOneWidget);
      expect(find.text('Only Super Admin is authorized to change employee credentials'), findsWidgets);
      expect(find.text('Staff details updated successfully!'), findsNothing);
    });
  });
}
