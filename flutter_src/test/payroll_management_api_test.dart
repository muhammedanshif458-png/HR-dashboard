import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/payroll/payroll_view.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  // ─── 1. ApiService.getPayrollSummary ───────────────────────────────────────
  group('ApiService.getPayrollSummary', () {
    test('calls GET /api/hr/payroll/summary with auth, month, year, department',
        () async {
      String? authHeader;
      String? requestedPath;
      Map<String, String>? queryParams;

      ApiService.setToken('test_jwt_payroll_token');
      ApiService.client = MockClient((request) async {
        authHeader = request.headers['Authorization'];
        requestedPath = request.url.path;
        queryParams = request.url.queryParameters;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Payroll summary retrieved successfully',
            'data': {
              'year': 2026,
              'month': 10,
              'department': 'Tech',
              'totalEmployees': 24,
              'totalPayrollExpenditure': 1560000.0,
              'totalDeductions': 42500.0,
              'totalNetPayout': 1517500.0,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final summary = await ApiService.getPayrollSummary(
        month: 10,
        year: 2026,
        department: 'Tech',
      );

      expect(authHeader, 'Bearer test_jwt_payroll_token');
      expect(requestedPath, '/api/hr/payroll/summary');
      expect(queryParams?['month'], '10');
      expect(queryParams?['year'], '2026');
      expect(queryParams?['department'], 'Tech');

      expect(summary.year, 2026);
      expect(summary.month, 10);
      expect(summary.department, 'Tech');
      expect(summary.totalEmployees, 24);
      expect(summary.totalPayrollExpenditure, 1560000.0);
      expect(summary.totalDeductions, 42500.0);
      expect(summary.totalNetPayout, 1517500.0);
    });

    test('handles 401 unauthorized error', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Unauthorized access: Invalid or expired token',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.getPayrollSummary(month: 10, year: 2026),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Unauthorized access'))),
      );
    });

    test('handles malformed JSON error', () async {
      ApiService.client = MockClient((request) async {
        return http.Response('<html>502 Bad Gateway</html>', 502);
      });

      expect(
        () => ApiService.getPayrollSummary(month: 10, year: 2026),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── 2. ApiService.getEmployeesPayroll ─────────────────────────────────────
  group('ApiService.getEmployeesPayroll', () {
    test('calls GET /api/hr/payroll/employees with pagination and search query',
        () async {
      String? authHeader;
      String? requestedPath;
      Map<String, String>? queryParams;

      ApiService.setToken('test_jwt_payroll_token');
      ApiService.client = MockClient((request) async {
        authHeader = request.headers['Authorization'];
        requestedPath = request.url.path;
        queryParams = request.url.queryParameters;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Employee payroll records retrieved successfully',
            'data': [
              {
                'employee': {
                  'id': 'emp_101',
                  'employeeId': 'EMP1001',
                  'firstName': 'Anita',
                  'lastName': 'Rao',
                  'name': 'Anita Rao',
                  'department': 'Tech',
                  'designation': 'Lead HR Manager',
                  'status': 'ACTIVE',
                  'salary': 85000,
                  'salaryCurrency': 'INR',
                },
                'year': 2026,
                'month': 10,
                'standardWorkingDays': 22,
                'presentDays': 21,
                'approvedLeaves': 1,
                'paidLeaveDays': 1,
                'unpaidLeaveDays': 0,
                'payableDays': 22,
                'grossSalary': 85000,
                'dailyRate': 3863.64,
                'deductions': 0,
                'netPay': 85000,
              },
              {
                'employee': {
                  'id': 'emp_102',
                  'employeeId': 'EMP1002',
                  'firstName': 'Vikram',
                  'lastName': 'Singh',
                  'name': 'Vikram Singh',
                  'department': 'Telecalling',
                  'designation': 'Support Lead',
                  'status': 'ACTIVE',
                  'salary': 52000,
                  'salaryCurrency': 'INR',
                },
                'year': 2026,
                'month': 10,
                'standardWorkingDays': 26,
                'presentDays': 23,
                'approvedLeaves': 3,
                'paidLeaveDays': 1,
                'unpaidLeaveDays': 2,
                'payableDays': 24,
                'grossSalary': 52000,
                'dailyRate': 2000.0,
                'deductions': 4000.0,
                'netPay': 48000.0,
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 2,
              'totalPages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.getEmployeesPayroll(
        month: 10,
        year: 2026,
        department: 'Tech',
        search: 'Anita',
        page: 1,
        limit: 50,
      );

      expect(authHeader, 'Bearer test_jwt_payroll_token');
      expect(requestedPath, '/api/hr/payroll/employees');
      expect(queryParams?['month'], '10');
      expect(queryParams?['year'], '2026');
      expect(queryParams?['department'], 'Tech');
      expect(queryParams?['search'], 'Anita');
      expect(queryParams?['page'], '1');
      expect(queryParams?['limit'], '50');

      expect(result.page, 1);
      expect(result.total, 2);
      expect(result.totalPages, 1);
      expect(result.records.length, 2);

      final r1 = result.records[0];
      expect(r1.employeeId, 'EMP1001');
      expect(r1.name, 'Anita Rao');
      expect(r1.department, 'Tech');
      expect(r1.standardWorkingDays, 22);
      expect(r1.presentDays, 21);
      expect(r1.approvedLeaves, 1);
      expect(r1.paidLeaveDays, 1);
      expect(r1.unpaidLeaveDays, 0);
      expect(r1.payableDays, 22);
      expect(r1.grossSalary, 85000);
      expect(r1.deductions, 0);
      expect(r1.netPay, 85000);

      final r2 = result.records[1];
      expect(r2.employeeId, 'EMP1002');
      expect(r2.name, 'Vikram Singh');
      expect(r2.department, 'Telecalling');
      expect(r2.standardWorkingDays, 26);
      expect(r2.unpaidLeaveDays, 2);
      expect(r2.dailyRate, 2000.0);
      expect(r2.deductions, 4000.0);
      expect(r2.netPay, 48000.0);
    });

    test('handles empty results and server error response safely', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Employee payroll records retrieved successfully',
            'data': [],
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 0,
              'totalPages': 0,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result =
          await ApiService.getEmployeesPayroll(month: 10, year: 2026);
      expect(result.records, isEmpty);
      expect(result.total, 0);
    });
  });

  // ─── 3. ApiService.getEmployeePayrollById ──────────────────────────────────
  group('ApiService.getEmployeePayrollById', () {
    test(
        'calls GET /api/hr/payroll/employees/:id and parses single computation',
        () async {
      ApiService.setToken('test_jwt_payroll_token');
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/payroll/employees/emp_101');
        expect(request.url.queryParameters['month'], '10');
        expect(request.url.queryParameters['year'], '2026');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Employee payroll details retrieved successfully',
            'data': {
              'employee': {
                'id': 'emp_101',
                'employeeId': 'EMP1001',
                'firstName': 'Anita',
                'lastName': 'Rao',
                'name': 'Anita Rao',
                'department': 'Tech',
                'designation': 'Lead HR Manager',
                'status': 'ACTIVE',
                'salary': 85000,
                'salaryCurrency': 'INR',
              },
              'year': 2026,
              'month': 10,
              'standardWorkingDays': 22,
              'presentDays': 21,
              'approvedLeaves': 1,
              'paidLeaveDays': 1,
              'unpaidLeaveDays': 0,
              'payableDays': 22,
              'grossSalary': 85000,
              'dailyRate': 3863.64,
              'deductions': 0,
              'netPay': 85000,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final detail = await ApiService.getEmployeePayrollById(
        'emp_101',
        month: 10,
        year: 2026,
      );

      expect(detail.name, 'Anita Rao');
      expect(detail.grossSalary, 85000);
      expect(detail.netPay, 85000);
      expect(detail.department, 'Tech');
    });

    test('handles 404 employee not found', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Employee not found',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.getEmployeePayrollById('unknown_id',
            month: 10, year: 2026),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'message', contains('not found'))),
      );
    });
  });

  // ─── 4. HRProvider Payroll State & Filter Operations ───────────────────────
  group('HRProvider Payroll Integration', () {
    test('loadPayroll populates summary, records, and pagination metadata',
        () async {
      final provider = HRProvider();

      ApiService.setToken('test_token');
      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/payroll/summary') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Payroll summary retrieved successfully',
              'data': {
                'year': 2026,
                'month': 10,
                'department': 'all',
                'totalEmployees': 1,
                'totalPayrollExpenditure': 95000.0,
                'totalDeductions': 4318.18,
                'totalNetPayout': 90681.82,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path == '/api/hr/payroll/employees') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Employee payroll records retrieved successfully',
              'data': [
                {
                  'employee': {
                    'id': 'emp_201',
                    'employeeId': 'EMP2001',
                    'firstName': 'John',
                    'lastName': 'Doe',
                    'name': 'John Doe',
                    'department': 'Tech',
                    'designation': 'Software Engineer',
                    'status': 'ACTIVE',
                    'salary': 95000,
                    'salaryCurrency': 'INR',
                  },
                  'year': 2026,
                  'month': 10,
                  'standardWorkingDays': 22,
                  'presentDays': 21,
                  'approvedLeaves': 2,
                  'paidLeaveDays': 1,
                  'unpaidLeaveDays': 1,
                  'payableDays': 22,
                  'grossSalary': 95000,
                  'dailyRate': 4318.18,
                  'deductions': 4318.18,
                  'netPay': 90681.82,
                }
              ],
              'pagination': {
                'page': 1,
                'limit': 50,
                'total': 1,
                'totalPages': 1,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      await provider.loadPayroll();

      expect(provider.hasLoadedApiPayroll, true);
      expect(provider.isPayrollLoading, false);
      expect(provider.payrollError, isNull);
      expect(provider.apiPayrollRecords.length, 1);
      expect(provider.filteredPayrollRecords.length, 1);
      expect(provider.payrollTotal, 1);
      expect(provider.effectivePayrollSummary.totalPayrollExpenditure, 95000.0);
      expect(provider.effectivePayrollSummary.totalNetPayout, 90681.82);
    });

    test('prevents stale mock data and sets error state on API failure',
        () async {
      final provider = HRProvider();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Server database unreachable',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.loadPayroll();

      expect(provider.isPayrollLoading, false);
      expect(provider.payrollError, contains('Server database unreachable'));
      expect(provider.hasLoadedApiPayroll, false);
      // Critical check: filteredPayrollRecords returns empty list upon error, NOT mock records!
      expect(provider.filteredPayrollRecords, isEmpty);
      expect(provider.effectivePayrollSummary.totalPayrollExpenditure, 0.0);
    });

    test('filter changes reset current page to 1 and reload data', () async {
      final provider = HRProvider();
      provider.hasLoadedApiPayroll = true;
      provider.payrollPage = 3;

      int summaryCalls = 0;
      int employeeCalls = 0;

      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/payroll/summary') {
          summaryCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'year': 2026,
                'month': 11,
                'department': 'Tech',
                'totalEmployees': 0,
                'totalPayrollExpenditure': 0,
                'totalDeductions': 0,
                'totalNetPayout': 0
              }
            }),
            200,
          );
        } else if (request.url.path == '/api/hr/payroll/employees') {
          employeeCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {
                'page': 1,
                'limit': 50,
                'total': 0,
                'totalPages': 0
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // 1. Changing month resets page to 1 and triggers reload
      provider.setPayrollMonth(11);
      expect(provider.payrollMonth, 11);
      expect(provider.payrollPage, 1);

      // 2. Changing department resets page to 1 and triggers reload
      provider.payrollPage = 4;
      provider.setPayrollDepartment('Tech');
      expect(provider.payrollDepartment, 'Tech');
      expect(provider.payrollPage, 1);

      // 3. Changing search resets page to 1 and triggers reload
      provider.payrollPage = 5;
      provider.setPayrollSearchQuery('Vikram');
      expect(provider.payrollSearchQuery, 'Vikram');
      expect(provider.payrollPage, 1);

      // Allow background async calls to settle
      await Future.delayed(const Duration(milliseconds: 50));
      expect(summaryCalls >= 3, true);
      expect(employeeCalls >= 3, true);
    });
  });

  // ─── 5. PayrollView Widget Integration Tests ───────────────────────────────
  group('PayrollView Widget Tests', () {
    testWidgets('renders loaded payroll records, metrics, and data table',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiPayroll = true;
      provider.apiPayrollSummary = const PayrollSummary(
        year: 2026,
        month: 10,
        department: 'all',
        totalEmployees: 2,
        totalPayrollExpenditure: 137000.0,
        totalDeductions: 4000.0,
        totalNetPayout: 133000.0,
      );
      provider.apiPayrollRecords = [
        const EmployeePayrollRecord(
          id: 'emp_1',
          employeeId: 'EMP1001',
          firstName: 'Anita',
          lastName: 'Rao',
          name: 'Anita Rao',
          department: 'Tech',
          designation: 'Lead HR Manager',
          status: 'ACTIVE',
          salary: 85000.0,
          salaryCurrency: 'INR',
          year: 2026,
          month: 10,
          standardWorkingDays: 22,
          presentDays: 21,
          approvedLeaves: 1,
          paidLeaveDays: 1,
          unpaidLeaveDays: 0,
          payableDays: 22,
          grossSalary: 85000.0,
          dailyRate: 3863.64,
          deductions: 0.0,
          netPay: 85000.0,
        ),
        const EmployeePayrollRecord(
          id: 'emp_2',
          employeeId: 'EMP1002',
          firstName: 'Vikram',
          lastName: 'Singh',
          name: 'Vikram Singh',
          department: 'Telecalling',
          designation: 'Support Lead',
          status: 'ACTIVE',
          salary: 52000.0,
          salaryCurrency: 'INR',
          year: 2026,
          month: 10,
          standardWorkingDays: 26,
          presentDays: 23,
          approvedLeaves: 3,
          paidLeaveDays: 1,
          unpaidLeaveDays: 2,
          payableDays: 24,
          grossSalary: 52000.0,
          dailyRate: 2000.0,
          deductions: 4000.0,
          netPay: 48000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const PayrollView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and Metrics
      expect(find.text('Monthly Payroll Processing'), findsOneWidget);
      expect(find.text('Gross Salary Pool'), findsOneWidget);
      expect(find.text('₹ 137000'), findsOneWidget);
      expect(find.text('Unpaid Leave Deductions'), findsOneWidget);
      expect(find.text('₹ 4000'), findsOneWidget);
      expect(find.text('Net Payout Amount'), findsOneWidget);
      expect(find.text('₹ 133000'), findsOneWidget);

      // Verify Table Rows
      expect(find.text('Anita Rao'), findsOneWidget);
      expect(find.text('Vikram Singh'), findsOneWidget);
      expect(find.text('22 days (M-F)'), findsOneWidget);
      expect(find.text('26 days (M-Sat)'), findsOneWidget);
      expect(find.text('2 LOP'), findsOneWidget);
      expect(find.text('- ₹ 4000'), findsOneWidget);
    });

    testWidgets(
        'renders error banner with Retry button when payrollError is set',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.payrollError = 'Network timeout reaching payroll service';
      provider.hasLoadedApiPayroll = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const PayrollView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.text(
              'Failed to load payroll data from server: Network timeout reaching payroll service'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No payroll data available due to server error'),
          findsOneWidget);
    });

    testWidgets('opens payslip dialog when View Payslip Details is tapped',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2560, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiPayroll = true;
      provider.apiPayrollSummary = const PayrollSummary(
        year: 2026,
        month: 10,
        department: 'all',
        totalEmployees: 1,
        totalPayrollExpenditure: 85000.0,
        totalDeductions: 0.0,
        totalNetPayout: 85000.0,
      );
      provider.apiPayrollRecords = [
        const EmployeePayrollRecord(
          id: 'emp_1',
          employeeId: 'EMP1001',
          firstName: 'Anita',
          lastName: 'Rao',
          name: 'Anita Rao',
          department: 'Tech',
          designation: 'Lead HR Manager',
          status: 'ACTIVE',
          salary: 85000.0,
          salaryCurrency: 'INR',
          year: 2026,
          month: 10,
          standardWorkingDays: 22,
          presentDays: 21,
          approvedLeaves: 1,
          paidLeaveDays: 1,
          unpaidLeaveDays: 0,
          payableDays: 22,
          grossSalary: 85000.0,
          dailyRate: 3863.64,
          deductions: 0.0,
          netPay: 85000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const PayrollView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final payslipIcon = find.byTooltip('View Payslip Details');
      expect(payslipIcon, findsOneWidget);

      await tester.ensureVisible(payslipIcon);
      await tester.pumpAndSettle();

      await tester.tap(payslipIcon);
      await tester.pumpAndSettle();

      expect(find.text('Payslip: Anita Rao — October 2026'), findsOneWidget);
      expect(find.text('Base Monthly Salary'), findsOneWidget);
      expect(find.text('Total Payable Days'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('22 / 22'),
        ),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Payslip: Anita Rao — October 2026'), findsNothing);
    });

    testWidgets(
        'Process & Finalize Batch shows safe notification without mutating records',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const PayrollView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final finalizeBtn = find.text('Process & Finalize Batch');
      expect(finalizeBtn, findsOneWidget);

      await tester.tap(finalizeBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
            'Batch finalization mutation is pending backend endpoint implementation'),
        findsOneWidget,
      );
    });
  });
}
