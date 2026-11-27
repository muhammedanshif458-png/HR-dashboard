// ═════════════════════════════════════════════════════════════════════════════
//  API LIST — HR DASHBOARD
//
//  BASE URL
//    Live (release build) : https://hrsystembackend-4xzs.onrender.com
//    Local (flutter run)  : http://localhost:5000
//    Override             : --dart-define=API_BASE_URL=...
//
//  Every backend API used by the HR dashboard, separated by category.
//  Full URL = ApiList.baseUrl + path   →   ApiList.url(EmployeeApis.byId(id))
//  `:id` style parameters are functions, e.g. LeaveApis.approve(id).
// ═════════════════════════════════════════════════════════════════════════════

import '../../core/config.dart';

/// Base URL of the backend (live on Render in release builds).
class ApiList {
  ApiList._();

  /// e.g. https://hrsystembackend-4xzs.onrender.com
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// e.g. https://hrsystembackend-4xzs.onrender.com/api
  static String get apiUrl => '$baseUrl/api';

  /// Builds a full URL from a path in this file.
  static String url(String path) => '$baseUrl$path';

  /// Builds a full Uri, with optional query parameters.
  static Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse(url(path)).replace(queryParameters: query);
}

// ─── 1. AUTHENTICATION ───────────────────────────────────────────────────────
class AuthApis {
  AuthApis._();

  /// POST — HR / Super Admin login. Body: { email, password }
  static const String login = '/api/auth/login';
}

// ─── 2. DASHBOARD ────────────────────────────────────────────────────────────
class DashboardApis {
  DashboardApis._();

  /// GET — dashboard metrics and counts
  static const String metrics = '/api/hr/dashboard';

  /// GET — today's birthdays
  static const String birthdaysToday = '/api/birthdays/today';
}

// ─── 3. EMPLOYEES ────────────────────────────────────────────────────────────
class EmployeeApis {
  EmployeeApis._();

  /// GET — list employees (search, filters, paging) | POST — create staff (email + password)
  static const String employees = '/api/hr/employees';

  /// GET — details | PUT — update | DELETE — delete
  static String byId(String id) => '/api/hr/employees/$id';

  /// PATCH — change status
  static String status(String id) => '/api/hr/employees/$id/status';

  /// PUT — update salary
  static String salary(String id) => '/api/hr/employees/$id/salary';

  /// POST — deactivate
  static String deactivate(String id) => '/api/hr/employees/$id/deactivate';

  /// POST — reactivate
  static String reactivate(String id) => '/api/hr/employees/$id/reactivate';

  /// POST — mark as resigned
  static String resign(String id) => '/api/hr/employees/$id/resign';
}

// ─── 4. DEPARTMENTS ──────────────────────────────────────────────────────────
class DepartmentApis {
  DepartmentApis._();

  /// GET — departments with counts
  static const String departments = '/api/hr/departments';

  /// GET — department details
  static String byKey(String deptKey) => '/api/hr/departments/$deptKey';
}

// ─── 5. ATTENDANCE ───────────────────────────────────────────────────────────
class AttendanceApis {
  AttendanceApis._();

  /// GET — all attendance records
  static const String attendance = '/api/hr/attendance';

  /// GET — attendance of one employee
  static String byEmployee(String employeeId) => '/api/hr/attendance/$employeeId';

  /// GET — checked-out count
  static const String checkedOutCount = '/api/hr/attendance/checked-out/count';

  /// POST — staff check-in (staff portal view)
  static const String staffCheckIn = '/api/staff/attendance/check-in';

  /// POST — staff check-out (staff portal view)
  static const String staffCheckOut = '/api/staff/attendance/check-out';
}

// ─── 6. LEAVES ───────────────────────────────────────────────────────────────
class LeaveApis {
  LeaveApis._();

  /// GET — leave requests | DELETE — bulk delete
  static const String leaves = '/api/hr/leaves';

  /// DELETE — clear all leaves
  static const String all = '/api/hr/leaves/all';

  /// GET — leave details
  static String byId(String id) => '/api/hr/leaves/$id';

  /// PUT — approve leave
  static String approve(String id) => '/api/hr/leaves/$id/approve';

  /// PUT — reject leave
  static String reject(String id) => '/api/hr/leaves/$id/reject';
}

// ─── 7. DOCUMENTS ────────────────────────────────────────────────────────────
class DocumentApis {
  DocumentApis._();

