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
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/reports/reports_view.dart';
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
      'renders ReportsView matching reference design and captures preview',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1050);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    ApiService.client = MockClient((request) async {
      if (request.url.path.contains('/reports/attendance')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Loaded',
            'data': {
              'statusSummary': [
                {'_id': 'PRESENT', 'count': 62},
                {'_id': 'HALF_DAY', 'count': 15},
              ],
              'departmentSummary': [],
              'lateArrivals': 0,
              'onTimeArrivals': 0,
              'totalAbsent': 0,
              'totalAttendanceRecords': 62,
              'presentRecords': 62,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.contains('/reports/leaves')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Loaded',
            'data': {
              'totalLeaveApplications': 14,
              'approvedRequests': 9,
              'pendingRequests': 1,
              'rejectedRequests': 4,
              'casualLeaves': 5,
              'sickMedicalLeaves': 9,
              'statusSummary': [
                {'_id': 'APPROVED', 'count': 9},
                {'_id': 'PENDING', 'count': 1},
                {'_id': 'REJECTED', 'count': 4},
              ],
              'typeSummary': [
                {'_id': 'SICK', 'count': 9},
                {'_id': 'CASUAL', 'count': 5},
              ],
            },
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
    provider.setScreen('reports');
    provider.reportsStartDate = DateTime(2026, 11, 1);
    provider.reportsEndDate = DateTime(2026, 11, 19);

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
            child: const AppShell(child: ReportsView()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify key UI elements matching screenshot
    expect(find.text('HR Reports & Workforce Analytics'), findsOneWidget);
    expect(find.text('Attendance & Punctuality Overview'), findsOneWidget);
    expect(find.text('Leave Distribution & Types Overview'), findsOneWidget);
    expect(find.text('Total Attendance Records'), findsOneWidget);
    expect(find.text('Nov 01, 2026 – Nov 19, 2026'), findsOneWidget);
    expect(find.text('62 Total Records Logged'), findsOneWidget);
    expect(find.text('100% Processed Rate'), findsOneWidget);
    expect(find.text('Export Report'), findsOneWidget);

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
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/reports_view_preview.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });
  });

  testWidgets(
      'renders Total Attendance Records drill-down matching reference screenshot and captures preview',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1050);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAttendanceRecords = [
      {
        '_id': 'att_1',
        'employee': {
          '_id': 'emp_1',
          'employeeId': 'EMP1013',
          'firstName': 'Arjun',
          'lastName': 'kp',
          'department': 'Telecalling',
        },
        'date': '2026-11-19',
        'checkIn': '2026-11-19T10:34:00Z',
        'checkInTime': '10:34 AM',
        'checkOutTime': null,
        'status': 'PRESENT',
        'minutesLate': 95,
        'workingHours': 0.0,
      },
      {
        '_id': 'att_2',
        'employee': {
          '_id': 'emp_2',
          'employeeId': 'EMP1107',
          'firstName': 'Attendance Tester',
          'lastName': '1795005051646',
          'department': 'Tech',
        },
        'date': '2026-11-18',
        'checkIn': '2026-11-18T18:00:00Z',
        'checkInTime': '06:00 PM',
        'checkOutTime': '06:00 PM',
        'status': 'PRESENT',
        'minutesLate': 48,
        'workingHours': 8.0,
      },
      {
        '_id': 'att_3',
        'employee': {
          '_id': 'emp_3',
          'employeeId': 'EMP1105',
          'firstName': 'Attendance Tester',
          'lastName': '1794988125315',
          'department': 'Tech',
        },
        'date': '2026-11-18',
        'checkIn': '2026-11-18T13:18:00Z',
        'checkInTime': '01:18 PM',
        'checkOutTime': '01:18 PM',
        'status': 'PRESENT',
        'minutesLate': 19,
        'workingHours': 8.0,
      },
      {
        '_id': 'att_4',
        'employee': {
          '_id': 'emp_4',
          'employeeId': 'EMP1013',
          'firstName': 'Arjun',
          'lastName': 'kp',
          'department': 'Telecalling',
        },
        'date': '2026-11-18',
        'checkIn': '2026-11-18T12:32:00Z',
        'checkInTime': '12:32 PM',
        'checkOutTime': null,
        'status': 'PRESENT',
        'minutesLate': 27,
        'workingHours': 0.0,
      },
      {
        '_id': 'att_5',
        'employee': {
          '_id': 'emp_5',
          'employeeId': 'EMP1066',
          'firstName': 'Rahul',
          'lastName': 'k',
          'department': 'Tech',
        },
        'date': '2026-11-18',
        'checkIn': '2026-11-18T10:25:00Z',
        'checkInTime': '10:25 AM',
        'checkOutTime': '11:28 AM',
        'status': 'PRESENT',
        'minutesLate': 25,
        'workingHours': 1.05,
      },
      {
        '_id': 'att_6',
        'employee': {
          '_id': 'emp_6',
          'employeeId': 'EMP1098',
          'firstName': 'Hashim',
          'lastName': 'k',
          'department': 'Tech',
        },
        'date': '2026-11-18',
        'checkIn': '2026-11-18T10:24:00Z',
        'checkInTime': '10:24 AM',
        'checkOutTime': null,
        'status': 'PRESENT',
        'minutesLate': 25,
        'workingHours': 0.0,
      },
      {
        '_id': 'att_7',
        'employee': {
          '_id': 'emp_7',
          'employeeId': 'EMP1103',
          'firstName': 'Attendance Tester',
          'lastName': '1794910372153',
          'department': 'Tech',
        },
        'date': '2026-11-17',
        'checkIn': '2026-11-17T15:42:00Z',
        'checkInTime': '03:42 PM',
        'checkOutTime': '03:42 PM',
        'status': 'PRESENT',
        'minutesLate': 34,
        'workingHours': 8.0,
      },
    ];

    ApiService.client = MockClient((request) async {
      if (request.url.path.contains('/reports/attendance')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Loaded',
            'data': {
              'statusSummary': [
                {'_id': 'PRESENT', 'count': 62},
              ],
              'departmentSummary': [],
              'lateArrivals': 0,
              'onTimeArrivals': 0,
              'totalAbsent': 0,
              'totalAttendanceRecords': 62,
              'presentRecords': 62,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.contains('/reports/leaves')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'statusSummary': [], 'typeSummary': []},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.contains('/api/hr/attendance')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': mockAttendanceRecords,
            'pagination': {
              'page': 1,
              'limit': 25,
              'total': 62,
              'totalPages': 3,
            },
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
    provider.setScreen('reports');
    provider.reportsStartDate = DateTime(2026, 11, 1);
    provider.reportsEndDate = DateTime(2026, 11, 19);

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
            child: const AppShell(child: ReportsView()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Tap "Total Attendance Records" to open drill-down
    await tester.tap(find.text('Total Attendance Records').first);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify key drill-down components matching reference screenshot
    expect(find.text('Total Attendance Records'), findsOneWidget);
    expect(find.text('Back to Overview'), findsOneWidget);
    expect(find.text('Export Report'), findsOneWidget);
    expect(find.text('EMPLOYEE ID'), findsOneWidget);
    expect(find.text('EMPLOYEE NAME'), findsOneWidget);
    expect(find.text('DEPARTMENT'), findsOneWidget);
    expect(find.text('DATE'), findsOneWidget);
    expect(find.text('CHECK-IN'), findsOneWidget);
    expect(find.text('CHECK-OUT'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('LATE BY'), findsOneWidget);

    // Verify sample records
    expect(find.text('Arjun kp'), findsNWidgets(2));
    expect(find.text('Rahul k'), findsOneWidget);
    expect(find.text('Hashim k'), findsOneWidget);
    expect(find.text('EMP1013'), findsNWidgets(2));
    expect(find.text('Telecalling'), findsNWidgets(2));
    expect(find.text('Tech'), findsNWidgets(5));
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

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
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/attendance_drilldown_preview.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });
  });

  testWidgets(
      'renders Total Leave Requests drill-down matching reference design and captures preview',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1050);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockLeaveRecords = [
      {
        '_id': 'leave_1',
        'staffId': 'EMP1066',
        'employee': {
          '_id': 'emp_1',
          'employeeId': 'EMP1066',
          'firstName': 'Rahul',
          'lastName': 'k',
          'department': 'Tech',
        },
        'leaveType': 'CASUAL',
        'startDate': '2026-11-17',
        'endDate': '2026-11-17',
        'days': 1,
        'status': 'APPROVED',
        'reason': 'Family function',
      },
      {
        '_id': 'leave_2',
        'staffId': 'EMP1092',
        'employee': {
          '_id': 'emp_2',
          'employeeId': 'EMP1092',
          'firstName': 'Vishnu',
          'lastName': 'ps',
          'department': 'Telecalling',
        },
        'leaveType': 'SICK',
        'startDate': '2026-11-10',
        'endDate': '2026-11-12',
        'days': 3,
        'status': 'PENDING',
        'reason': 'Viral fever and rest',
      },
      {
        '_id': 'leave_3',
        'staffId': 'EMP1098',
        'employee': {
          '_id': 'emp_3',
          'employeeId': 'EMP1098',
          'firstName': 'Hashim',
          'lastName': 'k',
          'department': 'Tech',
        },
        'leaveType': 'ANNUAL',
        'startDate': '2026-11-01',
        'endDate': '2026-11-05',
        'days': 5,
        'status': 'REJECTED',
        'reason': 'Vacation trip',
      },
    ];

    ApiService.client = MockClient((request) async {
      if (request.url.path.contains('/reports/attendance')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'statusSummary': [], 'departmentSummary': []},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.contains('/reports/leaves')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Loaded',
            'data': {
              'totalLeaveApplications': 14,
              'approvedRequests': 9,
              'pendingRequests': 1,
              'rejectedRequests': 4,
              'casualLeaves': 5,
              'sickMedicalLeaves': 9,
              'statusSummary': [
                {'_id': 'APPROVED', 'count': 9},
                {'_id': 'PENDING', 'count': 1},
                {'_id': 'REJECTED', 'count': 4},
              ],
              'typeSummary': [
                {'_id': 'SICK', 'count': 9},
                {'_id': 'CASUAL', 'count': 5},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.contains('/api/hr/leaves')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': mockLeaveRecords,
            'pagination': {
              'page': 1,
              'limit': 25,
              'total': 14,
              'totalPages': 1,
            },
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
    provider.setScreen('reports');
    provider.reportsStartDate = DateTime(2026, 11, 1);
    provider.reportsEndDate = DateTime(2026, 11, 19);

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
            child: const AppShell(child: ReportsView()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Tap "Total Leave Requests" to open drill-down
    await tester.tap(find.text('Total Leave Requests').first);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify key drill-down components matching reference screenshot
    expect(find.text('Total Leave Requests'), findsOneWidget);
    expect(find.text('Back to Overview'), findsOneWidget);
    expect(find.text('Export Report'), findsOneWidget);
    expect(find.text('EMPLOYEE ID'), findsOneWidget);
    expect(find.text('EMPLOYEE NAME'), findsOneWidget);
    expect(find.text('DEPARTMENT'), findsOneWidget);
    expect(find.text('LEAVE TYPE'), findsOneWidget);
    expect(find.text('START DATE'), findsOneWidget);
    expect(find.text('END DATE'), findsOneWidget);
    expect(find.text('DAYS'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('REASON'), findsOneWidget);

    // Verify sample records
    expect(find.text('Rahul k'), findsOneWidget);
    expect(find.text('Vishnu ps'), findsOneWidget);
    expect(find.text('Hashim k'), findsOneWidget);
    expect(find.text('EMP1066'), findsOneWidget);
    expect(find.text('EMP1092'), findsOneWidget);
    expect(find.text('EMP1098'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('REJECTED'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

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
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/leave_drilldown_preview.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });
  });
}
