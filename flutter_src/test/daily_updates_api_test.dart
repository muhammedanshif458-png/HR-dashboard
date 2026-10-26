import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/features/tasks/tasks_view.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  Map<String, dynamic> envelope(List<Map<String, dynamic>> updates,
          {int page = 1, int limit = 20, int? total}) =>
      {
        'success': true,
        'message': 'Daily work updates retrieved successfully',
        'data': updates,
        'pagination': {
          'page': page,
          'limit': limit,
          'total': total ?? updates.length,
          'totalPages':
              ((total ?? updates.length) / limit).ceil().clamp(1, 999),
        },
      };

  Map<String, dynamic> update({
    required String id,
    required String employeeId,
    required String employeeName,
    required String department,
    required String title,
    required String text,
  }) =>
      {
        'id': id,
        'staffId': 'mongo_$employeeId',
        'employeeId': employeeId,
        'employeeName': employeeName,
        'department': department,
        'title': title,
        'date': '2026-10-23',
        'updateText': text,
        'createdAt': '2026-10-23T11:30:00.000Z',
      };

  test('fetches HR daily updates with auth, filters, schema, and pagination',
      () async {
    ApiService.setToken('hr-jwt');
    http.Request? captured;
    ApiService.client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(envelope([
          update(
            id: 'upd-1',
            employeeId: 'EMP1001',
            employeeName: 'Anita Rao',
            department: 'Tech',
            title: 'calling',
            text: '49 call complete',
          ),
          update(
            id: 'upd-2',
            employeeId: 'EMP1002',
            employeeName: 'Vikram Singh',
            department: 'Tech',
            title: 'Follow up',
            text: 'Reached customers',
          ),
        ], page: 2, limit: 1, total: 2)),
        200,
      );
    });

    final result = await ApiService.getDailyUpdatesPage(
      page: 2,
      limit: 1,
      department: 'Tech',
      employeeId: 'emp-mongo-1',
    );

    expect(captured!.url.path, '/api/hr/daily-updates');
    expect(captured!.headers['authorization'], 'Bearer hr-jwt');
    expect(captured!.url.queryParameters, {
      'page': '2',
      'limit': '1',
      'department': 'Tech',
      'employeeId': 'emp-mongo-1',
    });
    expect(result.page, 2);
    expect(result.total, 2);
    expect(result.updates, hasLength(2));
    expect(result.updates.first.title, 'calling');
    expect(result.updates.first.updateText, '49 call complete');
    expect(result.updates.first.employeeName, 'Anita Rao');
    expect(result.updates.first.employeeId, 'EMP1001');
    expect(result.updates.first.department, 'Tech');
    expect(result.updates.first.createdAt, isNotNull);
  });

  test('parses populated employee shape and accepts empty results', () async {
    ApiService.client = MockClient((_) async => http.Response(
          jsonEncode(envelope([
            {
              '_id': 'upd-populated',
              'employee': {
                '_id': 'emp-mongo',
                'employeeId': 'EMP9',
                'firstName': 'Sam',
                'lastName': 'Staff',
                'department': 'Telecalling',
              },
              'date': '2026-10-20',
              'updateText': 'Calls finished',
            }
          ])),
          200,
        ));
    final populated = await ApiService.getDailyUpdatesPage();
    expect(populated.updates.single.employeeName, 'Sam Staff');
    expect(populated.updates.single.staffId, 'emp-mongo');
    expect(populated.updates.single.employeeId, 'EMP9');

    ApiService.client = MockClient((_) async => http.Response(
          jsonEncode(envelope([])),
          200,
        ));
    expect((await ApiService.getDailyUpdatesPage()).updates, isEmpty);
  });

  test('provider refresh replaces records and exposes API errors', () async {
    var calls = 0;
    ApiService.setToken('hr-jwt');
    ApiService.client = MockClient((_) async {
      calls++;
      return http.Response(
        jsonEncode(envelope([
          update(
            id: 'upd-$calls',
            employeeId: 'EMP1',
            employeeName: 'A Staff',
            department: 'Tech',
            title: 'calling',
            text: '49 call complete',
          )
        ])),
        200,
      );
    });
    final provider = HRProvider();
    await provider.loadDailyUpdates();
    expect(provider.apiDailyUpdatesList.single.id, 'upd-1');
    await provider.loadDailyUpdates();
    expect(calls, 2);
    expect(provider.apiDailyUpdatesList.single.id, 'upd-2');

    ApiService.client = MockClient((_) async => http.Response(
          jsonEncode({'success': false, 'message': 'HR access denied'}),
          403,
        ));
    await provider.loadDailyUpdates();
    expect(provider.dailyUpdatesError, contains('HR access denied'));
    expect(provider.isDailyUpdatesLoading, isFalse);
  });

  test('provider department filters on server and searches title locally',
      () async {
    ApiService.setToken('hr-jwt');
    http.Request? captured;
    ApiService.client = MockClient((request) async {
      captured = request;
      return http.Response(
          jsonEncode(envelope([
            update(
              id: 'upd-v',
              employeeId: 'EMP2',
              employeeName: 'Vikram Singh',
              department: 'Tech',
              title: 'calling',
              text: '49 call complete',
            ),
            update(
              id: 'upd-a',
              employeeId: 'EMP3',
              employeeName: 'Anita Rao',
              department: 'Tech',
              title: 'Customer follow up',
              text: 'Reached customers',
            ),
          ])),
          200);
    });
    final provider = HRProvider();
    provider.dailyUpdatesDeptFilter = 'Tech';
    await provider.loadDailyUpdates();
    expect(captured!.url.queryParameters['department'], 'Tech');
    expect(captured!.url.queryParameters.containsKey('search'), isFalse);
    expect(provider.filteredDailyUpdates, hasLength(2));
    provider.setDailyUpdatesSearch('calling');
    expect(provider.filteredDailyUpdates, hasLength(1));
    expect(provider.filteredDailyUpdates.single.employeeName, 'Vikram Singh');
  });

  test('employee daily updates are requested and constrained to selected ID',
      () async {
    ApiService.setToken('hr-jwt');
    http.Request? captured;
    ApiService.client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(envelope([
          update(
            id: 'selected',
            employeeId: 'emp-selected',
            employeeName: 'Selected Staff',
            department: 'Tech',
            title: 'Daily report',
            text: 'Selected update',
          ),
          update(
            id: 'other',
            employeeId: 'emp-other',
            employeeName: 'Other Staff',
            department: 'Tech',
            title: 'Other report',
            text: 'Must not be displayed',
          ),
        ])),
        200,
      );
    });

    final provider = HRProvider();
    await provider.loadEmployeeDailyUpdates('emp-selected');
    expect(captured!.url.path, '/api/hr/daily-updates');
    expect(captured!.url.queryParameters['employeeId'], 'emp-selected');
    expect(captured!.headers['authorization'], 'Bearer hr-jwt');
    expect(provider.employeeDailyUpdates, hasLength(1));
    expect(provider.employeeDailyUpdates.single.id, 'selected');
    expect(provider.employeeDailyUpdatesStaffId, 'emp-selected');
  });

  testWidgets('HR screen loads and refreshes the latest submitted update',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    var calls = 0;
    ApiService.setToken('hr-jwt');
    ApiService.client = MockClient((_) async {
      calls++;
      return http.Response(
        jsonEncode(envelope([
          update(
            id: 'upd-$calls',
            employeeId: 'EMP1001',
            employeeName: 'Anita Rao',
            department: 'Tech',
            title: calls == 1 ? 'calling' : 'calling refreshed',
            text: '49 call complete',
          )
        ])),
        200,
      );
    });
    final provider = HRProvider();
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<HRProvider>.value(
        value: provider,
        child: const TasksView(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('calling'), findsOneWidget);
    expect(find.text('49 call complete'), findsOneWidget);
    expect(find.text('Anita Rao'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh Updates'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('calling refreshed'), findsOneWidget);
  });
}
