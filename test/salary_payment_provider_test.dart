import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

Map<String, dynamic> paymentJson({String status = 'PENDING'}) => {
      '_id': 'payment_1',
      'employee': 'employee_1',
      'employeeId': 'EMP001',
      'employeeName': 'Test Employee',
      'department': 'Tech',
      'payrollBatch': 'batch_1',
      'payrollRecord': 'record_1',
      'payrollMonth': 5,
      'payrollYear': 2026,
      'monthlyBaseSalary': 50000,
      'totalPresentDays': 20,
      'paidLeaveDays': 1,
      'lopDays': 0,
      'payableDays': 21,
      'netSalary': 49000,
      'status': status,
      'paymentDate': status == 'PAID' ? '2026-06-02T00:00:00.000Z' : null,
      'paymentMethod': status == 'PAID' ? 'CASH' : null,
      'transactionReference': '',
      'remarks': '',
      'confirmedBy': null,
      'confirmedAt': null,
      'paymentStatusEvidence': status == 'PAID'
          ? 'EMPLOYEE_PAYMENT_CONFIRMED'
          : 'NO_EMPLOYEE_PAYMENT_CONFIRMATION',
    };

Map<String, dynamic> paymentSummaryJson({int paid = 0}) => {
      'year': 2026,
      'month': 5,
      'totalEmployees': 1,
      'totalSalary': 49000,
      'paidEmployees': paid,
      'pendingEmployees': 1 - paid,
      'paidAmount': paid == 1 ? 49000 : 0,
      'pendingAmount': paid == 0 ? 49000 : 0,
    };

Map<String, dynamic> listResponse({String status = 'PENDING'}) => {
      'success': true,
      'data': [paymentJson(status: status)],
      'pagination': {
        'pagination': {'page': 1, 'limit': 50, 'total': 1, 'totalPages': 1},
        'summary': paymentSummaryJson(paid: status == 'PAID' ? 1 : 0),
      },
    };

Map<String, dynamic> historyResponse({String status = 'PENDING'}) => {
      'success': true,
      'data': [paymentJson(status: status)],
      'pagination': {'page': 1, 'limit': 50, 'total': 1, 'totalPages': 1},
    };

