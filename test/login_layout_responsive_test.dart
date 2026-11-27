import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/features/auth/login_view.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';

/// Layout-only checks for the login screen: no overflow at common widths,
/// the side image only on desktop, and one shared left/right edge for the form.
void main() {
  Future<void> pumpLogin(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: HRProvider(),
          child: const LoginView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder sideImage() => find.byWidgetPredicate((w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == 'assets/images/login-side-tree.jpg');

  Finder logo() => find.byWidgetPredicate((w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == 'assets/images/ly-softwares-logo.png');

  const sizes = <String, Size>{
    'desktop 1440': Size(1440, 900),
    'laptop 1024': Size(1024, 768),
    'tablet 768': Size(768, 1024),
    'mobile 390': Size(390, 844),
    'mobile 390 + keyboard': Size(390, 420),
  };

  for (final entry in sizes.entries) {
    testWidgets('no overflow at ${entry.key}, also with validation errors',
        (tester) async {
      await pumpLogin(tester, entry.value);
      expect(tester.takeException(), isNull);

      final isDesktop = entry.value.width >= 900;
      expect(sideImage(), isDesktop ? findsOneWidget : findsNothing);
      expect(tester.getSize(logo()).height, isDesktop ? 40 : 32);

      // Submit empty form -> both validators show errors; still no overflow.
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('form elements share one left and one right edge', (tester) async {
    await pumpLogin(tester, const Size(1440, 900));

    final email = tester.getRect(find.widgetWithText(TextFormField, 'Email'));
    final password = tester.getRect(find.widgetWithText(TextFormField, 'Password'));
    final button = tester.getRect(find.widgetWithText(ElevatedButton, 'Sign In'));
    final heading = tester.getRect(find.text('Welcome back'));
    final emailLabel = tester.getRect(find.text('EMAIL*'));
    final passwordLabel = tester.getRect(find.text('PASSWORD*'));
    final forgot = tester.getRect(find.widgetWithText(TextButton, 'Forgot password?'));
    final logoRect = tester.getRect(logo());

    for (final r in [password, button, heading, emailLabel, passwordLabel]) {
      expect(r.left, moreOrLessEquals(email.left, epsilon: 0.5));
    }
    for (final r in [password, button, forgot]) {
      expect(r.right, moreOrLessEquals(email.right, epsilon: 0.5));
    }
    expect(email.width, lessThanOrEqualTo(420));
    expect(email.height, moreOrLessEquals(password.height, epsilon: 0.5));
    expect(button.height, 52);
    // Logo is the only centred element.
    expect(logoRect.center.dx, moreOrLessEquals(email.center.dx, epsilon: 0.5));
    // Spacing logo -> heading 56, heading -> label 28, label -> field 8.
    expect(heading.top - logoRect.bottom, moreOrLessEquals(56, epsilon: 0.5));
    expect(emailLabel.top - heading.bottom, moreOrLessEquals(28, epsilon: 0.5));
    expect(email.top - emailLabel.bottom, moreOrLessEquals(8, epsilon: 0.5));
    expect(password.top - passwordLabel.bottom, moreOrLessEquals(8, epsilon: 2));
    expect(button.top - password.bottom, moreOrLessEquals(28, epsilon: 0.5));
  });
}
