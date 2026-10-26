import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/staff.dart';
import '../models/hr_models.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  static String? _token;
  static http.Client client = http.Client();

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  static Future<Map<String, dynamic>> getDashboardMetrics() async {
    final response = await client.get(Uri.parse('$baseUrl/hr/dashboard'), headers: _headers());
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch dashboard metrics');
  }

  static Future<List<Staff>> getEmployees() async {
    final response = await client.get(Uri.parse('$baseUrl/hr/employees'), headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? json;
      return data.map((e) => Staff.fromJson(e)).toList();
    }
    throw Exception('Failed to load employees');
  }

  static Future<bool> addEmployee(Map<String, dynamic> staffData) async {
    final response = await client.post(Uri.parse('$baseUrl/hr/employees'), headers: _headers(), body: jsonEncode(staffData));
    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> updateEmployee(String id, Map<String, dynamic> staffData) async {
    final response = await client.put(Uri.parse('$baseUrl/hr/employees/$id'), headers: _headers(), body: jsonEncode(staffData));
    return response.statusCode == 200;
  }

  static Future<bool> deleteEmployee(String id) async {
    final response = await client.delete(Uri.parse('$baseUrl/hr/employees/$id'), headers: _headers());
    return response.statusCode == 200;
  }

  static Future<List<Attendance>> getAttendance() async {
    final response = await client.get(Uri.parse('$baseUrl/hr/attendance'), headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? json;
      return data.map((e) => Attendance.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<Attendance>> getAttendanceForEmployee(String employeeId) async {
    final response = await client.get(Uri.parse('$baseUrl/hr/attendance/$employeeId'), headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? json;
      return data.map((e) => Attendance.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<LeaveRequest>> getLeaves() async {
    final response = await client.get(Uri.parse('$baseUrl/hr/leaves'), headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? json;
      return data.map((e) => LeaveRequest.fromJson(e)).toList();
    }
    return [];
  }

  static Future<LeaveRequest?> getLeaveDetails(String id) async {
    final response = await client.get(Uri.parse('$baseUrl/hr/leaves/$id'), headers: _headers());
    if (response.statusCode == 200) {
      return LeaveRequest.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  static Future<bool> approveLeave(String id) async {
    final response = await client.put(Uri.parse('$baseUrl/hr/leaves/$id/approve'), headers: _headers());
    return response.statusCode == 200;
  }

  static Future<bool> rejectLeave(String id) async {
    final response = await client.put(Uri.parse('$baseUrl/hr/leaves/$id/reject'), headers: _headers());
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getAttendanceReport() async {
    final response = await client.get(Uri.parse('$baseUrl/hr/reports/attendance'), headers: _headers());
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getLeavesReport() async {
    final response = await client.get(Uri.parse('$baseUrl/hr/reports/leaves'), headers: _headers());
    return jsonDecode(response.body);
  }

  static Future<List<DailyUpdate>> getDailyUpdates({String? employeeId, String? department, String? date}) async {
    final queryParams = <String, String>{};
    if (employeeId != null && employeeId.isNotEmpty) queryParams['employeeId'] = employeeId;
    if (department != null && department.isNotEmpty) queryParams['department'] = department;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;

    final uri = Uri.parse('$baseUrl/hr/daily-updates').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final response = await client.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? json;
      return data.map((e) => DailyUpdate.fromJson(e)).toList();
    }
    return [];
  }
}
