// ─── lib/features/api_list/api_list.dart ────────────────────────────────────
// "API List" page for the HR dashboard: every backend API this app calls,
// grouped by category, with the live base URL at the top.
// Developer reference only: not registered as a route, so users never see it.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config.dart';

class ApiEndpoint {
  const ApiEndpoint(this.method, this.path, this.description, {this.onBackend = true});

  final String method;
  final String path;
  final String description;

  /// false when the dashboard has code for it but the backend has no such route.
  final bool onBackend;
}

class ApiCategory {
  const ApiCategory(this.name, this.icon, this.endpoints);

  final String name;
  final IconData icon;
  final List<ApiEndpoint> endpoints;
}

/// Every API the HR dashboard calls (from lib/services/api_service.dart).
const List<ApiCategory> hrApiCategories = [
  ApiCategory('Authentication', Icons.lock_outline, [
    ApiEndpoint('POST', '/api/auth/login', 'HR / Super Admin login'),
  ]),
  ApiCategory('Dashboard', Icons.dashboard_outlined, [
    ApiEndpoint('GET', '/api/hr/dashboard', 'Dashboard metrics and counts'),
    ApiEndpoint('GET', '/api/birthdays/today', "Today's birthdays"),
  ]),
  ApiCategory('Employees', Icons.people_outline, [
    ApiEndpoint('GET', '/api/hr/employees', 'List employees (search, filters, paging)'),
    ApiEndpoint('POST', '/api/hr/employees', 'Create staff with email + password'),
    ApiEndpoint('GET', '/api/hr/employees/:id', 'Employee details'),
    ApiEndpoint('PUT', '/api/hr/employees/:id', 'Update employee'),
    ApiEndpoint('PATCH', '/api/hr/employees/:id/status', 'Change status'),
    ApiEndpoint('PUT', '/api/hr/employees/:id/salary', 'Update salary'),
    ApiEndpoint('POST', '/api/hr/employees/:id/deactivate', 'Deactivate employee'),
    ApiEndpoint('POST', '/api/hr/employees/:id/reactivate', 'Reactivate employee'),
    ApiEndpoint('POST', '/api/hr/employees/:id/resign', 'Mark as resigned'),
    ApiEndpoint('DELETE', '/api/hr/employees/:id', 'Delete employee'),
  ]),
  ApiCategory('Departments', Icons.apartment_outlined, [
    ApiEndpoint('GET', '/api/hr/departments', 'Departments with counts'),
    ApiEndpoint('GET', '/api/hr/departments/:deptKey', 'Department details'),
  ]),
  ApiCategory('Attendance', Icons.access_time, [
    ApiEndpoint('GET', '/api/hr/attendance', 'All attendance records'),
    ApiEndpoint('GET', '/api/hr/attendance/:employeeId', 'Attendance of one employee'),
    ApiEndpoint('GET', '/api/hr/attendance/checked-out/count', 'Checked-out count'),
    ApiEndpoint('POST', '/api/staff/attendance/check-in', 'Staff check-in (staff portal view)'),
    ApiEndpoint('POST', '/api/staff/attendance/check-out', 'Staff check-out (staff portal view)'),
  ]),
  ApiCategory('Leaves', Icons.event_busy_outlined, [
    ApiEndpoint('GET', '/api/hr/leaves', 'Leave requests'),
    ApiEndpoint('GET', '/api/hr/leaves/:id', 'Leave details'),
    ApiEndpoint('PUT', '/api/hr/leaves/:id/approve', 'Approve leave'),
    ApiEndpoint('PUT', '/api/hr/leaves/:id/reject', 'Reject leave'),
    ApiEndpoint('DELETE', '/api/hr/leaves', 'Bulk delete leaves'),
    ApiEndpoint('DELETE', '/api/hr/leaves/all', 'Clear all leaves'),
  ]),
  ApiCategory('Documents', Icons.description_outlined, [
    ApiEndpoint('GET', '/api/hr/employees/:id/documents', 'Employee documents'),
    ApiEndpoint('POST', '/api/hr/employees/:id/documents', 'Upload document'),
    ApiEndpoint('GET', '/api/hr/documents/:docId', 'Document details'),
    ApiEndpoint('GET', '/api/hr/documents/:docId/download', 'Download / preview document'),
    ApiEndpoint('PUT', '/api/hr/documents/:docId', 'Replace document'),
    ApiEndpoint('PATCH', '/api/hr/documents/:docId/archive', 'Archive document'),
  ]),
  ApiCategory('Tasks', Icons.task_alt, [
    ApiEndpoint('GET', '/api/hr/tasks', 'List tasks'),
    ApiEndpoint('POST', '/api/hr/tasks', 'Create task'),
    ApiEndpoint('GET', '/api/hr/tasks/:id', 'Task details'),
    ApiEndpoint('PUT', '/api/hr/tasks/:id', 'Update task'),
    ApiEndpoint('DELETE', '/api/hr/tasks/:id', 'Delete task'),
  ]),
  ApiCategory('Daily Updates', Icons.edit_note, [
    ApiEndpoint('GET', '/api/hr/daily-updates', 'Staff daily updates'),
    ApiEndpoint('DELETE', '/api/hr/daily-updates', 'Bulk delete daily updates'),
    ApiEndpoint('DELETE', '/api/hr/daily-updates/all', 'Clear all daily updates'),
  ]),
  ApiCategory('Reports', Icons.bar_chart, [
    ApiEndpoint('GET', '/api/hr/reports/attendance', 'Attendance report'),
    ApiEndpoint('GET', '/api/hr/reports/leaves', 'Leaves report'),
  ]),
  ApiCategory('Department Chat', Icons.forum_outlined, [
    ApiEndpoint('GET', '/api/hr/departments/:deptKey/messages', 'Department messages'),
    ApiEndpoint('GET', '/api/hr/departments/:deptKey/messages/search', 'Search messages'),
    ApiEndpoint('POST', '/api/hr/departments/:deptKey/messages', 'Send message'),
    ApiEndpoint('POST', '/api/hr/departments/:deptKey/messages/clear', 'Clear chat'),
    ApiEndpoint('PATCH', '/api/hr/departments/:deptKey/messages/:messageId/delete-for-me', 'Delete for me'),
    ApiEndpoint('DELETE', '/api/hr/departments/:deptKey/messages/:messageId', 'Delete for everyone'),
    ApiEndpoint('GET', '/api/hr/chat/messages/:participantId', 'Private messages (unused)', onBackend: false),
    ApiEndpoint('POST', '/api/hr/chat/messages/:participantId', 'Send private message (unused)', onBackend: false),
  ]),
  ApiCategory('Payroll', Icons.payments_outlined, [
    ApiEndpoint('GET', '/api/hr/payroll/summary', 'Payroll summary'),
    ApiEndpoint('GET', '/api/hr/payroll/employees', 'Employees payroll'),
    ApiEndpoint('GET', '/api/hr/payroll/employees/:id', 'Employee payroll'),
    ApiEndpoint('POST', '/api/hr/payroll/batches/draft', 'Create draft batch'),
    ApiEndpoint('GET', '/api/hr/payroll/batches', 'Payroll batches'),
    ApiEndpoint('GET', '/api/hr/payroll/batches/:batchId', 'Batch details'),
    ApiEndpoint('POST', '/api/hr/payroll/batches/:batchId/finalize', 'Finalize batch'),
    ApiEndpoint('POST', '/api/hr/payroll/batches/:batchId/pay', 'Mark batch paid'),
    ApiEndpoint('GET', '/api/hr/payroll/batches/:batchId/employees/:employeeId/payslip', 'Employee payslip'),
    ApiEndpoint('GET', '/api/hr/payroll/conflicts', 'Payroll conflicts'),
    ApiEndpoint('POST', '/api/hr/payroll/conflicts/:conflictId/resolve', 'Resolve conflict'),
    ApiEndpoint('POST', '/api/hr/payroll/conflicts/archive-resolved', 'Archive resolved conflicts'),
    ApiEndpoint('GET', '/api/hr/payroll/payments', 'Salary payments'),
    ApiEndpoint('GET', '/api/hr/payroll/payments/summary', 'Payments summary'),
    ApiEndpoint('GET', '/api/hr/payroll/payments/history', 'Payments history'),
    ApiEndpoint('GET', '/api/hr/payroll/payments/:id', 'Payment details'),
    ApiEndpoint('POST', '/api/hr/payroll/payments/:id/mark-paid', 'Mark payment paid'),
  ]),
];

