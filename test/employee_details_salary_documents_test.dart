import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';
import 'package:ly_hr_dashboard_flutter/widgets/modals.dart';

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  test('document list includes archived items and safely parses nullable data',
      () async {
    late http.Request request;
    ApiService.setToken('hr-token');
    ApiService.client = MockClient((incoming) async {
      request = incoming;
      return http.Response(
          jsonEncode({
            'data': [
              {
                '_id': 'doc-1',
                'employee': {'_id': 'emp-db-id'},
                'title': 'Offer',
                'status': 'ARCHIVED',
                'fileSize': null
              }
            ]
          }),
          200);
    });

    final documents = await ApiService.getEmployeeDocuments('emp-db-id');
    expect(request.url.path, '/api/hr/employees/emp-db-id/documents');
    expect(request.url.queryParameters, {'includeArchived': 'true'});
    expect(request.headers['authorization'], 'Bearer hr-token');
    expect(documents.single.id, 'doc-1');
    expect(documents.single.employeeId, 'emp-db-id');
    expect(documents.single.status, 'ARCHIVED');
    expect(documents.single.fileSize, 0);
  });

  test('document detail uses the authenticated documented route', () async {
    late http.Request request;
    ApiService.client = MockClient((incoming) async {
      request = incoming;
      return http.Response(
          jsonEncode({
            'data': {'_id': 'doc-2', 'title': 'Resume'}
          }),
          200);
    });
    final doc = await ApiService.getEmployeeDocument('doc-2');
    expect(request.url.path, '/api/hr/documents/doc-2');
    expect(doc.title, 'Resume');
  });

  test('multipart upload uses existing form fields and Bearer token', () async {
    late http.Request request;
    ApiService.setToken('upload-token');
    ApiService.client = MockClient((incoming) async {
      request = incoming;
      return http.Response('', 201);
    });
    final success = await ApiService.uploadEmployeeDocument(
      employeeId: 'emp-4',
      title: 'ID Proof',
      category: 'Identity Proof',
      description: 'Passport',
      issueDate: '2026-01-01',
      fileName: 'id.pdf',
      fileBytes: [37, 80, 68, 70],
    );
    expect(success, isTrue);
    expect(request.url.path, '/api/hr/employees/emp-4/documents');
    expect(request.headers['authorization'], 'Bearer upload-token');
    expect(request.headers['content-type'], contains('multipart/form-data'));
    final multipartBody = latin1.decode(request.bodyBytes);
    expect(multipartBody, contains('name="title"'));
    expect(multipartBody, contains('ID Proof'));
    expect(multipartBody, contains('name="category"'));
    expect(multipartBody, contains('name="file"; filename="id.pdf"'));
  });

  test('document replacement and archive use documented methods and paths',
      () async {
    final requests = <http.Request>[];
    ApiService.client = MockClient((incoming) async {
      requests.add(incoming);
      return http.Response('', incoming.method == 'PUT' ? 200 : 204);
    });
    expect(
        await ApiService.replaceEmployeeDocument(
            docId: 'doc-8',
            title: 'Updated',
            fileName: 'new.pdf',
            fileBytes: [1, 2]),
        isTrue);
    expect(await ApiService.archiveEmployeeDocument('doc-8'), isTrue);
    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'PUT /api/hr/documents/doc-8',
      'PATCH /api/hr/documents/doc-8/archive'
    ]);
  });

  test('binary download returns bytes without attempting JSON decoding',
      () async {
    late http.Request request;
    final bytes = [0, 255, 42, 13, 10];
    ApiService.client = MockClient((incoming) async {
      request = incoming;
      return http.Response.bytes(bytes, 200,
          headers: {'content-type': 'application/pdf'});
    });
    final response = await ApiService.downloadEmployeeDocument('doc-9');
    expect(request.url.path, '/api/hr/documents/doc-9/download');
    expect(response.bodyBytes, bytes);
    expect(response.headers['content-type'], 'application/pdf');
  });

  test('document failures do not become an empty successful response',
      () async {
    ApiService.client = MockClient((_) async => http.Response('offline', 500));
    await expectLater(
        ApiService.getEmployeeDocuments('emp-1'), throwsA(isA<Exception>()));
    await expectLater(ApiService.downloadEmployeeDocument('doc-1'),
        throwsA(isA<Exception>()));
  });

  test('salary update sends only the documented salary payload', () async {
    late http.Request request;
    ApiService.client = MockClient((incoming) async {
      request = incoming;
      return http.Response('{}', 200);
    });
    await ApiService.updateEmployeeSalary('employee-db-id', {
      'salary': 72000,
      'salaryCurrency': 'INR',
      'salaryEffectiveDate': '2026-10-15',
      'reason': 'Annual review',
    });
    expect(request.method, 'PUT');
    expect(request.url.path, '/api/hr/employees/employee-db-id/salary');
    expect(jsonDecode(request.body), {
      'salary': 72000,
      'salaryCurrency': 'INR',
      'salaryEffectiveDate': '2026-10-15',
      'reason': 'Annual review',
    });
  });

  test('GET /api/hr/employees/:id parses full profile and salaryHistory',
      () async {
    late http.Request request;
    ApiService.setToken('hr-token-xyz');
    ApiService.client = MockClient((incoming) async {
      request = incoming;
      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Employee fetched successfully',
          'data': {
            '_id': 'emp-101',
            'employeeId': 'EMP1001',
            'firstName': 'Anita',
            'lastName': 'Rao',
            'email': 'anita@company.com',
            'phone': '9876543210',
            'department': 'Tech',
            'designation': 'Lead HR Manager',
            'salary': 85000,
            'salaryCurrency': 'INR',
            'salaryEffectiveDate': '2024-01-15',
            'salaryHistory': [
              {
                'amount': 85000,
                'currency': 'INR',
                'effectiveDate': '2024-01-15',
                'changedBy': 'System Initializer',
                'reason': 'Joining Base Salary',
                'timestamp': '2024-01-15 09:00:00'
              }
            ]
          }
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final staff = await ApiService.getEmployee('emp-101');
    expect(request.url.path, '/api/hr/employees/emp-101');
    expect(request.headers['authorization'], 'Bearer hr-token-xyz');
    expect(staff.id, 'emp-101');
    expect(staff.name, 'Anita Rao');
    expect(staff.salary, 85000.0);
    expect(staff.salaryCurrency, 'INR');
    expect(staff.salaryHistory.length, 1);
    expect(staff.salaryHistory.first.amount, 85000.0);
    expect(staff.salaryHistory.first.reason, 'Joining Base Salary');
    expect(staff.salaryHistory.first.changedBy, 'System Initializer');
  });

  test('PUT /api/hr/employees/:id sends updated fields with Bearer auth',
      () async {
    late http.Request request;
    ApiService.setToken('hr-token-put');
    ApiService.client = MockClient((incoming) async {
      request = incoming;
      return http.Response(
        jsonEncode({'success': true, 'message': 'Updated'}),
        200,
      );
    });

    final success = await ApiService.updateEmployee('emp-102', {
      'name': 'Anita Rao Updated',
      'department': 'Tech & Engineering',
    });

    expect(success, isTrue);
    expect(request.method, 'PUT');
    expect(request.url.path, '/api/hr/employees/emp-102');
    expect(request.headers['authorization'], 'Bearer hr-token-put');
    expect(jsonDecode(request.body), {
      'name': 'Anita Rao Updated',
      'department': 'Tech & Engineering',
    });
  });

  testWidgets('showSalaryHistoryModal renders actual history items',
      (tester) async {
    final staffWithHistory = Staff(
      id: 'staff-1',
      name: 'Anita Rao',
      email: 'anita@company.com',
      phoneNumber: '9876543210',
      department: 'Tech',
      role: 'HR Manager',
      joinDate: '2024-01-15',
      status: 'active',
      onLeaveToday: false,
      salary: 95000,
      salaryHistory: [
        SalaryHistoryItem(
          amount: 95000,
          currency: 'INR',
          effectiveDate: '2026-10-15',
          changedBy: 'Director',
          reason: 'Promotion Hike',
          timestamp: '2026-10-15 10:00:00',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                Modals.showSalaryHistoryModal(context, staffWithHistory),
            child: const Text('Open Modal'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Salary History: Anita Rao'), findsOneWidget);
    expect(find.text('INR 95000'), findsOneWidget);
    expect(find.text('Reason: Promotion Hike'), findsOneWidget);
    expect(find.text('Effective: 2026-10-15 • By: Director'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Salary History: Anita Rao'), findsNothing);
  });

  testWidgets(
      'showSalaryHistoryModal renders safe empty state when no history exists',
      (tester) async {
    final staffWithoutHistory = Staff(
      id: 'staff-2',
      name: 'John Doe',
      email: 'john@company.com',
      phoneNumber: '9876543211',
      department: 'Tech',
      role: 'Engineer',
      joinDate: '2024-01-15',
      status: 'active',
      onLeaveToday: false,
      salary: 50000,
      salaryHistory: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                Modals.showSalaryHistoryModal(context, staffWithoutHistory),
            child: const Text('Open Modal'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Salary History: John Doe'), findsOneWidget);
    expect(
        find.text('No salary adjustment records available for this employee.'),
        findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
}
