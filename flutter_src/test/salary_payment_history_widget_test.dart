import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/features/payroll/payroll_view.dart';
import 'package:ly_hr_dashboard_flutter/features/payroll/salary_payment_history_tab.dart';
import 'package:ly_hr_dashboard_flutter/models/department.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> paymentJson({
  String id = 'pay_1',
  String employeeId = 'EMP001',
  String employeeName = 'Asha Rao',
  String department = 'Tech',
  String status = 'PAID',
}) =>
    {
      '_id': id,
      'employee': 'employee_1',
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
      'transactionReference': status == 'PAID' ? 'TXN-001' : '',
      'remarks': status == 'PAID' ? 'Salary paid' : '',
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

http.Response response(Map<String, dynamic> body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

Map<String, dynamic> historyResponse([List<Map<String, dynamic>>? rows]) => {
      'success': true,
      'message': 'Salary payment history retrieved successfully',
      'data': rows ??
          [
            paymentJson(),
            paymentJson(id: 'pay_2', department: 'Sales', status: 'PENDING'),
          ],
      'pagination': {
        'page': 1,
        'limit': 50,
        'total': rows?.length ?? 2,
        'totalPages': 1
      },
    };

Map<String, dynamic> paymentListResponse() => {
      'success': true,
      'data': [paymentJson(status: 'PENDING')],
      'pagination': {
        'pagination': {'page': 1, 'limit': 50, 'total': 1, 'totalPages': 1},
        'summary': {
          'year': 2026,
          'month': 11,
          'totalEmployees': 1,
          'totalSalary': 60000,
          'paidEmployees': 0,
          'pendingEmployees': 1,
          'paidAmount': 0,
          'pendingAmount': 60000,
        },
      },
    };

SalaryPayment payment({
  String id = 'pay_1',
  String status = 'PAID',
  String department = 'Tech',
}) =>
    SalaryPayment.fromJson(
        paymentJson(id: id, status: status, department: department));

Future<void> mountHistory(WidgetTester tester, HRProvider provider) async {
  tester.view.physicalSize = const Size(1920, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() => tester.view.resetPhysicalSize());
  provider.hasLoadedApiPayroll = true;
  await tester.pumpWidget(ChangeNotifierProvider<HRProvider>.value(
    value: provider,
    child: const MaterialApp(home: PayrollView()),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Payment History').first);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
    ApiService.resetBaseUrl();
  });

  testWidgets('switching across payroll tabs keeps each screen available',
      (tester) async {
    final paths = <String>[];
    ApiService.client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/api/hr/payroll/payments') {
        return response(paymentListResponse());
      }
      if (request.url.path == '/api/hr/payroll/payments/history') {
        return response(historyResponse());
      }
      return response({'success': false, 'message': 'Unexpected route'}, 404);
    });
    final provider = HRProvider()..hasLoadedApiPayroll = true;
    await mountHistory(tester, provider);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salary Payments').first);
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Manage employee monthly salary payments and track payment status.'),
        findsOneWidget);

    await tester.tap(find.text('Conflicts').first);
    await tester.pumpAndSettle();
    expect(find.text('Payroll Conflicts'), findsOneWidget);

    await tester.tap(find.text('Payroll Calc').first);
    await tester.pumpAndSettle();
    expect(find.text('Gross Salary Pool'), findsOneWidget);
    expect(paths, [
      '/api/hr/payroll/payments/history',
      '/api/hr/payroll/payments',
    ]);
  });

  testWidgets('initial Payroll Calc tab does not load payment endpoints',
      (tester) async {
    final paths = <String>[];
    ApiService.client = MockClient((request) async {
      paths.add(request.url.path);
      return response({'success': false, 'message': 'Not expected'}, 404);
    });
    final provider = HRProvider()..hasLoadedApiPayroll = true;
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(ChangeNotifierProvider<HRProvider>.value(
      value: provider,
      child: const MaterialApp(home: PayrollView()),
    ));
    await tester.pumpAndSettle();
    expect(paths.where((path) => path.contains('/payroll/payments')), isEmpty);
  });

  testWidgets('history tab loads endpoint and renders paid/pending rows',
      (tester) async {
    Uri? requestedUri;
    ApiService.client = MockClient((request) async {
      requestedUri = request.url;
      return response(historyResponse());
    });
    final provider = HRProvider()
      ..salaryPaymentMonth = 11
      ..salaryPaymentYear = 2026;
    await mountHistory(tester, provider);
    await tester.pumpAndSettle();

    expect(requestedUri?.path, '/api/hr/payroll/payments/history');
    expect(requestedUri?.queryParameters['month'], '11');
    expect(requestedUri?.queryParameters['year'], '2026');
    expect(requestedUri?.queryParameters.containsKey('status'), isFalse);
    expect(find.text('Payment History'), findsWidgets);
    expect(find.text('PAID'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('Mark as Paid'), findsNothing);
    expect(find.text('TXN-001'), findsOneWidget);
  });

  testWidgets('Payment History department dropdown has exactly four options',
      (tester) async {
    ApiService.client = MockClient((request) async =>
        response(historyResponse()));
    final provider = HRProvider()
      ..departments = const [
        Department(deptKey: 'tech', title: 'Tech & Engineering'),
        Department(
            deptKey: 'telecalling', title: 'Telecalling & Client Relations'),
        Department(deptKey: 'sales', title: 'Sales'),
      ]
      ..salaryPaymentHistory = [
        payment(),
        payment(id: 'pay_2', department: 'Sales'),
      ]
      ..hasLoadedSalaryPaymentHistory = true;
    await mountHistory(tester, provider);
    await tester.pumpAndSettle();

    final fieldFinder =
        find.byKey(const ValueKey('payment_history_department_all'));
    final dropdown = tester.widget<DropdownButton<String>>(
      find.descendant(of: fieldFinder, matching: find.byType(DropdownButton<String>)),
    );
    expect(dropdown.items!.map((item) => item.value).toList(), [
      'all',
      'Tech',
      'Telecalling',
      'Management',
    ]);
    expect(dropdown.items, hasLength(4));
  });

  testWidgets('month/year, department and status filters use provider query',
      (tester) async {
    final requested = <Uri>[];
    final employeeRows = [
      paymentJson(employeeId: 'EMP_TECH', employeeName: 'Asha Rao',
          department: 'Tech', status: 'PENDING'),
      paymentJson(id: 'pay_2', employeeId: 'EMP_TELE',
          employeeName: 'Neha Shah', department: 'Telecalling', status: 'PENDING'),
      paymentJson(id: 'pay_3', employeeId: 'EMP_MGMT',
          employeeName: 'Morgan Lee', department: 'Management', status: 'PENDING'),
    ];
    ApiService.client = MockClient((request) async {
      requested.add(request.url);
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
      return response(historyResponse(rows));
    });
    final provider = HRProvider()
      ..salaryPaymentMonth = 11
      ..salaryPaymentYear = 2026
      ..salaryPaymentHistory = [
        payment(department: 'Tech', status: 'PENDING'),
        payment(id: 'pay_2', department: 'Telecalling', status: 'PENDING'),
        payment(id: 'pay_3', department: 'Management', status: 'PENDING'),
      ]
      ..hasLoadedSalaryPaymentHistory = true;
    await mountHistory(tester, provider);
    await tester.pumpAndSettle();
    requested.clear();

    await tester.tap(find.byKey(const ValueKey('payment_history_month_11')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('October').last);
    await tester.pumpAndSettle();
    expect(provider.salaryPaymentMonth, 10);
    expect(requested.last.queryParameters['month'], '10');

    await tester.tap(find.byKey(const ValueKey('payment_history_year_2026')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025').last);
    await tester.pumpAndSettle();
    expect(provider.salaryPaymentYear, 2025);
    expect(requested.last.queryParameters['year'], '2025');

    await tester
        .tap(find.byKey(const ValueKey('payment_history_department_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tech').last);
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters['department'], 'Tech');
    expect(requested.last.queryParameters['month'], '10');
    expect(requested.last.queryParameters['year'], '2025');
    expect(provider.salaryPaymentHistory.map((item) => item.department),
        ['Tech']);

    await tester.tap(
        find.byKey(const ValueKey('payment_history_department_Tech')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Telecalling').last);
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters['department'], 'Telecalling');
    expect(provider.salaryPaymentHistory.map((item) => item.department),
        ['Telecalling']);

    await tester.tap(
        find.byKey(const ValueKey('payment_history_department_Telecalling')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Management').last);
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters['department'], 'Management');
    expect(provider.salaryPaymentHistory.map((item) => item.department),
        ['Management']);

    await tester.tap(
        find.byKey(const ValueKey('payment_history_department_Management')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Departments').last);
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters.containsKey('department'), isFalse);
    expect(provider.salaryPaymentHistory.map((item) => item.department),
        ['Tech', 'Telecalling', 'Management']);

    await tester.tap(find.byKey(const ValueKey('payment_history_status_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PENDING').last);
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters['status'], 'PENDING');

    await tester.enterText(
        find.byKey(const ValueKey('payment_history_search')), 'Asha');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(const ValueKey('payment_history_department_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tech').last);
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters['department'], 'Tech');
    expect(requested.last.queryParameters['month'], '10');
    expect(requested.last.queryParameters['year'], '2025');
    expect(requested.last.queryParameters['status'], 'PENDING');
    expect(requested.last.queryParameters['search'], 'Asha');
    expect(provider.salaryPaymentHistory.map((item) => item.employeeName),
        ['Asha Rao']);

    await tester
        .tap(find.byKey(const ValueKey('payment_history_status_PENDING')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All').last);
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters.containsKey('status'), isFalse);
  });

  testWidgets('employee search is debounced and sent to the history endpoint',
      (tester) async {
    Uri? requestedUri;
    ApiService.client = MockClient((request) async {
      requestedUri = request.url;
      return response(historyResponse());
    });
    final provider = HRProvider()
      ..hasLoadedSalaryPaymentHistory = true
      ..salaryPaymentHistory = [payment()];
    await mountHistory(tester, provider);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('payment_history_search')), 'Asha');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(requestedUri?.queryParameters['search'], 'Asha');
  });

  testWidgets('history pagination requests the selected page', (tester) async {
    Uri? requestedUri;
    ApiService.client = MockClient((request) async {
      requestedUri = request.url;
      final body = historyResponse([paymentJson(id: 'page_2')]);
      body['pagination']['page'] = 2;
      body['pagination']['total'] = 80;
      body['pagination']['totalPages'] = 2;
      return response(body);
    });
    final provider = HRProvider()
      ..salaryPaymentHistory = [payment()]
      ..salaryPaymentHistoryTotal = 80
      ..salaryPaymentHistoryTotalPages = 2
      ..hasLoadedSalaryPaymentHistory = true;
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(ChangeNotifierProvider<HRProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: SalaryPaymentHistoryTab())),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Page 1 of 2'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Next page'));
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    expect(requestedUri?.queryParameters['page'], '2');
    expect(provider.salaryPaymentHistoryPage, 2);
    expect(provider.salaryPaymentHistory.single.id, 'page_2');
  });

  testWidgets('paid row details show backend metadata and nulls safely',
      (tester) async {
    ApiService.client = MockClient((request) async {
      if (request.url.path.endsWith('/pay_1')) {
        return response({
          'success': true,
          'data': paymentJson(),
        });
      }
      return response(historyResponse([paymentJson()]));
    });
    final provider = HRProvider()
      ..hasLoadedSalaryPaymentHistory = true
      ..salaryPaymentHistory = [payment()];
    await mountHistory(tester, provider);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('payment_history_details_pay_1')));
    await tester
        .tap(find.byKey(const ValueKey('payment_history_details_pay_1')));
    await tester.pumpAndSettle();
    expect(find.text('Payment Details'), findsOneWidget);
    expect(find.text('Morgan Lee'), findsNWidgets(2));
    expect(find.text('Bank Transfer'), findsNWidgets(2));
    expect(find.text('Salary paid'), findsOneWidget);
    expect(find.textContaining('Confirmed timestamp'), findsOneWidget);
  });

  testWidgets('history loading, API error retry, empty and no-results states',
      (tester) async {
    final gate = Completer<void>();
    var fail = true;
    ApiService.client = MockClient((request) async {
      if (fail) {
        await gate.future;
        return response({
          'success': false,
          'message': 'History service unavailable',
        }, 503);
      }
      return response(historyResponse(const []));
    });
    final provider = HRProvider();
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    provider.hasLoadedApiPayroll = true;
    await tester.pumpWidget(ChangeNotifierProvider<HRProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: SalaryPaymentHistoryTab())),
    ));
    provider.loadSalaryPaymentHistory(page: 1);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('History service unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No salary payment history found for this period.'),
        findsOneWidget);

    provider
      ..salaryPaymentSearchQuery = 'no match'
      ..salaryPaymentHistory = [];
    provider.notifyListeners();
    await tester.pumpAndSettle();
    expect(
        find.text('No payment history matches your search.'), findsOneWidget);
  });
}
