import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ly_hr_dashboard_flutter/features/dashboard/staff_profile_view.dart';
import 'package:ly_hr_dashboard_flutter/models/staff.dart';
import 'package:ly_hr_dashboard_flutter/providers/hr_provider.dart';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

Staff _staff(String id, String name) => Staff(
      id: id,
      name: name,
      email: '${id.toLowerCase()}@example.com',
      phoneNumber: '555-0100',
      department: 'Tech',
      role: 'Engineer',
      joinDate: '2024-01-01',
      status: 'active',
      onLeaveToday: false,
    );

Map<String, dynamic> _update({
  required String id,
  required String staffId,
  required String employeeId,
  required String employeeName,
  required String title,
  required String text,
}) =>
    {
      'id': id,
      'staffId': staffId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'department': 'Tech',
      'title': title,
      'date': '2026-10-23',
      'updateText': text,
      'createdAt': '2026-10-23T10:30:00.000Z',
    };

void main() {
  tearDown(() {
    ApiService.client = http.Client();
    ApiService.clearTokens();
  });

  Future<void> mountProfile(WidgetTester tester, HRProvider provider) async {
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<HRProvider>.value(
        value: provider,
        child: const StaffProfileView(),
      ),
    ));
  }

  testWidgets(
      'shows selected employee updates and preserves other profile sections',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    ApiService.setToken('hr-jwt');
    http.Request? request;
    var requestCount = 0;
    ApiService.client = MockClient((incoming) async {
      requestCount++;
      request = incoming;
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [
            _update(
              id: 'u-1',
              staffId: 'staff-1',
              employeeId: 'EMP1001',
              employeeName: 'Anita Rao',
              title: 'calling',
              text: '49 call complete',
            ),
            _update(
              id: 'u-2',
              staffId: 'staff-1',
              employeeId: 'EMP1001',
              employeeName: 'Anita Rao',
              title: 'Follow up',
              text: 'Completed the customer follow-up list.',
            ),
            _update(
              id: 'u-other',
              staffId: 'staff-2',
              employeeId: 'EMP1002',
              employeeName: 'Different Employee',
              title: 'Private update',
              text: 'Must not appear in this profile.',
            ),
          ],
          'pagination': {'page': 1, 'limit': 100, 'total': 3, 'totalPages': 1},
        }),
        200,
      );
    });

    final provider = HRProvider();
    provider.employeeDirectory = [_staff('staff-1', 'Anita Rao')];
    provider.selectedStaffId = 'staff-1';
    await mountProfile(tester, provider);
    await tester.pumpAndSettle();

    expect(request!.url.path, '/api/hr/daily-updates');
    expect(request!.url.queryParameters['employeeId'], 'staff-1');
    expect(find.text('Assigned Tasks (0)'), findsNothing);
    expect(find.text('Staff Daily Work Updates'), findsOneWidget);
    expect(find.text('calling'), findsOneWidget);
    expect(find.text('49 call complete'), findsOneWidget);
    expect(find.text('Follow up'), findsOneWidget);
    expect(find.text('Must not appear in this profile.'), findsNothing);
    expect(find.text('Different Employee'), findsNothing);

    expect(find.textContaining('HR Document Management'), findsOneWidget);
    expect(find.textContaining('Attendance History'), findsOneWidget);
    expect(find.textContaining('Leave History'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('refresh_staff_daily_updates')));
    await tester.pumpAndSettle();
    expect(requestCount, 2);
  });

  testWidgets('shows empty state after a successful empty response',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    ApiService.setToken('hr-jwt');
    ApiService.client = MockClient((_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': [],
            'pagination': {
              'page': 1,
              'limit': 100,
              'total': 0,
              'totalPages': 1
            },
          }),
          200,
        ));
    final provider = HRProvider();
    provider.employeeDirectory = [_staff('staff-1', 'Anita Rao')];
    provider.selectedStaffId = 'staff-1';
    await mountProfile(tester, provider);
    await tester.pumpAndSettle();

    expect(find.text('No daily work updates submitted.'), findsOneWidget);
    expect(find.text('Staff Daily Work Updates'), findsOneWidget);
  });

  testWidgets('shows loading and API error with retry action', (tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    ApiService.setToken('hr-jwt');
    var requests = 0;
    ApiService.client = MockClient((_) async {
      requests++;
      return http.Response(
        jsonEncode({'success': false, 'message': 'HR access denied'}),
        403,
      );
    });
    final provider = HRProvider();
    provider.employeeDirectory = [_staff('staff-1', 'Anita Rao')];
    provider.selectedStaffId = 'staff-1';
    await mountProfile(tester, provider);
    expect(find.text('Loading daily work updates…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('Unable to load daily work updates'),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No daily work updates submitted.'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requests, 2);
  });

  testWidgets('profile cards fit a narrow viewport without layout overflow',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    ApiService.setToken('hr-jwt');
    ApiService.client = MockClient((_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': [],
            'pagination': {
              'page': 1,
              'limit': 100,
              'total': 0,
              'totalPages': 1
            },
          }),
          200,
        ));
    final provider = HRProvider();
    provider.employeeDirectory = [_staff('staff-1', 'Anita Rao')];
    provider.selectedStaffId = 'staff-1';
    await mountProfile(tester, provider);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Staff Daily Work Updates'), findsOneWidget);
  });
}
