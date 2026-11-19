import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/models/hr_models.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/features/tasks/tasks_view.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  // ─── 1. ApiService.getTasksPage ────────────────────────────────────────────
  group('ApiService.getTasksPage', () {
    test('calls GET /api/hr/tasks with auth token, pagination, and filters',
        () async {
      String? authHeader;
      String? requestedPath;
      Map<String, String>? queryParams;

      ApiService.setToken('test_jwt_task_token');
      ApiService.client = MockClient((request) async {
        authHeader = request.headers['Authorization'];
        requestedPath = request.url.path;
        queryParams = request.url.queryParameters;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Tasks retrieved successfully',
            'data': [
              {
                '_id': 'task_101',
                'staffId': 'emp_101',
                'employeeId': 'EMP1001',
                'employeeName': 'Anita Rao',
                'department': 'Tech',
                'title': 'API Performance Tuning',
                'description': 'Optimize DB queries and cache leave balances',
                'status': 'in-progress',
                'date': '2026-10-15',
                'dueDate': '2026-10-22',
                'createdAt': '2026-10-15T09:00:00.000Z'
              },
              {
                '_id': 'task_102',
                'staffId': 'emp_102',
                'employeeId': 'EMP1002',
                'employeeName': 'Vikram Singh',
                'department': 'Telecalling',
                'title': 'Call Script Update',
                'description': 'Refine onboarding script for Q4 campaigns',
                'status': 'pending',
                'date': '2026-10-16',
                'dueDate': '2026-10-25',
                'createdAt': '2026-10-16T11:00:00.000Z'
              }
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 2, 'totalPages': 1}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.getTasksPage(
        page: 1,
        limit: 20,
        status: 'in-progress',
        department: 'Tech',
        employeeId: 'EMP1001',
      );

      expect(authHeader, 'Bearer test_jwt_task_token');
      expect(requestedPath, '/api/hr/tasks');
      expect(queryParams?['page'], '1');
      expect(queryParams?['limit'], '20');
      expect(queryParams?['status'], 'in-progress');
      expect(queryParams?['department'], 'Tech');
      expect(queryParams?['employeeId'], 'EMP1001');

      expect(result.page, 1);
      expect(result.total, 2);
      expect(result.totalPages, 1);
      expect(result.tasks.length, 2);

      final t1 = result.tasks[0];
      expect(t1.id, 'task_101');
      expect(t1.staffId, 'emp_101');
      expect(t1.employeeId, 'EMP1001');
      expect(t1.employeeName, 'Anita Rao');
      expect(t1.department, 'Tech');
      expect(t1.title, 'API Performance Tuning');
      expect(t1.description, contains('Optimize DB queries'));
      expect(t1.status, 'in-progress');
      expect(t1.dueDate, '2026-10-22');

      final t2 = result.tasks[1];
      expect(t2.id, 'task_102');
      expect(t2.department, 'Telecalling');
      expect(t2.status, 'pending');
    });

    test('handles empty task list and server error response safely', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Tasks retrieved successfully',
            'data': [],
            'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ApiService.getTasksPage();
      expect(result.tasks, isEmpty);
      expect(result.total, 0);
    });

    test('throws exception on 401 unauthorized or 500 server error', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'HR authorization required to access tasks',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => ApiService.getTasksPage(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('HR authorization required'))),
      );
    });
  });

  // ─── 2. ApiService Mutations: createTask, updateTask, deleteTask ───────────
  group('ApiService Task Mutations', () {
    test('createTask sends POST /api/hr/tasks and returns populated task',
        () async {
      ApiService.setToken('test_jwt_task_token');
      ApiService.client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/hr/tasks');

        final body = jsonDecode(request.body);
        expect(body['staffId'], 'EMP1001');
        expect(body['department'], 'Tech');
        expect(body['title'], 'Design Architecture');
        expect(body['description'], 'Prepare system design docs');
        expect(body['dueDate'], '2026-10-30');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Task assigned successfully',
            'data': {
              '_id': 'new_task_001',
              'staffId': 'emp_101',
              'employeeId': 'EMP1001',
              'employeeName': 'Anita Rao',
              'department': 'Tech',
              'title': 'Design Architecture',
              'description': 'Prepare system design docs',
              'status': 'pending',
              'date': '2026-10-16',
              'dueDate': '2026-10-30',
              'createdAt': '2026-10-16T10:00:00.000Z'
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final task = await ApiService.createTask(
        staffId: 'EMP1001',
        department: 'Tech',
        title: 'Design Architecture',
        description: 'Prepare system design docs',
        dueDate: '2026-10-30',
      );

      expect(task.id, 'new_task_001');
      expect(task.title, 'Design Architecture');
      expect(task.employeeName, 'Anita Rao');
      expect(task.status, 'pending');
    });

    test('updateTask sends PUT /api/hr/tasks/:id and returns updated record',
        () async {
      ApiService.setToken('test_jwt_task_token');
      ApiService.client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/hr/tasks/task_101');

        final body = jsonDecode(request.body);
        expect(body['status'], 'done');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Task updated successfully',
            'data': {
              '_id': 'task_101',
              'staffId': 'emp_101',
              'employeeId': 'EMP1001',
              'employeeName': 'Anita Rao',
              'department': 'Tech',
              'title': 'API Performance Tuning',
              'description': 'Optimize DB queries',
              'status': 'done',
              'date': '2026-10-15',
              'dueDate': '2026-10-22'
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final updated = await ApiService.updateTask(
        'task_101',
        status: 'done',
      );

      expect(updated.id, 'task_101');
      expect(updated.status, 'done');
    });

    test(
        'deleteTask sends DELETE /api/hr/tasks/:id and returns true on success',
        () async {
      ApiService.setToken('test_jwt_task_token');
      ApiService.client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/hr/tasks/task_101');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Task deleted successfully',
            'data': null
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ok = await ApiService.deleteTask('task_101');
      expect(ok, true);
    });
  });

  // ─── 3. HRProvider Task Management State & Flow ────────────────────────────
  group('HRProvider Task State Integration', () {
    test('loadTasks fetches paginated tasks and updates provider state',
        () async {
      final provider = HRProvider();

      ApiService.setToken('test_token');
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/api/hr/tasks');
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Tasks retrieved successfully',
            'data': [
              {
                '_id': 'task_301',
                'staffId': 'emp_301',
                'employeeId': 'EMP3001',
                'employeeName': 'Dev Team',
                'department': 'Tech',
                'title': 'Security Audit',
                'description': 'Verify JWT expiry and payload verification',
                'status': 'pending',
                'date': '2026-10-16',
                'dueDate': '2026-10-28'
              }
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.loadTasks();

      expect(provider.hasLoadedApiTasks, true);
      expect(provider.isTasksLoading, false);
      expect(provider.tasksError, isNull);
      expect(provider.apiTasksList.length, 1);
      expect(provider.filteredTasksList.length, 1);
      expect(provider.tasksTotal, 1);
      expect(provider.filteredTasksList.first.title, 'Security Audit');
    });

    test('prevents stale mock data and sets error on API failure', () async {
      final provider = HRProvider();

      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Task service temporarily unavailable',
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      await provider.loadTasks();

      expect(provider.isTasksLoading, false);
      expect(provider.tasksError,
          contains('Task service temporarily unavailable'));
      expect(provider.hasLoadedApiTasks, false);
      // Critical check: filteredTasksList returns empty list on error, NOT stale mock tasks
      expect(provider.filteredTasksList, isEmpty);
    });

    test('filter changes reset current page to 1 and trigger reload', () async {
      final provider = HRProvider();
      provider.hasLoadedApiTasks = true;
      provider.tasksPage = 4;

      int callCount = 0;
      ApiService.client = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [],
            'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0}
          }),
          200,
        );
      });

      // Status filter
      provider.setTaskStatusFilter('done');
      expect(provider.taskStatusFilter, 'done');
      expect(provider.tasksPage, 1);

      // Department filter
      provider.tasksPage = 3;
      provider.setTaskDeptFilter('Tech');
      expect(provider.taskDeptFilter, 'Tech');
      expect(provider.tasksPage, 1);

      // Search query
      provider.tasksPage = 2;
      provider.setTaskSearchQuery('EMP1001');
      expect(provider.taskSearchQuery, 'EMP1001');
      expect(provider.tasksPage, 1);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount >= 3, true);
    });

    test(
        'assignTask, updateTaskStatus, and deleteTask call APIs and refresh state',
        () async {
      final provider = HRProvider();
      provider.hasLoadedApiTasks = true;

      int postCalls = 0;
      int putCalls = 0;
      int deleteCalls = 0;
      int getCalls = 0;

      ApiService.setToken('test_token');
      ApiService.client = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/hr/tasks') {
          postCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                '_id': 't_new',
                'staffId': 'emp_1',
                'department': 'Tech',
                'title': 'New Task',
                'description': 'Description',
                'status': 'pending',
                'date': '2026-10-16',
                'dueDate': '2026-10-20'
              }
            }),
            201,
          );
        } else if (request.method == 'PUT') {
          putCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                '_id': 't_new',
                'staffId': 'emp_1',
                'department': 'Tech',
                'title': 'New Task',
                'description': 'Description',
                'status': 'done',
                'date': '2026-10-16',
                'dueDate': '2026-10-20'
              }
            }),
            200,
          );
        } else if (request.method == 'DELETE') {
          deleteCalls++;
          return http.Response(
            jsonEncode({'success': true, 'data': null}),
            200,
          );
        } else if (request.method == 'GET' &&
            request.url.path == '/api/hr/tasks') {
          getCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {
                'page': 1,
                'limit': 20,
                'total': 0,
                'totalPages': 0
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // 1. Assign Task
      final created = await provider.assignTask(
        'emp_1',
        'Tech',
        'Description',
        '2026-10-20',
        title: 'New Task',
      );
      expect(created, true);
      expect(postCalls, 1);
      expect(getCalls >= 1, true);

      // 2. Update Task Status
      final updated = await provider.updateTaskStatus('t_new', 'done');
      expect(updated, true);
      expect(putCalls, 1);

      // 3. Delete Task
      final deleted = await provider.deleteTask('t_new');
      expect(deleted, true);
      expect(deleteCalls, 1);
    });
  });

  // ─── 4. TasksView Widget Integration Tests ─────────────────────────────────
  group('TasksView Widget Tests', () {
    testWidgets(
        'renders loaded staff daily work updates without task creation controls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiDailyUpdates = true;
      provider.isDailyUpdatesLoading = true;
      provider.apiDailyUpdatesList = [
        DailyUpdate(
          id: 'task_view_1',
          staffId: 'emp_1',
          employeeId: 'EMP1001',
          employeeName: 'Anita Rao',
          department: 'Tech',
          title: 'calling',
          updateText: '49 call complete',
          date: '2026-10-16',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const TasksView(),
          ),
        ),
      );

      await tester.pump();

      // Screen title and content
      expect(find.text('Staff Daily Work Updates'), findsOneWidget);
      expect(find.text('Anita Rao'), findsOneWidget);
      expect(find.text('EMP1001'), findsOneWidget);
      expect(find.text('Tech'), findsOneWidget);
      expect(find.text('calling'), findsOneWidget);
      expect(find.text('49 call complete'), findsOneWidget);
      expect(find.text('Submitted: 2026-10-16'), findsOneWidget);

      // Verify removed controls are NOT present
      expect(find.text('Assign New Task'), findsNothing);
      expect(find.byTooltip('Delete Task'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('All Tasks'), findsNothing);
      expect(find.text('In Progress'), findsNothing);
      expect(find.text('Done'), findsNothing);
      expect(find.text('Cancelled'), findsNothing);
    });

    testWidgets('renders error banner with Retry button when updates fail',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.dailyUpdatesError = 'Network connection reset by peer';
      provider.hasLoadedApiDailyUpdates = false;
      provider.isDailyUpdatesLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const TasksView(),
          ),
        ),
      );

      await tester.pump();

      expect(
          find.text(
              'Failed to load updates from server: Network connection reset by peer'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No updates available due to server error'),
          findsOneWidget);
    });

    testWidgets('search query filters updates dynamically',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiDailyUpdates = true;
      provider.isDailyUpdatesLoading = true;
      provider.apiDailyUpdatesList = [
        DailyUpdate(
          id: 'task_1',
          staffId: 'emp_1',
          employeeName: 'Anita Rao',
          department: 'Tech',
          title: 'Frontend Architecture',
          updateText: 'Refactoring state management and providers',
          date: '2026-10-16',
        ),
        DailyUpdate(
          id: 'task_2',
          staffId: 'emp_2',
          employeeName: 'Vikram Singh',
          department: 'Telecalling',
          title: 'Customer Feedback Outreach',
          updateText: 'Completed 60 customer feedback phone calls',
          date: '2026-10-16',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const TasksView(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Anita Rao'), findsOneWidget);
      expect(find.text('Vikram Singh'), findsOneWidget);

      // Search for Telecalling employee
      // Simulate the result of the backend search request while preserving
      // the currently rendered page during the async fetch.
      provider.dailyUpdatesSearchQuery = 'Vikram';
      provider.apiDailyUpdatesList = [provider.apiDailyUpdatesList.last];
      provider.notifyListeners();
      await tester.pump();

      expect(find.text('Vikram Singh'), findsOneWidget);
      expect(find.text('Anita Rao'), findsNothing);
    });

    testWidgets(
        'confirms HR task creation controls and delete actions are removed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = HRProvider();
      provider.hasLoadedApiDailyUpdates = true;
      provider.isDailyUpdatesLoading = true;
      provider.apiDailyUpdatesList = [
        DailyUpdate(
          id: 'task_view_2',
          staffId: 'emp_1',
          department: 'Tech',
          title: 'Work Update Deliverable',
          updateText: 'Submitted progress report',
          date: '2026-10-16',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HRProvider>.value(
            value: provider,
            child: const TasksView(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Assign New Task'), findsNothing);
      expect(find.byTooltip('Delete Task'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });
  });
}
