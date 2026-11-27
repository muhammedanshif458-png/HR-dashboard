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
import 'package:ly_hr_dashboard_flutter/models/hr_document.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
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

  testWidgets('renders StaffProfileView matching reference design and captures preview',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    ApiService.client = MockClient((request) async {
      return http.Response(
        jsonEncode({'success': true, 'data': []}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final provider = HRProvider();
    final staff = Staff(
      id: 'staff-arjun',
      employeeId: 'EMP-84920',
      name: 'Arjun kp',
      email: 'arjun456@gmail.com',
      phoneNumber: '9876542361',
      role: 'Software Engineer',
      designation: 'Software Engineer',
      department: 'Telecalling',
      joinDate: '2026-10-21',
      status: 'active',
      salary: 33000,
      salaryCurrency: 'INR',
      paidLeaveAllowance: 1,
      workMode: 'Office',
      onLeaveToday: false,
    );

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

    provider.employeeDirectory = [staff];
    provider.selectedStaffId = staff.id;
    provider.setScreen('staff-profile');

    provider.documentsList = [
      HRDocumentItem(
        id: 'doc-1',
        employeeId: staff.id,
        title: 'Leave Attachment - Medical Certificate',
        category: 'Medical',
        fileName: 'sample_medical_certificate_template.pdf',
        originalName: 'sample_medical_certificate_template.pdf',
        filePath: '/uploads/sample_medical_certificate_template.pdf',
        fileType: 'application/pdf',
        fileSize: 27443,
        status: 'ACTIVE',
        uploadedBy: 'Arjun kp',
        createdAt: DateTime.parse('2026-10-29T10:00:00Z'),
        description: 'fever',
      ),
      HRDocumentItem(
        id: 'doc-2',
        employeeId: staff.id,
        title: 'Leave Attachment - Medical Certificate',
        category: 'Medical',
        fileName: 'sample_medical_certificate_template.pdf',
        originalName: 'sample_medical_certificate_template.pdf',
        filePath: '/uploads/sample_medical_certificate_template.pdf',
        fileType: 'application/pdf',
        fileSize: 27443,
        status: 'ACTIVE',
        uploadedBy: 'Arjun kp',
        createdAt: DateTime.parse('2026-10-22T10:00:00Z'),
        description: 'fever',
      ),
      HRDocumentItem(
        id: 'doc-3',
        employeeId: staff.id,
        title: 'Arjun kp - Offer Letter & Contract',
        category: 'Offer Letter',
        fileName: 'sample_offer_letter_test.pdf',
        originalName: 'sample_offer_letter_test.pdf',
        filePath: '/uploads/sample_offer_letter_test.pdf',
        fileType: 'application/pdf',
        fileSize: 27955,
        status: 'ACTIVE',
        uploadedBy: 'Super Admin',
        issueDate: '2026-10-21',
        expiryDate: '2027-03-21',
        createdAt: DateTime.parse('2026-10-21T10:00:00Z'),
        description: 'Active Agreement',
      ),
      HRDocumentItem(
        id: 'doc-4',
        employeeId: staff.id,
        title: 'Arjun kp - Curriculum Vitae (Resume)',
        category: 'Resume / CV',
        fileName: 'sample_resume_duplicate.pdf',
        originalName: 'sample_resume_duplicate.pdf',
        filePath: '/uploads/sample_resume_duplicate.pdf',
        fileType: 'application/pdf',
        fileSize: 27545,
        status: 'ACTIVE',
        uploadedBy: 'Super Admin',
        issueDate: '2026-10-21',
        expiryDate: '2027-10-21',
        createdAt: DateTime.parse('2026-10-21T10:00:00Z'),
        description: 'Archived Copy',
      ),
    ];

    provider.hasLoadedApiAttendance = true;
    provider.apiAttendanceRecords = [
      Attendance(
        id: 'att-1',
        staffId: staff.id,
        employeeId: staff.employeeId,
        date: '2026-11-19',
        checkInTime: '2026-11-19T10:14:00Z',
        checkOutTime: '2026-11-19T19:15:00Z',
        workedDuration: '9h 01m',
        breakDuration: '0m',
        workMode: 'Desk 4B',
        isLate: false,
      ),
      Attendance(
        id: 'att-2',
        staffId: staff.id,
        employeeId: staff.employeeId,
        date: '2026-11-18',
        checkInTime: '2026-11-18T12:32:00Z',
        checkOutTime: '2026-11-18T19:45:00Z',
        workedDuration: '7h 13m',
        breakDuration: '0m',
        workMode: 'Office',
        isLate: true,
      ),
      Attendance(
        id: 'att-3',
        staffId: staff.id,
        employeeId: staff.employeeId,
        date: '2026-11-17',
        checkInTime: '2026-11-17T09:58:00Z',
        checkOutTime: '2026-11-17T18:30:00Z',
        workedDuration: '8h 32m',
        breakDuration: '0m',
        workMode: 'Office',
        isLate: false,
      ),
    ];

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      ChangeNotifierProvider<HRProvider>.value(
        value: provider,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Plus Jakarta Sans',
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          ),
          home: RepaintBoundary(
            key: repaintKey,
            child: const HRApp(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify key UI elements matching screenshot
    expect(find.text('Employee Profile & Records'), findsOneWidget);
    expect(find.text('Arjun kp'), findsWidgets);
    expect(find.text('Telecalling'), findsWidgets);
    expect(find.text('Software Engineer'), findsWidgets);
    expect(find.text('arjun456@gmail.com'), findsOneWidget);
    expect(find.text('9876542361'), findsOneWidget);
    expect(find.text('MONTHLY SALARY'), findsOneWidget);
    expect(find.text('₹33,000'), findsOneWidget);
    expect(find.text('PAID LEAVE'), findsOneWidget);
    expect(find.text('1 day / mo'), findsOneWidget);
    expect(find.text('WORK MODE'), findsOneWidget);
    expect(find.text('Office'), findsWidgets);
    expect(find.text('Employee Documents & Compliance'), findsOneWidget);
    expect(find.text('4 Documents'), findsOneWidget);
    expect(find.text('Attendance History'), findsOneWidget);
    expect(find.text('Leave History'), findsOneWidget);
    expect(find.text('Staff Daily Work Updates'), findsOneWidget);

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
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/staff_profile_preview.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });
  });
}
