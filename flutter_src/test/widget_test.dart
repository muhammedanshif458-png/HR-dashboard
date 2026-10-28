import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/app.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/features/auth/login_view.dart';
import 'package:ly_hr_dashboard_flutter/features/leaves/leave_management_view.dart';
import 'package:ly_hr_dashboard_flutter/features/attendance/attendance_view.dart';
import 'package:ly_hr_dashboard_flutter/features/employees/employees_view.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/features/departments/departments_view.dart';
import 'fixtures/hr_mock_fixtures.dart';

void main() {
  setUpAll(() {
    installMockFixtures();
    HRProvider.enableTestFixtures = true;
  });

  tearDownAll(() {
    uninstallMockFixtures();
    HRProvider.enableTestFixtures = false;
  });

  group('HRProvider Local State Interactions', () {
    test('Login sets current user and dashboard screen', () {
      final provider = HRProvider();
      expect(provider.currentScreen, 'login');

      provider.login('admin@test.com', 'pass');
      expect(provider.currentScreen, 'hr-dashboard');
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.email, 'admin@test.com');
    });

    test('Add Staff updates local mock list', () async {
      final provider = HRProvider();
      final initialCount = provider.staffList.length;

      await provider.addStaff({
        'name': 'New Guy',
        'email': 'new@test.com',
      });

      expect(provider.staffList.length, initialCount + 1);
      expect(provider.staffList.last.name, 'New Guy');
    });

    test('Update Staff updates local mock state', () async {
      final provider = HRProvider();
      final target = provider.staffList.first;

      await provider.updateStaff(target.id, {
        'name': 'Updated Name',
      });

      final updated = provider.staffList.firstWhere((s) => s.id == target.id);
      expect(updated.name, 'Updated Name');
    });

    test('Approve Leave updates local mock state', () async {
      final provider = HRProvider();
      final target = provider.leaveRequests.first;
      expect(target.status, 'Pending');

      await provider.reviewLeave(target.id, true);

      final updated =
          provider.leaveRequests.firstWhere((l) => l.id == target.id);
      expect(updated.status, 'Approved');
    });

    test('Reject Leave with remark updates status and reason', () async {
      final provider = HRProvider();
      final target =
          provider.leaveRequests.firstWhere((l) => l.status == 'Pending');

      await provider.rejectLeave(target.id, 'Notice period not served');

      final updated =
          provider.leaveRequests.firstWhere((l) => l.id == target.id);
      expect(updated.status, 'Rejected');
      expect(updated.rejectionReason, 'Notice period not served');
    });

    test('Medical leave proof status is tracked correctly', () {
      final provider = HRProvider();
      final medicalWithProof =
          provider.leaveRequests.where((l) => l.isMedical && l.hasMedicalProof);
      final medicalWithoutProof = provider.leaveRequests
          .where((l) => l.isMedical && !l.hasMedicalProof);

      expect(medicalWithProof.isNotEmpty, true);
      expect(medicalWithoutProof.isNotEmpty, true);
    });

    test('Attendance filtering by status functions properly', () {
      final provider = HRProvider();
      provider.setAttendanceStatusFilter('Late');
      final filtered = provider.filteredAttendanceList;
      for (final att in filtered) {
        expect(att.status.toLowerCase(), 'late');
      }
    });

    test('Navigation to profile updates screen and selected ID', () {
      final provider = HRProvider();
      provider.viewStaffProfile('staff_2');

      expect(provider.currentScreen, 'staff-profile');
      expect(provider.selectedStaffId, 'staff_2');
    });
  });

  group('UI Rendering Smoke Tests', () {
    testWidgets('Login screen renders correctly', (WidgetTester tester) async {
      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      // Verify Login UI
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets(
        'HRDashboardView renders without unbounded height errors and shows branding',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass');
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Team Dashboard'), findsOneWidget);
      expect(find.text('LY SOFTWARE'), findsOneWidget);
      expect(find.text('Assign Task'), findsNothing);
    });

    testWidgets('LeaveManagementView renders with summary counters and filters',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass');
      hrProvider.navigateToLeaveManagement();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(LeaveManagementView), findsOneWidget);
      expect(find.text('Leave Management'), findsWidgets);
      expect(find.text('Pending Requests'), findsOneWidget);
      expect(find.text('Approved Leaves'), findsOneWidget);
    });

    testWidgets('AttendanceView renders with today tab and table',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass');
      hrProvider.navigateToAttendance();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AttendanceView), findsOneWidget);
      expect(find.text('Attendance Management'), findsOneWidget);
      expect(find.text('Present Today'), findsOneWidget);
      expect(find.text('Late Arrivals'), findsOneWidget);
    });

    testWidgets('EmployeesView renders with employee directory',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass');
      hrProvider.navigateToEmployees();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(EmployeesView), findsOneWidget);
      expect(find.text('Employee Directory'), findsOneWidget);
    });

    testWidgets('StaffProfileView renders without unbounded height errors',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass');
      await tester.pump(const Duration(milliseconds: 600));
      hrProvider.viewStaffProfile('staff_1');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Staff Profile'), findsOneWidget);
      expect(find.text('Assign Task'), findsNothing);
      expect(find.text('Add Document'), findsWidgets);
      expect(find.text('Edit Salary'), findsOneWidget);
      expect(find.text('Salary History'), findsOneWidget);
      expect(find.text('Edit Staff'), findsOneWidget);
      expect(find.text('Mark Resigned'), findsOneWidget);
    });

    testWidgets('DepartmentsView renders with department cards and counts',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass');
      hrProvider.navigateToDepartments();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(DepartmentsView), findsOneWidget);
      expect(find.text('Departments & Headcount'), findsOneWidget);
    });

    test('Add Staff with salary and leave allowance persists fields', () async {
      final provider = HRProvider();
      final initialCount = provider.staffList.length;

      await provider.addStaff({
        'name': 'Rahul Sharma',
        'email': 'rahul.s@lysoftware.com',
        'department': 'Tech',
        'salary': 55000.0,
        'salaryCurrency': 'INR',
        'salaryEffectiveDate': '2026-10-01',
        'paidLeaveAllowance': 1,
      });

      expect(provider.staffList.length, initialCount + 1);
      final added = provider.staffList.last;
      expect(added.salary, 55000.0);
      expect(added.salaryCurrency, 'INR');
      expect(added.paidLeaveAllowance, 1);
      expect(added.salaryHistory.isNotEmpty, true);
      expect(added.salaryHistory.first.amount, 55000.0);
    });

    test('Edit salary preserves salary history and effective dates', () async {
      final provider = HRProvider();
      final target = provider.staffList.first;
      final prevHistoryCount = target.salaryHistory.length;

      await provider.editSalary(
        staffId: target.id,
        newSalary: 95000.0,
        effectiveDate: '2026-11-01',
        currency: 'INR',
        reason: 'Q4 Performance Hike',
      );

      final updated = provider.staffList.firstWhere((s) => s.id == target.id);
      expect(updated.salary, 95000.0);
      expect(updated.salaryEffectiveDate, '2026-11-01');
      expect(updated.salaryHistory.length, prevHistoryCount + 1);
      expect(updated.salaryHistory.first.amount, 95000.0);
      expect(updated.salaryHistory.first.reason, 'Q4 Performance Hike');
    });

    testWidgets(
        'PayrollView renders with department calendars and summary metrics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass');
      hrProvider.setScreen('payroll');
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Monthly Payroll Processing'), findsOneWidget);
      expect(find.text('Gross Salary Pool'), findsOneWidget);
      expect(find.text('Unpaid Leave Deductions'), findsOneWidget);
      expect(find.text('Net Payout Amount'), findsOneWidget);
    });

    testWidgets(
        'StaffProfileView renders complete profile and documents for Tech and Telecalling',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass');

      // 1. Test Tech Employee (Anita Rao - staff_1)
      hrProvider.viewStaffProfile('staff_1');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HR Document Management'), findsOneWidget);
      expect(find.text('Add Document'), findsWidgets);
      expect(find.text('Master Employment Agreement'), findsOneWidget);
      expect(find.text('B.Tech Degree Certificate'), findsOneWidget);

      // Verify Tech employee can add document
      await hrProvider.uploadDocument(
        employeeId: 'staff_1',
        title: 'Tech Certification 2024',
        category: 'Educational Certificates',
        fileName: 'tech_cert.pdf',
        fileBytes: [1, 2, 3],
      );
      await tester.pumpAndSettle();
      expect(find.text('Tech Certification 2024'), findsOneWidget);

      // 2. Test Telecalling Employee (Neha Sharma - staff_3)
      hrProvider.viewStaffProfile('staff_3');
      await tester.pumpAndSettle();

      expect(find.text('HR Document Management'), findsOneWidget);
      expect(find.text('Neha Sharma Appointment Letter'), findsOneWidget);
      expect(find.text('National Identity Card (PAN)'), findsOneWidget);

      // Verify Telecalling employee can replace and archive document
      final teleDocs = hrProvider.getDocumentsForStaff('staff_3');
      expect(teleDocs.isNotEmpty, isTrue);

      final panDoc = teleDocs.firstWhere((d) => d.category == 'Identity Proof');
      await hrProvider.replaceDocument(
        docId: panDoc.id,
        employeeId: 'staff_3',
        title: 'Updated PAN Card Copy',
        fileName: 'neha_pan_updated.png',
        fileBytes: [4, 5, 6],
      );
      await tester.pumpAndSettle();
      expect(find.text('Updated PAN Card Copy'), findsOneWidget);

      await hrProvider.archiveDocument(panDoc.id, 'staff_3');
      await tester.pumpAndSettle();
      expect(find.text('Updated PAN Card Copy'), findsNothing);
    });

    testWidgets(
        'Company-Wide Birthday Celebration renders across departments and protects birth year',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();
      hrProvider.login('admin@company.com', 'admin123');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Today's birthday celebration card should render on the dashboard
      expect(find.text("🎂 TODAY'S BIRTHDAYS"), findsOneWidget);
      expect(find.text('Happy Birthday, Anita!'), findsOneWidget);

      // Verify birth year is NOT displayed (only friendly month & day)
      expect(find.textContaining('1990'), findsNothing);

      // Verify upcoming birthdays section displays colleagues across departments (Tech & Telecalling)
      expect(find.text('📅 UPCOMING BIRTHDAYS (Next 30 Days)'), findsOneWidget);
      expect(find.text('Arjun Desai'), findsWidgets);
      expect(find.text('Neha Sharma'), findsWidgets);
    });

    testWidgets('LoginView validates empty inputs before sending request',
        (WidgetTester tester) async {
      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Sign In with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(hrProvider.currentScreen, 'login');
    });

    testWidgets(
        'LoginView successfully navigates to HR dashboard for permitted HR role',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                'id': 'u_hr_1',
                'firstName': 'Priya',
                'lastName': 'Nair',
                'email': 'priya.hr@company.com',
                'role': 'HR',
                'isActive': true,
              },
              'accessToken': 'jwt_access_token_123',
              'refreshToken': 'jwt_refresh_token_456',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'priya.hr@company.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'hrSecurePass');

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(hrProvider.currentScreen, 'hr-dashboard');
      expect(hrProvider.currentUser, isNotNull);
      expect(hrProvider.currentUser?.name, 'Priya Nair');
      expect(find.text('Team Dashboard'), findsOneWidget);
      expect(ApiService.token, 'jwt_access_token_123');
      expect(ApiService.refreshToken, 'jwt_refresh_token_456');
    });

    testWidgets(
        'LoginView successfully navigates to HR dashboard for permitted SUPER_ADMIN role',
        (WidgetTester tester) async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                'id': 'sa_01',
                'firstName': 'Super',
                'lastName': 'Admin',
                'email': 'lysoftware@gmail.com',
                'role': 'SUPER_ADMIN',
                'isActive': true,
              },
              'accessToken': 'super_admin_jwt_123',
              'refreshToken': 'super_admin_refresh_456',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'lysoftware@gmail.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'hrAdmin');

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(hrProvider.currentScreen, 'hr-dashboard');
      expect(hrProvider.currentUser, isNotNull);
      expect(hrProvider.currentUser?.role, 'Super Admin');
      expect(hrProvider.isSuperAdmin, true);
      expect(find.text('Team Dashboard'), findsOneWidget);
      expect(ApiService.token, 'super_admin_jwt_123');

      // Verify Super Admin can navigate to all administrative screens
      const adminScreens = [
        'employees',
        'attendance',
        'leave-management',
        'tasks',
        'reports',
        'departments',
        'payroll',
        'dept-chat',
        'chat',
      ];
      for (final screen in adminScreens) {
        hrProvider.setScreen(screen);
        expect(hrProvider.currentScreen, screen);
      }
    });

    testWidgets(
        'Staff user navigation guard blocks navigation to administrative HR screens',
        (WidgetTester tester) async {
      final hrProvider = HRProvider();
      hrProvider.setCurrentUserForTesting(
        Staff(
          id: 'staff_99',
          name: 'Arjun Desai',
          email: 'arjun@company.com',
          phoneNumber: '9876543210',
          department: 'Tech',
          role: 'Staff',
          joinDate: '2024-01-01',
          status: 'active',
          onLeaveToday: false,
        ),
      );

      hrProvider.setScreen('employees');
      expect(hrProvider.currentScreen, 'staff-portal');

      hrProvider.setScreen('payroll');
      expect(hrProvider.currentScreen, 'staff-portal');

      hrProvider.setScreen('reports');
      expect(hrProvider.currentScreen, 'staff-portal');
    });

    testWidgets(
        'LoginView logs in STAFF role and routes to staff-portal',
        (WidgetTester tester) async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                'id': 'u_staff_1',
                'firstName': 'Vikram',
                'lastName': 'Singh',
                'email': 'vikram@company.com',
                'role': 'STAFF',
                'isActive': true,
              },
              'accessToken': 'staff_access_token',
              'refreshToken': 'staff_refresh_token',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'vikram@company.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'staffPassword');

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Screen routes to staff-portal for STAFF role
      expect(hrProvider.currentScreen, 'staff-portal');
      expect(hrProvider.isStaffUser, isTrue);
      expect(ApiService.token, 'staff_access_token');
    });

    testWidgets(
        'LoginView displays user-friendly error on invalid credentials (401)',
        (WidgetTester tester) async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid email or password',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'wrong@company.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'badpass');

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(hrProvider.currentScreen, 'login');
      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    testWidgets(
        'LoginView displays error on network failure / connection refused',
        (WidgetTester tester) async {
      ApiService.client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'hr@company.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(hrProvider.currentScreen, 'login');
      expect(find.textContaining('Unable to connect to the server'),
          findsOneWidget);
    });

    testWidgets('LoginView displays error on malformed/invalid JSON response',
        (WidgetTester tester) async {
      ApiService.client = MockClient((request) async {
        return http.Response('<html>502 Bad Gateway</html>', 502);
      });

      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'hr@company.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(hrProvider.currentScreen, 'login');
      expect(find.textContaining('Invalid response received from server'),
          findsOneWidget);
    });

    testWidgets(
        'LoginView rejects inactive/deactivated account (403 or isActive:false)',
        (WidgetTester tester) async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                'id': 'u_deact_1',
                'firstName': 'Deactivated',
                'lastName': 'User',
                'email': 'inactive.hr@company.com',
                'role': 'HR',
                'isActive': false,
              },
              'accessToken': 'dummy_access_token',
              'refreshToken': 'dummy_refresh_token',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'),
          'inactive.hr@company.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'anyPassword123');

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(hrProvider.currentScreen, 'login');
      expect(find.textContaining('Your account has been deactivated'),
          findsOneWidget);
      expect(ApiService.token, isNull);
    });
  });
}
