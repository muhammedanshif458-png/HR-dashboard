import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

Map<String, dynamic> paymentJson({
  String status = 'PENDING',
  dynamic confirmedBy,
}) =>
    {
      '_id': 'payment_1',
      'employee': 'employee_1',
      'employeeId': 'EMP001',
      'employeeName': 'Test Employee',
      'department': 'Tech',
      'payrollBatch': 'batch_1',
      'payrollRecord': 'record_1',
      'payrollMonth': '5',
      'payrollYear': 2026,
      'legacyBatchStatus': 'PAID',
      'monthlyBaseSalary': '50000.50',
      'totalPresentDays': 20,
      'paidLeaveDays': 1.0,
      'lopDays': '0.5',
      'payableDays': 20.5,
      'netSalary': '49000.25',
      'status': status,
      'paymentDate': status == 'PAID' ? '2026-06-02T00:00:00.000Z' : null,
      'paymentMethod': status == 'PAID' ? 'BANK_TRANSFER' : null,
      'transactionReference': status == 'PAID' ? 'TXN-001' : '',
      'remarks': '',
      'confirmedBy': confirmedBy,
      'confirmedAt': null,
      'paymentStatusEvidence': status == 'PAID'
          ? 'EMPLOYEE_PAYMENT_CONFIRMED'
          : 'NO_EMPLOYEE_PAYMENT_CONFIRMATION',
    };

