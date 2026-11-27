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
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/payroll/payroll_view.dart';
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
      'renders PayrollView matching reference design and captures preview',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1050);
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
    provider.setScreen('payroll');

    provider.payrollMonth = 11;
    provider.payrollYear = 2026;
    provider.hasLoadedApiPayroll = true;
    provider.isPayrollLoading = false;
    provider.payrollError = null;
    provider.conflictsUnresolvedTotal = 2;

    provider.apiPayrollSummary = const PayrollSummary(
      year: 2026,
      month: 11,
      department: 'all',
      totalEmployees: 16,
      totalPayrollExpenditure: 295000.0,
      totalDeductions: 277139.0,
      totalNetPayout: 17861.0,
      unresolvedConflictCount: 0,
    );

    provider.apiPayrollRecords = [
      const EmployeePayrollRecord(
        id: 'emp_1',
        employeeId: 'EMP1001',
        firstName: 'Super',
        lastName: 'Admin',
        name: 'Super Admin',
        department: 'Management',
        designation: 'Super Administrator',
        status: 'ACTIVE',
        salary: 200000.0,
        salaryCurrency: 'INR',
        year: 2026,
        month: 11,
        standardWorkingDays: 25,
        presentDays: 0.0,
        approvedLeaves: 0,
        paidLeaveDays: 0.0,
        unpaidLeaveDays: 25.0,
        payableDays: 0.0,
        grossSalary: 200000.0,
        dailyRate: 8000.0,
        deductions: 200000.0,
        netPay: 0.0,
      ),
      const EmployeePayrollRecord(
        id: 'emp_2',
        employeeId: 'EMP1066',
        firstName: 'Rahul',
        lastName: 'k',
        name: 'Rahul k',
        department: 'Tech',
        designation: 'Software Engineer',
        status: 'ACTIVE',
        salary: 25000.0,
        salaryCurrency: 'INR',
        year: 2026,
        month: 11,
        standardWorkingDays: 21,
        presentDays: 19.0,
        approvedLeaves: 1,
        paidLeaveDays: 1.0,
        unpaidLeaveDays: 0.0,
        payableDays: 20.0,
        grossSalary: 25000.0,
        dailyRate: 1190.48,
        deductions: 1190.0,
        netPay: 23810.0,
      ),
      const EmployeePayrollRecord(
        id: 'emp_3',
        employeeId: 'EMP1070',
        firstName: 'shibu',
        lastName: 'k',
        name: 'shibu k',
        department: 'Tech',
        designation: 'Software Engineer',
        status: 'ACTIVE',
        salary: 30000.0,
        salaryCurrency: 'INR',
        year: 2026,
        month: 11,
        standardWorkingDays: 21,
        presentDays: 20.0,
        approvedLeaves: 1,
        paidLeaveDays: 1.0,
        unpaidLeaveDays: 0.0,
        payableDays: 21.0,
        grossSalary: 30000.0,
        dailyRate: 1428.57,
        deductions: 0.0,
        netPay: 30000.0,
      ),
      const EmployeePayrollRecord(
        id: 'emp_4',
        employeeId: 'EMP1080',
        firstName: 'vishnu',
        lastName: 'ps',
        name: 'vishnu ps',
        department: 'Telecalling',
        designation: 'Software Engineer',
        status: 'ACTIVE',
        salary: 40000.0,
        salaryCurrency: 'INR',
        year: 2026,
        month: 11,
        standardWorkingDays: 25,
        presentDays: 22.0,
        approvedLeaves: 0,
        paidLeaveDays: 1.0,
        unpaidLeaveDays: 1.0,
        payableDays: 23.0,
        grossSalary: 40000.0,
        dailyRate: 1600.0,
        deductions: 3200.0,
        netPay: 36800.0,
      ),
    ];

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
            home: const AppShell(child: PayrollView()),
          ),
        ),
      ),
    );

    // Settle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify key UI elements matching reference screenshot
    expect(find.text('HRconsole.'), findsOneWidget);
    expect(find.text('STAFFHUB ENTERPRISE'), findsOneWidget);
    expect(find.text('Monthly Payroll Processing'), findsOneWidget);
    expect(find.text('Audit Log'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Payroll Calc'), findsOneWidget);
    expect(find.text('Conflicts'), findsOneWidget);
    expect(find.text('Privacy & Working Rules Policy'), findsOneWidget);
    expect(find.text('Gross Salary Pool'), findsOneWidget);
    expect(find.text('Unpaid Leave Deductions'), findsOneWidget);
    expect(find.text('Net Payout Amount'), findsOneWidget);
    expect(find.text('₹2,95,000'), findsOneWidget);
    expect(find.text('₹2,77,139'), findsOneWidget);
    expect(find.text('₹17,861'), findsOneWidget);
    expect(find.text('Rahul k'), findsOneWidget);
    expect(find.text('shibu k'), findsOneWidget);
    expect(find.text('vishnu ps'), findsOneWidget);

    // Capture visual snapshot of Payroll screen
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File(
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/payroll_preview.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });

    // Tap View Payslip Details on first row (Super Admin)
    final payslipBtn = find.byTooltip('View Payslip Details').first;
    expect(payslipBtn, findsOneWidget);
    await tester.ensureVisible(payslipBtn);
    await tester.pumpAndSettle();
    await tester.tap(payslipBtn);
    await tester.pumpAndSettle();

    // Verify modal elements matching reference screenshot
    expect(find.text('Payslip Details'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('MANAGEMENT'), findsOneWidget);
    expect(find.text('WORK SCHEDULE'), findsOneWidget);
    expect(find.text('Mon-Sat (25 Days)'), findsOneWidget);
    expect(find.text('ATTENDANCE SUMMARY'), findsOneWidget);
    expect(find.text('SALARY CALCULATION'), findsOneWidget);
    expect(find.text('INR (₹)'), findsOneWidget);
    expect(find.text('NET PAYABLE AMOUNT'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Capture visual snapshot of the Payslip modal
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File(
              'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/payslip_preview.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    });
  });
}
