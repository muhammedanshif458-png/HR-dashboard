import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/features/chat/department_chat_view.dart';

void main() {
  setUpAll(() {
    HRProvider.enableTestFixtures = true;
  });

  tearDownAll(() {
    HRProvider.enableTestFixtures = false;
  });

  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  // ─── 1. ApiService Department Chat Endpoints ──────────────────────────────
  group('ApiService Department Chat Endpoints (Screen 11)', () {
    test('getDepartmentMessages parses envelope and message fields correctly',
        () async {
      ApiService.setToken('test_chat_token');
      ApiService.client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/hr/departments/tech/messages');
        expect(request.headers['Authorization'], 'Bearer test_chat_token');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Department messages retrieved successfully',
            'data': [
              {
                '_id': 'msg_tech_101',
                'departmentKey': 'tech',
                'senderId': 'staff_2',
                'senderName': 'Arjun Desai',
                'text': 'Deploying new release to staging server.',
                'timestamp': '2026-10-16T09:30:00.000Z',
                'isRead': true,
                'deletedForEveryone': false,
                'deletedByIds': ['staff_9'],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final messages = await ApiService.getDepartmentMessages('tech');
      expect(messages.length, 1);
      final m = messages.first;
      expect(m.id, 'msg_tech_101');
      expect(m.senderId, 'staff_2');
      expect(m.senderName, 'Arjun Desai');
      expect(m.text, 'Deploying new release to staging server.');
      expect(m.isRead, true);
      expect(m.deletedForEveryone, false);
      expect(m.deletedByIds.contains('staff_9'), true);
      expect(m.isHiddenFor('staff_9'), true);
      expect(m.isHiddenFor('staff_2'), false);
    });

    test(
        'getDepartmentMessages throws descriptive exception when endpoint fails',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Department not found',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.getDepartmentMessages('unknown_dept'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Department not found'))),
      );
    });

    test('sendDepartmentMessage dispatches POST with text and senderName',
        () async {
      ApiService.setToken('test_chat_token');
      ApiService.client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/hr/departments/telecalling/messages');
        expect(request.headers['Authorization'], 'Bearer test_chat_token');

        final body = jsonDecode(request.body);
        expect(body['text'], 'Campaign targets updated.');
        expect(body['senderName'], 'Anita Roy (HR Manager)');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Message sent successfully',
            'data': {
              '_id': 'msg_tele_201',
              'departmentKey': 'telecalling',
              'text': 'Campaign targets updated.',
              'senderName': 'Anita Roy (HR Manager)',
              'timestamp': '2026-10-16T10:00:00.000Z',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final success = await ApiService.sendDepartmentMessage(
        'telecalling',
        'Campaign targets updated.',
        senderName: 'Anita Roy (HR Manager)',
      );
      expect(success, true);
    });

    test('sendDepartmentMessage throws exception when server rejects request',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Message text cannot be empty',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.sendDepartmentMessage('tech', ''),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Message text cannot be empty'))),
      );
    });

    test('deleteDepartmentMessageForMe dispatches PATCH to correct endpoint',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path,
            '/api/hr/departments/tech/messages/msg_123/delete-for-me');
        final body = jsonDecode(request.body);
        expect(body['userId'], 'user_456');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Message deleted for user successfully',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ok = await ApiService.deleteDepartmentMessageForMe(
          'tech', 'msg_123', 'user_456');
      expect(ok, true);
    });

    test(
        'deleteDepartmentMessageForMe throws DeletionPermissionException on 403',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Unauthorized deletion request',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.deleteDepartmentMessageForMe(
            'tech', 'msg_123', 'user_456'),
        throwsA(isA<DeletionPermissionException>()),
      );
    });

    test('deleteDepartmentMessageForEveryone dispatches DELETE to endpoint',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path,
            '/api/hr/departments/tech/messages/msg_tombstone');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Message deleted for everyone successfully',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ok = await ApiService.deleteDepartmentMessageForEveryone(
          'tech', 'msg_tombstone');
      expect(ok, true);
    });

    test(
        'deleteDepartmentMessageForEveryone throws DeletionPermissionException on 403',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message':
                'Only the sender or an HR manager can delete for everyone',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () =>
            ApiService.deleteDepartmentMessageForEveryone('tech', 'msg_denied'),
        throwsA(isA<DeletionPermissionException>().having(
            (e) => e.message, 'message', contains('delete for everyone'))),
      );
    });
  });

  // ─── 2. HRProvider Department Chat State & Loaders ─────────────────────────
  group('HRProvider Department Chat State & Loaders', () {
    test(
        'loadDepartmentMessages successfully populates thread and sets hasLoadedApiDepartmentChat',
        () async {
      final provider = HRProvider();
      expect(provider.hasLoadedApiDepartmentChat, false);

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Department messages retrieved',
            'data': [
              {
                '_id': 'live_msg_1',
                'departmentKey': 'tech',
                'senderId': 'staff_2',
                'senderName': 'Arjun Desai',
                'text': 'Live Tech room message from backend.',
                'timestamp': '2026-10-16T11:00:00.000Z',
                'isRead': false,
                'deletedForEveryone': false,
                'deletedByIds': [],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.loadDepartmentMessages('tech');

      expect(provider.hasLoadedApiDepartmentChat, true);
      expect(provider.isDepartmentChatLoading, false);
      expect(provider.departmentChatError, isNull);

      final thread = provider.getDepartmentThread('tech');
      expect(thread, isNotNull);
      expect(thread!.messages.length, 1);
      expect(
          thread.messages.first.text, 'Live Tech room message from backend.');
    });

    test(
        'loadDepartmentMessages failure sets departmentChatError and isolates from presenting mock data as live',
        () async {
      final provider = HRProvider();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Service temporarily unavailable',
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.loadDepartmentMessages('tech');

      expect(provider.hasLoadedApiDepartmentChat, false);
      expect(provider.isDepartmentChatLoading, false);
      expect(provider.departmentChatError, 'Service temporarily unavailable');

      // Thread messages must be empty when in error state and not loaded from live API
      final thread = provider.getDepartmentThread('tech');
      expect(thread, isNotNull);
      expect(thread!.messages.isEmpty, true);
    });

    test('sendDepartmentMessage optimistically updates state and triggers sync',
        () async {
      final provider = HRProvider();
      provider.login('admin@company.com', 'password');

      bool sentToServer = false;
      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/messages')) {
          sentToServer = true;
          return http.Response(
            jsonEncode({'success': true, 'message': 'Message dispatched'}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.sendDepartmentMessage(
          'tech', 'Sprint review starts in 10 minutes.');

      final thread = provider.getDepartmentThread('tech');
      expect(thread, isNotNull);
      expect(
          thread!.messages
              .any((m) => m.text == 'Sprint review starts in 10 minutes.'),
          true);
      expect(sentToServer, true);
    });

    test('deleteDepartmentMessageForMe marks message hidden for caller',
        () async {
      final provider = HRProvider();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'message': 'Deleted for caller'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final initialThread = provider.getDepartmentThread('tech')!;
      final targetMsg = initialThread.messages.first;

      final result = await provider.deleteDepartmentMessageForMe(
          'tech', targetMsg.id, 'admin_1');

      expect(result.isSuccess, true);
      final updatedThread = provider.getDepartmentThread('tech')!;
      final updatedMsg =
          updatedThread.messages.firstWhere((m) => m.id == targetMsg.id);
      expect(updatedMsg.isHiddenFor('admin_1'), true);
    });

    test(
        'deleteDepartmentMessageForEveryone removes message from thread when authorized',
        () async {
      final provider = HRProvider();
      provider.login('admin@company.com', 'password'); // Role is HR Manager

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'message': 'Deleted for everyone'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final initialThread = provider.getDepartmentThread('tech')!;
      final targetMsg = initialThread.messages.first;

      final result = await provider.deleteDepartmentMessageForEveryone(
          'tech', targetMsg.id, 'admin_1');

      expect(result.isSuccess, true);
      final updatedThread = provider.getDepartmentThread('tech')!;
      expect(updatedThread.messages.any((m) => m.id == targetMsg.id), false);
    });
  });

  // ─── 3. DepartmentChatView Widget Verification ────────────────────────────
  group('DepartmentChatView Widget Verification', () {
    testWidgets('renders header, member info, and message input',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'widget_msg_1',
                'departmentKey': 'tech',
                'senderId': 'staff_2',
                'senderName': 'Arjun Desai',
                'text': 'Unit testing UI components.',
                'timestamp': '2026-10-16T11:00:00.000Z',
                'isRead': true,
                'deletedForEveryone': false,
                'deletedByIds': [],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const Scaffold(
              body: DepartmentChatView(departmentKey: 'tech'),
            ),
          ),
        ),
      );

      // Settle frame callbacks and async loader
      await tester.pumpAndSettle();

      expect(find.text('Tech & Engineering'), findsOneWidget);
      expect(find.text('Department Group'), findsOneWidget);
      expect(find.text('View Department Staff'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Unit testing UI components.'), findsOneWidget);
    });

    testWidgets('displays error state and retry button on load failure',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Failed to reach chat server',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const Scaffold(
              body: DepartmentChatView(departmentKey: 'tech'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to reach chat server'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);

      // Verify Retry Connection button triggers reload
      bool retryAttempted = false;
      ApiService.client = MockClient((request) async {
        retryAttempted = true;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'msg_after_retry',
                'departmentKey': 'tech',
                'senderId': 'staff_2',
                'senderName': 'Arjun Desai',
                'text': 'Connection restored!',
                'timestamp': '2026-10-16T11:05:00.000Z',
                'isRead': true,
                'deletedForEveryone': false,
                'deletedByIds': [],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(retryAttempted, true);
      expect(find.text('Connection restored!'), findsOneWidget);
    });
  });

  // ─── 4. Role-Based Chat Endpoint Selection ────────────────────────────────
  group('Role-Based Chat Endpoint Selection (Staff vs HR)', () {
    test('routes to /api/staff/departments/:key/messages when isStaff is true',
        () async {
      String? requestedPath;
      ApiService.client = MockClient((request) async {
        requestedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // Staff GET
      await ApiService.getDepartmentMessages('tech', isStaff: true);
      expect(requestedPath, '/api/staff/departments/tech/messages');

      // Staff POST
      await ApiService.sendDepartmentMessage('tech', 'Hello team',
          isStaff: true);
      expect(requestedPath, '/api/staff/departments/tech/messages');

      // Staff delete-for-me
      await ApiService.deleteDepartmentMessageForMe('tech', 'msg123', 'staff1',
          isStaff: true);
      expect(requestedPath,
          '/api/staff/departments/tech/messages/msg123/delete-for-me');

      // Staff delete-for-everyone
      await ApiService.deleteDepartmentMessageForEveryone('tech', 'msg123',
          isStaff: true);
      expect(requestedPath, '/api/staff/departments/tech/messages/msg123');

      // HR GET defaults to /api/hr
      await ApiService.getDepartmentMessages('tech', isStaff: false);
      expect(requestedPath, '/api/hr/departments/tech/messages');
    });

    test('HRProvider passes role to chat ApiService based on currentUser role',
        () async {
      final provider = HRProvider();
      provider.setCurrentUserForTesting(
        Staff(
          id: 'staff_101',
          name: 'Jane Staff',
          email: 'jane@lysoftware.com',
          phoneNumber: '1234567890',
          department: 'Tech',
          role: 'Staff',
          joinDate: '2025-01-01',
          status: 'active',
          onLeaveToday: false,
          designation: 'Frontend Engineer',
          workMode: 'Office',
        ),
      );

      String? requestedPath;
      ApiService.client = MockClient((request) async {
        requestedPath = request.url.path;
        return http.Response(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.loadDepartmentMessages('tech');
      expect(requestedPath, '/api/staff/departments/tech/messages');
    });
  });
}
