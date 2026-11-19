import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/widgets/sidebar.dart';
import 'package:ly_hr_dashboard_flutter/widgets/header.dart';
import 'package:ly_hr_dashboard_flutter/app.dart';

void main() {
  group('Announcements and Notifications Removal Verification', () {
    late HRProvider provider;

    setUp(() {
      provider = HRProvider();
      provider.setCurrentUserForTesting(
        Staff(
          id: 'admin_1',
          name: 'Super Admin',
          email: 'lysoftware@gmail.com',
          phoneNumber: '9876543210',
          department: 'Tech',
          role: 'HR Manager',
          joinDate: '2024-01-01',
          status: 'active',
          designation: 'HR Director',
          workMode: 'Office',
          onLeaveToday: false,
        ),
      );
    });

    Widget createTestWidget(Widget child) {
      return ChangeNotifierProvider<HRProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets(
        'Sidebar does NOT contain Announcements menu item or campaign icon',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const AppSidebar()));
      await tester.pumpAndSettle();

      // Verify Announcements item is completely absent
      expect(find.text('Announcements'), findsNothing);
      expect(find.byIcon(Icons.campaign_outlined), findsNothing);
      expect(find.byIcon(Icons.campaign), findsNothing);

      // Verify all valid remaining navigation items are present
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Employees'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Leave Management'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Departments'), findsOneWidget);
      expect(find.text('Payroll'), findsOneWidget);
    });

    testWidgets(
        'Header does NOT contain notification bell or announcement button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              appBar: Header(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify notification icons and badges are absent
      expect(find.byIcon(Icons.notifications_none_outlined), findsNothing);
      expect(find.byIcon(Icons.notifications), findsNothing);
      expect(find.byIcon(Icons.campaign_outlined), findsNothing);
      expect(find.byTooltip('Notifications'), findsNothing);
      expect(find.byTooltip('Announcements'), findsNothing);

      // Verify User Profile is the active action in the Header
      expect(find.byTooltip('User Profile'), findsOneWidget);
      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('Live Systems Connected'), findsOneWidget);
    });

    testWidgets(
        'MainRouter gracefully routes unknown or removed screens to HRDashboardView',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      provider.setScreen('announcements');
      await tester.pumpWidget(createTestWidget(const MainRouter()));
      await tester.pumpAndSettle();

      // Should default to HRDashboardView without crashing
      expect(find.text('Team Dashboard'), findsOneWidget);
    });

    testWidgets(
        'Sidebar navigation works for all active administrative screens',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(const AppSidebar()));
      await tester.pumpAndSettle();

      const validScreens = [
        {'title': 'Employees', 'screen': 'employees'},
        {'title': 'Attendance', 'screen': 'attendance'},
        {'title': 'Leave Management', 'screen': 'leave-management'},
        {'title': 'Tasks', 'screen': 'tasks'},
        {'title': 'Reports', 'screen': 'reports'},
        {'title': 'Departments', 'screen': 'departments'},
        {'title': 'Payroll', 'screen': 'payroll'},
        {'title': 'Dashboard', 'screen': 'hr-dashboard'},
      ];

      for (final item in validScreens) {
        await tester.tap(find.text(item['title']!));
        await tester.pumpAndSettle();
        expect(provider.currentScreen, item['screen']);
      }
    });
  });
}
