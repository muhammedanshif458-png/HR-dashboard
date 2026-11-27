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
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/tasks/tasks_view.dart';
import 'package:ly_hr_dashboard_flutter/app.dart';

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
    await _loadCustomFonts();
  });

  testWidgets('renders TasksView matching reference design and captures preview',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1050);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    ApiService.client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Loaded',
          'data': [
            {
              '_id': 'update_1',
              'employeeId': 'EMP1098',
              'employeeName': 'Hashim k',
              'department': 'Tech',
              'title': 'work',
              'updateText': 'database connect',
              'date': '2026-11-05',
              'createdAt': '2026-11-05T14:37:00.000Z',
            },
            {
              '_id': 'update_2',
              'employeeId': 'EMP1066',
              'employeeName': 'Rahul k',
              'department': 'Tech',
              'title': 'UI Implementation & Component Balancing',
              'updateText':
                  'Worked on Staff-hub application, reviewed the dashboard screens, implemented attendance details modal, and refined the overall user experience and responsive layout.',
              'date': '2026-11-19',
              'createdAt': '2026-11-19T16:15:00.000Z',
            },
            {
              '_id': 'update_3',
              'employeeId': 'EMP1092',
              'employeeName': 'Vishnu ps',
              'department': 'Telecalling',
              'title': 'Client Outreach & Onboarding Calls',
              'updateText':
                  'Conducted 24 onboarding verification calls with enterprise leads, updated CRM records, and scheduled follow-ups for tomorrow morning.',
              'date': '2026-11-19',
              'createdAt': '2026-11-19T15:45:00.000Z',
            },
            {
              '_id': 'update_4',
              'employeeId': 'EMP1085',
              'employeeName': 'Shibu k',
              'department': 'Tech',
              'title': 'API Endpoint Optimization',
              'updateText':
                  'Refactored workforce attendance sync microservice, reduced database latency by 32%, verified unit tests with QA team.',
              'date': '2026-11-19',
              'createdAt': '2026-11-19T14:20:00.000Z',
            },
          ],
          'pagination': {
            'page': 1,
            'limit': 20,
            'total': 4,
            'totalPages': 1,
          }
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final provider = HRProvider();
    provider.setCurrentUserForTesting(Staff(
      id: 'admin_1',
      employeeId: 'EMP001',
      name: 'Super Admin',
      email: 'admin@ly.com',
      phoneNumber: '+919876543210',
      role: 'Super Admin',
      department: 'Management',
      joinDate: '2024-01-01',
      status: 'Active',
      onLeaveToday: false,
    ));
    provider.navigateToTasks();
    provider.hasLoadedApiDailyUpdates = true;
    provider.isDailyUpdatesLoading = false;
    provider.apiDailyUpdatesList = [
      DailyUpdate(
        id: 'update_1',
        staffId: 'emp_1098',
        employeeId: 'EMP1098',
        employeeName: 'Hashim k',
        department: 'Tech',
        title: 'work',
        updateText: 'database connect',
        date: '2026-11-05',
        createdAt: '2026-11-05T14:37:00.000Z',
      ),
      DailyUpdate(
        id: 'update_2',
        staffId: 'emp_1066',
        employeeId: 'EMP1066',
        employeeName: 'Rahul k',
        department: 'Tech',
        title: 'UI Implementation & Component Balancing',
        updateText:
            'Worked on Staff-hub application, reviewed the dashboard screens, implemented attendance details modal, and refined the overall user experience and responsive layout.',
        date: '2026-11-19',
        createdAt: '2026-11-19T16:15:00.000Z',
      ),
      DailyUpdate(
        id: 'update_3',
        staffId: 'emp_1092',
        employeeId: 'EMP1092',
        employeeName: 'Vishnu ps',
        department: 'Telecalling',
        title: 'Client Outreach & Onboarding Calls',
        updateText:
            'Conducted 24 onboarding verification calls with enterprise leads, updated CRM records, and scheduled follow-ups for tomorrow morning.',
        date: '2026-11-19',
        createdAt: '2026-11-19T15:45:00.000Z',
      ),
      DailyUpdate(
        id: 'update_4',
        staffId: 'emp_1085',
        employeeId: 'EMP1085',
        employeeName: 'Shibu k',
        department: 'Tech',
        title: 'API Endpoint Optimization',
        updateText:
            'Refactored workforce attendance sync microservice, reduced database latency by 32%, verified unit tests with QA team.',
        date: '2026-11-19',
        createdAt: '2026-11-19T14:20:00.000Z',
      ),
    ];

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Plus Jakarta Sans',
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        ),
        home: RepaintBoundary(
          key: repaintKey,
          child: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const AppShell(child: TasksView()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify key UI elements
    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.text('Staff Daily Work Updates'), findsOneWidget);
    expect(find.text('Select Updates'), findsOneWidget);
    expect(find.text('Hashim k'), findsWidgets);
    expect(find.text('Rahul k'), findsWidgets);
    expect(find.text('Vishnu ps'), findsOneWidget);
    expect(find.text('Shibu k'), findsOneWidget);
    expect(find.text("Member's Leave"), findsOneWidget);

    // Capture visual snapshot
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File(
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/tasks_view_preview.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });
  });
}
