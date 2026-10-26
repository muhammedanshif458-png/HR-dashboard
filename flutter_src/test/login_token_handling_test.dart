import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';

void main() {
  setUp(() {
    ApiService.resetBaseUrl();
    ApiService.clearTokens();
    ApiService.client = http.Client();
  });

  tearDown(() {
    ApiService.resetBaseUrl();
    ApiService.clearTokens();
    ApiService.client = http.Client();
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

  group('Live End-to-End Real Backend Integration Tests', () {
    test('real login returns data.token and executes authenticated dashboard call',
        () async {
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
