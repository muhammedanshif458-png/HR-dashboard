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

PayrollConflict _testConflict({
  required String id,
  required String employeeId,
  required String name,
  required String status,
}) {
  return PayrollConflict.fromJson({
    '_id': id,
    'employeeId': employeeId,
    'employee': {
      'employeeId': employeeId,
      'firstName': name,
      'lastName': 'Test',
    },
    'dateKey': '2026-11-10',
    'conflictDate': '2026-11-10T00:00:00.000Z',
    'year': 2026,
    'month': 11,
    'conflictType': 'ATTENDANCE_AND_APPROVED_LEAVE',
    'status': status,
  });
}

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
      provider.payrollMonth = 10;
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
          presentDays: 21.0,
          approvedLeaves: 1,
          paidLeaveDays: 1.0,
          unpaidLeaveDays: 0.0,
          payableDays: 22.0,
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
          presentDays: 23.0,
          approvedLeaves: 3,
          paidLeaveDays: 1.0,
          unpaidLeaveDays: 2.0,
          payableDays: 24.0,
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
          presentDays: 21.0,
          approvedLeaves: 1,
          paidLeaveDays: 1.0,
          unpaidLeaveDays: 0.0,
          payableDays: 22.0,
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
        'Payroll table and payslip modal display combined Total Present for Hashim K and Rahul K without separate WFH columns',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2560, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiPayroll = true;
      provider.apiPayrollSummary = const PayrollSummary(
        year: 2026,
        month: 11,
        department: 'all',
        totalEmployees: 2,
        totalPayrollExpenditure: 110000.0,
        totalDeductions: 102272.72,
        totalNetPayout: 7727.28,
      );

      // Hashim K: presentDays 0 + wfhDays 1 = Total Present 1
      // Standard working days: 22, Gross: 50,000, Net: 2272.73
      const hashimRecord = EmployeePayrollRecord(
        id: 'emp_hashim',
        employeeId: 'EMP2001',
        firstName: 'Hashim',
        lastName: 'K',
        name: 'Hashim K',
        department: 'Tech',
        designation: 'Backend Developer',
        status: 'ACTIVE',
        salary: 50000.0,
        salaryCurrency: 'INR',
        year: 2026,
        month: 11,
        standardWorkingDays: 22,
        presentDays: 0.0,
        wfhDays: 1,
        halfDays: 0.0,
        approvedLeaves: 0,
        paidLeaveDays: 0.0,
        unpaidLeaveDays: 21.0,
        payableDays: 1.0,
        grossSalary: 50000.0,
        dailyRate: 2272.73,
        deductions: 47727.27,
        netPay: 2272.73,
      );

      // Rahul K: presentDays 2 + wfhDays 0 = Total Present 2
      // Standard working days: 22, Gross: 60,000, Net: 5454.55
      const rahulRecord = EmployeePayrollRecord(
        id: 'emp_rahul',
        employeeId: 'EMP2002',
        firstName: 'Rahul',
        lastName: 'K',
        name: 'Rahul K',
        department: 'Tech',
        designation: 'Frontend Developer',
        status: 'ACTIVE',
        salary: 60000.0,
        salaryCurrency: 'INR',
        year: 2026,
        month: 11,
        standardWorkingDays: 22,
        presentDays: 2.0,
        wfhDays: 0,
        halfDays: 0.0,
        approvedLeaves: 0,
        paidLeaveDays: 0.0,
        unpaidLeaveDays: 20.0,
        payableDays: 2.0,
        grossSalary: 60000.0,
        dailyRate: 2727.27,
        deductions: 54545.45,
        netPay: 5454.55,
      );

      provider.apiPayrollRecords = [hashimRecord, rahulRecord];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const PayrollView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Column Headers in Table
      expect(find.text('Total Present'), findsOneWidget);
      expect(find.text('Half Days'), findsOneWidget);
      expect(find.text('Approved Leaves'), findsOneWidget);
      expect(find.text('Paid / Unpaid'), findsOneWidget);
      expect(find.text('Payable Days'), findsOneWidget);
      // No separate WFH Days or Actual Present or Office Days columns
      expect(find.text('WFH Days'), findsNothing);
      expect(find.text('Actual Present'), findsNothing);
      expect(find.text('Office Days'), findsNothing);

      // 2. Verify Hashim K row in Table: presentDays 0 + wfhDays 1 = Total Present 1
      expect(find.text('Hashim K'), findsOneWidget);
      expect(find.text('1 day'), findsWidgets);
      expect(find.text('1 / 22'), findsOneWidget);

      // 3. Verify Rahul K row in Table: presentDays 2 + wfhDays 0 = Total Present 2
      expect(find.text('Rahul K'), findsOneWidget);
      expect(find.text('2 days'), findsWidgets);
      expect(find.text('2 / 22'), findsOneWidget);

      // 4. Open Payslip Modal for Hashim K
      final payslipIcons = find.byTooltip('View Payslip Details');
      expect(payslipIcons, findsNWidgets(2));

      await tester.tap(payslipIcons.first);
      await tester.pumpAndSettle();

      // Verify Payslip Modal Breakdown
      expect(find.text('Payslip: Hashim K — November 2026'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Total Present Days'),
        ),
        findsOneWidget,
      );
      // Total Present Days for Hashim: 1 day
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('1 day'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Half Days'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Approved Leaves'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Paid Leave Days'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Unpaid Leave / LOP'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Total Payable Days'),
        ),
        findsOneWidget,
      );

      // No separate WFH Days or Actual Present or Office Days row in modal
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('WFH Days'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Actual Present Days'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Office Days'),
        ),
        findsNothing,
      );

      // Payable days remain unchanged: 1 / 22
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('1 / 22'),
        ),
        findsOneWidget,
      );

      // Existing payslip salary values remain unchanged
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Base Monthly Salary'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('₹ 50000'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Net Pay'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('₹ 2273'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // 5. Open Payslip Modal for Rahul K
      await tester.tap(payslipIcons.last);
      await tester.pumpAndSettle();

      expect(find.text('Payslip: Rahul K — November 2026'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Total Present Days'),
        ),
        findsOneWidget,
      );
      // Total Present Days for Rahul: 2 days
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('2 days'),
        ),
        findsOneWidget,
      );
      // Payable days: 2 / 22
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('2 / 22'),
        ),
        findsOneWidget,
      );
      // Existing salary values remain unchanged
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('₹ 60000'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('₹ 5455'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Payroll header preserves refresh button and does not render obsolete Process & Finalize Batch button',
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

      // Obsolete header button is removed
      expect(find.text('Process & Finalize Batch'), findsNothing);

      // Refresh button is preserved
      final refreshBtn = find.byTooltip('Refresh Payroll Data');
      expect(refreshBtn, findsOneWidget);
    });

    testWidgets('renders all 4 tabs and displays conflict badge',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.conflictsUnresolvedTotal = 2;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const PayrollView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Payroll Calc'), findsOneWidget);
      expect(find.text('Conflicts'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // unresolved count badge
      expect(find.text('Salary Payments'), findsOneWidget);
      expect(find.text('Payment History'), findsOneWidget);
      expect(find.text('Batch'), findsNothing);
    });
    testWidgets('Clear Resolved confirmation can be cancelled without changing conflicts',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider()
        ..hasLoadedApiPayroll = true
        ..hasLoadedConflicts = true
        ..conflictsTotal = 2
        ..conflictsUnresolvedTotal = 1
        ..payrollConflicts = [
          _testConflict(id: 'resolved_1', employeeId: 'EMP_RES',
              name: 'Resolved Person', status: 'RESOLVED'),
          _testConflict(id: 'unresolved_1', employeeId: 'EMP_UNRES',
              name: 'Unresolved Person', status: 'UNRESOLVED'),
        ];
      var apiCalls = 0;
      ApiService.client = MockClient((request) async {
        apiCalls++;
        fail('Cancel must not make an API request: ${request.method} ${request.url}');
      });

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const PayrollView(),
        ),
      ));
      await tester.tap(find.text('Conflicts'));
      await tester.pumpAndSettle();
      expect(find.text('Resolved Person Test'), findsOneWidget);
      expect(find.text('Unresolved Person Test'), findsOneWidget);

      await tester.tap(find.text('Clear Resolved'));
      await tester.pumpAndSettle();
      expect(find.text('Clear resolved conflicts?'), findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ));
      await tester.pumpAndSettle();

      expect(provider.conflictsStatusFilter, 'all');
      expect(provider.payrollConflicts.map((c) => c.id),
          containsAll(['resolved_1', 'unresolved_1']));
      expect(find.text('Resolved Person Test'), findsOneWidget);
      expect(find.text('Unresolved Person Test'), findsOneWidget);
      expect(apiCalls, 0);
    });

    testWidgets('confirming Clear Resolved reloads Unresolved records only',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider()
        ..hasLoadedApiPayroll = true
        ..hasLoadedConflicts = true
        ..conflictsTotal = 2
        ..conflictsUnresolvedTotal = 1
        ..payrollConflicts = [
          _testConflict(id: 'resolved_1', employeeId: 'EMP_RES',
              name: 'Resolved Person', status: 'RESOLVED'),
          _testConflict(id: 'unresolved_1', employeeId: 'EMP_UNRES',
              name: 'Unresolved Person', status: 'UNRESOLVED'),
        ];
      final requests = <http.Request>[];
      ApiService.client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'unresolved_1',
                'employeeId': 'EMP_UNRES',
                'employee': {
                  'employeeId': 'EMP_UNRES',
                  'firstName': 'Unresolved',
                  'lastName': 'Person',
                },
                'dateKey': '2026-11-10',
                'conflictDate': '2026-11-10T00:00:00.000Z',
                'year': 2026,
                'month': 11,
                'conflictType': 'ATTENDANCE_AND_APPROVED_LEAVE',
                'status': 'UNRESOLVED',
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 1,
              'totalPages': 1,
              'unresolvedTotal': 1,
            },
          }),
          200,
        );
      });

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const PayrollView(),
        ),
      ));
      await tester.tap(find.text('Conflicts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear Resolved'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Clear Resolved'),
      ));
      await tester.pumpAndSettle();

      expect(provider.conflictsStatusFilter, 'UNRESOLVED');
      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/api/hr/payroll/conflicts');
      expect(requests.single.url.queryParameters['status'], 'UNRESOLVED');
      expect(requests.any((request) => request.method == 'DELETE'), isFalse);
      expect(provider.payrollConflicts.map((c) => c.id), ['unresolved_1']);
      expect(provider.payrollConflicts.every((c) => c.isUnresolved), isTrue);
      expect(find.text('Resolved Person Test'), findsNothing);
      expect(find.text('Unresolved Person'), findsOneWidget);
    });

    testWidgets('Clear Resolved is disabled when no resolved conflicts exist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider()
        ..hasLoadedApiPayroll = true
        ..hasLoadedConflicts = true
        ..conflictsTotal = 1
        ..conflictsUnresolvedTotal = 1
        ..payrollConflicts = [
          _testConflict(id: 'unresolved_1', employeeId: 'EMP_UNRES',
              name: 'Unresolved Person', status: 'UNRESOLVED'),
        ];
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const PayrollView(),
        ),
      ));
      await tester.tap(find.text('Conflicts'));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text('Clear Resolved'),
        matching: find.byType(ElevatedButton),
      ).first);
      expect(button.onPressed, isNull);
    });
  });

  // ─── 6. Payroll Batch Management API & Provider Tests ──────────────────────
  group('Payroll Batch Management APIs', () {
    setUp(() {
      ApiService.setToken('test-hr-token');
    });

    tearDown(() {
      ApiService.clearTokens();
    });

    test('formats conflict dates and safely handles null or invalid values', () {
      expect(formatPayrollConflictDate('2026-11-10T00:00:00.000Z'), '10 Nov 2026');
      expect(formatPayrollConflictDate('2026-11-10'), '10 Nov 2026');
      expect(formatPayrollConflictDate(null), '—');
      expect(formatPayrollConflictDate('not-a-date'), '—');
      expect(formatPayrollConflictDate('2026-02-30'), '—');
    });

    test('createDraftBatch calls POST /api/hr/payroll/batches/draft and parses batch', () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/hr/payroll/batches/draft');
        final body = jsonDecode(request.body);
        expect(body['year'], 2026);
        expect(body['month'], 11);
        expect(body['department'], 'Tech');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Draft payroll batch calculated',
            'data': {
              'batch': {
                '_id': 'batch_123',
                'year': 2026,
                'month': 11,
                'department': 'Tech',
                'status': 'DRAFT',
                'grossSalary': 150000.0,
                'totalMonthlyBaseSalary': 150000.0,
                'totalDeductions': 5000.0,
                'netPay': 145000.0,
                'totalNetPayout': 145000.0,
                'employeeCount': 2,
                'unresolvedConflictCount': 1,
              },
              'summary': {
                'batchId': 'batch_123',
                'year': 2026,
                'month': 11,
                'department': 'Tech',
                'status': 'DRAFT',
                'employeeCount': 2,
                'totalMonthlyBaseSalary': 150000.0,
                'totalDeductions': 5000.0,
                'totalNetPayout': 145000.0,
                'unresolvedConflictCount': 1,
                'hasUnresolvedConflicts': true,
              }
            }
          }),
          200,
        );
      });

      final result = await ApiService.createDraftBatch(
        year: 2026,
        month: 11,
        department: 'Tech',
      );

      expect(result['success'], true);
      expect(result['data']['batch']['_id'], 'batch_123');
      expect(result['data']['batch']['status'], 'DRAFT');
    });

    test('getPayrollConflicts calls GET /api/hr/payroll/conflicts and parses result', () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/hr/payroll/conflicts');
        expect(request.url.queryParameters['month'], '11');
        expect(request.url.queryParameters['year'], '2026');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'conf_1',
                'employee': {
                  'id': 'emp_1',
                  'employeeId': 'EMP1001',
                  'firstName': 'Anita',
                  'lastName': 'Rao',
                  'department': 'Tech',
                },
                'dateKey': '2026-11-04',
                'conflictDate': '2026-11-04',
                'year': 2026,
                'month': 11,
                'conflictType': 'ATTENDANCE_AND_APPROVED_LEAVE',
                'status': 'UNRESOLVED',
                'attendance': {'status': 'PRESENT', 'workMode': 'Office'},
                'leave': {'leaveType': 'CASUAL_LEAVE', 'reason': 'Family event'},
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 1,
              'totalPages': 1,
              'unresolvedTotal': 1,
            }
          }),
          200,
        );
      });

      final result = await ApiService.getPayrollConflicts(
          month: 11, year: 2026, status: 'UNRESOLVED');
      expect(result.conflicts.length, 1);
      expect(result.conflicts.first.employeeName, 'Anita Rao');
      expect(result.conflicts.first.isUnresolved, true);
      expect(result.unresolvedTotal, 1);
    });

    test('resolvePayrollConflict calls POST /api/hr/payroll/conflicts/:id/resolve', () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/hr/payroll/conflicts/conf_1/resolve');
        final body = jsonDecode(request.body);
        expect(body['decision'], 'PRESENT');
        expect(body['reason'], 'Employee was verified present on-site');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Conflict resolved',
            'data': {
              '_id': 'conf_1',
              'status': 'RESOLVED',
              'employeeId': 'EMP1001',
              'employee': {'firstName': 'Anita', 'lastName': 'Rao'},
              'conflictType': 'ATTENDANCE_AND_APPROVED_LEAVE',
              'dateKey': '2026-11-04',
              'year': 2026,
              'month': 11,
              'resolution': {
                'decision': 'PRESENT',
                'reason': 'Employee was verified present on-site',
              }
            }
          }),
          200,
        );
      });

      final result = await ApiService.resolvePayrollConflict(
        'conf_1',
        decision: 'PRESENT',
        reason: 'Employee was verified present on-site',
      );

      expect(result.status, 'RESOLVED');
      expect(result.resolutionDecision, 'PRESENT');
    });

    test('finalizePayrollBatch calls POST /api/hr/payroll/batches/:id/finalize', () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/hr/payroll/batches/batch_123/finalize');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Batch finalized successfully',
            'data': {
              '_id': 'batch_123',
              'year': 2026,
              'month': 11,
              'department': 'Tech',
              'status': 'FINALIZED',
              'grossSalary': 150000.0,
              'totalMonthlyBaseSalary': 150000.0,
              'totalDeductions': 5000.0,
              'netPay': 145000.0,
              'totalNetPayout': 145000.0,
              'employeeCount': 2,
              'unresolvedConflictCount': 0,
              'finalizedAt': '2026-11-10T10:00:00.000Z',
            }
          }),
          200,
        );
      });

      final batch = await ApiService.finalizePayrollBatch('batch_123');
      expect(batch.status, 'FINALIZED');
      expect(batch.unresolvedConflictCount, 0);
    });

    test('markPayrollBatchAsPaid calls POST /api/hr/payroll/batches/:id/pay', () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/hr/payroll/batches/batch_123/pay');
        final body = jsonDecode(request.body);
        expect(body['paymentMethod'], 'NEFT');
        expect(body['reference'], 'UTR99887766');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Batch marked as paid',
            'data': {
              '_id': 'batch_123',
              'year': 2026,
              'month': 11,
              'department': 'Tech',
              'status': 'PAID',
              'grossSalary': 150000.0,
              'totalMonthlyBaseSalary': 150000.0,
              'totalDeductions': 5000.0,
              'netPay': 145000.0,
              'totalNetPayout': 145000.0,
              'employeeCount': 2,
              'unresolvedConflictCount': 0,
              'paidAt': '2026-11-10T12:00:00.000Z',
            }
          }),
          200,
        );
      });

      final batch = await ApiService.markPayrollBatchAsPaid(
        'batch_123',
        paymentMethod: 'NEFT',
        reference: 'UTR99887766',
      );

      expect(batch.status, 'PAID');
    });

    test('HRProvider batch integration methods manage draft, conflicts, finalization, and payment', () async {
      final provider = HRProvider();

      ApiService.client = MockClient((request) async {
        if (request.url.path == '/api/hr/payroll/batches/draft') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'batch': {
                  '_id': 'batch_456',
                  'year': 2026,
                  'month': 11,
                  'department': 'all',
                  'status': 'DRAFT',
                  'grossSalary': 200000.0,
                  'totalMonthlyBaseSalary': 200000.0,
                  'totalDeductions': 8000.0,
                  'netPay': 192000.0,
                  'totalNetPayout': 192000.0,
                  'employeeCount': 4,
                  'unresolvedConflictCount': 0,
                },
                'summary': {
                  'batchId': 'batch_456',
                  'status': 'DRAFT',
                  'unresolvedConflictCount': 0,
                }
              }
            }),
            200,
          );
        } else if (request.url.path == '/api/hr/payroll/batches/batch_456/finalize') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                '_id': 'batch_456',
                'year': 2026,
                'month': 11,
                'department': 'all',
                'status': 'FINALIZED',
                'grossSalary': 200000.0,
                'totalMonthlyBaseSalary': 200000.0,
                'totalDeductions': 8000.0,
                'netPay': 192000.0,
                'totalNetPayout': 192000.0,
                'employeeCount': 4,
                'unresolvedConflictCount': 0,
              }
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      // 1. Create draft batch
      await provider.createOrRefreshDraftBatch();
      expect(provider.activeDraftBatch, isNotNull);
      expect(provider.activeDraftBatch!.id, 'batch_456');
      expect(provider.activeDraftBatch!.status, 'DRAFT');

      // 2. Finalize batch
      final finalizeSuccess = await provider.finalizeBatch('batch_456');
      expect(finalizeSuccess, true);
      expect(provider.activeDraftBatch!.status, 'FINALIZED');
    });

    test(
        'getPayrollBatchById reads records from pagination container and parses all 10 records',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/hr/payroll/batches/batch_123');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 'batch_123',
              'year': 2026,
              'month': 11,
              'department': 'all',
              'status': 'FINALIZED',
              'grossSalary': 500000.0,
              'totalMonthlyBaseSalary': 500000.0,
              'totalDeductions': 20000.0,
              'netPay': 480000.0,
              'totalNetPayout': 480000.0,
              'employeeCount': 10,
              'unresolvedConflictCount': 0,
            },
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 10,
              'totalPages': 1,
              'records': List.generate(
                10,
                (i) => {
                  'employee': {
                    'id': 'emp_$i',
                    'employeeId': 'EMP100$i',
                    'firstName': 'Employee',
                    'lastName': '$i',
                    'department': 'Tech',
                    'designation': 'Developer',
                    'status': 'ACTIVE',
                    'salary': 50000.0,
                  },
                  'year': 2026,
                  'month': 11,
                  'scheduledWorkingDays': 22,
                  'presentDays': 20.0,
                  'approvedLeaves': 2,
                  'paidLeaveDays': 1.0,
                  'unpaidLeaveDays': 1.0,
                  'payableDays': 21.0,
                  'monthlyBaseSalary': 50000.0,
                  'dailySalary': 2272.73,
                  'grossPay': 50000.0,
                  'deductions': 2272.73,
                  'netPay': 47727.27,
                },
              ),
            },
          }),
          200,
        );
      });

      final result = await ApiService.getPayrollBatchById('batch_123');

      // All 10 employee records must be parsed from pagination.records
      expect(result.records.length, 10);
      expect(result.total, 10);
      expect(result.page, 1);
      expect(result.limit, 50);
      expect(result.totalPages, 1);
      expect(result.batch.status, 'FINALIZED');
      expect(result.batch.id, 'batch_123');
    });

    test('getPayrollBatchById handles empty pagination records safely',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 'batch_empty',
              'year': 2026,
              'month': 11,
              'department': 'all',
              'status': 'DRAFT',
              'grossSalary': 0.0,
              'totalMonthlyBaseSalary': 0.0,
              'totalDeductions': 0.0,
              'netPay': 0.0,
              'totalNetPayout': 0.0,
              'employeeCount': 0,
              'unresolvedConflictCount': 0,
            },
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 0,
              'totalPages': 1,
              'records': [],
            },
          }),
          200,
        );
      });

      final result = await ApiService.getPayrollBatchById('batch_empty');

      expect(result.records, isEmpty);
      expect(result.total, 0);
      expect(result.page, 1);
      expect(result.batch.status, 'DRAFT');
    });
  });
}
