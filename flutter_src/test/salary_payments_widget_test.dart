import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
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
}) =>
    {
      '_id': id,
      'employee': 'employee_$employeeId',
      'employeeId': employeeId,
      'employeeName': employeeName,
      'department': 'Tech',
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

Map<String, dynamic> summaryJson({int paid = 0}) => {
      'year': 2026,
      'month': 11,
      'totalEmployees': 2,
      'totalSalary': 120000,
      'paidEmployees': paid,
      'pendingEmployees': 2 - paid,
      'paidAmount': paid * 60000,
      'pendingAmount': (2 - paid) * 60000,
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

SalaryPayment payment({String status = 'PENDING', String id = 'payment_1'}) =>
    SalaryPayment.fromJson(paymentJson(status: status, id: id));

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
    expect(find.text('₹ 120000.00'), findsNWidgets(2));
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
