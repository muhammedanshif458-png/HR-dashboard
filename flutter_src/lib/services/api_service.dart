import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/staff.dart';
import '../models/hr_models.dart';
import '../models/hr_document.dart';
import '../models/birthday_item.dart';
import '../models/department.dart';
import '../core/department_helper.dart';
import 'login_debug_logger.dart';

class EmployeePage {
  final List<Staff> employees;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const EmployeePage(
      {required this.employees,
      required this.page,
      required this.limit,
      required this.total,
      required this.totalPages});
}

class AttendancePage {
  final List<Attendance> records;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const AttendancePage({
    required this.records,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class LeavePage {
  final List<LeaveRequest> leaves;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const LeavePage({
    required this.leaves,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class DailyUpdatePage {
  final List<DailyUpdate> updates;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const DailyUpdatePage({
    required this.updates,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Allows overriding the API base URL at runtime (e.g. in tests or dynamic environments).
  static void setBaseUrl(String? url) => AppConfig.setApiBaseUrl(url);

  /// Resets the API base URL back to default.
  static void resetBaseUrl() => AppConfig.resetApiBaseUrl();

  static String? _token;
  static String? _refreshToken;
  static String? _userRole;
  static http.Client client = http.Client();

  /// Sanitizes raw token input to prevent storing null, 'null', empty strings,
  /// or accidental full JSON objects/strings as tokens.
  static String? _sanitizeToken(dynamic rawToken) {
    if (rawToken == null) return null;
    if (rawToken is Map) {
      final inner = rawToken['token'] ?? rawToken['accessToken'];
      if (inner != null) return _sanitizeToken(inner);
      return null;
    }
    var str = rawToken.toString().trim();
    if (str.isEmpty ||
        str.toLowerCase() == 'null' ||
        str.toLowerCase() == 'undefined') {
      return null;
    }
    // Check if full JSON string was passed e.g. {"token": "..."}
    if (str.startsWith('{') && str.endsWith('}')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          final inner = decoded['token'] ??
              decoded['accessToken'] ??
              decoded['data']?['token'] ??
              decoded['data']?['accessToken'];
          if (inner != null) return _sanitizeToken(inner);
        }
      } catch (_) {}
      return null;
    }
    // Strip wrapping quotes if present
    if ((str.startsWith('"') && str.endsWith('"')) ||
        (str.startsWith("'") && str.endsWith("'"))) {
      str = str.substring(1, str.length - 1).trim();
    }
    if (str.isEmpty ||
        str.toLowerCase() == 'null' ||
        str.toLowerCase() == 'undefined') {
      return null;
    }
    return str;
  }

  static void setToken(dynamic token) {
    _token = _sanitizeToken(token);
  }

  static void setUserRole(String? role) {
    _userRole = role;
  }

  static String? get userRole => _userRole;

  static bool get isSuperAdminRole =>
      _userRole != null &&
      (_userRole!.toUpperCase() == 'SUPER_ADMIN' ||
          _userRole!.toUpperCase() == 'SUPERADMIN');

  static bool get isHrAdminRole =>
      _userRole != null &&
      (_userRole!.toUpperCase() == 'HR' ||
          _userRole!.toUpperCase() == 'HR MANAGER' ||
          _userRole!.toUpperCase() == 'ADMIN' ||
          _userRole!.toUpperCase() == 'SUPER_ADMIN' ||
          _userRole!.toUpperCase() == 'SUPERADMIN');

  static bool get isStaffRole =>
      _userRole != null &&
      (_userRole!.toUpperCase() == 'STAFF' ||
          _userRole!.toUpperCase() == 'EMPLOYEE');

  static void setTokens({
    dynamic token,
    dynamic accessToken,
    dynamic refreshToken,
    String? role,
  }) {
    final effectiveToken = token ?? accessToken;
    _token = _sanitizeToken(effectiveToken);
    _refreshToken = _sanitizeToken(refreshToken);
    if (role != null) {
      _userRole = role;
    }
  }

  static void clearTokens() {
    _token = null;
    _refreshToken = null;
    _userRole = null;
  }

  static String? get token => _token;
  static bool get hasToken =>
      _token != null &&
      _token!.trim().isNotEmpty &&
      _token!.trim().toLowerCase() != 'null';
  static String? get refreshToken => _refreshToken;

  static Map<String, String> _headers([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final t = _token?.trim();
    if (t != null && t.isNotEmpty && t.toLowerCase() != 'null') {
      headers['Authorization'] = 'Bearer $t';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  /// Formats and prints HR login authentication debug information directly to the terminal.
  /// Strictly restricted to [kDebugMode] so that full tokens are never exposed in production.
  static void printLoginTerminalDebug({
    required dynamic statusCode,
    required bool isSuccess,
    String? tokenFieldPath,
    String? token,
    bool tokenStored = false,
    String? errorMessage,
    String? diagnostic,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('\n========== HR LOGIN DEBUG ==========');
    buffer.writeln('Login API: POST /api/auth/login');
    buffer.writeln('HTTP Status: $statusCode');
    buffer.writeln('Login Status: ${isSuccess ? "SUCCESS" : "FAILED"}');

    if (isSuccess) {
      final hasTokenVal = token != null && token.isNotEmpty;
      buffer.writeln(
          'Token Field: ${tokenFieldPath ?? (hasTokenVal ? "data.token" : "NONE (MISSING)")}');
      buffer.writeln('Token Received: ${hasTokenVal ? "YES" : "NO"}');
      if (hasTokenVal) {
        buffer.writeln('JWT Token: $token');
        buffer.writeln('Token Storage: ${tokenStored ? "SUCCESS" : "FAILED"}');
      } else {
        buffer.writeln(
            'Diagnostic: ${diagnostic ?? "Authentication token is missing from response envelope. Expected field \"data.token\" or \"data.accessToken\"."}');
        buffer.writeln('Token Storage: FAILED');
      }
    } else {
      if (errorMessage != null && errorMessage.isNotEmpty) {
        buffer.writeln('Error: $errorMessage');
      }
    }
    buffer.writeln('===================================');

    debugPrint(buffer.toString());
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    // Clear any stale tokens before initiating a fresh authentication attempt
    clearTokens();

    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    LoginDebugLogger.instance.logRequestStart(
      url: '$baseUrl/api/auth/login',
      method: 'POST',
    );

    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': trimmedEmail,
              'password': trimmedPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (jsonErr) {
        LoginDebugLogger.instance.logResponseReceived(
          statusCode: response.statusCode,
          rawBody: response.body,
          decodedBody: null,
        );
        LoginDebugLogger.instance.logException(
          message: 'Malformed JSON response from server (${response.statusCode})',
          exception: jsonErr,
        );
        printLoginTerminalDebug(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: 'Malformed JSON response from server (${response.statusCode})',
        );
        return {
          'success': false,
          'message':
              'Invalid response received from server (${response.statusCode}). Please try again.',
          'errorType': response.statusCode >= 500 ? 'server' : 'malformed',
        };
      }

      LoginDebugLogger.instance.logResponseReceived(
        statusCode: response.statusCode,
        rawBody: response.body,
        decodedBody: decoded,
      );

      if (decoded is! Map<String, dynamic>) {
        LoginDebugLogger.instance.logException(
          message: 'Unexpected envelope: response is not a JSON object.',
        );
        printLoginTerminalDebug(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: 'Unexpected envelope: response is not a JSON object.',
        );
        return {
          'success': false,
          'message': 'Unexpected response format from server.',
          'errorType': 'malformed',
        };
      }

      if (response.statusCode == 200) {
        final success = decoded['success'] == true;
        if (!success) {
          final errorMsg = decoded['message'] ?? 'Login failed. Please try again.';
          LoginDebugLogger.instance.log(
            'Login failed: server returned success: false',
            level: 'warning',
          );
          printLoginTerminalDebug(
            statusCode: response.statusCode,
            isSuccess: false,
            errorMessage: errorMsg,
          );
          return {
            'success': false,
            'message': errorMsg,
            'errorType': 'authentication',
          };
        }

        final data = decoded['data'];
        if (data is! Map<String, dynamic>) {
          LoginDebugLogger.instance.log(
            'Malformed login response: missing "data" object.',
            level: 'error',
          );
          printLoginTerminalDebug(
            statusCode: response.statusCode,
            isSuccess: false,
            errorMessage: 'Malformed login response: missing data object.',
          );
          return {
            'success': false,
            'message': 'Malformed login response: missing data object.',
            'errorType': 'malformed',
          };
        }

        final user = data['user'];
        if (user is! Map<String, dynamic>) {
          LoginDebugLogger.instance.log(
            'Malformed login response: missing "user" details in data object.',
            level: 'error',
          );
          printLoginTerminalDebug(
            statusCode: response.statusCode,
            isSuccess: false,
            errorMessage: 'Malformed login response: missing user details.',
          );
          return {
            'success': false,
            'message': 'Malformed login response: missing user details.',
            'errorType': 'malformed',
          };
        }

        // Identify the exact JSON field path containing the token
        String? tokenFieldPath;
        if (data['token'] != null && data['token'].toString().trim().isNotEmpty) {
          tokenFieldPath = 'data.token';
        } else if (data['accessToken'] != null &&
            data['accessToken'].toString().trim().isNotEmpty) {
          tokenFieldPath = 'data.accessToken';
        } else if (decoded['token'] != null &&
            decoded['token'].toString().trim().isNotEmpty) {
          tokenFieldPath = 'token';
        } else if (decoded['accessToken'] != null &&
            decoded['accessToken'].toString().trim().isNotEmpty) {
          tokenFieldPath = 'accessToken';
        }

        final rawToken = data['token'] ??
            data['accessToken'] ??
            decoded['token'] ??
            decoded['accessToken'];
        final token = _sanitizeToken(rawToken);

        final rawRefresh = data['refreshToken'] ?? decoded['refreshToken'];
        final refreshToken = _sanitizeToken(rawRefresh);
        final userRole = user['role']?.toString();

        if (token != null && token.isNotEmpty) {
          setTokens(
            token: token,
            accessToken: token,
            refreshToken: refreshToken,
            role: userRole,
          );
        } else if (userRole != null) {
          setUserRole(userRole);
        }

        final isStored = token != null && token.isNotEmpty && hasToken;
        LoginDebugLogger.instance.logTokenAnalysis(
          decoded: decoded,
          token: token,
          storedSuccessfully: isStored,
        );

        // Terminal Debug Output strictly in kDebugMode
        printLoginTerminalDebug(
          statusCode: response.statusCode,
          isSuccess: true,
          tokenFieldPath: tokenFieldPath,
          token: token,
          tokenStored: isStored,
          diagnostic: (token == null || token.isEmpty)
              ? 'Authentication token is missing from response envelope. Expected field "data.token" or "data.accessToken".'
              : null,
        );

        return {
          'success': true,
          'message': decoded['message'] ?? 'Login successful',
          'data': data,
          'user': user,
          'token': token,
          'accessToken': token,
          'refreshToken': refreshToken,
        };
      } else if (response.statusCode == 400) {
        final errorMsg = decoded['message'] ??
            'Invalid login request. Please verify your email and password.';
        LoginDebugLogger.instance.log(
          'HTTP 400 Bad Request: $errorMsg',
          level: 'warning',
        );
        printLoginTerminalDebug(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: errorMsg,
        );
        return {
          'success': false,
          'message': errorMsg,
          'errorType': 'validation',
        };
      } else if (response.statusCode == 401) {
        final errorMsg = decoded['message'] ?? 'Invalid email or password.';
        LoginDebugLogger.instance.log(
          'HTTP 401 Unauthorized: $errorMsg',
          level: 'warning',
        );
        printLoginTerminalDebug(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: errorMsg,
        );
        return {
          'success': false,
          'message': errorMsg,
          'errorType': 'authentication',
        };
      } else if (response.statusCode == 403) {
        final errorMsg = decoded['message'] ??
            'Your account has been deactivated. Please contact HR.';
        LoginDebugLogger.instance.log(
          'HTTP 403 Forbidden: $errorMsg',
          level: 'warning',
        );
        printLoginTerminalDebug(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: errorMsg,
        );
        return {
          'success': false,
          'message': errorMsg,
          'errorType': 'forbidden',
        };
      } else if (response.statusCode == 422) {
        final errors = decoded['errors'];
        String? errorMsg;
        if (errors is List && errors.isNotEmpty && errors.first is Map) {
          errorMsg = errors.first['message']?.toString();
        }
        final finalMsg = errorMsg ??
            decoded['message']?.toString() ??
            'Validation failed. Please check your input.';
        LoginDebugLogger.instance.log(
          'HTTP 422 Validation Error: $finalMsg',
          level: 'warning',
        );
        printLoginTerminalDebug(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: finalMsg,
        );
        return {
          'success': false,
          'message': finalMsg,
          'errorType': 'validation',
        };
      } else if (response.statusCode >= 500) {
        final errorMsg =
            'Server error (${response.statusCode}). Please try again later.';
        LoginDebugLogger.instance.log(
          'HTTP ${response.statusCode} Server Error',
          level: 'error',
        );
        printLoginTerminalDebug(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: errorMsg,
        );
        return {
          'success': false,
          'message': errorMsg,
          'errorType': 'server',
        };
      } else {
        final errorMsg = decoded['message'] ??
            'Server error (${response.statusCode}). Please try again later.';
        LoginDebugLogger.instance.log(
          'HTTP ${response.statusCode} Unhandled Status Code',
          level: 'warning',
        );
        printLoginTerminalDebug(
          statusCode: response.statusCode,
          isSuccess: false,
          errorMessage: errorMsg,
        );
        return {
          'success': false,
          'message': errorMsg,
          'errorType': 'http',
        };
      }
    } on http.ClientException catch (e) {
      LoginDebugLogger.instance.logException(
        message: 'Network / Client Exception: ${e.message}',
        exception: e,
      );
      printLoginTerminalDebug(
        statusCode: 'CLIENT_EXCEPTION',
        isSuccess: false,
        errorMessage: e.message,
      );
      final msg = e.message.toLowerCase();
      if (msg.contains('xmlhttprequest') ||
          msg.contains('cors') ||
          msg.contains('failed to fetch')) {
        return {
          'success': false,
          'message':
              'Unable to connect to backend server at $baseUrl. Please verify the server is running and CORS is allowed.',
          'errorType': 'connection',
        };
      }
      return {
        'success': false,
        'message':
            'Unable to connect to the server. Please check your connection.',
        'errorType': 'connection',
      };
    } catch (e) {
      LoginDebugLogger.instance.logException(
        message: 'Unexpected Exception during login: $e',
        exception: e,
      );
      printLoginTerminalDebug(
        statusCode: 'EXCEPTION',
        isSuccess: false,
        errorMessage: e.toString(),
      );
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('timeout')) {
        return {
          'success': false,
          'message':
              'Request timed out. Please check your connection and try again.',
          'errorType': 'timeout',
        };
      }
      return {
        'success': false,
        'message': 'Network error. Please verify the server is running.',
        'errorType': 'connection',
      };
    }
  }

  static Future<Map<String, dynamic>> getDashboardMetrics(
      {String? date}) async {
    final uri = Uri.parse('$baseUrl/api/hr/dashboard').replace(
      queryParameters: date == null ? null : {'date': date},
    );
    final response = await client.get(
      uri,
      headers: _headers(),
    );
    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException('Invalid dashboard response from server.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected dashboard response envelope.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded['success'] != true ||
          decoded['data'] is! Map<String, dynamic>) {
        throw Exception(decoded['message']?.toString() ??
            'Failed to fetch dashboard metrics');
      }
      return decoded;
    }
    throw Exception(decoded['message']?.toString() ??
        'Failed to fetch dashboard metrics (HTTP ${response.statusCode})');
  }

  /// Fetches all organizational units / departments from `GET /api/hr/departments`.
  static Future<List<Department>> getDepartments() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/hr/departments'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final dynamic rawData =
          (decoded is Map<String, dynamic>) ? decoded['data'] : decoded;
      if (rawData is List) {
        final list = rawData
            .whereType<Map<String, dynamic>>()
            .map(Department.fromJson)
            .toList();
        return DepartmentHelper.deduplicateDepartments(list);
      }
    }
    throw Exception(
        'Failed to fetch departments (Status: ${response.statusCode})');
  }

  /// Fetches a single department's detailed information from `GET /api/hr/departments/:deptKey`.
  static Future<Department> getDepartmentDetail(String deptKey) async {
    final cleanKey = Uri.encodeComponent(deptKey.trim());
    final response = await client.get(
      Uri.parse('$baseUrl/api/hr/departments/$cleanKey'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final dynamic rawData =
          (decoded is Map<String, dynamic>) ? decoded['data'] : decoded;
      if (rawData is Map<String, dynamic>) {
        return Department.fromJson(rawData);
      }
    }
    throw Exception(
        'Failed to fetch department details for $deptKey (Status: ${response.statusCode})');
  }

  static Uri _employeeUri([String? id, Map<String, String>? query]) {
    final suffix = id == null
        ? ''
        : '/${id.split('/').map(Uri.encodeComponent).join('/')}';
    final path = '$baseUrl/api/hr/employees$suffix';
    return Uri.parse(path)
        .replace(queryParameters: query?.isEmpty == true ? null : query);
  }

  static String _employeeError(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) {
          final msgs = errors
              .whereType<Map>()
              .map((e) => e['message']?.toString())
              .where((m) => m != null && m.isNotEmpty)
              .cast<String>()
              .toList();
          if (msgs.isNotEmpty) return msgs.join('. ');
        }
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
        final error = decoded['error']?.toString();
        if (error != null && error.isNotEmpty) return error;
      }
    } catch (_) {}
    return '$fallback (HTTP ${response.statusCode})';
  }

  static Future<EmployeePage> getEmployeePage(
      {int page = 1,
      int limit = 20,
      String? search,
      String? department,
      String? status}) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (department != null && department != 'all' && department.isNotEmpty) {
      query['department'] = department;
    }
    if (status != null && status != 'all' && status.isNotEmpty) {
      query['status'] = status.toUpperCase();
    }
    final response =
        await client.get(_employeeUri(null, query), headers: _headers());
    if (response.statusCode != 200) {
      throw Exception(_employeeError(response, 'Failed to load employees'));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! List ||
        decoded['pagination'] is! Map) {
      throw const FormatException('Employee list response is malformed');
    }
    final rawPagination = decoded['pagination'] as Map;
    final list = (decoded['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(Staff.fromJson)
        .toList();
    return EmployeePage(
        employees: list,
        page: int.tryParse(rawPagination['page']?.toString() ?? '') ?? page,
        limit: int.tryParse(rawPagination['limit']?.toString() ?? '') ?? limit,
        total: int.tryParse(rawPagination['total']?.toString() ?? '') ??
            list.length,
        totalPages:
            int.tryParse(rawPagination['totalPages']?.toString() ?? '') ??
                (list.isEmpty ? 0 : 1));
  }

  static Future<List<Staff>> getEmployees() async {
    final response = await client.get(_employeeUri(null), headers: _headers());
    if (response.statusCode != 200) {
      throw Exception(_employeeError(response, 'Failed to load employees'));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
      throw const FormatException('Employee list response is malformed');
    }
    return (decoded['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(Staff.fromJson)
        .toList();
  }

  static Future<Staff> getEmployee(String id) async {
    final response = await client.get(_employeeUri(id), headers: _headers());
    if (response.statusCode != 200) {
      throw Exception(
          _employeeError(response, 'Failed to load employee details'));
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Employee detail response is malformed');
    }
    return Staff.fromJson(data);
  }

  static Future<bool> addEmployee(Map<String, dynamic> staffData) async {
    final response = await client.post(_employeeUri(),
        headers: _headers(), body: jsonEncode(staffData));
    if (response.statusCode == 201 || response.statusCode == 200) return true;
    throw Exception(_employeeError(response, 'Failed to create employee'));
  }

  static Future<bool> updateEmployee(
      String id, Map<String, dynamic> staffData) async {
    final response = await client.put(_employeeUri(id),
        headers: _headers(), body: jsonEncode(staffData));
    if (response.statusCode == 200) return true;
    throw Exception(_employeeError(response, 'Failed to update employee'));
  }

  static Future<bool> updateEmployeeStatus(String id, String status) async {
    final response = await client.patch(_employeeUri('$id/status'),
        headers: _headers(),
        body: jsonEncode({'status': status.toUpperCase()}));
    if (response.statusCode == 200) return true;
    throw Exception(
        _employeeError(response, 'Failed to update employee status'));
  }

  /// Calls the dedicated salary endpoint that persists salary + history in DB.
  static Future<bool> updateEmployeeSalary(
      String id, Map<String, dynamic> salaryData) async {
    try {
      final response = await client.put(
        _employeeUri('$id/salary'),
        headers: _headers(),
        body: jsonEncode(salaryData),
      );
      if (response.statusCode == 200) return true;
      throw Exception(_employeeError(response, 'Failed to update salary'));
    } catch (error) {
      rethrow;
    }
  }

  static Future<bool> deleteEmployee(String id) async {
    final response = await client.delete(_employeeUri(id), headers: _headers());
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception(_employeeError(response, 'Failed to deactivate employee'));
  }

  static Future<List<Attendance>> getAttendance(
      {String? startDate, String? endDate, String? status}) async {
    final queryParams = <String, String>{};
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['endDate'] = endDate;
    }
    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams['status'] = status.toUpperCase();
    }

    final baseUri = Uri.parse('$baseUrl/api/hr/attendance');
    final uri = queryParams.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParams);

    final response = await client.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? json;
      return data.map((e) => Attendance.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<Attendance>> getAttendanceForEmployee(
      String employeeId) async {
    final response = await client.get(
        Uri.parse('$baseUrl/api/hr/attendance/$employeeId'),
        headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? json;
      return data.map((e) => Attendance.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<LeaveRequest>> getLeaves(
      {String? status,
      String? leaveType,
      String? startDate,
      String? endDate}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams['status'] = status.toUpperCase();
    }
    if (leaveType != null && leaveType.isNotEmpty && leaveType != 'All') {
      queryParams['leaveType'] = leaveType.toUpperCase();
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['endDate'] = endDate;
    }

    final baseUri = Uri.parse('$baseUrl/api/hr/leaves');
    final uri = queryParams.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParams);

    final response = await client.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? json;
      return data.map((e) => LeaveRequest.fromJson(e)).toList();
    }
    return [];
  }

  /// Fetches paginated leave requests from `GET /api/hr/leaves`.
  static Future<LeavePage> getLeavesPage({
    int page = 1,
    int limit = 20,
    String? employeeId,
    String? status,
    String? leaveType,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (employeeId != null && employeeId.trim().isNotEmpty)
        'employeeId': employeeId.trim(),
      if (status != null && status.trim().isNotEmpty && status != 'all')
        'status': status.trim(),
      if (leaveType != null &&
          leaveType.trim().isNotEmpty &&
          leaveType != 'all')
        'leaveType': leaveType.trim(),
      if (startDate != null && startDate.trim().isNotEmpty)
        'startDate': startDate.trim(),
      if (endDate != null && endDate.trim().isNotEmpty)
        'endDate': endDate.trim(),
    };

    final uri = Uri.parse('$baseUrl/api/hr/leaves')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await client.get(uri, headers: _headers());

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(
            decoded['message']?.toString() ?? 'Failed to fetch leaves');
      }

      final rawData = decoded['data'];
      final rawList = rawData is List
          ? rawData
          : (rawData is Map<String, dynamic> ? rawData['leaves'] : null);
      final List<LeaveRequest> leaves = [];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            leaves.add(LeaveRequest.fromJson(item));
          }
        }
      }

      final pagination = decoded['pagination'] is Map<String, dynamic>
          ? decoded['pagination'] as Map<String, dynamic>
          : <String, dynamic>{};

      final p = pagination['page'] is num
          ? (pagination['page'] as num).toInt()
          : page;
      final l = pagination['limit'] is num
          ? (pagination['limit'] as num).toInt()
          : limit;
      final t = pagination['total'] is num
          ? (pagination['total'] as num).toInt()
          : leaves.length;
      final tp = pagination['totalPages'] is num
          ? (pagination['totalPages'] as num).toInt()
          : 1;

      return LeavePage(
        leaves: leaves,
        page: p,
        limit: l,
        total: t,
        totalPages: tp,
      );
    }

    final message = decoded['message']?.toString() ??
        'Failed to fetch leave requests (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Fetches single leave request details from `GET /api/hr/leaves/:id`.
  static Future<LeaveRequest?> getLeaveDetails(String id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/hr/leaves/$id'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'] ?? decoded;
        if (data is Map<String, dynamic>) {
          return LeaveRequest.fromJson(data);
        }
      }
    }
    return null;
  }

  /// Approves a leave request via `PUT /api/hr/leaves/:id/approve`.
  static Future<LeaveRequest> approveLeaveRequest(String id) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/hr/leaves/$id/approve'),
      headers: _headers(),
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return LeaveRequest.fromJson(data);
      }
      throw const FormatException('Malformed leave data returned on approval.');
    }

    final message = decoded['message']?.toString() ??
        'Failed to approve leave request (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Rejects a leave request via `PUT /api/hr/leaves/:id/reject`.
  static Future<LeaveRequest> rejectLeaveRequest(
      String id, String rejectionReason) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/hr/leaves/$id/reject'),
      headers: _headers(),
      body: jsonEncode({'rejectionReason': rejectionReason}),
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return LeaveRequest.fromJson(data);
      }
      throw const FormatException(
          'Malformed leave data returned on rejection.');
    }

    final message = decoded['message']?.toString() ??
        'Failed to reject leave request (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  static Future<bool> approveLeave(String id) async {
    final response = await client.put(
        Uri.parse('$baseUrl/api/hr/leaves/$id/approve'),
        headers: _headers());
    return response.statusCode == 200;
  }

  static Future<bool> rejectLeave(String id, [String? rejectionReason]) async {
    final body = jsonEncode({
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
    final response = await client.put(
      Uri.parse('$baseUrl/api/hr/leaves/$id/reject'),
      headers: _headers(),
      body: rejectionReason != null ? body : null,
    );
    return response.statusCode == 200;
  }

  static Future<AttendanceReportData> getAttendanceReport({
    String? startDate,
    String? endDate,
    String? department,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['endDate'] = endDate;
    }
    if (department != null &&
        department.isNotEmpty &&
        department.toLowerCase() != 'all') {
      queryParams['department'] = department;
    }

    final uri = Uri.parse('$baseUrl/api/hr/reports/attendance')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await client.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
      return AttendanceReportData.fromJson(data as Map<String, dynamic>);
    } else {
      String msg = 'Failed to load attendance report';
      try {
        final json = jsonDecode(response.body);
        msg = json['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<LeaveReportData> getLeavesReport({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['endDate'] = endDate;
    }

    final uri = Uri.parse('$baseUrl/api/hr/reports/leaves')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await client.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
      return LeaveReportData.fromJson(data as Map<String, dynamic>);
    } else {
      String msg = 'Failed to load leave report';
      try {
        final json = jsonDecode(response.body);
        msg = json['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Resolves and normalizes any document URL or ID to a complete, valid Uri.
  /// Handles bare document IDs, relative paths (/api/hr/documents/..., /hr/documents/..., /uploads/...),
  /// absolute URLs, and prevents missing `/api` or duplicate `/api/api`.
  static Uri buildDocumentUri(String documentUrlOrId) {
    var raw = documentUrlOrId.trim();
    if (raw.isEmpty) {
      throw Exception('Document URL or identifier cannot be empty.');
    }

    // If it's a bare document ID (like a 24-character Mongo ObjectId or alphanumeric ID without /)
    if (!raw.contains('/') && !raw.startsWith('http')) {
      raw = '/api/hr/documents/$raw/download';
    }

    // If already absolute HTTP / HTTPS URL
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.parse(raw);
      // Clean up accidental duplicate /api/api in path
      if (uri.path.contains('/api/api/')) {
        final fixedPath = uri.path.replaceAll('/api/api/', '/api/');
        return uri.replace(path: fixedPath);
      }
      return uri;
    }

    // Relative path formatting
    if (!raw.startsWith('/')) {
      raw = '/$raw';
    }

    // If relative path starts with /hr/documents/, ensure /api is prepended
    if (raw.startsWith('/hr/documents/')) {
      raw = '/api$raw';
    } else if (raw.startsWith('/staff/documents/')) {
      // HR administrative access uses /api/hr/documents/
      raw = raw.replaceFirst('/staff/documents/', '/api/hr/documents/');
    }

    // Normalize base URL
    String base = baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    // Prevent duplicate /api if base ends with /api and raw starts with /api
    if (base.endsWith('/api') && raw.startsWith('/api/')) {
      base = base.substring(0, base.length - 4);
      while (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }
    }

    final full = '$base$raw';
    final parsed = Uri.parse(full);
    if (parsed.path.contains('/api/api/')) {
      final fixedPath = parsed.path.replaceAll('/api/api/', '/api/');
      return parsed.replace(path: fixedPath);
    }
    return parsed;
  }

  /// Verifies whether the provided binary bytes represent a valid PDF file
  /// by checking for the standard '%PDF-' magic header signature in the first 1024 bytes.
  static bool isPdfSignature(List<int> bytes) {
    if (bytes.length < 5) return false;
    final checkLen = bytes.length < 1024 ? bytes.length : 1024;
    final headerStr = String.fromCharCodes(bytes.take(checkLen));
    return headerStr.contains('%PDF-');
  }

  /// Fetches an authenticated medical document or employee document securely.
  /// Sends the current HR / SUPER_ADMIN Bearer token, validates the response,
  /// verifies the '%PDF-' signature if expected or returned as PDF,
  /// and returns binary bytes and content type.
  static Future<Map<String, dynamic>> fetchMedicalDocumentSecurely(
    String documentUrlOrId, {
    String? expectedFileName,
    String? expectedFileType,
  }) async {
    // 1. Verify authentication token
    if (_token == null || _token!.isEmpty) {
      throw Exception(
          'Authentication required: missing or expired authentication token. Please sign in (HTTP 401).');
    }

    // 2. Build full URL with normalization
    final fullUri = buildDocumentUri(documentUrlOrId);

    // 3. Prepare headers
    final headers = {
      ..._headers(),
      'Accept': 'application/pdf, image/png, image/jpeg, image/*, */*',
    };

    // 4. Send authenticated GET request
    http.Response response;
    try {
      response = await client.get(fullUri, headers: headers);
    } catch (e) {
      if (e is Exception && e.toString().contains('HTTP 401')) {
        rethrow;
      }
      throw Exception(
          'Network error: Failed to connect to backend server. Please verify network connectivity.');
    }

    // 5. Handle HTTP status codes
    if (response.statusCode == 401) {
      throw Exception(
          'Authentication expired or invalid. Please sign in again (HTTP 401).');
    } else if (response.statusCode == 403) {
      throw Exception(
          'Access denied: insufficient HR or administrative permissions to access this medical record (HTTP 403).');
    } else if (response.statusCode == 404) {
      throw Exception(
          'Medical document not found on file server (HTTP 404). Document path: ${fullUri.path}');
    } else if (response.statusCode != 200) {
      String errMsg = 'Failed to load document (HTTP ${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          errMsg = '$errMsg: ${decoded['message']}';
        }
      } catch (_) {}
      throw Exception(errMsg);
    }

    // 6. Validate binary content
    final rawBytes = response.bodyBytes;
    if (rawBytes.isEmpty) {
      throw Exception('The retrieved document file is empty (0 bytes).');
    }

    final cTypeHeader = (response.headers['content-type'] ?? '').toLowerCase();

    // Check if server returned a JSON error payload disguised as 200
    if (cTypeHeader.contains('application/json') ||
        cTypeHeader.contains('text/json')) {
      String msg =
          'Server returned a JSON response instead of the document file.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['message'] != null) {
            msg = decoded['message'];
          } else if (decoded['error'] != null) {
            msg = decoded['error'];
          }
        }
      } catch (_) {}
      throw Exception(msg);
    }

    // Check if server returned an HTML error page
    if (cTypeHeader.contains('text/html')) {
      throw Exception(
          'Received an HTML error page from server instead of the requested document file.');
    }

    final bytes = Uint8List.fromList(rawBytes);

    // Determine content type and format
    final isPdfSig = isPdfSignature(bytes);
    final fileNameLower = (expectedFileName ?? fullUri.path).toLowerCase();
    final isPdfExpected = (expectedFileType?.contains('pdf') ?? false) ||
        fileNameLower.endsWith('.pdf') ||
        cTypeHeader.contains('pdf');

    if (isPdfExpected && !isPdfSig) {
      throw Exception(
          'Invalid PDF file: document header does not contain the standard "%PDF-" signature.');
    }

    final isPdf = isPdfSig || isPdfExpected;
    final isImage = !isPdf &&
        (cTypeHeader.startsWith('image/') ||
            fileNameLower.endsWith('.png') ||
            fileNameLower.endsWith('.jpg') ||
            fileNameLower.endsWith('.jpeg') ||
            fileNameLower.endsWith('.webp') ||
            fileNameLower.endsWith('.gif'));

    final effectiveContentType = cTypeHeader.isNotEmpty
        ? cTypeHeader
        : (isPdf
            ? 'application/pdf'
            : (fileNameLower.endsWith('.png')
                ? 'image/png'
                : (fileNameLower.endsWith('.jpg') ||
                        fileNameLower.endsWith('.jpeg')
                    ? 'image/jpeg'
                    : 'application/octet-stream')));

    return {
      'statusCode': 200,
      'bytes': bytes,
      'contentType': effectiveContentType,
      'isPdf': isPdf,
      'isImage': isImage,
      'uri': fullUri,
    };
  }

  // --- Department Chat & Messaging API (Screen 11 Integration) ---

  static Future<List<ChatMessage>> getDepartmentMessages(
    String deptKey, {
    bool? isStaff,
  }) async {
    final prefix = (isStaff ?? isStaffRole) ? 'staff' : 'hr';
    final response = await client.get(
      Uri.parse(
          '$baseUrl/api/$prefix/departments/${Uri.encodeComponent(deptKey)}/messages'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List list =
          json['data'] is List ? json['data'] : (json is List ? json : []);
      return list
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    } else {
      String msg = 'Failed to load department messages';
      try {
        final json = jsonDecode(response.body);
        msg = json['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<bool> sendDepartmentMessage(
    String deptKey,
    String text, {
    String? senderName,
    bool? isStaff,
  }) async {
    final prefix = (isStaff ?? isStaffRole) ? 'staff' : 'hr';
    final response = await client.post(
      Uri.parse(
          '$baseUrl/api/$prefix/departments/${Uri.encodeComponent(deptKey)}/messages'),
      headers: _headers(),
      body: jsonEncode({
        'text': text,
        if (senderName != null && senderName.isNotEmpty)
          'senderName': senderName,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      String msg = 'Failed to send message';
      try {
        final json = jsonDecode(response.body);
        msg = json['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<List<ChatMessage>> getPrivateMessages(
      String participantId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/hr/chat/messages/$participantId'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List list = json['data'] ?? json;
        return list.map((m) => ChatMessage.fromJson(m)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> sendPrivateMessage(
      String participantId, String text, {String? senderId}) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/hr/chat/messages/$participantId'),
        headers: _headers(),
        body: jsonEncode({
          'text': text,
          if (senderId != null && senderId.isNotEmpty) 'senderId': senderId,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {}
    return false;
  }

  // ── Message Deletion ──────────────────────────────────────────────────────

  /// Marks a message as deleted only for the requesting user.
  /// Sends PATCH with { "userId": <callerId> } so the backend appends the ID
  /// to the message's `deletedByIds` array without touching other fields.
  /// Returns true on 200/204, false on network failure.
  /// Throws [DeletionPermissionException] on HTTP 403.
  static Future<bool> deleteDepartmentMessageForMe(
    String deptKey,
    String messageId,
    String callerId, {
    bool? isStaff,
  }) async {
    final prefix = (isStaff ?? isStaffRole) ? 'staff' : 'hr';
    final response = await client.patch(
      Uri.parse(
          '$baseUrl/api/$prefix/departments/${Uri.encodeComponent(deptKey)}/messages/${Uri.encodeComponent(messageId)}/delete-for-me'),
      headers: _headers(),
      body: jsonEncode({'userId': callerId}),
    );
    if (response.statusCode == 403) {
      String msg = 'You do not have permission to delete this message.';
      try {
        final json = jsonDecode(response.body);
        msg = json['message'] ?? msg;
      } catch (_) {}
      throw DeletionPermissionException(msg);
    }
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    String msg = 'Failed to delete message for user';
    try {
      final json = jsonDecode(response.body);
      msg = json['message'] ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  /// Deletes a message for everyone (hard delete / tombstone).
  /// Only the original sender or an HR Manager may call this.
  /// The backend validates authorization using the JWT in the Authorization header.
  /// Throws [DeletionPermissionException] on HTTP 403.
  static Future<bool> deleteDepartmentMessageForEveryone(
    String deptKey,
    String messageId, {
    bool? isStaff,
  }) async {
    final prefix = (isStaff ?? isStaffRole) ? 'staff' : 'hr';
    final response = await client.delete(
      Uri.parse(
          '$baseUrl/api/$prefix/departments/${Uri.encodeComponent(deptKey)}/messages/${Uri.encodeComponent(messageId)}'),
      headers: _headers(),
    );
    if (response.statusCode == 403) {
      String msg =
          'Only the message sender or an HR administrator can delete for everyone.';
      try {
        final json = jsonDecode(response.body);
        msg = json['message'] ?? msg;
      } catch (_) {}
      throw DeletionPermissionException(msg);
    }
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    String msg = 'Failed to delete message for everyone';
    try {
      final json = jsonDecode(response.body);
      msg = json['message'] ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  // --- HR Document Management Endpoints ---

  static Future<List<HRDocumentItem>> getEmployeeDocuments(
      String employeeId) async {
    final response = await client.get(
      Uri.parse(
              '$baseUrl/api/hr/employees/${Uri.encodeComponent(employeeId)}/documents')
          .replace(queryParameters: {'includeArchived': 'true'}),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(
          _employeeError(response, 'Failed to load employee documents'));
    }
    final json = jsonDecode(response.body);
    final rawList = json is Map<String, dynamic>
        ? (json['data'] is List
            ? json['data']
            : (json['message'] is List ? json['message'] : null))
        : null;
    if (rawList is! List) {
      throw const FormatException('Document list response is malformed');
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(HRDocumentItem.fromJson)
        .toList();
  }

  static Future<HRDocumentItem> getEmployeeDocument(String documentId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/hr/documents/${Uri.encodeComponent(documentId)}'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(
          _employeeError(response, 'Failed to load document details'));
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? (decoded['data'] is Map<String, dynamic>
            ? decoded['data']
            : (decoded['message'] is Map<String, dynamic>
                ? decoded['message']
                : null))
        : null;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Document detail response is malformed');
    }
    return HRDocumentItem.fromJson(data);
  }

  static Future<http.Response> downloadEmployeeDocument(
      String documentId) async {
    final response = await client.get(
      Uri.parse(
          '$baseUrl/api/hr/documents/${Uri.encodeComponent(documentId)}/download'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(_employeeError(response, 'Failed to download document'));
    }
    final cType = response.headers['content-type']?.toLowerCase() ?? '';
    if (cType.contains('application/json')) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          final msg = decoded['message'] ?? 'Document retrieval failed';
          throw Exception(msg);
        }
      } catch (e) {
        if (e is! FormatException) rethrow;
      }
    } else if (cType.contains('text/html')) {
      final bodyStr = response.body.toLowerCase();
      if (bodyStr.contains('<html') || bodyStr.contains('<!doctype html')) {
        throw Exception(
            'Received an HTML error page instead of the requested document.');
      }
    }
    if (response.bodyBytes.isEmpty) {
      throw Exception('The requested document is empty.');
    }
    return response;
  }

  static Future<bool> uploadEmployeeDocument({
    required String employeeId,
    required String title,
    required String category,
    String? description,
    String? issueDate,
    String? expiryDate,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/api/hr/employees/${Uri.encodeComponent(employeeId)}/documents');
      final request = http.MultipartRequest('POST', uri);
      final t = _token?.trim();
      if (t != null && t.isNotEmpty && t.toLowerCase() != 'null') {
        request.headers['Authorization'] = 'Bearer $t';
      }

      request.fields['title'] = title;
      request.fields['category'] = category;
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      if (issueDate != null && issueDate.isNotEmpty) {
        request.fields['issueDate'] = issueDate;
      }
      if (expiryDate != null && expiryDate.isNotEmpty) {
        request.fields['expiryDate'] = expiryDate;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) return true;
      throw Exception(_employeeError(response, 'Document upload failed'));
    } catch (_) {
      rethrow;
    }
  }

  static Future<bool> replaceEmployeeDocument({
    required String docId,
    required String title,
    String? description,
    String? issueDate,
    String? expiryDate,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final uri =
          Uri.parse('$baseUrl/api/hr/documents/${Uri.encodeComponent(docId)}');
      final request = http.MultipartRequest('PUT', uri);
      final t = _token?.trim();
      if (t != null && t.isNotEmpty && t.toLowerCase() != 'null') {
        request.headers['Authorization'] = 'Bearer $t';
      }

      request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (issueDate != null) request.fields['issueDate'] = issueDate;
      if (expiryDate != null) request.fields['expiryDate'] = expiryDate;

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) return true;
      throw Exception(_employeeError(response, 'Document replacement failed'));
    } catch (_) {
      rethrow;
    }
  }

  static Future<bool> archiveEmployeeDocument(String docId) async {
    final response = await client.patch(
      Uri.parse(
          '$baseUrl/api/hr/documents/${Uri.encodeComponent(docId)}/archive'),
      headers: _headers(),
    );
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception(_employeeError(response, 'Document archive failed'));
  }

  // --- Company-Wide Birthday Celebrations ---

  static Future<Map<String, dynamic>> getCompanyBirthdays({
    int daysAhead = 30,
    bool? isStaff,
  }) async {
    final useStaff = isStaff ?? isStaffRole;
    final endpointPath = useStaff
        ? '$baseUrl/api/staff/birthdays?daysAhead=$daysAhead'
        : '$baseUrl/api/hr/birthdays?daysAhead=$daysAhead';

    try {
      final response = await client.get(
        Uri.parse(endpointPath),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? json;
        final List todayRaw = data['today'] ?? [];
        final List upcomingRaw = data['upcoming'] ?? [];
        return {
          'today': todayRaw.map((b) => BirthdayItem.fromJson(b)).toList(),
          'upcoming': upcomingRaw.map((b) => BirthdayItem.fromJson(b)).toList(),
          'totalToday': data['totalToday'] ?? todayRaw.length,
          'totalUpcoming': data['totalUpcoming'] ?? upcomingRaw.length,
        };
      }
      return {
        'today': <BirthdayItem>[],
        'upcoming': <BirthdayItem>[],
        'totalToday': 0,
        'totalUpcoming': 0,
        'error': 'Failed to load birthdays (HTTP ${response.statusCode})',
      };
    } catch (e) {
      return {
        'today': <BirthdayItem>[],
        'upcoming': <BirthdayItem>[],
        'totalToday': 0,
        'totalUpcoming': 0,
        'error': 'Failed to fetch birthdays: $e',
      };
    }
  }

  // --- Attendance Management (Screen 6 API Integration) ---

  /// Fetches paginated attendance records from `GET /api/hr/attendance`.
  static Future<AttendancePage> getAttendancePage({
    int page = 1,
    int limit = 20,
    String? employeeId,
    String? date,
    String? startDate,
    String? endDate,
    String? status,
    String? department,
    String? search,
    String? workMode,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (employeeId != null && employeeId.trim().isNotEmpty)
        'employeeId': employeeId.trim(),
      if (department != null &&
          department.trim().isNotEmpty &&
          department != 'all')
        'department': department.trim(),
      if (search != null && search.trim().isNotEmpty)
        'search': search.trim(),
      if (workMode != null && workMode.trim().isNotEmpty && workMode != 'all')
        'workMode': workMode.trim(),
      if (date != null && date.trim().isNotEmpty)
        'date': date.trim(),
      if (startDate != null && startDate.trim().isNotEmpty)
        'startDate': startDate.trim(),
      if (endDate != null && endDate.trim().isNotEmpty)
        'endDate': endDate.trim(),
      if (status != null && status.trim().isNotEmpty && status != 'all')
        'status': status.trim(),
    };

    final uri = Uri.parse('$baseUrl/api/hr/attendance')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await client.get(uri, headers: _headers());

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(
            decoded['message']?.toString() ?? 'Failed to fetch attendance');
      }

      final rawList = decoded['data'];
      final List<Attendance> records = [];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            records.add(Attendance.fromJson(item));
          }
        }
      }

      final pagination = decoded['pagination'] is Map<String, dynamic>
          ? decoded['pagination'] as Map<String, dynamic>
          : <String, dynamic>{};

      final p = pagination['page'] is num
          ? (pagination['page'] as num).toInt()
          : page;
      final l = pagination['limit'] is num
          ? (pagination['limit'] as num).toInt()
          : limit;
      final t = pagination['total'] is num
          ? (pagination['total'] as num).toInt()
          : records.length;
      final tp = pagination['totalPages'] is num
          ? (pagination['totalPages'] as num).toInt()
          : 1;

      return AttendancePage(
        records: records,
        page: p,
        limit: l,
        total: t,
        totalPages: tp,
      );
    }

    final message = decoded['message']?.toString() ??
        'Failed to fetch attendance records (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Fetches attendance records for a specific employee from `GET /api/hr/attendance/:employeeId`.
  static Future<AttendancePage> getAttendanceByEmployee({
    required String employeeId,
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
  }) async {
    final cleanId = Uri.encodeComponent(employeeId.trim());
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (startDate != null && startDate.trim().isNotEmpty)
        'startDate': startDate.trim(),
      if (endDate != null && endDate.trim().isNotEmpty)
        'endDate': endDate.trim(),
    };

    final uri = Uri.parse('$baseUrl/api/hr/attendance/$cleanId')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await client.get(uri, headers: _headers());

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(decoded['message']?.toString() ??
            'Failed to fetch employee attendance');
      }

      final rawList = decoded['data'];
      final List<Attendance> records = [];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            records.add(Attendance.fromJson(item));
          }
        }
      }

      final pagination = decoded['pagination'] is Map<String, dynamic>
          ? decoded['pagination'] as Map<String, dynamic>
          : <String, dynamic>{};

      final p = pagination['page'] is num
          ? (pagination['page'] as num).toInt()
          : page;
      final l = pagination['limit'] is num
          ? (pagination['limit'] as num).toInt()
          : limit;
      final t = pagination['total'] is num
          ? (pagination['total'] as num).toInt()
          : records.length;
      final tp = pagination['totalPages'] is num
          ? (pagination['totalPages'] as num).toInt()
          : 1;

      return AttendancePage(
        records: records,
        page: p,
        limit: l,
        total: t,
        totalPages: tp,
      );
    }

    final message = decoded['message']?.toString() ??
        'Failed to fetch employee attendance records (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  // --- Staff Self-Service Attendance & Leaves ---

  /// Dispatches staff check-in to `POST /api/staff/attendance/check-in`.
  static Future<Map<String, dynamic>> staffCheckIn({String? workMode}) async {
    final response = await client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/staff/attendance/check-in'),
      headers: _headers(),
      body: jsonEncode({
        if (workMode != null && workMode.isNotEmpty) 'workMode': workMode,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return decoded is Map<String, dynamic> ? decoded : {'success': true};
    }
    final message = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Check-in failed (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Dispatches staff check-out to `POST /api/staff/attendance/check-out`.
  static Future<Map<String, dynamic>> staffCheckOut() async {
    final response = await client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/staff/attendance/check-out'),
      headers: _headers(),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return decoded is Map<String, dynamic> ? decoded : {'success': true};
    }
    final message = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Check-out failed (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Fetches historical attendance logs for the authenticated staff user.
  static Future<List<Attendance>> getStaffAttendance({int page = 1, int limit = 20}) async {
    final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/staff/attendance?page=$page&limit=$limit');
    final response = await client.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final rawList = decoded is Map<String, dynamic> && decoded['data'] is List
          ? decoded['data'] as List
          : (decoded is List ? decoded : []);
      return rawList
          .map((j) => Attendance.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    final decoded = jsonDecode(response.body);
    final message = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to load staff attendance (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Submits a new leave request for the authenticated staff member.
  static Future<bool> applyStaffLeave({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    String? medicalDocumentPath,
  }) async {
    final response = await client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/staff/leaves'),
      headers: _headers(),
      body: jsonEncode({
        'leaveType': leaveType,
        'fromDate': fromDate,
        'toDate': toDate,
        'reason': reason,
        if (medicalDocumentPath != null)
          'medicalDocumentPath': medicalDocumentPath,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    final decoded = jsonDecode(response.body);
    final message = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Failed to submit leave request (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  // --- Payroll Processing (Screen 8 API Integration) ---

  /// Fetches payroll summary from `GET /api/hr/payroll/summary`.
  static Future<PayrollSummary> getPayrollSummary({
    int? month,
    int? year,
    String? department,
  }) async {
    final query = <String, String>{
      if (month != null) 'month': month.toString(),
      if (year != null) 'year': year.toString(),
      if (department != null &&
          department.trim().isNotEmpty &&
          department != 'all')
        'department': department.trim(),
    };

    final uri = Uri.parse('$baseUrl/api/hr/payroll/summary')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await client.get(uri, headers: _headers());

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(decoded['message']?.toString() ??
            'Failed to fetch payroll summary');
      }
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return PayrollSummary.fromJson(data);
      }
      throw const FormatException('Payroll summary data is malformed');
    }

    final message = decoded['message']?.toString() ??
        'Failed to fetch payroll summary (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Fetches itemized employee payroll list from `GET /api/hr/payroll/employees`.
  static Future<EmployeePayrollPage> getEmployeesPayroll({
    int? month,
    int? year,
    String? department,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (month != null) 'month': month.toString(),
      if (year != null) 'year': year.toString(),
      if (department != null &&
          department.trim().isNotEmpty &&
          department != 'all')
        'department': department.trim(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final uri = Uri.parse('$baseUrl/api/hr/payroll/employees')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await client.get(uri, headers: _headers());

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(decoded['message']?.toString() ??
            'Failed to fetch employee payroll records');
      }

      final rawList = decoded['data'];
      final List<EmployeePayrollRecord> records = [];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            records.add(EmployeePayrollRecord.fromJson(item));
          }
        }
      }

      final pagination = decoded['pagination'] is Map<String, dynamic>
          ? decoded['pagination'] as Map<String, dynamic>
          : <String, dynamic>{};

      final p = pagination['page'] is num
          ? (pagination['page'] as num).toInt()
          : page;
      final l = pagination['limit'] is num
          ? (pagination['limit'] as num).toInt()
          : limit;
      final t = pagination['total'] is num
          ? (pagination['total'] as num).toInt()
          : records.length;
      final tp = pagination['totalPages'] is num
          ? (pagination['totalPages'] as num).toInt()
          : 1;

      return EmployeePayrollPage(
        records: records,
        page: p,
        limit: l,
        total: t,
        totalPages: tp,
      );
    }

    final message = decoded['message']?.toString() ??
        'Failed to fetch employee payroll records (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Fetches individual employee payroll calculation details from `GET /api/hr/payroll/employees/:employeeId`.
  static Future<EmployeePayrollRecord> getEmployeePayrollById(
    String employeeId, {
    int? month,
    int? year,
  }) async {
    final cleanId = Uri.encodeComponent(employeeId.trim());
    final query = <String, String>{
      if (month != null) 'month': month.toString(),
      if (year != null) 'year': year.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/hr/payroll/employees/$cleanId')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await client.get(uri, headers: _headers());

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(decoded['message']?.toString() ??
            'Failed to fetch employee payroll details');
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return EmployeePayrollRecord.fromJson(data);
      }
      throw const FormatException('Employee payroll detail data is malformed');
    }

    final message = decoded['message']?.toString() ??
        'Failed to fetch employee payroll details (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  // --- Task Management (Screen 9 API Integration) ---

  /// Fetches staff-submitted daily work updates for HR review.
  static Future<DailyUpdatePage> getDailyUpdatesPage({
    int page = 1,
    int limit = 20,
    String? department,
    String? employeeId,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (department != null &&
          department.trim().isNotEmpty &&
          department != 'all')
        'department': department.trim(),
      if (employeeId != null && employeeId.trim().isNotEmpty)
        'employeeId': employeeId.trim(),
    };
    final uri = Uri.parse('$baseUrl/api/hr/daily-updates')
        .replace(queryParameters: query);
    final response = await client.get(uri, headers: _headers());

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message']?.toString() ??
          'Failed to fetch daily work updates (HTTP ${response.statusCode})');
    }
    if (decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ??
          'Failed to fetch daily work updates');
    }

    final rawList = decoded['data'];
    if (rawList is! List) {
      throw const FormatException('Daily work updates data is malformed.');
    }
    final updates = rawList
        .whereType<Map>()
        .map((item) => DailyUpdate.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final pagination = decoded['pagination'] is Map
        ? Map<String, dynamic>.from(decoded['pagination'] as Map)
        : const <String, dynamic>{};
    int number(String key, int fallback) =>
        pagination[key] is num ? (pagination[key] as num).toInt() : fallback;

    return DailyUpdatePage(
      updates: updates,
      page: number('page', page),
      limit: number('limit', limit),
      total: number('total', updates.length),
      totalPages: number('totalPages', 1),
    );
  }

  /// Fetches paginated tasks from `GET /api/hr/tasks`.
  static Future<TaskPage> getTasksPage({
    int page = 1,
    int limit = 50,
    String? status,
    String? department,
    String? employeeId,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status.trim().isNotEmpty && status != 'all')
        'status': status.trim().toLowerCase(),
      if (department != null &&
          department.trim().isNotEmpty &&
          department != 'all')
        'department': department.trim(),
      if (employeeId != null && employeeId.trim().isNotEmpty)
        'employeeId': employeeId.trim(),
    };

    final uri = Uri.parse('$baseUrl/api/hr/tasks')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await client.get(uri, headers: _headers());

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(
            decoded['message']?.toString() ?? 'Failed to fetch tasks');
      }

      final rawList = decoded['data'];
      final List<Task> tasks = [];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            tasks.add(Task.fromJson(item));
          }
        }
      }

      final pagination = decoded['pagination'] is Map<String, dynamic>
          ? decoded['pagination'] as Map<String, dynamic>
          : <String, dynamic>{};

      final p = pagination['page'] is num
          ? (pagination['page'] as num).toInt()
          : page;
      final l = pagination['limit'] is num
          ? (pagination['limit'] as num).toInt()
          : limit;
      final t = pagination['total'] is num
          ? (pagination['total'] as num).toInt()
          : tasks.length;
      final tp = pagination['totalPages'] is num
          ? (pagination['totalPages'] as num).toInt()
          : 1;

      return TaskPage(
        tasks: tasks,
        page: p,
        limit: l,
        total: t,
        totalPages: tp,
      );
    }

    final message = decoded['message']?.toString() ??
        'Failed to fetch tasks (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Fetches single task details from `GET /api/hr/tasks/:id`.
  static Future<Task> getTaskDetails(String id) async {
    final cleanId = Uri.encodeComponent(id.trim());
    final response = await client.get(
      Uri.parse('$baseUrl/api/hr/tasks/$cleanId'),
      headers: _headers(),
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(
            decoded['message']?.toString() ?? 'Failed to fetch task details');
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Task.fromJson(data);
      }
      throw const FormatException('Task detail data is malformed');
    }

    final message = decoded['message']?.toString() ??
        'Failed to fetch task details (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Creates a new assigned task via `POST /api/hr/tasks`.
  static Future<Task> createTask({
    required String staffId,
    required String description,
    required String dueDate,
    String? department,
    String? title,
  }) async {
    final body = <String, dynamic>{
      'staffId': staffId.trim(),
      'description': description.trim(),
      'dueDate': dueDate.trim(),
      if (department != null && department.trim().isNotEmpty)
        'department': department.trim(),
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
    };

    final response = await client.post(
      Uri.parse('$baseUrl/api/hr/tasks'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(
            decoded['message']?.toString() ?? 'Failed to create task');
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Task.fromJson(data);
      }
      throw const FormatException('Created task data is malformed');
    }

    final message = decoded['message']?.toString() ??
        'Failed to create task (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Updates task fields or status via `PUT /api/hr/tasks/:id`.
  static Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    String? dueDate,
    String? status,
    String? department,
    String? staffId,
  }) async {
    final cleanId = Uri.encodeComponent(id.trim());
    final body = <String, dynamic>{
      if (title != null) 'title': title.trim(),
      if (description != null) 'description': description.trim(),
      if (dueDate != null) 'dueDate': dueDate.trim(),
      if (status != null) 'status': status.trim().toLowerCase(),
      if (department != null) 'department': department.trim(),
      if (staffId != null) 'staffId': staffId.trim(),
    };

    final response = await client.put(
      Uri.parse('$baseUrl/api/hr/tasks/$cleanId'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(
            decoded['message']?.toString() ?? 'Failed to update task');
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Task.fromJson(data);
      }
      throw const FormatException('Updated task data is malformed');
    }

    final message = decoded['message']?.toString() ??
        'Failed to update task (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  /// Soft deletes a task via `DELETE /api/hr/tasks/:id`.
  static Future<bool> deleteTask(String id) async {
    final cleanId = Uri.encodeComponent(id.trim());
    final response = await client.delete(
      Uri.parse('$baseUrl/api/hr/tasks/$cleanId'),
      headers: _headers(),
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const FormatException(
          'Invalid JSON response received from server.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response envelope from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = decoded['success'] == true;
      if (!success) {
        throw Exception(
            decoded['message']?.toString() ?? 'Failed to delete task');
      }
      return true;
    }

    final message = decoded['message']?.toString() ??
        'Failed to delete task (HTTP ${response.statusCode})';
    throw Exception(message);
  }

  static Future<List<DailyUpdate>> getDailyUpdates({String? employeeId, String? department, String? date}) async {
    final queryParams = <String, String>{};
    if (employeeId != null && employeeId.isNotEmpty) queryParams['employeeId'] = employeeId;
    if (department != null && department.isNotEmpty) queryParams['department'] = department;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;

    final uri = Uri.parse('$baseUrl/api/hr/daily-updates').replace(
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

/// Thrown when the server responds with HTTP 403 for a deletion request.
class DeletionPermissionException implements Exception {
  final String message;
  const DeletionPermissionException(this.message);
  @override
  String toString() => message;
}
