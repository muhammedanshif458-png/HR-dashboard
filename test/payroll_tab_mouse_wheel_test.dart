import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/features/payroll/payroll_view.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  testWidgets(
      'mouse wheel scrolls each tab vertically without changing tabs; tab clicks still work',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = _longContentProvider();
    ApiService.client = MockClient((request) async => http.Response(
          jsonEncode({
            'success': true,
            'data': List.generate(
              30,
              (index) => {
                '_id': 'history_$index',
                'employeeId': 'EMP${index + 1}',
                'employeeName': 'Employee $index',
                'department': 'Tech',
                'payrollBatch': 'batch_1',
                'payrollRecord': 'record_$index',
                'payrollMonth': 11,
                'payrollYear': 2026,
                'monthlyBaseSalary': 50000,
                'totalPresentDays': 21,
                'paidLeaveDays': 1,
                'lopDays': 0,
                'payableDays': 22,
                'netSalary': 50000,
                'status': 'PAID',
              },
            ),
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 30,
              'totalPages': 1,
            },
          }),
          200,
        ));
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<HRProvider>.value(
        value: provider,
        child: const PayrollView(),
      ),
    ));
    await tester.pumpAndSettle();

    const tabNames = [
      'Payroll Calc',
      'Conflicts',
      'Salary Payments',
      'Payment History',
    ];
    final tabBar = find.byType(TabBar);
    final tabView = find.byType(TabBarView);
    final tabController = tester.widget<TabBar>(tabBar).controller!;
    final pageRect = tester.getRect(tabView);
    final wheelPosition = Offset(pageRect.left + 40, pageRect.bottom - 30);

    for (var index = 0; index < tabNames.length; index++) {
      final tabFinder = find.descendant(
        of: tabBar,
        matching: find.text(tabNames[index]),
      );
      await tester.tap(tabFinder.first);
      await tester.pumpAndSettle();
      expect(tabController.index, index);
      if (index == 3) {
        expect(provider.salaryPaymentHistory, hasLength(30));
        expect(find.text('Review employee salary payments and confirmations.'),
            findsOneWidget);
        expect(find.text('Employee Name'), findsOneWidget);
      }

      final verticalScrollers = tester
          .widgetList<Scrollable>(
              find.descendant(of: tabView, matching: find.byType(Scrollable)))
          .where((scrollable) => scrollable.axisDirection == AxisDirection.down)
          .map((scrollable) =>
              tester.state<ScrollableState>(find.byWidget(scrollable)))
          .toList();
      final offsetsBefore = verticalScrollers
          .map((scrollable) => scrollable.position.pixels)
          .toList();

      await tester.sendEventToBinding(PointerScrollEvent(
        position: wheelPosition,
        scrollDelta: const Offset(0, 180),
        kind: PointerDeviceKind.mouse,
      ));
      await tester.pumpAndSettle();

      expect(tabController.index, index,
          reason:
              'A vertical mouse wheel must keep ${tabNames[index]} selected.');
      expect(
        verticalScrollers.asMap().entries.any(
            (entry) => entry.value.position.pixels > offsetsBefore[entry.key]),
        isTrue,
        reason:
            'The content in ${tabNames[index]} must still scroll vertically; '
            'before=$offsetsBefore, after=${verticalScrollers.map((s) => s.position.pixels).toList()}, '
            'extents=${verticalScrollers.map((s) => s.position.maxScrollExtent).toList()}.',
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendEventToBinding(PointerScrollEvent(
        position: wheelPosition,
        scrollDelta: const Offset(0, 180),
        kind: PointerDeviceKind.mouse,
      ));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(tabController.index, index,
          reason: 'A modified wheel event must not move the tab pager.');
    }

    for (var index = 0; index < tabNames.length; index++) {
      await tester.tap(find
          .descendant(
            of: tabBar,
            matching: find.text(tabNames[index]),
          )
          .first);
      await tester.pumpAndSettle();
      expect(tabController.index, index);
    }
  });
}

HRProvider _longContentProvider() {
  final provider = HRProvider()
    ..hasLoadedApiPayroll = true
    ..hasLoadedConflicts = true
    ..conflictsTotal = 30
    ..conflictsUnresolvedTotal = 30
    ..hasLoadedSalaryPayments = true
    ..hasLoadedSalaryPaymentSummary = true
    ..hasLoadedSalaryPaymentHistory = true
    ..salaryPaymentTotal = 30
    ..salaryPaymentHistoryTotal = 30;

  provider.apiPayrollSummary = PayrollSummary.fromJson({
    'year': 2026,
    'month': 11,
    'department': 'all',
    'totalEmployees': 30,
    'totalPayrollExpenditure': 1500000,
    'totalDeductions': 0,
    'totalNetPayout': 1500000,
  });
  provider.apiPayrollRecords = List.generate(
    30,
    (index) => EmployeePayrollRecord.fromJson({
      '_id': 'record_$index',
      'employeeId': 'EMP${index + 1}',
      'employeeName': 'Employee $index',
      'department': 'Tech',
      'designation': 'Staff',
      'status': 'ACTIVE',
      'salary': 50000,
      'year': 2026,
      'month': 11,
      'standardWorkingDays': 22,
      'presentDays': 21,
      'approvedLeaves': 1,
      'paidLeaveDays': 1,
      'unpaidLeaveDays': 0,
      'payableDays': 22,
      'grossSalary': 50000,
      'dailyRate': 2272.73,
      'deductions': 0,
      'netPay': 50000,
    }),
  );
  provider.payrollConflicts = List.generate(
    30,
    (index) => PayrollConflict.fromJson({
      '_id': 'conflict_$index',
      'employeeId': 'EMP${index + 1}',
      'employee': {
        'employeeId': 'EMP${index + 1}',
        'firstName': 'Employee',
        'lastName': '$index',
      },
      'dateKey': '2026-11-10',
      'conflictDate': '2026-11-10',
      'year': 2026,
      'month': 11,
      'conflictType': 'ATTENDANCE_AND_APPROVED_LEAVE',
      'status': 'UNRESOLVED',
    }),
  );
  provider.salaryPaymentSummary = SalaryPaymentSummary.fromJson({
    'year': 2026,
    'month': 11,
    'totalEmployees': 30,
    'totalSalary': 1500000,
    'paidEmployees': 0,
    'pendingEmployees': 30,
    'paidAmount': 0,
    'pendingAmount': 1500000,
  });
  final payments = List.generate(
    30,
    (index) => SalaryPayment.fromJson({
      '_id': 'payment_$index',
      'employeeId': 'EMP${index + 1}',
      'employeeName': 'Employee $index',
      'department': 'Tech',
      'payrollBatch': 'batch_1',
      'payrollRecord': 'record_$index',
      'payrollMonth': 11,
      'payrollYear': 2026,
      'monthlyBaseSalary': 50000,
      'totalPresentDays': 21,
      'paidLeaveDays': 1,
      'lopDays': 0,
      'payableDays': 22,
      'netSalary': 50000,
      'status': 'PENDING',
    }),
  );
  provider
    ..salaryPayments = payments
    ..salaryPaymentHistory = payments;
  return provider;
}