class ApiListPage extends StatefulWidget {
  const ApiListPage({super.key});

  @override
  State<ApiListPage> createState() => _ApiListPageState();
}

class _ApiListPageState extends State<ApiListPage> {
  String _query = '';

  String get _baseUrl => AppConfig.apiBaseUrl;

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Copied: $text'), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final categories = hrApiCategories
        .map((c) => ApiCategory(
              c.name,
              c.icon,
              c.endpoints
                  .where((e) =>
                      q.isEmpty ||
                      e.path.toLowerCase().contains(q) ||
                      e.method.toLowerCase().contains(q) ||
                      e.description.toLowerCase().contains(q) ||
                      c.name.toLowerCase().contains(q))
                  .toList(),
            ))
        .where((c) => c.endpoints.isNotEmpty)
        .toList();
    final total = hrApiCategories.fold<int>(0, (n, c) => n + c.endpoints.length);

    return Scaffold(
      appBar: AppBar(title: const Text('API List — HR Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BaseUrlCard(baseUrl: _baseUrl, total: total, onCopy: _copy),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search API (path, method, description)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          for (final c in categories)
            _CategoryCard(category: c, baseUrl: _baseUrl, onCopy: _copy, expanded: q.isNotEmpty),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No API matches your search.')),
            ),
        ],
      ),
    );
  }
}

