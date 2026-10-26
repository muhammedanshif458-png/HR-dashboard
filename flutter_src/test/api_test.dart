import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'dart:async';
import 'package:ly_hr_dashboard_flutter/core/config.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

void main() {
  setUp(() {
    ApiService.resetBaseUrl();
    ApiService.clearTokens();
  });

  tearDown(() {
    ApiService.resetBaseUrl();
    ApiService.clearTokens();
  });

  group('AppConfig & API Base URL Selection', () {
    test('default base URL targets port 5000', () {
      expect(AppConfig.apiBaseUrl, 'http://localhost:5000');
      expect(ApiService.baseUrl, 'http://localhost:5000');
    });

    test('normalizeBaseUrl strips trailing slashes', () {
      expect(AppConfig.normalizeBaseUrl('http://localhost:5000/'),
          'http://localhost:5000');
      expect(AppConfig.normalizeBaseUrl('http://localhost:5000///'),
          'http://localhost:5000');
    });

    test('normalizeBaseUrl strips duplicate /api suffix', () {
      expect(AppConfig.normalizeBaseUrl('http://localhost:5000/api'),
          'http://localhost:5000');
      expect(AppConfig.normalizeBaseUrl('http://localhost:5000/api/'),
          'http://localhost:5000');
    });

    test('normalizeBaseUrl intercepts Flutter web dev server port 51834', () {
      expect(AppConfig.normalizeBaseUrl('http://localhost:51834'),
          'http://localhost:5000');
      expect(AppConfig.normalizeBaseUrl('http://127.0.0.1:51834'),
          'http://localhost:5000');
    });

    test('normalizeBaseUrl handles empty string with default fallback', () {
      expect(AppConfig.normalizeBaseUrl(''), 'http://localhost:5000');
      expect(AppConfig.normalizeBaseUrl('   '), 'http://localhost:5000');
    });

    test(
        'ApiService.setBaseUrl overrides URL and resetBaseUrl restores default',
        () {
      ApiService.setBaseUrl('http://api.internal.com:5000/');
      expect(ApiService.baseUrl, 'http://api.internal.com:5000');

      ApiService.resetBaseUrl();
      expect(ApiService.baseUrl, 'http://localhost:5000');
    });
  });

  group('ApiService HR Endpoints', () {
    test('getEmployees returns staff list on 200', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/employees');
        expect(request.method, 'GET');

        return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 's1',
                  'name': 'Test User',
                  'email': 'test@example.com',
                  'department': 'Tech',
                  'role': 'Staff',
                  'status': 'active'
                }
              ]
            }),
            200);
      });

      final staff = await ApiService.getEmployees();
      expect(staff.length, 1);
      expect(staff[0].name, 'Test User');
    });

    test('addEmployee returns true on 201', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/employees');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['name'], 'New Staff');
        return http.Response('', 201);
      });

      final success = await ApiService.addEmployee({'name': 'New Staff'});
      expect(success, true);
    });

    test('updateEmployee returns true on 200', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/employees/s1');
        expect(request.method, 'PUT');
        return http.Response('', 200);
      });

      final success =
          await ApiService.updateEmployee('s1', {'name': 'Updated'});
      expect(success, true);
    });

    test('deleteEmployee returns true on 200', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/employees/s1');
        expect(request.method, 'DELETE');
        return http.Response('', 200);
      });

      final success = await ApiService.deleteEmployee('s1');
      expect(success, true);
    });

    test('approveLeave returns true on 200', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/hr/leaves/L1/approve');
        expect(request.method, 'PUT');
        return http.Response('', 200);
      });

      final success = await ApiService.approveLeave('L1');
      expect(success, true);
    });
  });

  group('ApiService.login endpoint', () {
    test(
        'successful login with valid credentials parses data and stores tokens',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.headers['Authorization'], isNull);

        final body = jsonDecode(request.body);
        expect(body['email'], 'hr.director@example.com');
        expect(body['password'], 'secretPass123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                'id': 'u101',
                'firstName': 'Anita',
                'lastName': 'Rao',
                'email': 'hr.director@example.com',
                'role': 'HR',
                'isActive': true,
              },
              'accessToken': 'valid-access-jwt-token',
              'refreshToken': 'valid-refresh-jwt-token',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result =
          await ApiService.login('hr.director@example.com', 'secretPass123');

      expect(result['success'], true);
      expect(result['message'], 'Login successful');
      expect(result['accessToken'], 'valid-access-jwt-token');
      expect(result['refreshToken'], 'valid-refresh-jwt-token');
      expect(result['user']['role'], 'HR');
      expect(ApiService.token, 'valid-access-jwt-token');
      expect(ApiService.refreshToken, 'valid-refresh-jwt-token');
    });

    test('login request clears existing stale tokens and does not send bearer',
        () async {
      ApiService.setTokens(accessToken: 'stale-token', role: 'STAFF');
      expect(ApiService.hasToken, true);

      ApiService.client = MockClient((request) async {
        expect(request.headers['Authorization'], isNull);
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                'id': 'u101',
                'email': 'admin@lysoftware.com',
                'role': 'HR',
              },
              'accessToken': 'fresh-access-token',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await ApiService.login('admin@lysoftware.com', 'Admin@12345');
      expect(ApiService.token, 'fresh-access-token');
      expect(ApiService.userRole, 'HR');
    });

    test('invalid credentials returns 401 with user-friendly message',
        () async {
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

      final result = await ApiService.login('wrong@example.com', 'badpassword');

      expect(result['success'], false);
      expect(result['message'], 'Invalid email or password');
      expect(result['errorType'], 'authentication');
    });

    test('inactive/deactivated account returns 403 message', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Your account has been deactivated. Please contact HR.',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.login('inactive@example.com', 'somepass');

      expect(result['success'], false);
      expect(result['message'], contains('deactivated'));
      expect(result['errorType'], 'forbidden');
    });

    test('validation error 422 extracts structured field error', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Validation failed',
            'errors': [
              {
                'field': 'email',
                'message': 'Please provide a valid email address'
              }
            ]
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.login('invalid-email', 'pass');

      expect(result['success'], false);
      expect(result['message'], 'Please provide a valid email address');
      expect(result['errorType'], 'validation');
    });

    test('server error 500 returns user-friendly server error message',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Internal database connection failed'
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.login('test@example.com', 'pass');

      expect(result['success'], false);
      expect(result['errorType'], 'server');
      expect(result['message'], contains('500'));
    });

    test('malformed/invalid JSON response is handled safely without throwing',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
            '<!DOCTYPE html><html>502 Bad Gateway</html>', 502);
      });

      final result = await ApiService.login('test@example.com', 'pass');

      expect(result['success'], false);
      expect(result['errorType'], 'server');
      expect(result['message'], contains('502'));
      expect(result['message'], isNot(contains('Exception')));
    });

    test('network failure / client exception returns safe error message',
        () async {
      ApiService.client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final result = await ApiService.login('test@example.com', 'pass');

      expect(result['success'], false);
      expect(result['errorType'], 'connection');
      expect(result['message'], contains('connect'));
    });

    test('CORS preflight or XMLHttpRequest error returns diagnostic message',
        () async {
      ApiService.client = MockClient((request) async {
        throw http.ClientException(
            'XMLHttpRequest error: CORS policy check failed');
      });

      final result = await ApiService.login('test@example.com', 'pass');

      expect(result['success'], false);
      expect(result['errorType'], 'connection');
      expect(result['message'], contains('CORS'));
    });

    test('request timeout is caught and categorized', () async {
      ApiService.client = MockClient((request) async {
        throw TimeoutException('Request timed out after 10s');
      });

      final result = await ApiService.login('test@example.com', 'pass');

      expect(result['success'], false);
      expect(result['errorType'], 'timeout');
      expect(result['message'], contains('timed out'));
    });

    test('SUPER_ADMIN login parses role, stores tokens, and sets admin flags',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/auth/login');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['email'], 'lysoftware@gmail.com');
        expect(body['password'], 'hrAdmin');

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
              'accessToken': 'super-admin-access-token',
              'refreshToken': 'super-admin-refresh-token',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.login('lysoftware@gmail.com', 'hrAdmin');

      expect(result['success'], true);
      expect(result['accessToken'], 'super-admin-access-token');
      expect(result['user']['role'], 'SUPER_ADMIN');
      expect(ApiService.token, 'super-admin-access-token');
      expect(ApiService.userRole, 'SUPER_ADMIN');
      expect(ApiService.isSuperAdminRole, true);
      expect(ApiService.isHrAdminRole, true);
      expect(ApiService.isStaffRole, false);
    });

    test('protected API request sends Super Admin bearer token', () async {
      ApiService.setTokens(
        accessToken: 'super-admin-jwt-bearer',
        role: 'SUPER_ADMIN',
      );

      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/employees');
        expect(request.method, 'GET');
        expect(
            request.headers['Authorization'], 'Bearer super-admin-jwt-bearer');
        return http.Response(jsonEncode({'data': []}), 200);
      });

      final staff = await ApiService.getEmployees();
      expect(staff, isEmpty);
    });
  });
}
