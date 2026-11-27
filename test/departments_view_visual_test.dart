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
import 'package:ly_hr_dashboard_flutter/models/department.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/departments/departments_view.dart';
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

  testWidgets(
      'renders DepartmentsView matching reference design and captures preview',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1050);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockDepartments = [
      const Department(
        deptKey: 'tech',
        title: 'Tech & Engineering',
        subtitle: 'Frontend, Backend, Infrastructure & QA',
        staffCount: 12,
        activeCount: 8,
        leadName: 'Anita Rao',
        iconName: 'computer',
        colorHex: '#2563EB',
      ),
      const Department(
        deptKey: 'telecalling',
        title: 'Telecalling & Client Relations',
        subtitle: 'Candidate Outreach, Lead Calling & Customer Support',
        staffCount: 3,
        activeCount: 3,
        leadName: 'Neha Sharma',
        iconName: 'headset_mic',
        colorHex: '#9333EA',
      ),
    ];

    ApiService.client = MockClient((request) async {
      if (request.url.path.contains('/api/hr/departments')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'deptKey': 'tech',
                'title': 'Tech & Engineering',
                'subtitle': 'Frontend, Backend, Infrastructure & QA',
                'staffCount': 12,
                'activeCount': 8,
                'leadName': 'Anita Rao',
                'icon': 'computer',
                'color': '#2563EB',
              },
              {
                'deptKey': 'telecalling',
                'title': 'Telecalling & Client Relations',
                'subtitle':
                    'Candidate Outreach, Lead Calling & Customer Support',
                'staffCount': 3,
                'activeCount': 3,
                'leadName': 'Neha Sharma',
                'icon': 'headset_mic',
                'color': '#9333EA',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'success': true, 'data': []}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final provider = HRProvider();
    provider.setCurrentUserForTesting(Staff(
      id: 'admin_1',
      name: 'Super Admin',
      email: 'admin@ly.com',
      phoneNumber: '+919876543210',
      role: 'Super Admin',
      department: 'Management',
      joinDate: '2024-01-01',
      status: 'Active',
      onLeaveToday: false,
    ));
    provider.setScreen('departments');
    provider.departments = mockDepartments;

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      ChangeNotifierProvider<HRProvider>.value(
        value: provider,
        child: RepaintBoundary(
          key: repaintKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'Plus Jakarta Sans',
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            ),
            home: const AppShell(child: DepartmentsView()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify AppBar user profile
    expect(find.text('Admin'), findsWidgets);
    expect(find.text('HQ Org Lead'), findsOneWidget);

    // Verify Page Header & Breadcrumb
    expect(find.text('LY SOFTWARE'), findsWidgets);
    expect(find.text('ORGANIZATIONAL UNITS'), findsOneWidget);
    expect(find.text('Departments & Headcount'), findsOneWidget);
    expect(
        find.text(
            'Manage organizational structure, division leads, and active staff distributions.'),
        findsOneWidget);
    expect(find.text('Add Department'), findsOneWidget);

    // Verify 3 Summary Cards
    expect(find.text('TOTAL DEPARTMENTS'), findsOneWidget);
    expect(find.text('TOTAL WORKFORCE'), findsOneWidget);
    expect(find.text('ACTIVE ON DUTY'), findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is RichText && w.text.toPlainText().contains('2 Units')),
        findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is RichText && w.text.toPlainText().contains('15 Members')),
        findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is RichText && w.text.toPlainText().contains('11 Online')),
        findsOneWidget);

    // Verify Department Cards
    expect(find.text('Tech & Engineering'), findsOneWidget);
    expect(find.text('Core Division'), findsOneWidget);
    expect(find.text('Frontend, Backend, Infrastructure & QA'), findsOneWidget);
    expect(find.text('Telecalling & Client Relations'), findsOneWidget);
    expect(find.text('Operations'), findsOneWidget);

    // Verify Metrics inside Cards
    expect(find.text('Total Members'), findsNWidgets(2));
    expect(find.text('Active Staff'), findsNWidgets(2));
    expect(find.text('Unit Status'), findsNWidgets(2));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('Active'), findsNWidgets(2));

    // Verify Leads and Attendance Rates
    expect(find.text('Key Leads:'), findsNWidgets(2));
    expect(find.text('AK'), findsOneWidget);
    expect(find.text('MR'), findsOneWidget);
    expect(find.text('TL'), findsOneWidget);
    expect(find.text('SP'), findsOneWidget);
    expect(find.text('DR'), findsOneWidget);
    expect(find.text('Attendance Rate:'), findsNWidgets(2));
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('View Staff'), findsNWidgets(2));
    expect(find.text('Open Chat'), findsNWidgets(2));

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
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/departments_preview.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });
  });

  testWidgets(
      'renders Department Detail dialog matching reference design and captures preview',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1050);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockDepartments = [
      const Department(
        deptKey: 'tech',
        title: 'Tech & Engineering',
        subtitle: 'Frontend, Backend, Infrastructure & QA',
        staffCount: 12,
        activeCount: 8,
        leadName: 'Anita Rao',
        iconName: 'laptop_mac',
        colorHex: '#2563EB',
      ),
      const Department(
        deptKey: 'telecalling',
        title: 'Telecalling & Client Relations',
        subtitle: 'Candidate Outreach, Lead Calling & Customer Support',
        staffCount: 3,
        activeCount: 3,
        leadName: 'Neha Sharma',
        iconName: 'headset_mic',
        colorHex: '#9333EA',
      ),
    ];

    final mockStaff = [
      Staff(
        id: 'staff_1',
        name: 'Attendance Tester 1795005051646',
        email: 'tester1@ly.com',
        phoneNumber: '+919876543201',
        role: 'QA Lead',
        designation: 'Quality Assurance',
        department: 'Tech & Engineering',
        joinDate: '2024-01-15',
        status: 'Active',
        onLeaveToday: false,
      ),
      Staff(
        id: 'staff_2',
        name: 'Attendance Tester 1794988125315',
        email: 'tester2@ly.com',
        phoneNumber: '+919876543202',
        role: 'QA Engineer',
        designation: 'Automation',
        department: 'Tech & Engineering',
        joinDate: '2024-02-01',
        status: 'Active',
        onLeaveToday: false,
      ),
      Staff(
        id: 'staff_3',
        name: 'Attendance Tester 1794910372153',
        email: 'tester3@ly.com',
        phoneNumber: '+919876543203',
        role: 'QA Engineer',
        designation: 'Performance',
        department: 'Tech & Engineering',
        joinDate: '2024-02-15',
        status: 'Active',
        onLeaveToday: false,
      ),
      Staff(
        id: 'staff_4',
        name: 'Attendance Tester 1794825243885',
        email: 'tester4@ly.com',
        phoneNumber: '+919876543204',
        role: 'QA Engineer',
        designation: 'Security',
        department: 'Tech & Engineering',
        joinDate: '2024-03-01',
        status: 'Active',
        onLeaveToday: false,
      ),
      Staff(
        id: 'staff_5',
        name: 'shibu k',
        email: 'shibu@ly.com',
        phoneNumber: '+919876543205',
        role: 'Software Engineer',
        designation: 'Mobile Development',
        department: 'Tech & Engineering',
        joinDate: '2024-03-15',
        status: 'Active',
        onLeaveToday: false,
      ),
    ];

    ApiService.client = MockClient((request) async {
      if (request.url.path.contains('/api/hr/departments/tech')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'deptKey': 'tech',
              'title': 'Tech & Engineering',
              'subtitle': 'Frontend, Backend, Infrastructure & QA',
              'staffCount': 12,
              'activeCount': 8,
              'leadName': 'Anita Rao',
              'icon': 'computer',
              'color': '#2563EB',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.contains('/api/hr/departments')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'deptKey': 'tech',
                'title': 'Tech & Engineering',
                'subtitle': 'Frontend, Backend, Infrastructure & QA',
                'staffCount': 12,
                'activeCount': 8,
                'leadName': 'Anita Rao',
                'icon': 'computer',
                'color': '#2563EB',
              },
              {
                'deptKey': 'telecalling',
                'title': 'Telecalling & Client Relations',
                'subtitle':
                    'Candidate Outreach, Lead Calling & Customer Support',
                'staffCount': 3,
                'activeCount': 3,
                'leadName': 'Neha Sharma',
                'icon': 'headset_mic',
                'color': '#9333EA',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'success': true, 'data': []}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final provider = HRProvider();
    provider.setCurrentUserForTesting(Staff(
      id: 'admin_1',
      name: 'Super Admin',
      email: 'admin@ly.com',
      phoneNumber: '+919876543210',
      role: 'Super Admin',
      department: 'Management',
      joinDate: '2024-01-01',
      status: 'Active',
      onLeaveToday: false,
    ));
    provider.setScreen('departments');
    provider.departments = mockDepartments;
    provider.staffList = mockStaff;

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      ChangeNotifierProvider<HRProvider>.value(
        value: provider,
        child: RepaintBoundary(
          key: repaintKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'Plus Jakarta Sans',
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            ),
            home: const AppShell(child: DepartmentsView()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the Tech & Engineering card to open the detail dialog
    await tester.tap(find.text('Tech & Engineering'));
    await tester.pumpAndSettle();

    // Verify dialog header elements
    expect(find.text('Tech & Engineering'), findsNWidgets(2));
    expect(find.text('Main Dept'), findsOneWidget);
    expect(find.text('deptKey: tech'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Verify 3 top metric cards
    expect(find.text('TOTAL MEMBERS'), findsWidgets);
    expect(find.text('ACTIVE STAFF'), findsWidgets);
    expect(find.text('UNIT STATUS'), findsOneWidget);
    expect(find.text('people'), findsWidgets);
    expect(find.text('on duty'), findsOneWidget);

    // Verify Assigned Team Members section
    expect(find.text('ASSIGNED TEAM MEMBERS'), findsOneWidget);
    expect(find.text('Filter by Role'), findsOneWidget);
    expect(find.text('Attendance Tester 1795005051646'), findsOneWidget);
    expect(find.text('shibu k'), findsOneWidget);
    expect(find.text('ACTIVE'), findsWidgets);

    // Verify bottom action buttons
    expect(find.text('View in Staff Directory'), findsOneWidget);
    expect(find.text('Department Chat'), findsOneWidget);

    // Capture visual snapshot of the modal dialog
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File(
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/department_details_preview.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });
  });
}
