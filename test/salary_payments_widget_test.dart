import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/models/department.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/features/payroll/payroll_view.dart';
import 'package:ly_hr_dashboard_flutter/features/payroll/salary_payments_tab.dart';

Map<String, dynamic> paymentJson({
  String id = 'payment_1',
  String status = 'PENDING',
  String employeeId = 'EMP001',
  String employeeName = 'Asha Rao',
  String department = 'Tech',
}) =>
    {
      '_id': id,
      'employee': 'employee_$employeeId',
      'employeeId': employeeId,
      'employeeName': employeeName,
      'department': department,
      'payrollBatch': 'batch_1',
      'payrollRecord': 'record_1',
      'payrollMonth': 11,
      'payrollYear': 2026,
      'legacyBatchStatus': 'FINALIZED',
      'monthlyBaseSalary': 60000,
      'totalPresentDays': 21,
      'paidLeaveDays': 1,
      'lopDays': 0,
      'payableDays': 22,
      'netSalary': 60000,
      'status': status,
      'paymentDate': status == 'PAID' ? '2026-11-10T00:00:00.000Z' : null,
      'paymentMethod': status == 'PAID' ? 'BANK_TRANSFER' : null,
      'transactionReference': status == 'PAID' ? 'TXN-PAID-1' : '',
      'remarks': status == 'PAID' ? 'November payroll' : '',
      'confirmedBy': status == 'PAID'
          ? {
              '_id': 'hr_1',
              'firstName': 'Morgan',
              'lastName': 'Lee',
              'email': 'morgan@example.com',
            }
          : null,
      'confirmedAt': status == 'PAID' ? '2026-11-10T12:30:00.000Z' : null,
      'paymentStatusEvidence': status == 'PAID'
          ? 'EMPLOYEE_PAYMENT_CONFIRMED'
          : 'NO_EMPLOYEE_PAYMENT_CONFIRMATION',
    };

Map<String, dynamic> summaryJson({int paid = 1}) => {
      'year': 2026,
      'month': 11,
      'totalEmployees': 10,
      'totalSalary': 6272.38,
      'paidEmployees': 1,
      'pendingEmployees': 9,
      'paidAmount': 3142.86,
      'pendingAmount': 3129.52,
    };

Map<String, dynamic> listResponse({
  List<Map<String, dynamic>>? payments,
  int paid = 0,
}) =>
    {
      'success': true,
      'message': 'Salary payments retrieved successfully',
      'data': payments ?? [paymentJson()],
      'pagination': {
        'pagination': {
          'page': 1,
          'limit': 50,
          'total': payments?.length ?? 1,
          'totalPages': 1
        },
        'summary': summaryJson(paid: paid),
      },
    };

Map<String, dynamic> summaryResponse({int paid = 0}) => {
      'success': true,
      'data': summaryJson(paid: paid),
    };

