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

  Map<String, dynamic> sampleUpdate({
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
        'date': '2026-10-28',
        'updateText': text,
        'createdAt': '2026-10-28T10:00:00.000Z',
      };

  group('ApiService Bulk Delete & Clear All', () {
    test('bulkDeleteDailyUpdates sends DELETE request with ids payload', () async {
      ApiService.setToken('hr-admin-token');
      http.Request? captured;

      ApiService.client = MockClient((request) async {
        captured = request as http.Request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Successfully deleted 2 daily work update(s)',
            'data': {'deletedCount': 2},
          }),
          200,
        );
      });

      final result = await ApiService.bulkDeleteDailyUpdates(['id-1', 'id-2']);

      expect(result, 2);
      expect(captured!.method, 'DELETE');
      expect(captured!.url.path, '/api/hr/daily-updates');
      expect(captured!.headers['authorization'], 'Bearer hr-admin-token');
      expect(captured!.headers['content-type'], contains('application/json'));
      expect(jsonDecode(captured!.body), {
        'ids': ['id-1', 'id-2'],
      });
    });

    test('clearAllDailyUpdates sends DELETE request to /api/hr/daily-updates/all', () async {
      ApiService.setToken('hr-admin-token');
      http.Request? captured;

      ApiService.client = MockClient((request) async {
        captured = request as http.Request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Successfully cleared all 10 daily work update(s)',
            'data': {'deletedCount': 10},
          }),
          200,
        );
      });

      final result = await ApiService.clearAllDailyUpdates();

      expect(result, 10);
      expect(captured!.method, 'DELETE');
      expect(captured!.url.path, '/api/hr/daily-updates/all');
      expect(captured!.headers['authorization'], 'Bearer hr-admin-token');
    });
  });

  group('HRProvider Bulk Delete & Clear All', () {
    test('bulkDeleteDailyUpdates removes deleted items from provider and recalculates totals', () async {
      ApiService.setToken('hr-admin-token');
      ApiService.client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(envelope([
              sampleUpdate(
                id: 'upd-1',
                employeeId: 'EMP1',
                employeeName: 'Alice',
                department: 'Tech',
                title: 'Task 1',
                text: 'Done 1',
              ),
              sampleUpdate(
                id: 'upd-2',
                employeeId: 'EMP2',
                employeeName: 'Bob',
                department: 'Sales',
                title: 'Task 2',
                text: 'Done 2',
              ),
            ], total: 2)),
            200,
          );
        }
        if (request.method == 'DELETE') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Deleted 1 update',
              'data': {'deletedCount': 1},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final provider = HRProvider();
      await provider.loadDailyUpdates();
      expect(provider.apiDailyUpdatesList, hasLength(2));
      expect(provider.dailyUpdatesTotal, 2);

      final success = await provider.bulkDeleteDailyUpdates(['upd-1']);
      expect(success, isTrue);
      expect(provider.apiDailyUpdatesList, hasLength(1));
      expect(provider.apiDailyUpdatesList.single.id, 'upd-2');
      expect(provider.dailyUpdatesTotal, 1);
    });

    test('clearAllDailyUpdates clears all updates in provider and resets count', () async {
      ApiService.setToken('hr-admin-token');
      ApiService.client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(envelope([
              sampleUpdate(
                id: 'upd-1',
                employeeId: 'EMP1',
                employeeName: 'Alice',
                department: 'Tech',
                title: 'Task 1',
                text: 'Done 1',
              ),
            ], total: 1)),
            200,
          );
        }
        if (request.method == 'DELETE') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Cleared all updates',
              'data': {'deletedCount': 1},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final provider = HRProvider();
      await provider.loadDailyUpdates();
      expect(provider.apiDailyUpdatesList, hasLength(1));

      final success = await provider.clearAllDailyUpdates();
      expect(success, isTrue);
      expect(provider.apiDailyUpdatesList, isEmpty);
      expect(provider.dailyUpdatesTotal, 0);
    });
  });

  group('TasksView Bulk Clearing UI', () {
    testWidgets('cards do not contain individual delete icon in normal or selection mode', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.setToken('hr-jwt');
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode(envelope([
            sampleUpdate(
              id: 'upd-1',
              employeeId: 'EMP1',
              employeeName: 'Alice',
              department: 'Tech',
              title: 'First Update',
              text: 'Completed sprint review',
            ),
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

      // Normal mode: no Checkbox on update cards, and NO individual delete icons on card
      expect(find.text('First Update'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      // Enter selection mode
      await tester.tap(find.text('Select Updates'));
      await tester.pumpAndSettle();

      // In selection mode: Checkbox appears, but still NO individual delete icon on card
      expect(find.byType(Checkbox), findsWidgets);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('selection mode toggles, select all / deselect all, and exit mode works', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      ApiService.setToken('hr-jwt');
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode(envelope([
            sampleUpdate(
              id: 'upd-1',
              employeeId: 'EMP1',
              employeeName: 'Alice',
              department: 'Tech',
              title: 'First Update',
              text: 'Description 1',
            ),
            sampleUpdate(
              id: 'upd-2',
              employeeId: 'EMP2',
              employeeName: 'Bob',
              department: 'Sales',
              title: 'Second Update',
              text: 'Description 2',
            ),
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

      expect(find.text('Select Updates'), findsOneWidget);
      expect(find.text('0 of 2 selected'), findsNothing);

      // Tap "Select Updates"
      await tester.tap(find.text('Select Updates'));
      await tester.pumpAndSettle();

      expect(find.text('0 of 2 selected'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);

      // Tap card or checkbox to select upd-1
      await tester.tap(find.text('First Update'));
      await tester.pumpAndSettle();
      expect(find.text('1 of 2 selected'), findsOneWidget);
      expect(find.text('Clear Selected (1)'), findsOneWidget);

      // Tap "Select All"
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2 selected'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);

      // Tap "Deselect All"
      await tester.tap(find.text('Deselect All'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 2 selected'), findsOneWidget);

      // Exit selection mode
      await tester.tap(find.text('Exit Selection Mode'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 2 selected'), findsNothing);
      expect(find.text('Select Updates'), findsOneWidget);
    });

    testWidgets('Clear Selected confirmation dialog and execution', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      var deleteCalls = 0;
      ApiService.setToken('hr-jwt');
      ApiService.client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(envelope(deleteCalls == 0
                ? [
                    sampleUpdate(
                      id: 'upd-1',
                      employeeId: 'EMP1',
                      employeeName: 'Alice',
                      department: 'Tech',
                      title: 'Update 1',
                      text: 'Text 1',
                    ),
                    sampleUpdate(
                      id: 'upd-2',
                      employeeId: 'EMP2',
                      employeeName: 'Bob',
                      department: 'Sales',
                      title: 'Update 2',
                      text: 'Text 2',
                    ),
                  ]
                : [
                    sampleUpdate(
                      id: 'upd-2',
                      employeeId: 'EMP2',
                      employeeName: 'Bob',
                      department: 'Sales',
                      title: 'Update 2',
                      text: 'Text 2',
                    ),
                  ])),
            200,
          );
        }
        if (request.method == 'DELETE') {
          deleteCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Deleted 1 update',
              'data': {'deletedCount': 1},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final provider = HRProvider();
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const TasksView(),
        ),
      ));
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.text('Select Updates'));
      await tester.pumpAndSettle();

      // Select first update
      await tester.tap(find.text('Update 1'));
      await tester.pumpAndSettle();

      // Tap "Clear Selected (1)"
      await tester.tap(find.text('Clear Selected (1)'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Clear Selected Updates?'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to permanently delete 1 selected daily work update'), findsOneWidget);

      // Test cancel button first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(deleteCalls, 0);
      expect(find.text('Clear Selected Updates?'), findsNothing);

      // Re-open and confirm deletion
      await tester.tap(find.text('Clear Selected (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Permanently Delete (1)'));
      await tester.pumpAndSettle();

      expect(deleteCalls, 1);
      // Dialog closed, toast shown, only Update 2 remains
      expect(find.text('Update 1'), findsNothing);
      expect(find.text('Update 2'), findsOneWidget);
    });

    testWidgets('Clear All menu action shows safety warning and requires explicit confirmation', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());

      var clearAllCalls = 0;
      ApiService.setToken('hr-jwt');
      ApiService.client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(envelope(clearAllCalls == 0
                ? [
                    sampleUpdate(
                      id: 'upd-1',
                      employeeId: 'EMP1',
                      employeeName: 'Alice',
                      department: 'Tech',
                      title: 'Update 1',
                      text: 'Text 1',
                    ),
                  ]
                : [])),
            200,
          );
        }
        if (request.method == 'DELETE') {
          clearAllCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Cleared all updates',
              'data': {'deletedCount': 1},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final provider = HRProvider();
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<HRProvider>.value(
          value: provider,
          child: const TasksView(),
        ),
      ));
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();

      // Select Clear All Updates
      await tester.tap(find.text('Clear All Updates'));
      await tester.pumpAndSettle();

      // Verify safety dialog
      expect(find.text('Clear All Daily Updates?'), findsOneWidget);
      expect(find.textContaining('This action will permanently delete all 1 daily work update records.'), findsOneWidget);

      // The button "Permanently Clear All" should be disabled until checkbox is checked
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Permanently Clear All');
      ElevatedButton deleteBtn = tester.widget(deleteBtnFinder);
      expect(deleteBtn.onPressed, isNull);

      // Check the explicit confirmation checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Button should now be enabled
      deleteBtn = tester.widget(deleteBtnFinder);
      expect(deleteBtn.onPressed, isNotNull);

      // Tap confirm
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(clearAllCalls, 1);
      expect(find.text('Clear All Daily Updates?'), findsNothing);
      expect(find.text('No Daily Updates Found'), findsOneWidget);
    });
  });
}