class _BaseUrlCard extends StatelessWidget {
  const _BaseUrlCard({required this.baseUrl, required this.total, required this.onCopy});

  final String baseUrl;
  final int total;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Base URL', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    baseUrl,
                    style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy base URL',
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => onCopy(baseUrl),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$total APIs • full URL = Base URL + path • tap an API to copy its full URL',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.baseUrl,
    required this.onCopy,
    required this.expanded,
  });

  final ApiCategory category;
  final String baseUrl;
  final ValueChanged<String> onCopy;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('${category.name}-$expanded'),
        initiallyExpanded: expanded,
        leading: Icon(category.icon),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Chip(label: Text('${category.endpoints.length}'), visualDensity: VisualDensity.compact),
        children: [
          for (final e in category.endpoints) _EndpointTile(endpoint: e, baseUrl: baseUrl, onCopy: onCopy),
        ],
      ),
    );
  }
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({required this.endpoint, required this.baseUrl, required this.onCopy});

  final ApiEndpoint endpoint;
  final String baseUrl;
  final ValueChanged<String> onCopy;

  static const Map<String, Color> _methodColors = {
    'GET': Color(0xff16a34a),
    'POST': Color(0xff2563eb),
    'PUT': Color(0xffd97706),
    'PATCH': Color(0xff7c3aed),
    'DELETE': Color(0xffdc2626),
  };

  @override
  Widget build(BuildContext context) {
    final color = _methodColors[endpoint.method] ?? Colors.grey;
    return ListTile(
      dense: true,
      onTap: () => onCopy('$baseUrl${endpoint.path}'),
      leading: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(
          endpoint.method,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      title: Text(endpoint.path, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
      subtitle: Text(endpoint.description),
      trailing: endpoint.onBackend
          ? const Icon(Icons.copy, size: 16)
          : const Tooltip(
              message: 'The dashboard has code for this, but the backend has no such route',
              child: Chip(
                label: Text('Not on backend', style: TextStyle(fontSize: 11)),
                backgroundColor: Color(0xfffff7ed),
                visualDensity: VisualDensity.compact,
              ),
            ),
    );
  }
}