http.Response response(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

SalaryPayment payment({
  String status = 'PENDING',
  String id = 'payment_1',
  String department = 'Tech',
}) =>
    SalaryPayment.fromJson(
        paymentJson(status: status, id: id, department: department));

Future<void> pumpSalaryPayments(
    WidgetTester tester, HRProvider provider) async {
  tester.view.physicalSize = const Size(1920, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() => tester.view.resetPhysicalSize());
  provider.hasLoadedApiPayroll = true;
  await tester.pumpWidget(
    ChangeNotifierProvider<HRProvider>.value(
      value: provider,
      child: const MaterialApp(home: PayrollView()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Salary Payments').first);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
    ApiService.resetBaseUrl();
  });

  testWidgets(
      'shows Salary Payments and Payment History, removes Batch, renders backend summary and table',
      (tester) async {
    final provider = HRProvider()
      ..hasLoadedSalaryPayments = true
      ..hasLoadedSalaryPaymentSummary = true
      ..salaryPaymentSummary = SalaryPaymentSummary.fromJson(summaryJson())
      ..salaryPayments = [
        payment(),
        payment(
          id: 'payment_2',
          status: 'PAID',
        ),
      ];

    await pumpSalaryPayments(tester, provider);

    expect(find.text('Payroll Calc'), findsOneWidget);
    expect(find.text('Conflicts'), findsOneWidget);
    expect(find.text('Salary Payments'), findsWidgets);
    expect(find.text('Payment History'), findsOneWidget);
    expect(find.text('Batch'), findsNothing);
    expect(find.text('Total Employees'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('₹ 6272.38'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('₹ 3142.86'), findsOneWidget);
    expect(find.text('₹ 3129.52'), findsOneWidget);
    expect(find.text('Paid Employees'), findsOneWidget);
    expect(find.text('Pending Employees'), findsOneWidget);
    expect(find.text('Total Paid Amount'), findsOneWidget);
    expect(find.text('Total Pending Amount'), findsOneWidget);
    expect(find.text('Employee ID'), findsOneWidget);
    expect(find.text('Monthly Base Salary'), findsOneWidget);
    expect(find.text('Total Present'), findsOneWidget);
    expect(find.text('Office Days'), findsNothing);
    expect(find.text('WFH Days'), findsNothing);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('PAID'), findsOneWidget);
    expect(find.text('Mark as Paid'), findsOneWidget);
    expect(find.text('View Payment Details'), findsOneWidget);
  });

  testWidgets('department dropdown has four exact options and filters payment rows',
      (tester) async {
    final requests = <Uri>[];
    final employeeRows = [
      paymentJson(employeeId: 'EMP_TECH', employeeName: 'Asha Rao',
          department: 'Tech', status: 'PENDING'),
      paymentJson(id: 'payment_2', employeeId: 'EMP_TELE',
          employeeName: 'Neha Shah', department: 'Telecalling', status: 'PENDING'),
      paymentJson(id: 'payment_3', employeeId: 'EMP_MGMT',
          employeeName: 'Morgan Lee', department: 'Management', status: 'PENDING'),
    ];
    ApiService.client = MockClient((request) async {
      requests.add(request.url);
      final department = request.url.queryParameters['department'];
      final search = request.url.queryParameters['search']?.toLowerCase();
      final status = request.url.queryParameters['status'];
      final rows = employeeRows.where((row) {
        final departmentMatches =
            department == null || row['department'] == department;
        final searchMatches = search == null ||
            row['employeeName'].toString().toLowerCase().contains(search) ||
            row['employeeId'].toString().toLowerCase().contains(search);
        final statusMatches = status == null || row['status'] == status;
        return departmentMatches && searchMatches && statusMatches;
      }).toList();
      return response(listResponse(payments: rows));
    });

    final provider = HRProvider()
      ..salaryPaymentMonth = 6
      ..salaryPaymentYear = 2025
      ..departments = const [
        Department(deptKey: 'tech', title: 'Tech & Engineering'),
        Department(
            deptKey: 'telecalling', title: 'Telecalling & Client Relations'),
        Department(deptKey: 'sales', title: 'Sales'),
      ]
      ..hasLoadedSalaryPayments = true
      ..hasLoadedSalaryPaymentSummary = true
      ..salaryPaymentSummary = SalaryPaymentSummary.fromJson(summaryJson())
      ..salaryPayments = [
        payment(department: 'Tech'),
        payment(id: 'payment_2', department: 'Telecalling'),
        payment(id: 'payment_3', department: 'Management'),
        payment(id: 'payment_4', department: 'Sales'),
      ];
    await pumpSalaryPayments(tester, provider);

    final dropdownFinder =
        find.byKey(const ValueKey('salary_payment_department_all'));
    final dropdown = tester.widget<DropdownButton<String>>(find.descendant(
      of: dropdownFinder,
      matching: find.byType(DropdownButton<String>),
    ));
    expect(dropdown.items!.map((item) => item.value).toList(), [
      'all',
      'Tech',
      'Telecalling',
      'Management',
    ]);
    expect(dropdown.items, hasLength(4));

    Future<void> selectDepartment(String current, String next) async {
      await tester.tap(
          find.byKey(ValueKey('salary_payment_department_$current')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(next == 'all' ? 'All Departments' : next).last);
      await tester.pumpAndSettle();
    }

    await selectDepartment('all', 'Tech');
    expect(requests.last.queryParameters['department'], 'Tech');
    expect(requests.last.queryParameters['month'], '6');
    expect(requests.last.queryParameters['year'], '2025');
    expect(provider.salaryPayments.map((row) => row.department), ['Tech']);

    await selectDepartment('Tech', 'Telecalling');
    expect(requests.last.queryParameters['department'], 'Telecalling');
    expect(provider.salaryPayments.map((row) => row.department), ['Telecalling']);

    await selectDepartment('Telecalling', 'Management');
    expect(requests.last.queryParameters['department'], 'Management');
    expect(provider.salaryPayments.map((row) => row.department), ['Management']);

    await selectDepartment('Management', 'all');
    expect(requests.last.queryParameters.containsKey('department'), isFalse);
    expect(provider.salaryPayments.map((row) => row.department), [
      'Tech', 'Telecalling', 'Management'
    ]);

    await tester.tap(find.byKey(const ValueKey('salary_payment_status_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('salary_payment_search')), 'Asha');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await selectDepartment('all', 'Tech');

    expect(requests.last.queryParameters['department'], 'Tech');
    expect(requests.last.queryParameters['month'], '6');
    expect(requests.last.queryParameters['year'], '2025');
    expect(requests.last.queryParameters['status'], 'PENDING');
    expect(requests.last.queryParameters['search'], 'Asha');
    expect(provider.salaryPayments.map((row) => row.employeeName), ['Asha Rao']);
  });

  testWidgets('summary cards filter in place and keep period and other filters',
      (tester) async {
    final queries = <Map<String, String>>[];
    ApiService.client = MockClient((request) async {
      queries.add(request.url.queryParameters);
      final status = request.url.queryParameters['status'];
      final rows = status == 'PAID'
          ? [paymentJson(status: 'PAID')]
          : status == 'PENDING'
              ? [paymentJson()]
              : [paymentJson(), paymentJson(id: 'payment_2', status: 'PAID')];
      return response(listResponse(
          payments: rows,
          paid: 1));
    });
    final provider = HRProvider()
      ..salaryPaymentMonth = 6
      ..salaryPaymentYear = 2025
      ..salaryPaymentDepartment = 'Tech'
      ..salaryPaymentSearchQuery = 'Asha'
      ..hasLoadedSalaryPayments = true
      ..hasLoadedSalaryPaymentSummary = true
      ..salaryPaymentSummary = SalaryPaymentSummary.fromJson(summaryJson())
      ..salaryPayments = [payment(), payment(id: 'payment_2', status: 'PAID')]
      ..salaryPaymentTotal = 2;
    await pumpSalaryPayments(tester, provider);

    final cases = <(String, String, String, int)>[
      ('total_employees', 'all', 'All Employee Salary Details', 2),
      ('total_net_salary', 'all', 'All Net Salary Details', 2),
      ('paid_employees', 'PAID', 'Paid Employees', 1),
      ('pending_employees', 'PENDING', 'Pending Employees', 1),
      ('total_paid_amount', 'PAID', 'Paid Salary Details', 1),
      ('total_pending_amount', 'PENDING', 'Pending Salary Details', 1),
    ];
    for (final (card, status, heading, count) in cases) {
      final previousStatus = provider.salaryPaymentStatusFilter;
      final previousRequestCount = queries.length;
      final key = ValueKey('salary_payment_summary_$card');
      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(provider.salaryPaymentStatusFilter, status);
      expect(find.byKey(const ValueKey('salary_payment_table_heading')),
          findsOneWidget);
      expect(
        tester.widget<Text>(
            find.byKey(const ValueKey('salary_payment_table_heading'))).data,
        heading,
      );
      expect(provider.salaryPayments, hasLength(count));
      expect(provider.salaryPayments.every((row) =>
          status == 'all' || row.status == status), isTrue);
      final summary = provider.salaryPaymentSummary!;
      expect(summary.totalEmployees, 10);
      expect(summary.totalSalary, 6272.38);
      expect(summary.paidEmployees, 1);
      expect(summary.pendingEmployees, 9);
      expect(summary.paidAmount, 3142.86);
      expect(summary.pendingAmount, 3129.52);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('₹ 6272.38'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('₹ 3142.86'), findsOneWidget);
      expect(find.text('₹ 3129.52'), findsOneWidget);
      final selectedDecoration = tester
          .widget<AnimatedContainer>(find.byKey(
              ValueKey('salary_payment_summary_card_$card')))
          .decoration as BoxDecoration;
      expect(selectedDecoration.border!.top.width, 2);
      if (status == previousStatus) {
        expect(queries, hasLength(previousRequestCount));
      } else {
        expect(queries, hasLength(previousRequestCount + 1));
        expect(queries.last['month'], '6');
        expect(queries.last['year'], '2025');
        expect(queries.last['department'], 'Tech');
        expect(queries.last['search'], 'Asha');
        expect(queries.last['status'], status == 'all' ? isNull : status);
      }
    }
    final callsAfterSelection = queries.length;
    await tester.ensureVisible(
        find.byKey(const ValueKey('salary_payment_summary_total_pending_amount')));
    await tester.tap(find.byKey(
        const ValueKey('salary_payment_summary_total_pending_amount')));
    await tester.pumpAndSettle();
    expect(queries, hasLength(callsAfterSelection));
  });

  testWidgets('mark-paid dialog validates date, method, and transfer reference',
      (tester) async {
    final provider = HRProvider()
      ..hasLoadedSalaryPayments = true
      ..salaryPayments = [payment()];
    await pumpSalaryPayments(tester, provider);
    await tester.ensureVisible(
        find.byKey(const ValueKey('mark_salary_payment_payment_1')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('mark_salary_payment_payment_1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('salary_payment_review')));
    await tester.pumpAndSettle();
    expect(
        find.text('Enter a valid payment date (YYYY-MM-DD)'), findsOneWidget);
    expect(find.text('Select a payment method'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('salary_payment_date')), '2026-11-11');
    await tester.tap(find.byKey(const ValueKey('salary_payment_method')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank Transfer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('salary_payment_review')));
    await tester.pumpAndSettle();
    expect(find.text('Transaction reference is required'), findsOneWidget);
  });

  testWidgets('successful mark-paid confirms, refreshes and shows PAID state',
      (tester) async {
    var postCount = 0;
    var listRefreshCount = 0;
    var summaryRefreshCount = 0;
    ApiService.client = MockClient((request) async {
      if (request.method == 'POST') {
        postCount++;
        expect(
            request.url.path, '/api/hr/payroll/payments/payment_1/mark-paid');
        expect(jsonDecode(request.body)['paymentMethod'], 'CASH');
        expect(jsonDecode(request.body)['paymentDate'], '2026-11-11');
        return response({
          'success': true,
          'data': paymentJson(status: 'PAID'),
        });
      }
      if (request.url.path == '/api/hr/payroll/payments') {
        listRefreshCount++;
        return response(
            listResponse(payments: [paymentJson(status: 'PAID')], paid: 1));
      }
      summaryRefreshCount++;
      return response(summaryResponse(paid: 1));
    });
    final provider = HRProvider()
      ..hasLoadedSalaryPayments = true
      ..hasLoadedSalaryPaymentSummary = true
      ..salaryPaymentSummary = SalaryPaymentSummary.fromJson(summaryJson())
      ..salaryPayments = [payment()];
    await pumpSalaryPayments(tester, provider);
    await tester.ensureVisible(
        find.byKey(const ValueKey('mark_salary_payment_payment_1')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('mark_salary_payment_payment_1')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('salary_payment_date')), '2026-11-11');
    await tester.tap(find.byKey(const ValueKey('salary_payment_method')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('salary_payment_review')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Salary Payment'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('salary_payment_confirm')));
    await tester.pumpAndSettle();

    expect(postCount, 1);
    expect(listRefreshCount, 1);
    expect(summaryRefreshCount, 0);
    expect(provider.salaryPayments.single.status, 'PAID');
    expect(find.text('PAID'), findsOneWidget);
    expect(find.text('Salary payment marked as paid.'), findsOneWidget);
  });

  testWidgets(
      'failed mark-paid preserves pending state and shows backend error',
      (tester) async {
    ApiService.client = MockClient((request) async => response({
          'success': false,
          'message':
              'Cannot confirm payment while unresolved payroll conflicts exist',
          'error': null,
        }, 409));
    final provider = HRProvider()
      ..hasLoadedSalaryPayments = true
      ..salaryPayments = [payment()];
    await pumpSalaryPayments(tester, provider);
    await tester.ensureVisible(
        find.byKey(const ValueKey('mark_salary_payment_payment_1')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('mark_salary_payment_payment_1')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('salary_payment_date')), '2026-11-11');
    await tester.tap(find.byKey(const ValueKey('salary_payment_method')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('salary_payment_review')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('salary_payment_confirm')));
    await tester.pumpAndSettle();

    expect(provider.salaryPayments.single.status, 'PENDING');
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.textContaining('unresolved payroll conflicts'), findsWidgets);
    expect(find.byKey(const ValueKey('salary_payment_submit_error')),
        findsOneWidget);
  });

  testWidgets('paid employee details load payment metadata from provider',
      (tester) async {
    ApiService.client = MockClient((request) async {
      expect(request.url.path, '/api/hr/payroll/payments/payment_2');
      return response({
        'success': true,
        'data': paymentJson(
          id: 'payment_2',
          status: 'PAID',
        )
      });
    });
    final provider = HRProvider()
      ..hasLoadedSalaryPayments = true
      ..salaryPayments = [payment(status: 'PAID', id: 'payment_2')];
    await pumpSalaryPayments(tester, provider);
    await tester.ensureVisible(
        find.byKey(const ValueKey('view_salary_payment_payment_2')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('view_salary_payment_payment_2')));
    await tester.pumpAndSettle();

    expect(find.text('Payment Details'), findsOneWidget);
    expect(find.text('Payment date'), findsOneWidget);
    expect(find.text('BANK_TRANSFER'), findsOneWidget);
    expect(find.text('TXN-PAID-1'), findsOneWidget);
    expect(find.text('November payroll'), findsOneWidget);
    expect(find.text('Morgan Lee'), findsOneWidget);
  });

  testWidgets(
      'tab load shows initial spinner, retryable error, empty and no-search-results states',
      (tester) async {
    final pending = Completer<void>();
    ApiService.client = MockClient((request) async {
      if (request.url.path == '/api/hr/payroll/payments') {
        await pending.future;
        return response({
          'success': false,
          'message': 'Payment service is temporarily unavailable',
          'error': null,
        }, 503);
      }
      return response(summaryResponse());
    });
    final provider = HRProvider();
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    provider.hasLoadedApiPayroll = true;
    await tester.pumpWidget(ChangeNotifierProvider<HRProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: SalaryPaymentsTab())),
    ));
    provider
      ..loadSalaryPayments()
      ..loadSalaryPaymentSummary();
    await tester.pump();
    expect(provider.isSalaryPaymentsLoading, isTrue);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Payment service is temporarily unavailable'),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    provider
      ..salaryPaymentsError = null
      ..hasLoadedSalaryPayments = true
      ..salaryPayments = []
      ..salaryPaymentSearchQuery = '';
    provider.notifyListeners();
    await tester.pumpAndSettle();
    expect(
        find.text('No salary payments found for this period.'), findsOneWidget);
    provider.salaryPaymentSearchQuery = 'nobody';
    provider.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('No employees match your search.'), findsOneWidget);
  });
}
