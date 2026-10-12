import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/app.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/auth/login_view.dart';

void main() {
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

      final updated = provider.leaveRequests.firstWhere((l) => l.id == target.id);
      expect(updated.status, 'Approved');
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

    testWidgets('HRDashboardView renders without unbounded height errors', (WidgetTester tester) async {
      // Create a large desktop viewport
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      
      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass'); // Sets screen to hr-dashboard
      await tester.pump(const Duration(milliseconds: 600)); // Clear fetch data timer

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HRProvider>.value(value: hrProvider),
          ],
          child: const HRApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Team dashboard'), findsOneWidget);
    });

    testWidgets('StaffProfileView renders without unbounded height errors', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      
      final hrProvider = HRProvider();
      hrProvider.login('admin@test.com', 'pass');
      await tester.pump(const Duration(milliseconds: 600)); // Clear fetch data timer
      hrProvider.viewStaffProfile('staff_1'); // Sets screen to staff-profile

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
    });
  });
}
