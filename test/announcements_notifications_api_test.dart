import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/widgets/sidebar.dart';
import 'package:ly_hr_dashboard_flutter/widgets/header.dart';
import 'package:ly_hr_dashboard_flutter/app.dart';

void main() {
  group('Announcements and Notifications Removal Verification', () {
    late HRProvider provider;

    setUp(() {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [],
            'pagination': {'total': 0, 'page': 1, 'limit': 10, 'totalPages': 1}
          }),
          200,
        );
      });
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

    tearDown(() {
      ApiService.client = http.Client();
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

      // Verify no notification badge or red count appears in Sidebar
      expect(find.descendant(of: find.byType(AppSidebar), matching: find.text('1')), findsNothing);
    });

    testWidgets(
        'Header contains notification bell icon immediately beside Admin profile section',
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

      // Verify notification bell icon is present immediately beside User Profile
      expect(find.byTooltip('Notifications'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // Zero unread notifications by default -> no badge shown
      expect(provider.unreadNotificationsCount, 0);

      // Verify User Profile is beside the notification bell
      expect(find.byTooltip('User Profile'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets(
        'AppBar notification badge displays dynamic unread count and hides when zero',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Add 2 pending leave requests
      provider.leaveRequests = [
        LeaveRequest(
          id: 'leave_pending_1',
          staffId: 'staff_1',
          employeeName: 'John Doe',
          fromDate: '2026-11-20',
          toDate: '2026-11-21',
          reason: 'Fever',
          status: 'pending',
          leaveType: 'Sick',
          daysCount: 2,
        ),
        LeaveRequest(
          id: 'leave_pending_2',
          staffId: 'staff_2',
          employeeName: 'Jane Smith',
          fromDate: '2026-11-22',
          toDate: '2026-11-22',
          reason: 'Personal',
          status: 'pending',
          leaveType: 'Casual',
          daysCount: 1,
        ),
      ];

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

      // Unread count should be 2, badge shows '2'
      expect(provider.unreadNotificationsCount, 2);
      expect(find.text('2'), findsOneWidget);

      // Tap the notification bell to open dropdown
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();

      // Verify dropdown content
      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('2 new'), findsOneWidget);
      expect(find.text('Mark all as read'), findsOneWidget);
      expect(find.textContaining('John Doe'), findsOneWidget);
      expect(find.textContaining('Jane Smith'), findsOneWidget);

      // Tap Mark all as read
      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();

      // Badge should now be hidden (unread count = 0)
      expect(provider.unreadNotificationsCount, 0);
      expect(find.text('2'), findsNothing);
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
