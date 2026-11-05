import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/models/department.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/departments/departments_view.dart';
import 'fixtures/hr_mock_fixtures.dart';

void main() {
  setUpAll(() {
    installMockFixtures();
    HRProvider.enableTestFixtures = true;
  });

  tearDownAll(() {
    uninstallMockFixtures();
    HRProvider.enableTestFixtures = false;
  });

  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  // ─── 1. ApiService.getDepartments ──────────────────────────────────────────
  group('ApiService.getDepartments', () {
    test('returns parsed department list on 200 with Bearer token', () async {
      String? authHeader;
      String? requestedPath;

      ApiService.client = MockClient((request) async {
        authHeader = request.headers['Authorization'];
        requestedPath = request.url.path;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Departments retrieved successfully',
            'data': [
              {
                'deptKey': 'tech',
                'title': 'Tech & Engineering',
                'subtitle': 'Frontend, Backend, Infrastructure & QA',
                'staffCount': 24,
                'activeCount': 22,
                'leadName': 'Anita Rao (Lead HR / Tech Ops)',
                'icon': 'computer',
                'color': '#2563EB',
              },
              {
                'deptKey': 'telecalling',
                'title': 'Telecalling & Client Relations',
                'subtitle':
                    'Candidate Outreach, Lead Calling & Customer Support',
                'staffCount': 18,
                'activeCount': 16,
                'leadName': 'Neha Sharma (Operations Senior)',
                'icon': 'headset_mic',
                'color': '#DB2777',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      ApiService.setTokens(accessToken: 'mock-bearer-token-123');

      final departments = await ApiService.getDepartments();

      expect(requestedPath, '/api/hr/departments');
      expect(authHeader, 'Bearer mock-bearer-token-123');
      expect(departments.length, 2);

      final tech = departments[0];
      expect(tech.deptKey, 'tech');
      expect(tech.title, 'Tech & Engineering');
      expect(tech.subtitle, 'Frontend, Backend, Infrastructure & QA');
      expect(tech.staffCount, 24);
      expect(tech.activeCount, 22);
      expect(tech.leadName, 'Anita Rao (Lead HR / Tech Ops)');
      expect(tech.icon, Icons.computer);
      expect(tech.color, const Color(0xFF2563EB));

      final tele = departments[1];
      expect(tele.deptKey, 'telecalling');
      expect(tele.title, 'Telecalling & Client Relations');
      expect(tele.icon, Icons.headset_mic);
      expect(tele.color, const Color(0xFFDB2777));
    });

    test('returns empty department list gracefully when backend data is empty',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'No departments found',
            'data': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      ApiService.setTokens(accessToken: 'token');
      final list = await ApiService.getDepartments();
      expect(list, isEmpty);
    });

    test('throws Exception on 401 Unauthorized', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      ApiService.setTokens(accessToken: 'bad-token');
      expect(() => ApiService.getDepartments(), throwsA(isA<Exception>()));
    });

    test('throws Exception on 500 Internal Server Error', () async {
      ApiService.client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      expect(() => ApiService.getDepartments(), throwsA(isA<Exception>()));
    });

    test('throws Exception on malformed JSON response', () async {
      ApiService.client = MockClient((request) async {
        return http.Response('<html><body>502 Bad Gateway</body></html>', 200,
            headers: {'content-type': 'text/html'});
      });

      expect(() => ApiService.getDepartments(), throwsA(isA<Exception>()));
    });

    test('throws Exception on network exception', () async {
      ApiService.client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      expect(() => ApiService.getDepartments(), throwsA(isA<Exception>()));
    });
  });

  // ─── 2. ApiService.getDepartmentDetail ─────────────────────────────────────
  group('ApiService.getDepartmentDetail', () {
    test('fetches detail using deptKey URL path with Bearer token', () async {
      String? requestedPath;
      String? authHeader;

      ApiService.client = MockClient((request) async {
        requestedPath = request.url.path;
        authHeader = request.headers['Authorization'];

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Department details fetched successfully',
            'data': {
              'deptKey': 'tech',
              'title': 'Tech & Engineering',
              'subtitle': 'Frontend, Backend, Infrastructure & QA',
              'staffCount': 24,
              'activeCount': 22,
              'leadName': 'Anita Rao (Lead HR / Tech Ops)',
              'icon': 'engineering',
              'color': '#2563EB',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      ApiService.setTokens(accessToken: 'token-xyz');

      final detail = await ApiService.getDepartmentDetail('tech');

      expect(requestedPath, '/api/hr/departments/tech');
      expect(authHeader, 'Bearer token-xyz');
      expect(detail.deptKey, 'tech');
      expect(detail.title, 'Tech & Engineering');
      expect(detail.staffCount, 24);
      expect(detail.activeCount, 22);
      expect(detail.icon, Icons.engineering);
    });

    test('properly encodes special characters in deptKey', () async {
      String? requestedPath;
      ApiService.client = MockClient((request) async {
        requestedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'deptKey': 'qa-&-testing', 'title': 'QA & Testing'},
          }),
          200,
        );
      });

      await ApiService.getDepartmentDetail('qa-&-testing');
      expect(requestedPath, '/api/hr/departments/qa-%26-testing');
    });

    test('throws Exception on 404 Department Not Found', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Department not found'}),
          404,
        );
      });

      expect(() => ApiService.getDepartmentDetail('unknown-dept'),
          throwsA(isA<Exception>()));
    });
  });

  // ─── 3. Department Model Resilience ─────────────────────────────────────────
  group('Department Model Parsing & Fallbacks', () {
    test('handles missing fields safely with intelligent defaults', () {
      final dept = Department.fromJson({});

      expect(dept.deptKey, '');
      expect(dept.title, '');
      expect(dept.subtitle, '');
      expect(dept.staffCount, 0);
      expect(dept.activeCount, 0);
      expect(dept.leadName, '');
      expect(dept.icon, Icons.business);
      expect(dept.color, const Color(0xFF64748B));
    });

    test('falls back gracefully on unknown icon string', () {
      final dept = Department.fromJson({
        'deptKey': 'research',
        'title': 'Research Lab',
        'icon': 'quantum_computer_icon_does_not_exist',
      });

      expect(dept.icon, Icons.business);
    });

    test('falls back gracefully on invalid hex color strings', () {
      final dept1 = Department.fromJson({'color': 'not-a-color'});
      final dept2 = Department.fromJson({'color': '#ZZZZZZ'});
      final dept3 = Department.fromJson({'color': '#12'});

      expect(dept1.color, const Color(0xFF64748B));
      expect(dept2.color, const Color(0xFF64748B));
      expect(dept3.color, const Color(0xFF64748B));
    });

    test('parses count fields when sent as double, string, or int', () {
      final deptDouble = Department.fromJson({
        'staffCount': 15.0,
        'activeCount': 12.0,
      });
      expect(deptDouble.staffCount, 15);
      expect(deptDouble.activeCount, 12);

      final deptString = Department.fromJson({
        'staffCount': '20',
        'activeCount': '18',
      });
      expect(deptString.staffCount, 20);
      expect(deptString.activeCount, 18);
    });
  });

  // ─── 4. HRProvider Department State & UI Tests ──────────────────────────────
  group('HRProvider & DepartmentsView Integration', () {
    test('HRProvider fetchDepartments updates departments list on API success',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'deptKey': 'ops',
                'title': 'Operations & Logistics',
                'subtitle': 'Supply Chain and Fleet',
                'staffCount': 10,
                'activeCount': 9,
                'leadName': 'David Miller',
                'icon': 'local_shipping',
                'color': '#059669',
              }
            ],
          }),
          200,
        );
      });

      final provider = HRProvider();
      await provider.fetchDepartments();

      expect(provider.departments.length, 1);
      expect(provider.departments.first.deptKey, 'ops');
      expect(provider.departments.first.title, 'Operations & Logistics');
      expect(provider.departmentsError, isNull);
      expect(provider.isDepartmentsLoading, false);
    });

    test(
        'HRProvider fetchDepartments sets error and retains fallback on failure',
        () async {
      ApiService.client = MockClient((request) async {
        throw http.ClientException('Network down');
      });

      final provider = HRProvider();
      final initialCount = provider.departments.length;
      expect(initialCount, greaterThan(0));

      await provider.fetchDepartments();

      expect(provider.departmentsError, isNotNull);
      expect(provider.departments.length,
          initialCount); // cached fallback retained
      expect(provider.isDepartmentsLoading, false);
    });

    test(
        'HRProvider fetchDepartmentDetail fetches and sets selectedDepartmentDetail',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'deptKey': 'tech',
              'title': 'Tech Unit',
              'staffCount': 25,
              'activeCount': 25,
            },
          }),
          200,
        );
      });

      final provider = HRProvider();
      final detail = await provider.fetchDepartmentDetail('tech');

      expect(detail, isNotNull);
      expect(detail!.deptKey, 'tech');
      expect(provider.selectedDepartmentDetail?.staffCount, 25);
      expect(provider.isDepartmentDetailLoading, false);
    });

    testWidgets(
        'DepartmentsView renders loading state when loading with empty list',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.departments = [];
      provider.isDepartmentsLoading = true;

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(home: DepartmentsView()),
        ),
      );

      expect(find.text('Loading organizational units...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('DepartmentsView renders full error state with retry button',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.departments = [];
      provider.departmentsError = 'Server connection timed out';

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(home: DepartmentsView()),
        ),
      );

      expect(find.text('Failed to load departments'), findsOneWidget);
      expect(find.text('Server connection timed out'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('DepartmentsView renders empty state when no departments found',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.departments = [];
      provider.departmentsError = null;
      provider.isDepartmentsLoading = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(home: DepartmentsView()),
        ),
      );

      expect(find.text('No departments found'), findsOneWidget);
      expect(find.text('Refresh'), findsWidgets);
    });

    testWidgets(
        'Tapping department card opens detail dialog and triggers detail fetch',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool detailEndpointCalled = false;
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/departments/tech') {
          detailEndpointCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'deptKey': 'tech',
                'title': 'Tech & Engineering',
                'subtitle': 'Frontend, Backend, Infrastructure & QA',
                'staffCount': 24,
                'activeCount': 22,
                'leadName': 'Anita Rao (Lead HR / Tech Ops)',
                'icon': 'computer',
                'color': '#2563EB',
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final provider = HRProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(home: DepartmentsView()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Tech & Engineering card and tap it
      final cardFinder = find.text('Tech & Engineering');
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Verify detail dialog is rendered
      expect(find.text('deptKey: tech'), findsOneWidget);
      // Unit Lead row must be completely removed
      expect(find.text('Unit Lead: '), findsNothing);
      expect(find.text('View in Staff Directory'), findsOneWidget);
      expect(find.text('Department Chat'), findsOneWidget);
      expect(detailEndpointCalled, true);

      // Tap close button on dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('deptKey: tech'), findsNothing);
    });

    testWidgets(
        'DepartmentsView cards display actual API counts and omit Unit Lead row completely',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.departments = [
        const Department(
          deptKey: 'tech',
          title: 'Tech & Engineering',
          subtitle: 'Frontend, Backend, Infrastructure & QA',
          staffCount: 8,
          activeCount: 3,
          leadName: '',
          iconName: 'computer',
          colorHex: '#2563EB',
        ),
        const Department(
          deptKey: 'telecalling',
          title: 'Telecalling & Client Relations',
          subtitle: 'Candidate Outreach, Lead Calling & Customer Support',
          staffCount: 2,
          activeCount: 2,
          leadName: '',
          iconName: 'headset_mic',
          colorHex: '#DB2777',
        ),
      ];

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(home: DepartmentsView()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify department titles are rendered
      expect(find.text('Tech & Engineering'), findsOneWidget);
      expect(find.text('Telecalling & Client Relations'), findsOneWidget);

      // Verify counts are department-isolated and displayed accurately
      // Tech: 8 members, 3 active
      expect(find.text('8'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Telecalling: 2 members, 2 active (appears twice: 2 members and 2 active)
      expect(find.text('2'), findsNWidgets(2));

      // Verify Unit Lead row and star icon are completely removed from cards
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.text('Division Lead Unassigned'), findsNothing);
      expect(find.text('Unit Lead: '), findsNothing);
      expect(find.text('Unit Lead'), findsNothing);

      // Verify action buttons and icons remain intact
      expect(find.text('View Staff'), findsNWidgets(2));
      expect(find.textContaining('Chat'), findsWidgets);
      expect(find.byIcon(Icons.info_outline_rounded), findsNWidgets(2));
    });
  });
}
