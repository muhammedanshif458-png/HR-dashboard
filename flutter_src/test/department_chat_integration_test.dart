import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/models/department.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/services/chat_socket_service.dart';
import 'package:ly_hr_dashboard_flutter/features/chat/department_chat_view.dart';
import 'package:ly_hr_dashboard_flutter/features/departments/departments_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late http.Client originalClient;

  setUpAll(() {
    originalClient = ApiService.client;
  });

  setUp(() {
    ChatSocketService().isTestMode = true;
    ApiService.setToken('test_jwt_hr_token_12345');
    ApiService.setUserRole('HR');
    ApiService.client = MockClient((request) async {
      if (request.url.path.contains('/messages')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [],
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 0,
              'totalPages': 1,
              'hasMore': false,
              'departmentKey': 'tech',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'});
    });
  });

  tearDown(() {
    ApiService.client = originalClient;
    ChatSocketService().disposeSocket();
  });

  group('ApiService Department Chat REST Integration', () {
    test(
        'getDepartmentMessagesPaginated retrieves messages and pagination metadata',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/hr/departments/tech/messages');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['limit'], '50');
        expect(
            request.headers['Authorization'], 'Bearer test_jwt_hr_token_12345');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Department messages retrieved successfully',
            'data': [
              {
                'id': 'msg_001',
                'departmentKey': 'tech',
                'senderId': 'user_hr_1',
                'senderName': 'Anita Rao',
                'senderRole': 'HR',
                'text': 'Sprint planning scheduled for 11 AM.',
                'timestamp': '2026-10-29T10:00:00.000Z',
                'isRead': true,
                'deletedForEveryone': false,
                'deletedByIds': [],
              },
              {
                'id': 'msg_002',
                'departmentKey': 'tech',
                'senderId': 'staff_dev_1',
                'senderName': 'Rohan Verma',
                'senderRole': 'STAFF',
                'text': 'Understood, backend API updates are pushed.',
                'timestamp': '2026-10-29T10:05:00.000Z',
                'isRead': true,
                'deletedForEveryone': false,
                'deletedByIds': [],
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 45,
              'totalPages': 1,
              'hasMore': false,
              'departmentKey': 'tech',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.getDepartmentMessagesPaginated('tech',
          page: 1, limit: 50);

      expect(result.messages.length, 2);
      expect(result.messages.first.senderRole, 'HR');
      expect(result.messages.first.isHR, isTrue);
      expect(result.messages.last.senderRole, 'STAFF');
      expect(result.messages.last.isHR, isFalse);
      expect(result.page, 1);
      expect(result.total, 45);
      expect(result.hasMore, isFalse);
    });

    test('sendDepartmentMessage posts valid payload and parses server response',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/hr/departments/tech/messages');
        final body = jsonDecode(request.body);
        expect(body['text'], 'Testing live broadcast');
        expect(body['clientMessageId'], 'client_temp_123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Message sent successfully',
            'data': {
              'id': 'mongo_server_id_999',
              'departmentKey': 'tech',
              'senderId': 'user_hr_1',
              'senderName': 'Anita Rao',
              'senderRole': 'HR',
              'clientMessageId': 'client_temp_123',
              'text': 'Testing live broadcast',
              'timestamp': DateTime.now().toIso8601String(),
              'isRead': false,
              'deletedForEveryone': false,
              'deletedByIds': [],
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final msg = await ApiService.sendDepartmentMessage(
        'tech',
        'Testing live broadcast',
        clientMessageId: 'client_temp_123',
      );

      expect(msg.id, 'mongo_server_id_999');
      expect(msg.clientMessageId, 'client_temp_123');
      expect(msg.senderRole, 'HR');
      expect(msg.text, 'Testing live broadcast');
    });

    test('sendDepartmentMessage throws readable Exception on 400 bad request',
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
        () => ApiService.sendDepartmentMessage('tech', '   '),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Message text cannot be empty'))),
      );
    });
  });

  group('HRProvider Department Chat & Real-Time Sync', () {
    test('loadDepartmentMessages populates thread and pagination state',
        () async {
      final provider = HRProvider();
      provider.setCurrentUserForTesting(
        Staff(
          id: 'hr_user_1',
          name: 'Super Admin',
          role: 'HR Manager',
          email: 'admin@company.com',
          phoneNumber: '1234567890',
          department: 'HR',
          joinDate: '2024-01-01',
          status: 'active',
          onLeaveToday: false,
        ),
      );

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 'm1',
                'departmentKey': 'tech',
                'senderId': 'hr_user_1',
                'senderName': 'Super Admin',
                'senderRole': 'HR',
                'text': 'System maintenance tonight at 10 PM.',
                'timestamp': '2026-10-29T08:00:00.000Z',
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 60,
              'totalPages': 2,
              'hasMore': true,
              'departmentKey': 'tech',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.loadDepartmentMessages('tech');

      expect(provider.hasLoadedApiDepartmentChat, isTrue);
      expect(provider.departmentChatHasMore, isTrue);
      expect(provider.departmentChatTotalMessages, 60);

      final thread = provider.getDepartmentThread('tech');
      expect(thread, isNotNull);
      expect(thread!.messages.length, 1);
      expect(
          thread.messages.first.text, 'System maintenance tonight at 10 PM.');
    });

    test(
        'addOrReconcileDepartmentMessage prevents duplicates and updates by id or clientMessageId',
        () {
      final provider = HRProvider();
      const canonicalKey = 'tech';

      // 1. Initial message with clientMessageId
      final localMsg = ChatMessage(
        id: 'client_temp_777',
        clientMessageId: 'client_temp_777',
        senderId: 'hr_1',
        senderName: 'HR Admin',
        senderRole: 'HR',
        receiverId: 'dept_tech',
        departmentKey: 'tech',
        text: 'Initial outgoing message',
        timestamp: DateTime.now(),
      );
      provider.addOrReconcileDepartmentMessage(canonicalKey, localMsg);

      var thread = provider.getDepartmentThread(canonicalKey);
      expect(thread!.messages.length, 1);
      expect(thread.messages.first.id, 'client_temp_777');

      // 2. Server reconciles with authoritative MongoDB ID using same clientMessageId
      final serverMsg = ChatMessage(
        id: 'mongo_persisted_888',
        clientMessageId: 'client_temp_777',
        senderId: 'hr_1',
        senderName: 'HR Admin',
        senderRole: 'HR',
        receiverId: 'dept_tech',
        departmentKey: 'tech',
        text: 'Initial outgoing message',
        timestamp: localMsg.timestamp,
      );
      provider.addOrReconcileDepartmentMessage(canonicalKey, serverMsg);

      thread = provider.getDepartmentThread(canonicalKey);
      // Must NOT duplicate, must update to authoritative ID
      expect(thread!.messages.length, 1);
      expect(thread.messages.first.id, 'mongo_persisted_888');

      // 3. Duplicate socket event arrives with same mongo ID
      provider.addOrReconcileDepartmentMessage(canonicalKey, serverMsg);
      thread = provider.getDepartmentThread(canonicalKey);
      expect(thread!.messages.length, 1);
    });

    test(
        'real-time message deletion updates deletedForEveryone status in thread',
        () {
      final provider = HRProvider();
      final msg = ChatMessage(
        id: 'msg_to_delete_1',
        senderId: 'staff_1',
        senderName: 'Staff Member',
        receiverId: 'dept_tech',
        departmentKey: 'tech',
        text: 'Accidental message',
        timestamp: DateTime.now(),
        deletedForEveryone: false,
      );
      provider.addOrReconcileDepartmentMessage('tech', msg);
      provider.addOrReconcileDepartmentMessage(
        'telecalling',
        ChatMessage(
          id: msg.id,
          senderId: 'staff_tele',
          senderName: 'Telecalling Member',
          receiverId: 'dept_telecalling',
          departmentKey: 'telecalling',
          text: 'Different department message',
          timestamp: DateTime.now(),
        ),
      );

      var thread = provider.getDepartmentThread('tech');
      expect(thread!.messages.first.deletedForEveryone, isFalse);

      // Trigger socket deletion event
      provider.initDepartmentChatSocket('tech');
      ChatSocketService().emitTestMessageDeleted(
        msg.id,
        true,
        departmentKey: 'tech',
      );

      thread = provider.getDepartmentThread('tech');
      expect(thread!.messages.first.deletedForEveryone, isTrue);
      expect(thread.messages.first.text, 'Accidental message');
      expect(thread.messages.first.isHiddenFor('any_user'), isTrue);
      expect(
        provider
            .getDepartmentThread('telecalling')!
            .messages
            .first
            .deletedForEveryone,
        isFalse,
        reason: 'A Tech delete event must never mutate the Telecalling thread.',
      );
    });
  });

  group('Department Selection & Navigation Flows', () {
    testWidgets(
        'Clicking Open Chat on Tech opens Tech conversation and on Telecalling opens Telecalling',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(
        Staff(
          id: 'hr_admin_1',
          name: 'Anita HR',
          role: 'HR Manager',
          email: 'anita@company.com',
          phoneNumber: '1234567890',
          department: 'HR',
          joinDate: '2024-01-01',
          status: 'active',
          onLeaveToday: false,
        ),
      );
      provider.departments = [
        const Department(
          deptKey: 'tech',
          title: 'Tech & Engineering',
          subtitle: 'Frontend, Backend, Infrastructure & QA',
          staffCount: 12,
          activeCount: 11,
          iconName: 'computer',
          colorHex: '#2563EB',
        ),
        const Department(
          deptKey: 'telecalling',
          title: 'Telecalling & Client Relations',
          subtitle: 'Candidate Outreach & Client Relations',
          staffCount: 8,
          activeCount: 8,
          iconName: 'headset_mic',
          colorHex: '#DB2777',
        ),
      ];

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: DepartmentsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Tech and Telecalling cards render
      expect(find.text('Tech & Engineering'), findsOneWidget);
      expect(find.text('Telecalling & Client Relations'), findsOneWidget);

      final openChatButtons = find.widgetWithText(ElevatedButton, 'Open Chat');
      expect(openChatButtons, findsAtLeastNWidgets(2));

      // Click Open Chat on first card (Tech)
      await tester.tap(openChatButtons.first);
      await tester.pumpAndSettle();

      expect(provider.currentScreen, 'dept-chat');
      expect(provider.activeDepartmentChatKey, 'tech');

      // Now navigate to telecalling chat
      provider.navigateToDepartmentChat('telecalling');
      await tester.pumpAndSettle();

      expect(provider.activeDepartmentChatKey, 'telecalling');
    });

    testWidgets(
        'View Department Staff filters Employees Directory by canonical department name',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(
        Staff(
          id: 'hr_admin_1',
          name: 'Anita HR',
          role: 'HR Manager',
          email: 'anita@company.com',
          phoneNumber: '1234567890',
          department: 'HR',
          joinDate: '2024-01-01',
          status: 'active',
          onLeaveToday: false,
        ),
      );
      provider.departments = [
        const Department(
          deptKey: 'tech',
          title: 'Tech & Engineering',
          subtitle: 'Frontend, Backend, Infrastructure & QA',
          staffCount: 12,
          activeCount: 11,
          iconName: 'computer',
          colorHex: '#2563EB',
        ),
        const Department(
          deptKey: 'telecalling',
          title: 'Telecalling & Client Relations',
          subtitle: 'Candidate Outreach & Client Relations',
          staffCount: 8,
          activeCount: 8,
          iconName: 'headset_mic',
          colorHex: '#DB2777',
        ),
      ];

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: DepartmentsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final viewStaffButtons =
          find.widgetWithText(OutlinedButton, 'View Staff');
      expect(viewStaffButtons, findsAtLeastNWidgets(2));

      // Click View Staff on Tech card
      await tester.tap(viewStaffButtons.first);
      await tester.pumpAndSettle();

      expect(provider.currentScreen, 'employees');
      expect(provider.employeeDeptFilter, 'Tech');
    });
  });

  group('DepartmentChatView UI & Real-Time Sync Elements', () {
    testWidgets(
        'Displays department group title, live sync status badge, and distinguishes HR vs Staff messages',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(
        Staff(
          id: 'hr_current_user',
          name: 'Anita Rao',
          role: 'HR Manager',
          email: 'anita@company.com',
          phoneNumber: '1234567890',
          department: 'HR',
          joinDate: '2024-01-01',
          status: 'active',
          onLeaveToday: false,
        ),
      );

      // Seed staff list for sidebar
      provider.employeeDirectory = [
        Staff(
          id: 'staff_1',
          name: 'Rohan Verma',
          email: 'rohan@company.com',
          phoneNumber: '9876543210',
          department: 'Tech & Engineering',
          role: 'Staff',
          joinDate: '2025-01-01',
          status: 'active',
          onLeaveToday: false,
          designation: 'Backend Developer',
          workMode: 'Office',
        ),
      ];

      // Seed messages with both HR and Staff roles
      final hrMessage = ChatMessage(
        id: 'msg_hr_1',
        senderId: 'other_hr_user',
        senderName: 'Super Admin',
        senderRole: 'SUPER_ADMIN',
        receiverId: 'dept_tech',
        departmentKey: 'tech',
        text: 'All deployments are locked until after the audit.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final staffMessage = ChatMessage(
        id: 'msg_staff_1',
        senderId: 'staff_1',
        senderName: 'Rohan Verma',
        senderRole: 'STAFF',
        receiverId: 'dept_tech',
        departmentKey: 'tech',
        text: 'Noted, QA testing has been completed.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [
              hrMessage.toJson(),
              staffMessage.toJson(),
            ],
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 2,
              'totalPages': 1,
              'hasMore': false,
              'departmentKey': 'tech',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: DepartmentChatView(departmentKey: 'tech'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Header and Live Sync Badge
      expect(find.text('Tech & Engineering'), findsWidgets);
      expect(find.text('Department Group'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('chat_live_status_badge')), findsOneWidget);

      // 2. Verify View Department Staff action
      expect(find.text('View Department Staff'), findsOneWidget);

      // 3. Verify messages rendered
      expect(find.text('All deployments are locked until after the audit.'),
          findsOneWidget);
      expect(
          find.text('Noted, QA testing has been completed.'), findsOneWidget);

      // 4. Verify Role distinction badges
      expect(find.text('HR ADMIN'), findsOneWidget);
      expect(find.text('STAFF'), findsOneWidget);

      // 5. Verify composer
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('chat_send_button')), findsOneWidget);
    });

    testWidgets('Pagination button renders when departmentChatHasMore is true',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(
        Staff(
          id: 'hr_1',
          name: 'Anita Rao',
          role: 'HR Manager',
          email: 'anita@company.com',
          phoneNumber: '1234567890',
          department: 'HR',
          joinDate: '2024-01-01',
          status: 'active',
          onLeaveToday: false,
        ),
      );

      provider.hasLoadedApiDepartmentChat = true;
      provider.departmentChatHasMore = true;
      provider.departmentChatTotalMessages = 50;

      final msg = ChatMessage(
        id: 'msg_1',
        senderId: 'staff_1',
        senderName: 'Rohan',
        senderRole: 'STAFF',
        receiverId: 'dept_tech',
        departmentKey: 'tech',
        text: 'Recent message',
        timestamp: DateTime.now(),
      );
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [msg.toJson()],
            'pagination': {
              'page': 1,
              'limit': 1,
              'total': 50,
              'totalPages': 50,
              'hasMore': true,
              'departmentKey': 'tech',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: DepartmentChatView(departmentKey: 'tech'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('chat_load_older_button')), findsOneWidget);
      expect(find.textContaining('Load earlier messages'), findsOneWidget);
    });

    testWidgets(
        'Send button rejects blank message and sends valid message via POST',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(
        Staff(
          id: 'hr_1',
          name: 'Anita Rao',
          role: 'HR Manager',
          email: 'anita@company.com',
          phoneNumber: '1234567890',
          department: 'HR',
          joinDate: '2024-01-01',
          status: 'active',
          onLeaveToday: false,
        ),
      );
      provider.hasLoadedApiDepartmentChat = true;

      bool postCalled = false;
      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/hr/departments/tech/messages') {
          postCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Message sent successfully',
              'data': {
                'id': 'posted_msg_101',
                'departmentKey': 'tech',
                'senderId': 'hr_1',
                'senderName': 'Anita Rao',
                'senderRole': 'HR',
                'text': 'Please submit attendance logs by 6 PM.',
                'timestamp': DateTime.now().toIso8601String(),
                'isRead': false,
                'deletedForEveryone': false,
                'deletedByIds': [],
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: DepartmentChatView(departmentKey: 'tech'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sendButton = find.byKey(const ValueKey('chat_send_button'));

      // 1. Click send while input is blank - should do nothing
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(postCalled, isFalse);

      // 2. Enter whitespace only - should do nothing
      await tester.enterText(find.byType(TextField), '     ');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      expect(postCalled, isFalse);

      // 3. Enter valid text and click send
      await tester.enterText(
          find.byType(TextField), 'Please submit attendance logs by 6 PM.');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(postCalled, isTrue);
      expect(
          find.text('Please submit attendance logs by 6 PM.'), findsOneWidget);
    });

    testWidgets('Real-time incoming message via Socket.IO appends to UI stream',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = HRProvider();
      provider.setCurrentUserForTesting(
        Staff(
          id: 'hr_1',
          name: 'Anita Rao',
          role: 'HR Manager',
          email: 'anita@company.com',
          phoneNumber: '1234567890',
          department: 'HR',
          joinDate: '2024-01-01',
          status: 'active',
          onLeaveToday: false,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: DepartmentChatView(departmentKey: 'tech'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify message is not present initially
      expect(find.text('Realtime socket push from StaffHub'), findsNothing);

      // Simulate incoming Socket.IO event 'new_message'
      ChatSocketService().emitTestIncomingMessage(
        ChatMessage(
          id: 'socket_push_msg_777',
          senderId: 'staff_dev_1',
          senderName: 'Rohan Verma',
          senderRole: 'STAFF',
          receiverId: 'dept_tech',
          departmentKey: 'tech',
          text: 'Realtime socket push from StaffHub',
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the new message appears in the conversation stream
      expect(find.text('Realtime socket push from StaffHub'), findsOneWidget);
    });
  });
}
