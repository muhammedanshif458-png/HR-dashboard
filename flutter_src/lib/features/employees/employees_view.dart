import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../models/staff.dart';
import '../../core/department_helper.dart';
import '../../widgets/header.dart';
import '../../widgets/modals.dart';
import '../../widgets/sidebar.dart';

class EmployeesView extends StatefulWidget {
  const EmployeesView({super.key});

  @override
  State<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<EmployeesView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final prov = context.read<HRProvider>();
        prov.loadEmployeeDirectory(page: 1);
        if (prov.departments.isEmpty && !prov.isDepartmentsLoading) {
          prov.fetchDepartments();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final employees = hrProvider.filteredEmployeeList;

    return Scaffold(
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LY SOFTWARE • PEOPLE DIRECTORY',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Employee Directory',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'View staff members, update profiles, and manage employee employment records.',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Modals.showAddStaffModal(context),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Add Staff Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search and Filters
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search
                    SizedBox(
                      width: 280,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, department...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    hrProvider.setEmployeeSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) =>
                            hrProvider.setEmployeeSearchQuery(val),
                      ),
                    ),

                    // Department Filter
                    Builder(builder: (context) {
                      final deptDropdownData =
                          DepartmentHelper.buildFilterDropdown(
                        currentValue: hrProvider.employeeDeptFilter,
                        departments: hrProvider.departments,
                        isLoading: hrProvider.isDepartmentsLoading,
                        error: hrProvider.departmentsError,
                      );
                      return SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                              'employee_dept_filter_${deptDropdownData.value}'),
                          isExpanded: true,
                          value: deptDropdownData.value,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            labelText: 'Department',
                            suffixIcon: hrProvider.isDepartmentsLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : null,
                          ),
                          items: deptDropdownData.items,
                          onChanged: (val) {
                            if (val != null) {
                              hrProvider.setEmployeeDeptFilter(val);
                            }
                          },
                        ),
                      );
                    }),

                    // Status Filter
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(
                            'employee_status_filter_${hrProvider.employeeStatusFilter}'),
                        isExpanded: true,
                        value: const [
                          'all',
                          'active',
                          'inactive',
                          'terminated',
                          'on_leave',
                          'resigned'
                        ].contains(hrProvider.employeeStatusFilter)
                            ? hrProvider.employeeStatusFilter
                            : 'all',
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          labelText: 'Status',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Statuses')),
                          DropdownMenuItem(
                              value: 'active', child: Text('Active')),
                          DropdownMenuItem(
                              value: 'inactive', child: Text('Inactive')),
                          DropdownMenuItem(
                              value: 'terminated', child: Text('Terminated')),
                          DropdownMenuItem(
                              value: 'on_leave', child: Text('On Leave')),
                          DropdownMenuItem(
                              value: 'resigned', child: Text('Resigned')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            hrProvider.setEmployeeStatusFilter(val);
                          }
                        },
                      ),
                    ),

                    // Reset Filters
                    if (hrProvider.employeeSearchQuery.isNotEmpty ||
                        hrProvider.employeeDeptFilter != 'all' ||
                        hrProvider.employeeStatusFilter != 'all')
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          hrProvider.setEmployeeSearchQuery('');
                          hrProvider.setEmployeeDeptFilter('all');
                          hrProvider.setEmployeeStatusFilter('all');
                        },
                        icon: const Icon(Icons.filter_alt_off, size: 16),
                        label: const Text('Reset'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (hrProvider.apiStaffError.isNotEmpty && employees.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MaterialBanner(
                  content: Text(
                      'Could not refresh the directory: ${hrProvider.apiStaffError}'),
                  leading: const Icon(Icons.cloud_off_outlined),
                  actions: [
                    TextButton(
                      onPressed: () => hrProvider.loadEmployeeDirectory(),
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),

            // Employee Directory Table
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: hrProvider.isApiStaffLoading && employees.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : hrProvider.apiStaffError.isNotEmpty && employees.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(children: [
                            Text(hrProvider.apiStaffError,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  hrProvider.loadEmployeeDirectory(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ]),
                        )
                      : employees.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(48.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search,
                                      size: 54, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No employees match criteria',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                      'Try broadening your search or clear filters.',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13)),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                horizontalMargin: 20,
                                columnSpacing: 24,
                                columns: const [
                                  DataColumn(
                                      label: Text('Employee Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Department',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Designation',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Phone Number',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Monthly Salary',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Joining Date',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Status',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Work Mode',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Actions',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                                rows: employees.map((staff) {
                                  return _buildEmployeeRow(
                                      context, staff, hrProvider);
                                }).toList(),
                              ),
                            ),
            ),
            if (hrProvider.employeeTotalPages > 0) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(
                    'Page ${hrProvider.employeePage} of ${hrProvider.employeeTotalPages} · ${hrProvider.employeeTotal} employees'),
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: hrProvider.employeePage > 1 &&
                          !hrProvider.isApiStaffLoading
                      ? () => hrProvider
                          .setEmployeePage(hrProvider.employeePage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Next page',
                  onPressed:
                      hrProvider.employeePage < hrProvider.employeeTotalPages &&
                              !hrProvider.isApiStaffLoading
                          ? () => hrProvider
                              .setEmployeePage(hrProvider.employeePage + 1)
                          : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  DataRow _buildEmployeeRow(
      BuildContext context, Staff staff, HRProvider hrProvider) {
    final String statusText;
    final Color statusColor;

    if (staff.status == 'resigned') {
      statusText = 'Resigned';
      statusColor = const Color(0xFFEF4444); // Red
    } else if (staff.status == 'inactive') {
      statusText = 'Inactive';
      statusColor = const Color(0xFFF59E0B); // Amber / Orange
    } else if (staff.status == 'terminated') {
      statusText = 'Terminated';
      statusColor = const Color(0xFF64748B); // Slate / Gray
    } else if (staff.status == 'on_leave' || staff.onLeaveToday) {
      statusText = 'On Leave';
      statusColor = const Color(0xFF8B5CF6); // Purple
    } else {
      statusText = 'Active';
      statusColor = const Color(0xFF10B981); // Green
    }

    return DataRow(
      cells: [
        // Name & Email
        DataCell(
          InkWell(
            onTap: () => hrProvider.viewStaffProfile(staff.id),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    staff.name.isNotEmpty ? staff.name[0] : 'U',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(staff.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB))),
                    Text(staff.email,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Department
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: staff.department == 'Tech'
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              staff.department,
              style: TextStyle(
                color: staff.department == 'Tech'
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFDB2777),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Designation
        DataCell(Text(
            staff.designation.isNotEmpty ? staff.designation : staff.role,
            style: const TextStyle(fontSize: 12))),

        // Phone Number
        DataCell(Text(staff.phoneNumber.isNotEmpty ? staff.phoneNumber : '—',
            style: const TextStyle(fontSize: 12))),

        // Monthly Salary
        DataCell(
          InkWell(
            onTap: () => Modals.showSalaryHistoryModal(context, staff),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${staff.salaryCurrency} ${staff.salary > 0 ? staff.salary.toStringAsFixed(0) : '0'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.history, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ),

        // Joining Date
        DataCell(Text(staff.joinDate.isNotEmpty ? staff.joinDate : '—',
            style: const TextStyle(fontSize: 12))),

        // Status Badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Work Mode
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: staff.workMode == 'WFH'
                  ? const Color(0xFFF3E8FF)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              staff.workMode,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: staff.workMode == 'WFH'
                    ? const Color(0xFF7E22CE)
                    : const Color(0xFF475569),
              ),
            ),
          ),
        ),

        // Actions
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.account_circle_outlined,
                    size: 18, color: Color(0xFF2563EB)),
                tooltip: 'View Profile',
                onPressed: () => hrProvider.viewStaffProfile(staff.id),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFF475569)),
                tooltip: 'Edit Details',
                onPressed: () => Modals.showEditStaffModal(context, staff),
              ),
              IconButton(
                icon: const Icon(Icons.currency_rupee,
                    size: 18, color: Color(0xFF10B981)),
                tooltip: 'Edit Salary',
                onPressed: () => Modals.showEditSalaryModal(context, staff),
              ),
              if (staff.status == 'active')
                IconButton(
                  icon: const Icon(Icons.person_off_outlined,
                      size: 18, color: Color(0xFFF59E0B)),
                  tooltip: 'Deactivate Employee',
                  onPressed: () =>
                      _showDeactivateConfirm(context, staff, hrProvider),
                ),
              if (staff.status == 'inactive')
                IconButton(
                  icon: const Icon(Icons.how_to_reg_outlined,
                      size: 18, color: Color(0xFF10B981)),
                  tooltip: 'Reactivate Employee',
                  onPressed: () =>
                      _showReactivateConfirm(context, staff, hrProvider),
                ),
              if (hrProvider.isHRAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFFDC2626)),
                  tooltip: 'Delete Employee',
                  onPressed: () =>
                      _showDeleteConfirm(context, staff, hrProvider),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeactivateConfirm(
      BuildContext context, Staff staff, HRProvider hrProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Deactivate Employee'),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate ${staff.name}? The employee will no longer be able to log in, but their historical records will be preserved.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await hrProvider.deactivateStaff(staff.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${staff.name} has been deactivated.'),
                      backgroundColor: const Color(0xFFF59E0B),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(hrProvider.apiStaffError.isNotEmpty
                        ? hrProvider.apiStaffError
                        : 'Could not deactivate employee.'),
                  ));
                }
              }
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showReactivateConfirm(
      BuildContext context, Staff staff, HRProvider hrProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Reactivate Employee'),
          ],
        ),
        content: Text(
          'Are you sure you want to reactivate ${staff.name}? The employee account will be restored to active status and login access will be re-enabled.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await hrProvider.reactivateStaff(staff.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${staff.name} has been reactivated.'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(hrProvider.apiStaffError.isNotEmpty
                        ? hrProvider.apiStaffError
                        : 'Could not reactivate employee.'),
                  ));
                }
              }
            },
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, Staff staff, HRProvider hrProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Employee'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${staff.name}? This will remove the employee record from the directory while preserving their historical records.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await hrProvider.deleteEmployee(staff.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${staff.name} has been deleted.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(hrProvider.apiStaffError.isNotEmpty
                        ? hrProvider.apiStaffError
                        : 'Could not delete employee.'),
                  ));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