Map<String, dynamic> summaryJson() => {
      'year': '2026',
      'month': 5,
      'totalEmployees': '1',
      'totalSalary': '49000.25',
      'paidEmployees': 0,
      'pendingEmployees': 1,
      'paidAmount': 0,
      'pendingAmount': '49000.25',
    };

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
    ApiService.resetBaseUrl();
  });

  group('Salary payment models', () {
    test('parses numeric strings, nullable fields, date and null confirmer',
        () {
      final payment = SalaryPayment.fromJson(paymentJson());
      expect(payment.id, 'payment_1');
      expect(payment.payrollMonth, 5);
      expect(payment.monthlyBaseSalary, 50000.50);
      expect(payment.netSalary, 49000.25);
      expect(payment.paymentDate, isNull);
      expect(payment.paymentMethod, isNull);
      expect(payment.confirmedBy, isNull);
      expect(payment.confirmedAt, isNull);
      expect(payment.status, 'PENDING');
    });

    test('parses PAID status and populated confirmedBy', () {
      final payment = SalaryPayment.fromJson(paymentJson(
        status: 'PAID',
        confirmedBy: {
          '_id': 'user_1',
          'firstName': 'HR',
          'lastName': 'Admin',
          'email': 'hr@example.com',
        },
      ));
      expect(payment.isPaid, isTrue);
      expect(payment.confirmedBy?.id, 'user_1');
      expect(payment.confirmedBy?.firstName, 'HR');
      expect(payment.paymentDate?.toUtc().toIso8601String(),
          '2026-06-02T00:00:00.000Z');
    });

    test('reads nested list metadata and summary', () {
      final result = SalaryPaymentListResult.fromJson({
        'data': [paymentJson()],
        'pagination': {
          'pagination': {
            'page': '2',
            'limit': 10.0,
            'total': '11',
            'totalPages': 2
          },
          'summary': summaryJson(),
        },
      });
      expect(result.payments, hasLength(1));
      expect(result.page, 2);
      expect(result.totalPages, 2);
      expect(result.summary.totalSalary, 49000.25);
      expect(result.summary.pendingEmployees, 1);
    });

    test('parses history records and direct pagination', () {
      final result = SalaryPaymentHistoryResult.fromJson({
        'data': [paymentJson(status: 'PAID')],
        'pagination': {'page': 1, 'limit': 50, 'total': 1, 'totalPages': 1},
      });
      expect(result.payments.single.status, 'PAID');
      expect(result.total, 1);
    });

    test(
        'serializes payment request using backend enums and validates reference',
        () {
      final request = ConfirmSalaryPaymentRequest(
        paymentDate: DateTime.utc(2026, 11, 11),
        paymentMethod: 'bank_transfer',
        transactionReference: ' TXN-001 ',
        remarks: ' November salary ',
      );
      expect(request.toJson(), {
        'paymentDate': '2026-11-11',
        'paymentMethod': 'BANK_TRANSFER',
        'transactionReference': 'TXN-001',
        'remarks': 'November salary',
      });
      expect(
        () => ConfirmSalaryPaymentRequest(
          paymentDate: DateTime(2026, 1, 1),
          paymentMethod: 'UPI',
        ).toJson(),
        throwsArgumentError,
      );
    });
  });

  group('Salary payment API service', () {
    setUp(() {
      ApiService.setBaseUrl('https://payroll.example.test/');
      ApiService.setToken('payment_test_token');
    });

    test('GET payment list builds safe query and parses nested pagination',
        () async {
      late http.Request captured;
      ApiService.client = MockClient((request) async {
        captured = request;
        return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Salary payments retrieved successfully',
              'data': [paymentJson()],
              'pagination': {
                'pagination': {
                  'page': 1,
                  'limit': 25,
                  'total': 1,
                  'totalPages': 1
                },
                'summary': summaryJson(),
              },
            }),
            200);
      });
      final result = await ApiService.getSalaryPayments(
        month: 5,
        year: 2026,
        department: 'Tech',
        search: ' A B ',
        employeeId: 'EMP001',
        status: 'pending',
        page: 1,
        limit: 25,
      );
      expect(captured.url.path, '/api/hr/payroll/payments');
      expect(captured.url.queryParameters, {
        'month': '5',
        'year': '2026',
        'department': 'Tech',
        'search': 'A B',
        'employeeId': 'EMP001',
        'status': 'PENDING',
        'page': '1',
        'limit': '25',
      });
      expect(captured.headers['Authorization'], 'Bearer payment_test_token');
      expect(result.payments.single.employeeId, 'EMP001');
      expect(result.page, 1);
    });

    test('GET summary uses correct path and data envelope', () async {
      late http.Request captured;
      ApiService.client = MockClient((request) async {
        captured = request;
        return http.Response(
            jsonEncode({
              'success': true,
              'data': summaryJson(),
            }),
            200);
      });
      final summary =
          await ApiService.getSalaryPaymentSummary(month: 5, year: 2026);
      expect(captured.url.path, '/api/hr/payroll/payments/summary');
      expect(captured.url.queryParameters, {'month': '5', 'year': '2026'});
      expect(summary.totalSalary, 49000.25);
    });

    test('mark-paid posts exact request body to registered route', () async {
      late http.Request captured;
      ApiService.client = MockClient((request) async {
        captured = request;
        return http.Response(
            jsonEncode({
              'success': true,
              'data': paymentJson(
                status: 'PAID',
                confirmedBy: {'_id': 'user_1', 'firstName': 'HR'},
              ),
            }),
            200);
      });
      final result = await ApiService.markSalaryPaymentPaid(
        'payment_1',
        ConfirmSalaryPaymentRequest(
          paymentDate: DateTime(2026, 11, 11),
          paymentMethod: 'BANK_TRANSFER',
          transactionReference: 'TXN-001',
          remarks: 'November salary',
        ),
      );
      expect(captured.url.path, '/api/hr/payroll/payments/payment_1/mark-paid');
      expect(captured.method, 'POST');
      expect(jsonDecode(captured.body), {
        'paymentDate': '2026-11-11',
        'paymentMethod': 'BANK_TRANSFER',
        'transactionReference': 'TXN-001',
        'remarks': 'November salary',
      });
      expect(result.payment.status, 'PAID');
    });

    test('payment details and history parse actual envelopes', () async {
      http.Request? historyRequest;
      ApiService.client = MockClient((request) async {
        if (request.url.path.endsWith('/history')) {
          historyRequest = request;
          return http.Response(
              jsonEncode({
                'success': true,
                'data': [paymentJson(status: 'PAID')],
                'pagination': {
                  'page': 1,
                  'limit': 50,
                  'total': 1,
                  'totalPages': 1
                },
              }),
              200);
        }
        return http.Response(
            jsonEncode({
              'success': true,
              'data': paymentJson(),
            }),
            200);
      });
      final detail = await ApiService.getSalaryPaymentDetails('payment_1');
      expect(detail.payment.id, 'payment_1');
      final history = await ApiService.getSalaryPaymentHistory(
        month: 5,
        year: 2026,
        employeeId: 'EMP001',
        department: 'Tech',
        status: 'paid',
        search: 'Test Employee',
        page: 1,
        limit: 50,
      );
      expect(history.payments.single.status, 'PAID');
      expect(history.total, 1);
      expect(historyRequest?.url.path, '/api/hr/payroll/payments/history');
      expect(historyRequest?.url.queryParameters, {
        'month': '5',
        'year': '2026',
        'employeeId': 'EMP001',
        'department': 'Tech',
        'status': 'PAID',
        'search': 'Test Employee',
        'page': '1',
        'limit': '50',
      });
    });

    test('preserves backend error message instead of returning empty results',
        () async {
      ApiService.client = MockClient((request) async => http.Response(
            jsonEncode({
              'success': false,
              'message':
                  'Cannot confirm payment while unresolved payroll conflicts exist',
              'error': null,
            }),
            409,
          ));
      await expectLater(
        ApiService.getSalaryPaymentDetails('missing'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('unresolved payroll conflicts'))),
      );
    });

    test('rejects malformed successful list envelope', () async {
      ApiService.client = MockClient((request) async => http.Response(
            jsonEncode({'success': true, 'data': []}),
            200,
          ));
      await expectLater(
        ApiService.getSalaryPayments(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
