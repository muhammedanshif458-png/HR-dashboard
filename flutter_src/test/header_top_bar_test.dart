import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/widgets/header.dart';
import 'package:ly_hr_dashboard_flutter/features/attendance/attendance_view.dart';

Staff _createTestUser() => Staff(
      id: 'user_admin',
      name: 'Super Admin',
      email: 'lysoftware@gmail.com',
      phoneNumber: '+1234567890',
      role: 'Super Admin',
      department: 'Management',
      joinDate: '2023-01-01',
      status: 'Active',
      onLeaveToday: false,
    );

void main() {
  group('Header Top Bar Tests', () {
    testWidgets('Header does NOT contain global search field or search icon on desktop wide screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.setCurrentUserForTesting(_createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const Scaffold(
              appBar: Header(),
              body: SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure global search placeholder is removed from Header
      expect(find.text('Search staff, records, leaves...'), findsNothing);

      // Ensure global search icon is removed from Header
      expect(find.descendant(of: find.byType(Header), matching: find.byIcon(Icons.search)), findsNothing);

      // Ensure Live Systems Connected badge remains visible
      expect(find.text('Live Systems Connected'), findsOneWidget);

      // Ensure user profile details remain visible
      expect(find.text('Super Admin'), findsNWidgets(2)); // Name & Role
    });

    testWidgets('Header renders cleanly on mobile/tablet narrow screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.setCurrentUserForTesting(_createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const Scaffold(
              appBar: Header(),
              body: SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure global search is not shown
      expect(find.text('Search staff, records, leaves...'), findsNothing);

      // Ensure mobile brand title and profile menu are present
      expect(find.text('LY SOFTWARE'), findsOneWidget);
      expect(find.text('Super Admin'), findsNWidgets(2));
    });

    testWidgets('Individual page search fields (e.g. in AttendanceView) remain functional and intact',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.setCurrentUserForTesting(_createTestUser());
      provider.hasLoadedApiAttendance = true;
      provider.apiAttendanceRecords = [];
      provider.attendancePage = 1;
      provider.attendanceLimit = 20;
      provider.attendanceTotal = 0;
      provider.attendanceTotalPages = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AttendanceView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar has no global search
      expect(find.text('Search staff, records, leaves...'), findsNothing);

      // AttendanceView page-level search field is intact
      expect(find.widgetWithText(TextField, 'Search employee by name...'), findsOneWidget);
    });
  });
}