  /// GET — employee documents | POST — upload document (multipart)
  static String employeeDocuments(String employeeId) => '/api/hr/employees/$employeeId/documents';

  /// GET — document details | PUT — replace document
  static String byId(String docId) => '/api/hr/documents/$docId';

  /// GET — download / preview
  static String download(String docId) => '/api/hr/documents/$docId/download';

  /// PATCH — archive document
  static String archive(String docId) => '/api/hr/documents/$docId/archive';
}

// ─── 8. TASKS ────────────────────────────────────────────────────────────────
class TaskApis {
  TaskApis._();

  /// GET — list tasks | POST — create task
  static const String tasks = '/api/hr/tasks';

  /// GET — details | PUT — update | DELETE — delete
  static String byId(String id) => '/api/hr/tasks/$id';
}

// ─── 9. DAILY UPDATES ────────────────────────────────────────────────────────
class DailyUpdateApis {
  DailyUpdateApis._();

  /// GET — staff daily updates | DELETE — bulk delete
  static const String dailyUpdates = '/api/hr/daily-updates';

  /// DELETE — clear all daily updates
  static const String all = '/api/hr/daily-updates/all';
}

// ─── 10. REPORTS ─────────────────────────────────────────────────────────────
class ReportApis {
  ReportApis._();

  /// GET — attendance report
  static const String attendance = '/api/hr/reports/attendance';

  /// GET — leaves report
  static const String leaves = '/api/hr/reports/leaves';
}

// ─── 11. DEPARTMENT CHAT ─────────────────────────────────────────────────────
class ChatApis {
  ChatApis._();

  /// GET — department messages | POST — send message
  static String messages(String deptKey) => '/api/hr/departments/$deptKey/messages';

  /// GET — search messages
  static String search(String deptKey) => '/api/hr/departments/$deptKey/messages/search';

  /// POST — clear chat
  static String clear(String deptKey) => '/api/hr/departments/$deptKey/messages/clear';

  /// DELETE — delete for everyone
  static String message(String deptKey, String messageId) =>
      '/api/hr/departments/$deptKey/messages/$messageId';

  /// PATCH — delete for me
  static String deleteForMe(String deptKey, String messageId) =>
      '/api/hr/departments/$deptKey/messages/$messageId/delete-for-me';

  // NOTE: api_service.dart also has private chat (GET/POST /api/hr/chat/messages/:participantId),
  // but the backend has no such route and no screen calls it, so it is not listed here.
}

// ─── 12. PAYROLL ─────────────────────────────────────────────────────────────
class PayrollApis {
  PayrollApis._();

  /// GET — payroll summary
  static const String summary = '/api/hr/payroll/summary';

  /// GET — employees payroll
  static const String employees = '/api/hr/payroll/employees';

  /// GET — employee payroll
  static String employee(String id) => '/api/hr/payroll/employees/$id';

  // Batches
  /// GET — payroll batches
  static const String batches = '/api/hr/payroll/batches';

  /// POST — create draft batch
  static const String draftBatch = '/api/hr/payroll/batches/draft';

  /// GET — batch details
  static String batch(String batchId) => '/api/hr/payroll/batches/$batchId';

  /// POST — finalize batch
  static String finalizeBatch(String batchId) => '/api/hr/payroll/batches/$batchId/finalize';

  /// POST — mark batch paid
  static String payBatch(String batchId) => '/api/hr/payroll/batches/$batchId/pay';

  /// GET — employee payslip from a batch
  static String payslip(String batchId, String employeeId) =>
      '/api/hr/payroll/batches/$batchId/employees/$employeeId/payslip';

  // Conflicts
  /// GET — payroll conflicts
  static const String conflicts = '/api/hr/payroll/conflicts';

  /// POST — resolve conflict
  static String resolveConflict(String conflictId) => '/api/hr/payroll/conflicts/$conflictId/resolve';

  /// POST — archive resolved conflicts
  static const String archiveResolvedConflicts = '/api/hr/payroll/conflicts/archive-resolved';

  // Salary payments
  /// GET — salary payments
  static const String payments = '/api/hr/payroll/payments';

  /// GET — payments summary
  static const String paymentsSummary = '/api/hr/payroll/payments/summary';

  /// GET — payments history
  static const String paymentsHistory = '/api/hr/payroll/payments/history';

  /// GET — payment details
  static String payment(String id) => '/api/hr/payroll/payments/$id';

  /// POST — mark payment paid
  static String markPaymentPaid(String id) => '/api/hr/payroll/payments/$id/mark-paid';
}
