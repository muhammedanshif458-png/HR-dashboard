import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/models/birthday_item.dart';

void main() {
  // ─── Dashboard Metrics ──────────────────────────────────────────────────────
  group('ApiService.getDashboardMetrics', () {
    test(
        'requests dashboard metrics for an explicitly selected attendance date',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.queryParameters['date'], '2026-10-26');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'todayPresent': 2,
              'lateArrivals': 1,
              'onLeaveToday': 1,
              'todayWfh': 1,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'test-access-token');

      final result = await ApiService.getDashboardMetrics(date: '2026-10-26');

      expect(result['data']['todayPresent'], 2);
      expect(result['data']['lateArrivals'], 1);
      expect(result['data']['onLeaveToday'], 1);
      expect(result['data']['todayWfh'], 1);
    });

    test('returns parsed map on 200 with full payload', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/dashboard');
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], startsWith('Bearer '));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'HR dashboard statistics fetched successfully',
            'data': {
              'totalEmployees': 42,
              'activeEmployees': 38,
              'inactiveEmployees': 4,
              'todayPresent': 35,
              'todayAbsent': 3,
              'pendingLeaves': 5,
              'upcomingBirthdays': 2,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // Set a token so _headers() includes Authorization
      ApiService.setTokens(accessToken: 'test-access-token');

      final result = await ApiService.getDashboardMetrics();

      expect(result['success'], true);
      expect(result['data']['totalEmployees'], 42);
      expect(result['data']['activeEmployees'], 38);
      expect(result['data']['inactiveEmployees'], 4);
      expect(result['data']['todayPresent'], 35);
      expect(result['data']['todayAbsent'], 3);
      expect(result['data']['pendingLeaves'], 5);
      expect(result['data']['upcomingBirthdays'], 2);
    });

    test('throws Exception on non-200 response (e.g. 401 Unauthorized)',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'test-access-token');

      expect(
        () async => await ApiService.getDashboardMetrics(),
        throwsException,
      );
    });

    test('throws Exception on 500 server error', () async {
      ApiService.client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      ApiService.setTokens(accessToken: 'test-access-token');

      expect(
        () async => await ApiService.getDashboardMetrics(),
        throwsException,
      );
    });

    test('throws Exception on network failure', () async {
      ApiService.client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });
      ApiService.setTokens(accessToken: 'test-access-token');

      expect(
        () async => await ApiService.getDashboardMetrics(),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('throws Exception on malformed JSON (HTML gateway response)',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
            '<!DOCTYPE html><html>502 Bad Gateway</html>', 502);
      });
      ApiService.setTokens(accessToken: 'test-access-token');

      expect(
        () async => await ApiService.getDashboardMetrics(),
        throwsException,
      );
    });
  });

  // ─── Company Birthdays ──────────────────────────────────────────────────────
  group('ApiService.getCompanyBirthdays', () {
    test('returns parsed BirthdayItems for the shared today endpoint',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/birthdays/today');
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], startsWith('Bearer '));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Birthdays fetched successfully',
            'data': {
              'today': [
                {
                  'id': 'e1',
                  'name': 'Alice Kumar',
                  'department': 'Engineering',
                  'dateOfBirth': '1990-10-15',
                  'profileImage': null,
                },
                {
                  'id': 'e3',
                  'name': 'Cara Mehta',
                  'department': 'Telecalling',
                  'dateOfBirth': '1992-10-15',
                  'profileImage': 'https://example.com/cara.png',
                }
              ],
              'upcoming': [
                {
                  'id': 'e2',
                  'name': 'Bob Singh',
                  'department': 'HR',
                  'dateOfBirth': '1988-10-20',
                  'profileImage': null,
                }
              ],
              'totalToday': 1,
              'totalUpcoming': 1,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      ApiService.setTokens(accessToken: 'test-access-token');

      final result = await ApiService.getCompanyBirthdays(daysAhead: 30);

      final today = result['today'] as List<BirthdayItem>;

      expect(today.length, 2);
      expect(today[0].name, 'Alice Kumar');
      expect(today[0].department, 'Engineering');
      expect(today[1].name, 'Cara Mehta');
      expect(today[1].profileImage, 'https://example.com/cara.png');

      expect(result['totalToday'], 1);
    });

    test('returns empty lists gracefully on 200 with empty arrays', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'today': [],
              'upcoming': [],
              'totalToday': 0,
              'totalUpcoming': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'test-access-token');

      final result = await ApiService.getCompanyBirthdays();

      expect((result['today'] as List).isEmpty, true);
      expect(result['totalToday'], 0);
    });

    test('returns empty fallback on 401 Unauthorized (no throw)', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Unauthorized'}),
          401,
        );
      });
      ApiService.setTokens(accessToken: 'expired-token');

      // getCompanyBirthdays catches errors and returns empty maps
      final result = await ApiService.getCompanyBirthdays();

      expect((result['today'] as List).isEmpty, true);
    });

    test('returns empty fallback on network failure (no throw)', () async {
      ApiService.client = MockClient((request) async {
        throw http.ClientException('No route to host');
      });
      ApiService.setTokens(accessToken: 'test-access-token');

      final result = await ApiService.getCompanyBirthdays();

      expect((result['today'] as List).isEmpty, true);
      expect(result['totalToday'], 0);
    });

    test('returns empty fallback on malformed JSON (no throw)', () async {
      ApiService.client = MockClient((request) async {
        return http.Response('<!DOCTYPE html>502 Gateway Error</html>', 502);
      });
      ApiService.setTokens(accessToken: 'test-access-token');

      final result = await ApiService.getCompanyBirthdays();

      expect((result['today'] as List).isEmpty, true);
    });

    test('always uses the company-wide today endpoint', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/birthdays/today');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'today': [],
              'upcoming': [],
              'totalToday': 0,
              'totalUpcoming': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      ApiService.setTokens(accessToken: 'test-access-token');

      final result = await ApiService.getCompanyBirthdays(daysAhead: 7);
      expect(result['totalToday'], 0);
    });

    test('uses the same company-wide endpoint for STAFF, HR, and admins',
        () async {
      String? requestedPath;
      ApiService.client = MockClient((request) async {
        requestedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'today': [],
              'upcoming': [],
              'totalToday': 0,
              'totalUpcoming': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // 1. Explicit isStaff: true
      ApiService.setTokens(accessToken: 'staff-token');
      await ApiService.getCompanyBirthdays(isStaff: true);
      expect(requestedPath, '/api/birthdays/today');

      // 2. Implicit via userRole: 'STAFF'
      ApiService.setUserRole('STAFF');
      await ApiService.getCompanyBirthdays();
      expect(requestedPath, '/api/birthdays/today');

      // 3. HR uses the same company-wide endpoint.
      ApiService.setUserRole('HR');
      await ApiService.getCompanyBirthdays();
      expect(requestedPath, '/api/birthdays/today');
    });

    test(
        'HRProvider.fetchBirthdays does not populate mock data when API request returns empty or fails in API mode',
        () async {
      final provider = HRProvider();
      ApiService.setTokens(accessToken: 'real-api-token', role: 'STAFF');

      // Mock API returning empty list
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/birthdays/today');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'today': [],
              'upcoming': [],
              'totalToday': 0,
              'totalUpcoming': 0
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.fetchBirthdays(isStaff: true);

      // Verify that mock birthdays (e.g. Anita Rao) are NOT silently populated
      expect(provider.todayBirthdays.isEmpty, true);
      expect(provider.upcomingBirthdays.isEmpty, true);
      expect(provider.hasLoadedApiBirthdays, true);

      // Now mock API failure (500)
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Internal server error'}),
          500,
        );
      });

      await provider.fetchBirthdays(isStaff: true);

      // Verify that mock data is STILL not used as fallback
      expect(provider.todayBirthdays.isEmpty, true);
      expect(provider.upcomingBirthdays.isEmpty, true);
      expect(provider.todayBirthdays.any((b) => b.name == 'Anita Rao'), false);
    });
  });
}
