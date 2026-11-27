import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/widgets/header.dart';
import 'package:ly_hr_dashboard_flutter/widgets/sidebar.dart';

Staff _createTestUser() => Staff(
      id: 'admin_1',
      name: 'Super Admin',
      email: 'admin@ly.com',
      phoneNumber: '+919876543210',
      role: 'Super Admin',
      department: 'Management',
      joinDate: '2024-01-01',
      status: 'Active',
      onLeaveToday: false,
    );

void main() {
  group('Dashboard Minor UI Changes - Active Dot & Profile Label', () {
    late HRProvider provider;

    setUp(() {
      provider = HRProvider();
      provider.setCurrentUserForTesting(_createTestUser());
      provider.setScreen('hr-dashboard');
    });

    Widget createWidget() {
      return MaterialApp(
        theme: ThemeData(fontFamily: 'Plus Jakarta Sans'),
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const Scaffold(
            appBar: Header(),
            body: Row(
              children: [
                AppSidebar(),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('Active navigation indicator dot is black (#000000)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find all dots with size 6.5 x 6.5
      final dotFinders = find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle &&
              widget.constraints?.maxWidth == 6.5 &&
              widget.constraints?.maxHeight == 6.5) {
            return true;
          }
        }
        return false;
      });

      expect(dotFinders, findsOneWidget);

      final dotContainer = tester.widget<Container>(dotFinders);
      final decoration = dotContainer.decoration as BoxDecoration;

      // Verify the active dot color is black (#000000)
      expect(decoration.color, const Color(0xFF000000));
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('Header displays Admin label, keeps SA avatar, and works with dropdown',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // 1. Verify visible profile text is 'Admin'
      final adminTextFinder = find.descendant(
        of: find.byType(Header),
        matching: find.text('Admin'),
      );
      expect(adminTextFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(adminTextFinder);
      expect(textWidget.style?.fontFamily, 'Plus Jakarta Sans');
      expect(textWidget.style?.fontSize, 12.5);
      expect(textWidget.style?.fontWeight, FontWeight.w700);
      expect(textWidget.style?.color, const Color(0xFF0F172A));

      // 2. Verify avatar displays 'SA'
      final avatarTextFinder = find.descendant(
        of: find.byType(Header),
        matching: find.text('SA'),
      );
      expect(avatarTextFinder, findsOneWidget);

      // 3. Verify dropdown icon exists and tapping opens the menu
      final dropdownIcon = find.descendant(
        of: find.byType(Header),
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      );
      expect(dropdownIcon, findsOneWidget);

      await tester.tap(dropdownIcon);
      await tester.pumpAndSettle();

      // Verify menu items opened
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('Navigation switches active black dot to new active item',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap Employees in Sidebar
      await tester.tap(find.text('Employees'));
      await tester.pumpAndSettle();

      expect(provider.currentScreen, 'employees');

      // The black dot should now be on the Employees item
      final dotFinders = find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle &&
              widget.constraints?.maxWidth == 6.5 &&
              widget.constraints?.maxHeight == 6.5) {
            return true;
          }
        }
        return false;
      });

      expect(dotFinders, findsOneWidget);

      final dotContainer = tester.widget<Container>(dotFinders);
      final decoration = dotContainer.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF000000));
    });
  });
}
