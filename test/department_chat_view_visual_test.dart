import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/services/chat_socket_service.dart';
import 'package:ly_hr_dashboard_flutter/features/chat/department_chat_view.dart';
import 'package:ly_hr_dashboard_flutter/app.dart';
import 'fixtures/hr_mock_fixtures.dart';

Future<void> _loadCustomFonts() async {
  final fontLoader = FontLoader('Plus Jakarta Sans');
  for (final name in [
    'PlusJakartaSans-Regular.ttf',
    'PlusJakartaSans-Medium.ttf',
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
    'PlusJakartaSans-ExtraBold.ttf',
  ]) {
    final file = File('assets/fonts/$name');
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await fontLoader.load();

  final iconFile = File(
      'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (iconFile.existsSync()) {
    final iconLoader = FontLoader('MaterialIcons');
    final bytes = iconFile.readAsBytesSync();
    iconLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await iconLoader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    installMockFixtures();
    HRProvider.enableTestFixtures = true;
    await _loadCustomFonts();
  });

  tearDownAll(() {
    uninstallMockFixtures();
    HRProvider.enableTestFixtures = false;
  });

  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  testWidgets(
      'renders DepartmentChatView matching reference design and captures preview',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    ChatSocketService().isTestMode = true;

    // Seed mock responses so loadDepartmentMessages completes immediately
    ApiService.setToken('test_token');
    ApiService.client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'OK',
          'data': [
            {
              '_id': 'msg_1',
              'departmentKey': 'tech',
              'senderId': 'user_super_admin',
              'senderName': 'Super Admin (Super Admin)',
              'senderRole': 'SUPER_ADMIN',
              'receiverId': 'dept_tech',
              'text': 'GD evening',
              'timestamp': '2026-11-05T12:07:00.000Z',
              'isRead': true,
              'deletedForEveryone': false,
              'deletedByIds': [],
            },
            {
              '_id': 'msg_2',
              'departmentKey': 'tech',
              'senderId': 'user_super_admin',
              'senderName': 'Super Admin (Super Admin)',
              'senderRole': 'SUPER_ADMIN',
              'receiverId': 'dept_tech',
              'text': 'teammmme',
              'timestamp': '2026-11-05T08:28:00.000Z',
              'isRead': true,
              'deletedForEveryone': false,
              'deletedByIds': [],
            },
            {
              '_id': 'msg_3',
              'departmentKey': 'tech',
              'senderId': 'emp_rk',
              'senderName': 'Rahul k',
              'senderRole': 'STAFF',
              'receiverId': 'dept_tech',
              'text': 'hllll',
              'timestamp': '2026-11-06T10:19:00.000Z',
              'isRead': true,
              'deletedForEveryone': false,
              'deletedByIds': [],
            },
            {
              '_id': 'msg_4',
              'departmentKey': 'tech',
              'senderId': 'emp_rk',
              'senderName': 'Rahul k',
              'senderRole': 'STAFF',
              'receiverId': 'dept_tech',
              'text': 'hhh',
              'timestamp': '2026-11-13T10:06:00.000Z',
              'isRead': true,
              'deletedForEveryone': false,
              'deletedByIds': [],
            },
          ],
          'pagination': {
            'page': 1,
            'limit': 50,
            'total': 4,
            'totalPages': 1,
            'hasMore': false,
            'departmentKey': 'tech',
          }
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final provider = HRProvider();
    provider.setCurrentUserForTesting(
      Staff(
        id: 'user_super_admin',
        name: 'Super Admin',
        role: 'Super Admin',
        email: 'superadmin@lysoftware.com',
        phoneNumber: '+1 555 0199',
        department: 'Management',
        joinDate: '2023-01-01',
        status: 'active',
        onLeaveToday: false,
      ),
    );

    // Seed department staff
    provider.employeeDirectory = [
      Staff(
        id: 'emp_at1',
        name: 'Attendance Tester 1795005051...',
        email: 'at1@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'QA Engineer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'QA Engineer',
      ),
      Staff(
        id: 'emp_at2',
        name: 'Attendance Tester 1794988125315',
        email: 'at2@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'QA Engineer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'QA Engineer',
      ),
      Staff(
        id: 'emp_at3',
        name: 'Attendance Tester 1794910372153',
        email: 'at3@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'QA Engineer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'QA Engineer',
      ),
      Staff(
        id: 'emp_at4',
        name: 'Attendance Tester 1794825243885',
        email: 'at4@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'QA Engineer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'QA Engineer',
      ),
      Staff(
        id: 'emp_sk',
        name: 'shibu k',
        email: 'shibu@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'Software Engineer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Software Engineer',
      ),
      Staff(
        id: 'emp_hk',
        name: 'Hashim k',
        email: 'hashim@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'Software Engineer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Software Engineer',
      ),
      Staff(
        id: 'emp_rk',
        name: 'Rahul k',
        email: 'rahul@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'Software Engineer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Software Engineer',
      ),
      Staff(
        id: 'emp_rk2',
        name: 'Rashid k',
        email: 'rashid@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'Software Engineer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Software Engineer',
      ),
      Staff(
        id: 'emp_fa',
        name: 'Faisal Ahmed',
        email: 'faisal@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'DevOps Specialist',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'DevOps Specialist',
      ),
      Staff(
        id: 'emp_as',
        name: 'Ananya Sen',
        email: 'ananya@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'Frontend Architect',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Frontend Architect',
      ),
      Staff(
        id: 'emp_mn',
        name: 'Mohammed N.',
        email: 'mohammed@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'Backend Engineer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'Backend Engineer',
      ),
      Staff(
        id: 'emp_pl',
        name: 'Pooja Lakshmi',
        email: 'pooja@test.com',
        phoneNumber: '',
        department: 'Tech & Engineering',
        role: 'UI/UX Designer',
        joinDate: '2024-01-01',
        status: 'active',
        onLeaveToday: false,
        designation: 'UI/UX Designer',
      ),
    ];

    provider.hasLoadedApiDepartmentChat = true;
    provider.isChatSocketConnected = true;
    provider.activeDepartmentChatKey = 'tech';
    provider.setScreen('departments'); // Activates Department Groups in Sidebar

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Plus Jakarta Sans',
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        ),
        home: RepaintBoundary(
          key: boundaryKey,
          child: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const Scaffold(
              body: AppShell(
                child: DepartmentChatView(departmentKey: 'tech'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify UI components rendered
    expect(find.text('Tech & Engineering'), findsWidgets);
    expect(find.text('Department Group'), findsWidgets);
    expect(find.text('• Live Sync'), findsOneWidget);
    expect(find.text('View Department Staff'), findsOneWidget);
    expect(find.text('GD evening'), findsOneWidget);
    expect(find.text('teammmme'), findsOneWidget);
    expect(find.text('hllll'), findsOneWidget);
    expect(find.text('hhh'), findsOneWidget);
    expect(find.text('Department Members (12)'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Manage Department Settings'), findsOneWidget);
    expect(find.text('Press Enter to send'), findsOneWidget);

    // Capture visual preview
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final previewFile = File(
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/department_chat_preview.png');
          await previewFile.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });
  });
}
