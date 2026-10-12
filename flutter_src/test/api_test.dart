import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:ly_hr_dashboard_flutter/services/api_service.dart';

void main() {
  group('ApiService HR Endpoints', () {
    test('getEmployees returns staff list on 200', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/hr/employees');
        expect(request.method, 'GET');
        
        return http.Response(jsonEncode({
          'data': [
            {
              'id': 's1',
              'name': 'Test User',
              'email': 'test@example.com',
              'department': 'Tech',
              'role': 'Staff',
              'status': 'active'
            }
          ]
        }), 200);
      });

      final staff = await ApiService.getEmployees();
      expect(staff.length, 1);
      expect(staff[0].name, 'Test User');
    });

    test('addEmployee returns true on 201', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/hr/employees');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['name'], 'New Staff');
        return http.Response('', 201);
      });

      final success = await ApiService.addEmployee({'name': 'New Staff'});
      expect(success, true);
    });

    test('updateEmployee returns true on 200', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/hr/employees/s1');
        expect(request.method, 'PUT');
        return http.Response('', 200);
      });

      final success = await ApiService.updateEmployee('s1', {'name': 'Updated'});
      expect(success, true);
    });

    test('deleteEmployee returns true on 200', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/hr/employees/s1');
        expect(request.method, 'DELETE');
        return http.Response('', 200);
      });

      final success = await ApiService.deleteEmployee('s1');
      expect(success, true);
    });

    test('approveLeave returns true on 200', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, '/hr/leaves/L1/approve');
        expect(request.method, 'PUT');
        return http.Response('', 200);
      });

      final success = await ApiService.approveLeave('L1');
      expect(success, true);
    });
  });
}
