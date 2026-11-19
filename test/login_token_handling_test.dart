import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/services/login_debug_logger.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/auth/login_view.dart';

void main() {
  setUp(() {
    ApiService.resetBaseUrl();
    ApiService.clearTokens();
    ApiService.client = http.Client();
    LoginDebugLogger.instance.clear();
  });

  tearDown(() {
    ApiService.resetBaseUrl();
    ApiService.clearTokens();
    ApiService.client = http.Client();
    LoginDebugLogger.instance.clear();
  });

  group('Login Response Token Parser & Storage', () {
    test('extracts token from "token" field in data object', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'token': 'jwt-access-token-12345',
              'accessToken': 'jwt-access-token-12345',
              'refreshToken': 'jwt-refresh-token-67890',
              'user': {
                'id': 'usr_hr_01',
                '_id': 'usr_hr_01',
                'name': 'HR Manager',
                'email': 'hr@example.com',
                'role': 'HR'
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final res = await ApiService.login('hr@example.com', 'password123');

      expect(res['success'], isTrue);
      expect(res['token'], 'jwt-access-token-12345');
      expect(res['accessToken'], 'jwt-access-token-12345');
      expect(ApiService.token, 'jwt-access-token-12345');
      expect(ApiService.hasToken, isTrue);
      expect(ApiService.userRole, 'HR');
      expect(ApiService.isHrAdminRole, isTrue);
      expect(ApiService.isStaffRole, isFalse);
    });

    test('extracts token from legacy "accessToken" field when "token" is absent',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'accessToken': 'legacy-jwt-access-token',
              'user': {
                'id': 'usr_sa_01',
                'name': 'Super Admin',
                'email': 'admin@example.com',
                'role': 'SUPER_ADMIN'
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final res = await ApiService.login('admin@example.com', 'pass123');

      expect(res['success'], isTrue);
      expect(res['token'], 'legacy-jwt-access-token');
      expect(res['accessToken'], 'legacy-jwt-access-token');
      expect(ApiService.token, 'legacy-jwt-access-token');
      expect(ApiService.hasToken, isTrue);
      expect(ApiService.isSuperAdminRole, isTrue);
      expect(ApiService.isHrAdminRole, isTrue);
    });

    test('sanitizes and ignores invalid or accidental JSON string tokens',
        () async {
      // Direct storage call with accidental JSON string
      ApiService.setToken('{"token": "extracted-jwt-clean-token"}');
      expect(ApiService.token, 'extracted-jwt-clean-token');
      expect(ApiService.hasToken, isTrue);

      // Literal "null" string
      ApiService.setToken('null');
      expect(ApiService.token, isNull);
      expect(ApiService.hasToken, isFalse);

      // Empty / whitespace
      ApiService.setToken('   ');
      expect(ApiService.token, isNull);
      expect(ApiService.hasToken, isFalse);

      // Token wrapped in quotes
      ApiService.setToken('"quoted-clean-token"');
      expect(ApiService.token, 'quoted-clean-token');
      expect(ApiService.hasToken, isTrue);
    });
  });

  group('Authenticated API Requests & Authorization Headers', () {
    test('attaches "Authorization: Bearer <token>" when token is valid',
        () async {
      ApiService.setTokens(token: 'valid-test-bearer-token', role: 'HR');

      ApiService.client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer valid-test-bearer-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'totalEmployees': 5,
              'todayPresent': 5,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final metrics = await ApiService.getDashboardMetrics();
      expect(metrics['success'], isTrue);
    });

    test('never sends "Bearer null" or empty header when unauthenticated',
        () async {
      ApiService.clearTokens();

      ApiService.client = MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': []
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await ApiService.getEmployees();
    });

    test('public login endpoint never transmits existing Authorization header',
        () async {
      // Simulate previously stored session token
      ApiService.setTokens(token: 'stale-jwt-token-999');
      expect(ApiService.hasToken, isTrue);

      ApiService.client = MockClient((request) async {
        // Must NOT contain Authorization header
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'token': 'fresh-token-111',
              'user': {
                'id': 'usr_01',
                'name': 'Test Admin',
                'email': 'test@example.com',
                'role': 'HR'
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final loginRes = await ApiService.login('test@example.com', 'Pass@123');
      expect(loginRes['token'], 'fresh-token-111');
      expect(ApiService.token, 'fresh-token-111');
    });
  });

  group('Session Clearance & Logout', () {
    test('clearTokens clears stored token, refreshToken, and role', () {
      ApiService.setTokens(
        token: 'token-abc',
        refreshToken: 'refresh-xyz',
        role: 'SUPER_ADMIN',
      );
      expect(ApiService.hasToken, isTrue);

      ApiService.clearTokens();

      expect(ApiService.token, isNull);
      expect(ApiService.refreshToken, isNull);
      expect(ApiService.userRole, isNull);
      expect(ApiService.hasToken, isFalse);
      expect(ApiService.isHrAdminRole, isFalse);
      expect(ApiService.isSuperAdminRole, isFalse);
    });

    test('HRProvider.logout clears session and resets tokens', () {
      final provider = HRProvider();
      ApiService.setTokens(token: 'active-session-token', role: 'HR');
      expect(ApiService.hasToken, isTrue);

      provider.logout();

      expect(provider.currentUser, isNull);
      expect(provider.currentScreen, 'login');
      expect(ApiService.hasToken, isFalse);
      expect(ApiService.token, isNull);
    });
  });

  group('LoginDebugLogger Lifecycle & Security', () {
    test('logs request, response, token analysis without leaking passwords', () async {
      final logger = LoginDebugLogger.instance;
      logger.clear();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'token': 'jwt-super-secret-token-xyz',
              'user': {
                'id': 'u100',
                'name': 'Admin User',
                'email': 'admin@company.com',
                'role': 'SUPER_ADMIN'
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      logger.logLoginClick('admin@company.com');
      final res = await ApiService.login('admin@company.com', 'SuperSecretPassword123');

      expect(res['success'], isTrue);
      expect(logger.entries.isNotEmpty, isTrue);
      expect(logger.extractedToken, 'jwt-super-secret-token-xyz');
      expect(logger.tokenJsonPath, 'data.token');
      expect(logger.isTokenStored, isTrue);
      expect(logger.isTokenMissing, isFalse);

      // Verify that the plaintext password is never logged anywhere
      for (final entry in logger.entries) {
        expect(entry.message.contains('SuperSecretPassword123'), isFalse);
        expect(entry.details?.contains('SuperSecretPassword123') ?? false, isFalse);
      }
    });

    test('identifies and warns on missing token in 200 response', () async {
      final logger = LoginDebugLogger.instance;
      logger.clear();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login succeeded but missing token field',
            'data': {
              'user': {
                'id': 'u101',
                'name': 'Staff User',
                'email': 'staff@company.com',
                'role': 'STAFF'
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await ApiService.login('staff@company.com', 'Pass@123');

      expect(logger.isTokenMissing, isTrue);
      expect(logger.tokenJsonPath, 'None (missing)');
      expect(logger.extractedToken, isNull);
      expect(logger.entries.any((e) => e.message.contains('token is MISSING')), isTrue);
    });

    test('clear() resets all entries and analysis fields', () {
      final logger = LoginDebugLogger.instance;
      logger.log('Sample log');
      logger.extractedToken = 'tok';
      logger.tokenJsonPath = 'data.token';
      logger.isTokenStored = true;

      logger.clear();

      expect(logger.entries, isEmpty);
      expect(logger.extractedToken, isNull);
      expect(logger.tokenJsonPath, isNull);
      expect(logger.isTokenStored, isFalse);
    });
  });

  group('LoginView Clean UI Verification (Debug Console Removed)', () {
    testWidgets('renders clean login card and confirms debug console is completely absent',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: hrProvider,
            child: const LoginView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify clean Login card is present
      expect(find.text('Login'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);

      // Verify Login Debug Console and its controls are COMPLETELY REMOVED from the UI
      expect(find.text('Login Debug Console'), findsNothing);
      expect(find.byKey(const Key('toggle_token_visibility')), findsNothing);
      expect(find.byKey(const Key('clear_logs_button')), findsNothing);
      expect(find.text('Pause redirect'), findsNothing);
      expect(find.text('Show Token'), findsNothing);
      expect(find.text('Hide Token'), findsNothing);
    });

    testWidgets(
        'password field has visibility toggle icon and toggles obscureText',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hrProvider = HRProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: hrProvider,
            child: const LoginView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Initially, eye-off icon is shown and password field is obscured
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      final passwordFieldInitial = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordFieldInitial.obscureText, isTrue);

      // 2. Click toggle icon -> changes to eye icon and shows plain text
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      final passwordFieldVisible = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordFieldVisible.obscureText, isFalse);

      // 3. Click again -> changes back to eye-off and hides password
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      final passwordFieldHiddenAgain = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordFieldHiddenAgain.obscureText, isTrue);
    });

    test('ApiService.printLoginTerminalDebug formats output properly in debug mode', () {
      // Test that printLoginTerminalDebug handles success, diagnostic, and error cases without throwing
      expect(() {
        ApiService.printLoginTerminalDebug(
          statusCode: 200,
          isSuccess: true,
          tokenFieldPath: 'data.token',
          token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummyJwtForTesting.abc',
          tokenStored: true,
        );

        ApiService.printLoginTerminalDebug(
          statusCode: 200,
          isSuccess: true,
          token: null,
          tokenStored: false,
          diagnostic: 'Authentication token is missing from response envelope.',
        );

        ApiService.printLoginTerminalDebug(
          statusCode: 401,
          isSuccess: false,
          errorMessage: 'Invalid email or password.',
        );
      }, returnsNormally);
    });
  });

  group('Live End-to-End Real Backend Integration Tests', () {
    test('real login returns data.token and executes authenticated dashboard call',
        () async {
      // Allow real HTTP connections in Flutter test environment
      HttpOverrides.global = null;

      // Use real HTTP client connecting to local backend at port 5000
      ApiService.client = http.Client();

      // 1. Perform login with seeded Super Admin
      final loginResult =
          await ApiService.login('lysoftware@gmail.com', 'hrAdmin');

      expect(loginResult['success'], isTrue,
          reason: 'Expected successful login: ${loginResult['message']}');
      expect(loginResult['token'], isNotNull);
      expect(loginResult['token'], isNotEmpty);
      expect(loginResult['data']['token'], isNotNull);
      expect(loginResult['user']['email'], 'lysoftware@gmail.com');
      expect(loginResult['user']['role'], 'SUPER_ADMIN');

      // 2. Verify token is stored in ApiService
      expect(ApiService.token, loginResult['token']);
      expect(ApiService.hasToken, isTrue);

      // 3. Make real authenticated call to protected HR Dashboard endpoint
      final dashResult = await ApiService.getDashboardMetrics();
      expect(dashResult['success'], isTrue);
      expect(dashResult['data'], isA<Map<String, dynamic>>());
      expect(dashResult['data']['totalEmployees'], greaterThanOrEqualTo(1));

      // 4. Test invalid credentials
      final invalidRes =
          await ApiService.login('lysoftware@gmail.com', 'WrongPassword123');
      expect(invalidRes['success'], isFalse);
      expect(invalidRes['errorType'], 'authentication');
      expect(ApiService.token, isNull);

      // 5. Test protected request with bad token returns error
      ApiService.setTokens(token: 'invalid-or-tampered-token');
      expect(
        () async => await ApiService.getDashboardMetrics(),
        throwsA(isA<Exception>()),
      );

      // 6. Test logout clears session
      final provider = HRProvider();
      ApiService.setTokens(token: 'some-active-token', role: 'HR');
      provider.logout();
      expect(ApiService.hasToken, isFalse);
      expect(ApiService.token, isNull);
    });
  });
}