http.Response jsonResponse(Map<String, dynamic> json, [int status = 200]) =>
    http.Response(jsonEncode(json), status,
        headers: {'content-type': 'application/json'});

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
    ApiService.resetBaseUrl();
  });

  test('provider construction and pre-load filters make no payment requests',
      () async {
    var requestCount = 0;
    ApiService.client = MockClient((request) async {
      requestCount++;
      return jsonResponse(listResponse());
    });
    final provider = HRProvider();

    provider.setSalaryPaymentMonth(5, 2026);
    provider.setSalaryPaymentSearch('Ravi');
    provider.setSalaryPaymentDepartment('Tech');
    provider.setSalaryPaymentStatus('PENDING');

    expect(requestCount, 0);
    expect(provider.salaryPaymentMonth, 5);
    expect(provider.salaryPaymentYear, 2026);
    expect(provider.salaryPaymentSearchQuery, 'Ravi');
    expect(provider.salaryPaymentDepartment, 'Tech');
    expect(provider.salaryPaymentStatusFilter, 'PENDING');
  });

  test('explicit list load sets loading, list, summary, and pagination',
      () async {
    late http.Request captured;
    ApiService.client = MockClient((request) async {
      captured = request;
      return jsonResponse(listResponse());
    });
    final provider = HRProvider();
    provider.setSalaryPaymentMonth(5, 2026);
    provider.setSalaryPaymentSearch(' Ravi ');
    provider.setSalaryPaymentDepartment('Tech');
    provider.setSalaryPaymentStatus('pending');

    final load = provider.loadSalaryPayments();
    expect(provider.isSalaryPaymentsLoading, isTrue);
    await load;

    expect(captured.url.queryParameters, {
      'month': '5',
      'year': '2026',
      'department': 'Tech',
      'search': 'Ravi',
      'status': 'PENDING',
      'page': '1',
      'limit': '50',
    });
    expect(provider.isSalaryPaymentsLoading, isFalse);
    expect(provider.hasLoadedSalaryPayments, isTrue);
    expect(provider.salaryPayments.single.status, 'PENDING');
    expect(provider.salaryPaymentSummary?.pendingEmployees, 1);
    expect(provider.salaryPaymentPage, 1);
    expect(provider.salaryPaymentTotal, 1);
  });

  test('explicit summary and history loads preserve independent state',
      () async {
    final paths = <String>[];
    ApiService.client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('/summary')) {
        return jsonResponse({'success': true, 'data': paymentSummaryJson()});
      }
      return jsonResponse(historyResponse());
    });
    final provider = HRProvider();
    provider.setSalaryPaymentMonth(5, 2026);
    provider.setSalaryPaymentSearch('EMP001');
    provider.setSalaryPaymentDepartment('Tech');
    provider.setSalaryPaymentStatus('PAID');

    final summaryLoad = provider.loadSalaryPaymentSummary();
    final historyLoad = provider.loadSalaryPaymentHistory();
    expect(provider.isSalaryPaymentSummaryLoading, isTrue);
    expect(provider.isSalaryPaymentHistoryLoading, isTrue);
    await Future.wait([summaryLoad, historyLoad]);

    expect(
        paths,
        containsAll([
          '/api/hr/payroll/payments/summary',
          '/api/hr/payroll/payments/history',
        ]));
    expect(provider.salaryPaymentSummary?.totalSalary, 49000);
    expect(provider.salaryPaymentHistory.single.id, 'payment_1');
    expect(provider.hasLoadedSalaryPaymentHistory, isTrue);
    expect(provider.isSalaryPaymentHistoryLoading, isFalse);
    expect(provider.salaryPaymentHistoryError, isNull);
  });

  test('payment detail loading stores the selected response', () async {
    ApiService.client = MockClient((request) async => jsonResponse({
          'success': true,
          'data': paymentJson(status: 'PAID'),
        }));
    final provider = HRProvider();
    final load = provider.loadSalaryPaymentDetails('payment_1');
    expect(provider.isSalaryPaymentDetailLoading, isTrue);
    await load;
    expect(provider.isSalaryPaymentDetailLoading, isFalse);
    expect(provider.selectedSalaryPayment?.status, 'PAID');
    expect(provider.salaryPaymentDetailError, isNull);
  });

  test('loaded filters trigger refreshed payment data with the selected period',
      () async {
    final listQueries = <Map<String, String>>[];
    ApiService.client = MockClient((request) async {
      if (request.url.path == '/api/hr/payroll/payments') {
        listQueries.add(request.url.queryParameters);
        return jsonResponse(listResponse());
      }
      if (request.url.path.endsWith('/summary')) {
        return jsonResponse({'success': true, 'data': paymentSummaryJson()});
      }
      return jsonResponse(historyResponse());
    });
    final provider = HRProvider();
    await provider.loadSalaryPayments();
    expect(listQueries, hasLength(1));

    provider.setSalaryPaymentMonth(6, 2026);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    provider.setSalaryPaymentSearch('EMP002');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    provider.setSalaryPaymentDepartment('Sales');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    provider.setSalaryPaymentStatus('PAID');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(listQueries.last, {
      'month': '6',
      'year': '2026',
      'department': 'Sales',
      'search': 'EMP002',
      'status': 'PAID',
      'page': '1',
      'limit': '50',
    });
    expect(provider.salaryPaymentPage, 1);
  });

  test('history-only filters avoid payment API calls until returning to tab',
      () async {
    final paths = <String>[];
    ApiService.client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/api/hr/payroll/payments') {
        return jsonResponse(listResponse());
      }
      if (request.url.path.endsWith('/summary')) {
        return jsonResponse({'success': true, 'data': paymentSummaryJson()});
      }
      return jsonResponse(historyResponse());
    });
    final provider = HRProvider();
    await Future.wait([
      provider.loadSalaryPayments(),
      provider.loadSalaryPaymentHistory(),
    ]);
    paths.clear();

    provider.setSalaryPaymentDepartment('Sales', historyOnly: true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(paths, ['/api/hr/payroll/payments/history']);
    expect(provider.salaryPaymentsNeedRefresh, isTrue);

    await Future.wait([
      provider.loadSalaryPayments(page: 1),
      provider.loadSalaryPaymentSummary(),
    ]);
    expect(
        paths.sublist(1),
        containsAll([
          '/api/hr/payroll/payments',
          '/api/hr/payroll/payments/summary',
        ]));
    expect(provider.salaryPaymentsNeedRefresh, isFalse);

    paths.clear();
    provider.setSalaryPaymentDepartment('Tech', paymentsOnly: true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(paths, ['/api/hr/payroll/payments']);
    expect(provider.salaryPaymentHistoryNeedRefresh, isTrue);

    await provider.loadSalaryPaymentHistory(page: 1);
    expect(paths.last, '/api/hr/payroll/payments/history');
    expect(provider.salaryPaymentHistoryNeedRefresh, isFalse);
  });

  test('payment list errors clear loading and retain the backend message',
      () async {
    ApiService.client = MockClient((request) async => jsonResponse({
          'success': false,
          'message': 'Payment list unavailable',
          'error': null,
        }, 500));
    final provider = HRProvider();

    final load = provider.loadSalaryPayments();
    expect(provider.isSalaryPaymentsLoading, isTrue);
    await load;

    expect(provider.isSalaryPaymentsLoading, isFalse);
    expect(provider.salaryPaymentsError, 'Payment list unavailable');
    expect(provider.salaryPayments, isEmpty);
  });

  test('summary and history errors clear their own loading states', () async {
    ApiService.client = MockClient((request) async => jsonResponse({
          'success': false,
          'message': 'Salary payment service unavailable',
          'error': null,
        }, 503));
    final provider = HRProvider();
    final summaryLoad = provider.loadSalaryPaymentSummary();
    final historyLoad = provider.loadSalaryPaymentHistory();
    expect(provider.isSalaryPaymentSummaryLoading, isTrue);
    expect(provider.isSalaryPaymentHistoryLoading, isTrue);
    await Future.wait([summaryLoad, historyLoad]);
    expect(provider.isSalaryPaymentSummaryLoading, isFalse);
    expect(provider.isSalaryPaymentHistoryLoading, isFalse);
    expect(provider.salaryPaymentSummaryError,
        'Salary payment service unavailable');
    expect(provider.salaryPaymentHistoryError,
        'Salary payment service unavailable');
  });

  test('successful mark-paid updates only after success and refreshes views',
      () async {
    final postStarted = Completer<void>();
    final releasePost = Completer<void>();
    var postCount = 0;
    var listRefreshCount = 0;
    var summaryRefreshCount = 0;
    var historyRefreshCount = 0;
    ApiService.client = MockClient((request) async {
      if (request.method == 'POST') {
        postCount++;
        postStarted.complete();
        await releasePost.future;
        return jsonResponse({
          'success': true,
          'data': paymentJson(status: 'PAID'),
        });
      }
      if (request.url.path == '/api/hr/payroll/payments') {
        listRefreshCount++;
        return jsonResponse(listResponse(status: 'PAID'));
      }
      if (request.url.path.endsWith('/summary')) {
        summaryRefreshCount++;
        return jsonResponse({
          'success': true,
          'data': paymentSummaryJson(paid: 1),
        });
      }
      historyRefreshCount++;
      return jsonResponse(historyResponse(status: 'PAID'));
    });
    final provider = HRProvider()
      ..salaryPayments = [SalaryPayment.fromJson(paymentJson())]
      ..salaryPaymentHistory = [SalaryPayment.fromJson(paymentJson())]
      ..hasLoadedSalaryPaymentHistory = true;
    final request = ConfirmSalaryPaymentRequest(
      paymentDate: DateTime(2026, 6, 2),
      paymentMethod: 'CASH',
    );

    final submission = provider.markSalaryPaymentPaid('payment_1', request);
    await postStarted.future;
    expect(provider.isMarkSalaryPaymentLoading, isTrue);
    expect(provider.salaryPayments.single.status, 'PENDING');
    expect(await provider.markSalaryPaymentPaid('payment_1', request), isFalse);
    expect(postCount, 1);
    releasePost.complete();

    expect(await submission, isTrue);
    expect(provider.isMarkSalaryPaymentLoading, isFalse);
    expect(provider.salaryPayments.single.status, 'PAID');
    expect(provider.salaryPaymentSummary?.paidEmployees, 1);
    expect(provider.salaryPaymentHistory.single.status, 'PAID');
    expect(listRefreshCount, 1);
    expect(summaryRefreshCount, 0);
    expect(historyRefreshCount, 1);
  });

  test('failed mark-paid preserves pending state and backend conflict message',
      () async {
    ApiService.client = MockClient((request) async => jsonResponse({
          'success': false,
          'message':
              'Cannot confirm payment while unresolved payroll conflicts exist',
          'error': null,
        }, 409));
    final provider = HRProvider()
      ..salaryPayments = [SalaryPayment.fromJson(paymentJson())];

    final success = await provider.markSalaryPaymentPaid(
      'payment_1',
      ConfirmSalaryPaymentRequest(
        paymentDate: DateTime(2026, 6, 2),
        paymentMethod: 'CASH',
      ),
    );

    expect(success, isFalse);
    expect(provider.isMarkSalaryPaymentLoading, isFalse);
    expect(provider.salaryPayments.single.status, 'PENDING');
    expect(provider.markSalaryPaymentError,
        'Cannot confirm payment while unresolved payroll conflicts exist');
  });
}
