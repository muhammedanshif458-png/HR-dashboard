import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/leaves/leave_management_view.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  // ─── 1. ApiService.getLeavesPage ───────────────────────────────────────────
  group('ApiService.getLeavesPage', () {
    test('calls GET /api/hr/leaves with auth token, pagination, and filters',
        () async {
      String? authHeader;
      String? requestedPath;
      Map<String, String>? queryParams;

      ApiService.setToken('test_jwt_leave_token');
      ApiService.client = MockClient((request) async {
        authHeader = request.headers['Authorization'];
        requestedPath = request.url.path;
        queryParams = request.url.queryParameters;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Leave requests fetched successfully',
            'data': [
              {
                '_id': 'leave_101',
                'employee': {
                  '_id': 'emp_101',
                  'employeeId': 'EMP1001',
                  'firstName': 'Anita',
                  'lastName': 'Rao',
                  'department': 'Tech',
                  'designation': 'Lead HR Manager',
                  'email': 'anita.rao@lysoftware.com'
                },
                'leaveType': 'CASUAL',
                'startDate': '2026-10-20T00:00:00.000Z',
                'endDate': '2026-10-22T00:00:00.000Z',
                'reason': 'Family emergency',
                'status': 'PENDING',
                'hasMedicalProof': false,
              },
              {
                '_id': 'leave_102',
                'employee': {
                  '_id': 'emp_102',
                  'employeeId': 'EMP1002',
                  'firstName': 'Arjun',
                  'lastName': 'Desai',
                  'department': 'Tech',
                  'designation': 'Senior Frontend Engineer',
                  'email': 'arjun.desai@lysoftware.com'
                },
                'leaveType': 'SICK',
                'startDate': '2026-10-18T00:00:00.000Z',
                'endDate': '2026-10-19T00:00:00.000Z',
                'reason': 'Viral fever recovery',
                'status': 'APPROVED',
                'hasMedicalProof': true,
                'medicalProofUrl': '/uploads/medical/leave_102.pdf',
                'approvedBy': {
                  '_id': 'adm_01',
                  'firstName': 'Admin',
                  'lastName': 'User',
                  'email': 'admin@lysoftware.com'
                },
                'approvedAt': '2026-10-17T10:00:00.000Z'
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 2,
              'totalPages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.getLeavesPage(
        page: 1,
        limit: 20,
        status: 'PENDING',
        leaveType: 'CASUAL',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        employeeId: 'EMP1001',
      );

      expect(authHeader, 'Bearer test_jwt_leave_token');
      expect(requestedPath, '/api/hr/leaves');
      expect(queryParams?['page'], '1');
      expect(queryParams?['limit'], '20');
      expect(queryParams?['status'], 'PENDING');
      expect(queryParams?['leaveType'], 'CASUAL');
      expect(queryParams?['startDate'], '2026-10-01');
      expect(queryParams?['endDate'], '2026-10-31');
      expect(queryParams?['employeeId'], 'EMP1001');

      expect(result.leaves.length, 2);
      expect(result.page, 1);
      expect(result.total, 2);
      expect(result.totalPages, 1);

      final first = result.leaves[0];
      expect(first.id, 'leave_101');
      expect(first.staffId, 'EMP1001');
      expect(first.employeeName, 'Anita Rao');
      expect(first.leaveType, 'Casual');
      expect(first.status, 'Pending');
      expect(first.calculatedDays, 3);

      final second = result.leaves[1];
      expect(second.id, 'leave_102');
      expect(second.leaveType, 'Sick Leave');
      expect(second.status, 'Approved');
      expect(second.approvedBy, 'Admin User');
      expect(second.hasMedicalProof, true);
    });

    test('throws typed Exception on 401 unauthorized', () async {
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
        () => ApiService.getLeavesPage(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Unauthorized access: Invalid or expired token'))),
      );
    });

    test('throws FormatException on malformed server payload', () async {
      ApiService.client = MockClient((request) async {
        return http.Response('Internal Server Error HTML', 500);
      });

      expect(
        () => ApiService.getLeavesPage(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── 2. ApiService.getLeaveDetails ─────────────────────────────────────────
  group('ApiService.getLeaveDetails', () {
    test('fetches single leave details successfully', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/leaves/60d5ecb8b5c9c82b88f11111');
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Leave request fetched successfully',
            'data': {
              '_id': '60d5ecb8b5c9c82b88f11111',
              'employee': {
                '_id': 'emp_201',
                'employeeId': 'EMP1005',
                'firstName': 'Priya',
                'lastName': 'Sharma',
                'department': 'Telecalling',
                'designation': 'Senior Telecaller',
                'email': 'priya.sharma@lysoftware.com'
              },
              'leaveType': 'ANNUAL',
              'startDate': '2026-11-01T00:00:00.000Z',
              'endDate': '2026-11-05T00:00:00.000Z',
              'reason': 'Annual vacation',
              'status': 'PENDING',
              'hasMedicalProof': false,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final detail =
          await ApiService.getLeaveDetails('60d5ecb8b5c9c82b88f11111');
      expect(detail, isNotNull);
      expect(detail!.id, '60d5ecb8b5c9c82b88f11111');
      expect(detail.employeeName, 'Priya Sharma');
      expect(detail.department, 'Telecalling');
      expect(detail.leaveType, 'Earned');
      expect(detail.status, 'Pending');
      expect(detail.calculatedDays, 5);
    });

    test('returns null when leave is not found (404)', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Leave request not found',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final detail =
          await ApiService.getLeaveDetails('60d5ecb8b5c9c82b88f99999');
      expect(detail, isNull);
    });
  });

  // ─── 3. ApiService Mutations: approve & reject ─────────────────────────────
  group('ApiService Mutations (approve & reject)', () {
    test(
        'approveLeaveRequest sends PUT /api/hr/leaves/:id/approve and parses confirmed result',
        () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path,
            '/api/hr/leaves/60d5ecb8b5c9c82b88f11111/approve');
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Leave request approved successfully',
            'data': {
              '_id': '60d5ecb8b5c9c82b88f11111',
              'employee': {
                'employeeId': 'EMP1005',
                'firstName': 'Priya',
                'lastName': 'Sharma',
                'department': 'Telecalling'
              },
              'leaveType': 'CASUAL',
              'startDate': '2026-11-01T00:00:00.000Z',
              'endDate': '2026-11-02T00:00:00.000Z',
              'status': 'APPROVED',
              'approvedBy': {
                'firstName': 'System',
                'lastName': 'Admin',
              },
              'approvedAt': '2026-10-15T12:00:00.000Z'
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final updated =
          await ApiService.approveLeaveRequest('60d5ecb8b5c9c82b88f11111');
      expect(updated.status, 'Approved');
      expect(updated.approvedBy, 'System Admin');
    });

    test('approveLeaveRequest throws on 400 when status is not PENDING',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Cannot approve leave request with status: APPROVED',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.approveLeaveRequest('60d5ecb8b5c9c82b88f11111'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Cannot approve leave request with status: APPROVED'))),
      );
    });

    test(
        'rejectLeaveRequest sends PUT /api/hr/leaves/:id/reject with reason body',
        () async {
      Map<String, dynamic>? requestBody;

      ApiService.client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(
            request.url.path, '/api/hr/leaves/60d5ecb8b5c9c82b88f11111/reject');
        requestBody = jsonDecode(request.body);

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Leave request rejected successfully',
            'data': {
              '_id': '60d5ecb8b5c9c82b88f11111',
              'employee': {
                'employeeId': 'EMP1005',
                'firstName': 'Priya',
                'lastName': 'Sharma',
                'department': 'Telecalling'
              },
              'leaveType': 'CASUAL',
              'startDate': '2026-11-01T00:00:00.000Z',
              'endDate': '2026-11-02T00:00:00.000Z',
              'status': 'REJECTED',
              'rejectionReason': 'Department coverage constraint',
              'approvedBy': 'HR Admin',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final updated = await ApiService.rejectLeaveRequest(
          '60d5ecb8b5c9c82b88f11111', 'Department coverage constraint');

      expect(requestBody?['rejectionReason'], 'Department coverage constraint');
      expect(updated.status, 'Rejected');
      expect(updated.rejectionReason, 'Department coverage constraint');
    });
  });

  // ─── 4. Model Parsing & Normalization ──────────────────────────────────────
  group('LeaveRequest Model Parsing', () {
    test('parses types and statuses with full normalization', () {
      final json = {
        '_id': 'leave_abc',
        'employee': {
          'employeeId': 'EMP2001',
          'firstName': 'Rahul',
          'lastName': 'Verma',
          'department': 'Telecalling',
          'email': 'rahul@ly.com'
        },
        'leaveType': 'UNPAID',
        'startDate': '2026-10-05T00:00:00.000Z',
        'endDate': '2026-10-07T00:00:00.000Z',
        'reason': 'Personal work',
        'status': 'CANCELLED',
      };

      final leave = LeaveRequest.fromJson(json);
      expect(leave.id, 'leave_abc');
      expect(leave.staffId, 'EMP2001');
      expect(leave.employeeName, 'Rahul Verma');
      expect(leave.department, 'Telecalling');
      expect(leave.leaveType, 'Unpaid');
      expect(leave.status, 'Cancelled');
      expect(leave.calculatedDays, 3);
    });

    test('normalizes SICK and SICK_LEAVE to Sick Leave with isSick=true and isMedical=false', () {
      final json1 = {
        '_id': 'sick_1',
        'leaveType': 'SICK',
        'startDate': '2026-11-01',
        'endDate': '2026-11-02',
        'reason': 'Fever and cold',
      };
      final leave1 = LeaveRequest.fromJson(json1);
      expect(leave1.leaveType, 'Sick Leave');
      expect(leave1.isSick, true);
      expect(leave1.isMedical, false);
      expect(leave1.hasMedicalProof, false);

      final json2 = {
        '_id': 'sick_2',
        'leaveType': 'SICK_LEAVE',
        'startDate': '2026-11-01',
        'endDate': '2026-11-02',
        'reason': 'Fever and cold',
        'hasMedicalProof': true,
      };
      final leave2 = LeaveRequest.fromJson(json2);
      expect(leave2.leaveType, 'Sick Leave');
      expect(leave2.isSick, true);
      expect(leave2.isMedical, false);
      expect(leave2.hasMedicalProof, true);
    });

    test('normalizes MEDICAL and MEDICAL_LEAVE to Medical Leave with isMedical=true and isSick=false', () {
      final json1 = {
        '_id': 'med_1',
        'leaveType': 'MEDICAL',
        'startDate': '2026-11-01',
        'endDate': '2026-11-05',
        'reason': 'Surgery',
      };
      final leave1 = LeaveRequest.fromJson(json1);
      expect(leave1.leaveType, 'Medical Leave');
      expect(leave1.isMedical, true);
      expect(leave1.isSick, false);

      final json2 = {
        '_id': 'med_2',
        'leaveType': 'MEDICAL_LEAVE',
        'startDate': '2026-11-01',
        'endDate': '2026-11-05',
        'reason': 'Hospital admission',
      };
      final leave2 = LeaveRequest.fromJson(json2);
      expect(leave2.leaveType, 'Medical Leave');
      expect(leave2.isMedical, true);
      expect(leave2.isSick, false);
    });

    test('does not silently convert unknown leave types to Medical Leave', () {
      final json = {
        '_id': 'custom_1',
        'leaveType': 'BEREAVEMENT',
        'startDate': '2026-11-01',
        'endDate': '2026-11-03',
        'reason': 'Family emergency',
      };
      final leave = LeaveRequest.fromJson(json);
      expect(leave.leaveType, 'BEREAVEMENT');
      expect(leave.isMedical, false);
      expect(leave.isSick, false);
    });

    test('formatLeaveDate formats UTC ISO timestamps and midnight dates without timezone day shift', () {
      // 1. UTC timestamp at midnight
      expect(LeaveRequest.formatLeaveDate('2026-11-09T00:00:00.000Z'), '09 Nov 2026');
      expect(LeaveRequest.formatLeaveDate('2026-11-10T00:00:00.000Z'), '10 Nov 2026');

      // 2. UTC timestamp at end of day (23:59:59)
      expect(LeaveRequest.formatLeaveDate('2026-11-09T23:59:59.999Z'), '09 Nov 2026');

      // 3. Plain date-only string YYYY-MM-DD
      expect(LeaveRequest.formatLeaveDate('2026-11-09'), '09 Nov 2026');
      expect(LeaveRequest.formatLeaveDate('2026-01-05'), '05 Jan 2026');

      // 4. Null, empty, and whitespace
      expect(LeaveRequest.formatLeaveDate(null), '—');
      expect(LeaveRequest.formatLeaveDate(''), '—');
      expect(LeaveRequest.formatLeaveDate('   '), '—');

      // 5. Invalid string returns safe fallback
      expect(LeaveRequest.formatLeaveDate('not-a-date'), 'not-a-date');
    });

    test('formattedDateRange handles single-day and multi-day leaves accurately', () {
      final singleDay = LeaveRequest(
        id: 'single_1',
        staffId: 'EMP1',
        fromDate: '2026-11-09T00:00:00.000Z',
        toDate: '2026-11-09T00:00:00.000Z',
        reason: 'Personal',
        status: 'Pending',
      );
      expect(singleDay.formattedFromDate, '09 Nov 2026');
      expect(singleDay.formattedToDate, '09 Nov 2026');
      expect(singleDay.formattedDateRange, '09 Nov 2026');

      final multiDay = LeaveRequest(
        id: 'multi_1',
        staffId: 'EMP2',
        fromDate: '2026-11-09T00:00:00.000Z',
        toDate: '2026-11-10T00:00:00.000Z',
        reason: 'Family event',
        status: 'Pending',
      );
      expect(multiDay.formattedFromDate, '09 Nov 2026');
      expect(multiDay.formattedToDate, '10 Nov 2026');
      expect(multiDay.formattedDateRange, '09 Nov 2026  ➔  10 Nov 2026');
    });
  });

  // ─── 5. HRProvider Leave Management State & Refresh ────────────────────────
  group('HRProvider Leave Management Integration', () {
    test(
        'loadLeaves transitions loading, populates records, and enables live mode',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Fetched',
            'data': [
              {
                '_id': 'live_1',
                'employee': {
                  'employeeId': 'EMP1001',
                  'firstName': 'Anita',
                  'lastName': 'Rao',
                  'department': 'Tech'
                },
                'leaveType': 'CASUAL',
                'startDate': '2026-10-15',
                'endDate': '2026-10-16',
                'reason': 'Doctor visit',
                'status': 'PENDING',
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 1,
              'totalPages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();
      expect(provider.hasLoadedApiLeaves, false);
      expect(provider.isLeavesLoading, false);

      await provider.loadLeaves();

      expect(provider.hasLoadedApiLeaves, true);
      expect(provider.isLeavesLoading, false);
      expect(provider.leavesError, isNull);
      expect(provider.filteredLeaveRequests.length, 1);
      expect(provider.filteredLeaveRequests.first.id, 'live_1');
      expect(provider.pendingLeavesCount, 1);
    });

    test(
        'loadLeaves surfaces error and does NOT silently show mock data on failure',
        () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Database connection error',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();
      await provider.loadLeaves();

      expect(provider.hasLoadedApiLeaves, false);
      expect(provider.isLeavesLoading, false);
      expect(provider.leavesError, contains('Database connection error'));
      // Never silently display mock data when an API fails
      expect(provider.filteredLeaveRequests, isEmpty);
    });

    test(
        'approveLeave in live mode refreshes from server and confirms updated status',
        () async {
      int getCalls = 0;

      ApiService.client = MockClient((request) async {
        if (request.method == 'GET') {
          getCalls++;
          final status = getCalls == 1 ? 'PENDING' : 'APPROVED';
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Fetched',
              'data': [
                {
                  '_id': 'live_100',
                  'employee': {
                    'employeeId': 'EMP1001',
                    'firstName': 'Anita',
                    'lastName': 'Rao',
                    'department': 'Tech'
                  },
                  'leaveType': 'CASUAL',
                  'startDate': '2026-10-15',
                  'endDate': '2026-10-16',
                  'reason': 'Personal',
                  'status': status,
                }
              ],
              'pagination': {
                'page': 1,
                'limit': 20,
                'total': 1,
                'totalPages': 1,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'PUT') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Leave approved',
              'data': {
                '_id': 'live_100',
                'employee': {
                  'employeeId': 'EMP1001',
                  'firstName': 'Anita',
                  'lastName': 'Rao',
                  'department': 'Tech'
                },
                'status': 'APPROVED',
                'leaveType': 'CASUAL',
                'startDate': '2026-10-15',
                'endDate': '2026-10-16',
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final provider = HRProvider();
      await provider.loadLeaves();
      expect(provider.filteredLeaveRequests.first.status, 'Pending');

      final success = await provider.approveLeave('live_100');
      expect(success, true);
      expect(getCalls, 2); // initial load + post-mutation refresh
      expect(provider.filteredLeaveRequests.first.status, 'Approved');
      expect(provider.approvedLeavesCount, 1);
      expect(provider.pendingLeavesCount, 0);
    });

    test(
        'approveLeave in live mode fails gracefully without mutating local state',
        () async {
      ApiService.client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Fetched',
              'data': [
                {
                  '_id': 'live_100',
                  'employee': {
                    'employeeId': 'EMP1001',
                    'firstName': 'Anita',
                    'lastName': 'Rao',
                    'department': 'Tech'
                  },
                  'leaveType': 'CASUAL',
                  'startDate': '2026-10-15',
                  'endDate': '2026-10-16',
                  'reason': 'Personal',
                  'status': 'PENDING',
                }
              ],
              'pagination': {
                'page': 1,
                'limit': 20,
                'total': 1,
                'totalPages': 1,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'PUT') {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Unauthorized action: Only HR can approve leaves',
            }),
            403,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final provider = HRProvider();
      await provider.loadLeaves();
      expect(provider.filteredLeaveRequests.first.status, 'Pending');

      final ok = await provider.approveLeave('live_100');
      expect(ok, false);
      expect(provider.leavesError,
          contains('Unauthorized action: Only HR can approve leaves'));
      expect(provider.filteredLeaveRequests.first.status, 'Pending');
    });

    test('filters and pagination update correctly in live mode', () async {
      Map<String, String>? lastQueryParams;

      ApiService.client = MockClient((request) async {
        lastQueryParams = request.url.queryParameters;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Fetched',
            'data': [],
            'pagination': {
              'page': int.parse(lastQueryParams?['page'] ?? '1'),
              'limit': 20,
              'total': 50,
              'totalPages': 3,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();
      await provider.loadLeaves();

      provider.setLeaveStatusFilter('Pending');
      await Future<void>.delayed(Duration.zero);
      expect(lastQueryParams?['status'], 'PENDING');

      provider.setLeaveTypeFilter('Medical');
      await Future<void>.delayed(Duration.zero);
      expect(lastQueryParams?['leaveType'], 'MEDICAL');

      provider.setLeaveTypeFilter('Sick');
      await Future<void>.delayed(Duration.zero);
      expect(lastQueryParams?['leaveType'], 'SICK');

      provider.setLeavesPage(2);
      await Future<void>.delayed(Duration.zero);
      expect(lastQueryParams?['page'], '2');
      expect(provider.leavesPage, 2);
    });
  });

  // ─── 6. LeaveManagementView Widget Rendering ──────────────────────────────
  group('LeaveManagementView Widget Tests', () {
    testWidgets('renders live server active badge when live leaves loaded',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Fetched',
            'data': [
              {
                '_id': 'live_w1',
                'employee': {
                  'employeeId': 'EMP1001',
                  'firstName': 'Anita',
                  'lastName': 'Rao',
                  'department': 'Tech',
                  'designation': 'Lead HR'
                },
                'leaveType': 'CASUAL',
                'startDate': '2026-10-20',
                'endDate': '2026-10-21',
                'reason': 'Personal work',
                'status': 'PENDING',
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 1,
              'totalPages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: LeaveManagementView(),
          ),
        ),
      );

      // Trigger post frame callback
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Live Server Leave Management Active'), findsOneWidget);
      expect(find.text('Anita Rao'), findsOneWidget);
      expect(find.text('Pending Requests'), findsOneWidget);
      expect(find.text('Casual'), findsWidgets);
    });

    testWidgets('renders error container and retry button on load failure',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Gateway timeout connecting to backend',
          }),
          504,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: LeaveManagementView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Failed to load leave records'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets(
        'renders Sick Leave without proof warning and Medical Leave with proof warning and verifies approval/rejection dialogs',
        (tester) async {
      tester.view.physicalSize = const Size(2200, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Fetched',
            'data': [
              {
                '_id': 'sick_test_1',
                'employee': {
                  'employeeId': 'EMP101',
                  'firstName': 'Pooja',
                  'lastName': 'Hegde',
                  'department': 'Tech',
                  'email': 'pooja@ly.com'
                },
                'leaveType': 'SICK',
                'startDate': '2026-11-10',
                'endDate': '2026-11-11',
                'reason': 'Seasonal cold',
                'status': 'PENDING',
                'hasMedicalProof': false,
              },
              {
                '_id': 'med_test_2',
                'employee': {
                  'employeeId': 'EMP102',
                  'firstName': 'Rohan',
                  'lastName': 'Kulkarni',
                  'department': 'Telecalling',
                  'email': 'rohan@ly.com'
                },
                'leaveType': 'MEDICAL',
                'startDate': '2026-11-12',
                'endDate': '2026-11-15',
                'reason': 'Fracture recovery',
                'status': 'PENDING',
                'hasMedicalProof': false,
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 2,
              'totalPages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: LeaveManagementView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // 1. Verify list renders correct normalized leave types
      expect(find.text('Sick Leave'), findsWidgets);
      expect(find.text('Medical Leave'), findsWidgets);

      // 2. Verify Medical Leave has 'No Document' warning badge (exactly 1 because Sick Leave does NOT show it)
      expect(find.text('No Document'), findsOneWidget);

      // 3. Verify Sick Leave row has '—' for proof (since proof is not mandatory)
      expect(find.text('—'), findsWidgets);

      // 4. Tap Approve on Sick Leave row -> check Approval Dialog shows 'Sick Leave'
      final approveButtons = find.widgetWithText(ElevatedButton, 'Approve');
      expect(approveButtons, findsNWidgets(2));
      await tester.tap(approveButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Approve Leave Request'), findsOneWidget);
      expect(find.textContaining('Pooja Hegde\'s Sick Leave request'), findsOneWidget);
      expect(find.text('Confirm Approval'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // 5. Tap Reject on Sick Leave row -> check Rejection Dialog shows 'Sick Leave'
      final rejectButtons = find.widgetWithText(ElevatedButton, 'Reject');
      expect(rejectButtons, findsNWidgets(2));
      await tester.tap(rejectButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Reject Leave Request'), findsOneWidget);
      expect(find.textContaining('Pooja Hegde\'s Sick Leave request'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'verifies Status dropdown is removed while Search, Department, Leave Type, and Date Range filters are preserved',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Fetched',
            'data': [],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 0,
              'totalPages': 0,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: LeaveManagementView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // 1. Verify Status dropdown is NOT present in UI
      expect(find.text('All Statuses'), findsNothing);
      expect(
          find.byWidgetPredicate(
            (w) =>
                w is DropdownButtonFormField<String> &&
                w.decoration.labelText == 'Status',
          ),
          findsNothing);

      // 2. Verify remaining filter controls ARE present in the UI
      expect(find.byType(TextField), findsOneWidget); // Search input
      expect(find.text('Department'), findsOneWidget); // Department dropdown
      expect(find.text('Leave Type'), findsOneWidget); // Leave Type dropdown
      expect(find.text('Date Range'), findsOneWidget); // Date Range button

      // 3. Verify status summary cards are preserved
      expect(find.text('Pending Requests'), findsOneWidget);
      expect(find.text('Approved Leaves'), findsOneWidget);
      expect(find.text('Rejected Leaves'), findsOneWidget);
      expect(find.text('On Leave Today'), findsOneWidget);
    });

    testWidgets(
        'renders clean formatted dates, tooltip for reason, and full reason in details modal',
        (tester) async {
      tester.view.physicalSize = const Size(2200, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const longReason =
          'due to death in family and attending funeral services in home town';
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Fetched',
            'data': [
              {
                '_id': 'leave_format_test',
                'employee': {
                  'employeeId': 'EMP999',
                  'firstName': 'Priyanka',
                  'lastName': 'Chopra',
                  'department': 'Tech',
                  'email': 'priyanka@ly.com'
                },
                'leaveType': 'CASUAL',
                'startDate': '2026-11-09T00:00:00.000Z',
                'endDate': '2026-11-10T00:00:00.000Z',
                'reason': longReason,
                'status': 'PENDING',
              }
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 1,
              'totalPages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = HRProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: LeaveManagementView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // 1. Verify Dates column renders clean formatted dates (not raw ISO 2026-11-09T00:00:00.000Z)
      expect(find.text('09 Nov 2026  ➔  10 Nov 2026'), findsOneWidget);
      expect(find.textContaining('2026-11-09T00:00:00.000Z'), findsNothing);

      // 2. Verify Tooltip wraps the reason cell with the complete reason
      final tooltipFinder = find.byWidgetPredicate(
        (w) => w is Tooltip && w.message == longReason,
      );
      expect(tooltipFinder, findsOneWidget);

      // 3. Tap on the reason cell to open Details Modal
      await tester.tap(tooltipFinder);
      await tester.pumpAndSettle();

      // 4. Verify Details Modal displays Start Date, End Date, and full reason untruncated
      expect(find.text('Leave Request Details'), findsOneWidget);
      expect(find.text('09 Nov 2026'), findsWidgets); // Start Date
      expect(find.text('10 Nov 2026'), findsWidgets); // End Date
      expect(find.text('"$longReason"'), findsOneWidget); // Full reason

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });
}
