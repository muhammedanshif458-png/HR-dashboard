import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../models/hr_models.dart';
import '../../core/department_helper.dart';
import '../../widgets/header.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/medical_document_preview_dialog.dart';
import '../../utils/file_download_helper.dart';

class LeaveManagementView extends StatefulWidget {
  const LeaveManagementView({super.key});

  @override
  State<LeaveManagementView> createState() => _LeaveManagementViewState();
}

class _LeaveManagementViewState extends State<LeaveManagementView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hrProvider = context.read<HRProvider>();
      if (!hrProvider.hasLoadedApiLeaves && !hrProvider.isLeavesLoading) {
        hrProvider.loadLeaves();
      }
      if (!hrProvider.hasLoadedLeaveMetrics) {
        hrProvider.fetchLeaveMetrics();
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
    final leaves = hrProvider.filteredLeaveRequests;

    return Scaffold(
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              eyebrow: 'LY Software • Workforce Operations',
              title: 'Leave Management',
              subtitle:
                  'Review employee leave applications, verify medical proofs, and manage decisions.',
              trailing: ElevatedButton.icon(
                onPressed: hrProvider.isLeavesLoading
                    ? null
                    : () => hrProvider.loadLeaves(),
                icon: hrProvider.isLeavesLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(
                    hrProvider.isLeavesLoading ? 'Syncing...' : 'Refresh Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            if (hrProvider.hasLoadedApiLeaves) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done, size: 14, color: Color(0xFF059669)),
                    SizedBox(width: 6),
                    Text(
                      'Live Server Leave Management Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (hrProvider.leavesError != null &&
                hrProvider.hasLoadedApiLeaves) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sync warning: ${hrProvider.leavesError}',
                        style: const TextStyle(
                            color: Color(0xFF991B1B), fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => hrProvider.loadLeaves(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Summary Counters
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 800
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: MetricCard(
                        label: 'Pending Requests',
                        value: hrProvider.pendingLeavesCount,
                        icon: Icons.hourglass_top,
                        tone: 'amber',
                        isActive: hrProvider.leaveStatusFilter == 'Pending',
                        onClick: () => hrProvider.setLeaveStatusFilter(
                          hrProvider.leaveStatusFilter == 'Pending'
                              ? 'all'
                              : 'Pending',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: MetricCard(
                        label: 'Approved Leaves',
                        value: hrProvider.approvedLeavesCount,
                        icon: Icons.check_circle_outline,
                        tone: 'green',
                        isActive: hrProvider.leaveStatusFilter == 'Approved',
                        onClick: () => hrProvider.setLeaveStatusFilter(
                          hrProvider.leaveStatusFilter == 'Approved'
                              ? 'all'
                              : 'Approved',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: MetricCard(
                        label: 'Rejected Leaves',
                        value: hrProvider.rejectedLeavesCount,
                        icon: Icons.cancel_outlined,
                        tone: 'red',
                        isActive: hrProvider.leaveStatusFilter == 'Rejected',
                        onClick: () => hrProvider.setLeaveStatusFilter(
                          hrProvider.leaveStatusFilter == 'Rejected'
                              ? 'all'
                              : 'Rejected',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: MetricCard(
                        label: 'On Leave Today',
                        value: hrProvider.onLeaveTodayCount,
                        icon: Icons.beach_access,
                        tone: 'blue',
                        isActive: hrProvider.leaveFilterOnLeaveToday,
                        onClick: () =>
                            hrProvider.toggleLeaveFilterOnLeaveToday(),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Filters Card
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
                    // Search Input
                    SizedBox(
                      width: 280,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search employee, reason...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    hrProvider.setLeaveSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        onChanged: (val) => hrProvider.setLeaveSearchQuery(val),
                      ),
                    ),

                    // Department Filter
                    Builder(builder: (context) {
                      final deptData = DepartmentHelper.buildFilterDropdown(
                        currentValue: hrProvider.leaveDeptFilter,
                        departments: hrProvider.departments,
                      );
                      return SizedBox(
                        width: 190,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('leave_dept_${deptData.value}'),
                          isExpanded: true,
                          initialValue: deptData.value,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            labelText: 'Department',
                          ),
                          items: deptData.items,
                          onChanged: (val) {
                            if (val != null) hrProvider.setLeaveDeptFilter(val);
                          },
                        ),
                      );
                    }),

                    // Leave Type Filter
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: () {
                          if (hrProvider.leaveTypeFilter == 'Sick') {
                            return 'Sick Leave';
                          }
                          if (hrProvider.leaveTypeFilter == 'Medical') {
                            return 'Medical Leave';
                          }
                          const valid = [
                            'all',
                            'Casual',
                            'Sick Leave',
                            'Medical Leave',
                            'Earned'
                          ];
                          return valid.contains(hrProvider.leaveTypeFilter)
                              ? hrProvider.leaveTypeFilter
                              : 'all';
                        }(),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          labelText: 'Leave Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Types')),
                          DropdownMenuItem(
                              value: 'Casual', child: Text('Casual')),
                          DropdownMenuItem(
                              value: 'Sick Leave', child: Text('Sick Leave')),
                          DropdownMenuItem(
                              value: 'Medical Leave',
                              child: Text('Medical Leave')),
                          DropdownMenuItem(
                              value: 'Earned', child: Text('Earned')),
                        ],
                        onChanged: (val) {
                          if (val != null) hrProvider.setLeaveTypeFilter(val);
                        },
                      ),
                    ),

                    // Date Pickers
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2028),
                          initialDateRange: hrProvider.leaveStartDate != null &&
                                  hrProvider.leaveEndDate != null
                              ? DateTimeRange(
                                  start: hrProvider.leaveStartDate!,
                                  end: hrProvider.leaveEndDate!)
                              : null,
                        );
                        if (picked != null) {
                          hrProvider.setLeaveDateRange(
                              picked.start, picked.end);
                        }
                      },
                      icon: const Icon(Icons.date_range, size: 16),
                      label: Text(
                        hrProvider.leaveStartDate != null &&
                                hrProvider.leaveEndDate != null
                            ? '${hrProvider.leaveStartDate!.toIso8601String().split('T')[0]} - ${hrProvider.leaveEndDate!.toIso8601String().split('T')[0]}'
                            : 'Date Range',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),

                    // Reset Filters Button
                    if (hrProvider.leaveSearchQuery.isNotEmpty ||
                        hrProvider.leaveStatusFilter != 'all' ||
                        hrProvider.leaveDeptFilter != 'all' ||
                        hrProvider.leaveTypeFilter != 'all' ||
                        hrProvider.leaveStartDate != null ||
                        hrProvider.leaveFilterOnLeaveToday)
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          hrProvider.setLeaveSearchQuery('');
                          hrProvider.setLeaveStatusFilter('all');
                          hrProvider.setLeaveDeptFilter('all');
                          hrProvider.setLeaveTypeFilter('all');
                          hrProvider.setLeaveDateRange(null, null);
                        },
                        icon: const Icon(Icons.filter_alt_off, size: 16),
                        label: const Text('Reset Filters'),
                      ),

                    // ── Bulk-select entry / exit ──────────────────────────
                    if (_canBulkDelete(hrProvider))
                      OutlinedButton.icon(
                        key: const ValueKey('leave_select_btn'),
                        onPressed: () =>
                            hrProvider.setLeaveBulkSelectMode(true),
                        icon:
                            const Icon(Icons.checklist_rtl_outlined, size: 16),
                        label: const Text('Select'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(color: Color(0xFF7C3AED)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Bulk-Selection Toolbar ─────────────────────────────────────
            if (hrProvider.isLeaveBulkSelectMode)
              _buildBulkToolbar(context, hrProvider, leaves),

            // Leaves Table / List
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: hrProvider.isLeavesLoading && leaves.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(64.0),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading leave requests...',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  : hrProvider.leavesError != null &&
                          !hrProvider.hasLoadedApiLeaves
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 54, color: Color(0xFFEF4444)),
                              const SizedBox(height: 12),
                              Text(
                                'Failed to load leave records: ${hrProvider.leavesError}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Check server connectivity or authentication.',
                                style: TextStyle(
                                    color: Color(0xFF64748B), fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => hrProvider.loadLeaves(),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : leaves.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(48.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 54, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No leave requests found',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try adjusting your search criteria or status filter.',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () => hrProvider.loadLeaves(),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Refresh'),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    horizontalMargin: 20,
                                    columnSpacing: 24,
                                    columns: [
                                      if (hrProvider.isLeaveBulkSelectMode)
                                        DataColumn(
                                          label: Checkbox(
                                            key: const ValueKey(
                                                'leave_select_all_checkbox'),
                                            tristate: true,
                                            value: _selectAllCheckboxValue(
                                                hrProvider, leaves),
                                            onChanged: (_) =>
                                                _onSelectAllChanged(
                                                    hrProvider, leaves),
                                          ),
                                        ),
                                      const DataColumn(
                                          label: Text('Employee',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const DataColumn(
                                          label: Text('Department',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const DataColumn(
                                          label: Text('Leave Type',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const DataColumn(
                                          label: Text('Duration',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const DataColumn(
                                          label: Text('Dates',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const DataColumn(
                                          label: Text('Reason',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const DataColumn(
                                          label: Text('Medical Proof',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const DataColumn(
                                          label: Text('Status',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const DataColumn(
                                          label: Text('Actions',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ],
                                    rows: leaves.map((leave) {
                                      return _buildLeaveRow(
                                          context, leave, hrProvider);
                                    }).toList(),
                                  ),
                                ),
                                if (hrProvider.hasLoadedApiLeaves &&
                                    hrProvider.leavesTotalPages > 0) ...[
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          () {
                                            final pageStart = (hrProvider.leavesPage - 1) * hrProvider.leavesLimit;
                                            final pageRows = hrProvider.apiLeaveRecords.length;
                                            final fromRow = pageRows == 0 ? 0 : pageStart + 1;
                                            final toRow = pageStart + pageRows;
                                            return 'Showing $fromRow to $toRow of ${hrProvider.leavesTotal} records';
                                          }(),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B)),
                                        ),
                                        Row(
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: hrProvider.leavesPage >
                                                          1 &&
                                                      !hrProvider
                                                          .isLeavesLoading
                                                  ? () => hrProvider
                                                      .setLeavesPage(hrProvider
                                                              .leavesPage -
                                                          1)
                                                  : null,
                                              icon: const Icon(
                                                  Icons.chevron_left,
                                                  size: 16),
                                              label: const Text('Previous'),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Page ${hrProvider.leavesPage} of ${hrProvider.leavesTotalPages > 0 ? hrProvider.leavesTotalPages : 1}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              onPressed: hrProvider.leavesPage <
                                                          hrProvider
                                                              .leavesTotalPages &&
                                                      !hrProvider
                                                          .isLeavesLoading
                                                  ? () => hrProvider
                                                      .setLeavesPage(hrProvider
                                                              .leavesPage +
                                                          1)
                                                  : null,
                                              icon: const Icon(
                                                  Icons.chevron_right,
                                                  size: 16),
                                              label: const Text('Next'),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildLeaveRow(
      BuildContext context, LeaveRequest leave, HRProvider hrProvider) {
    // Leave Type color
    Color typeColor = Colors.blue;
    if (leave.isMedical) {
      typeColor = Colors.purple;
    } else if (leave.isSick) {
      typeColor = const Color(0xFFD97706);
    } else if (leave.leaveType == 'Earned' || leave.leaveType == 'Earned Leave') {
      typeColor = Colors.teal;
    }

    // Status color
    Color statusColor = const Color(0xFFF59E0B); // Amber for Pending
    if (leave.status == 'Approved') {
      statusColor = const Color(0xFF10B981); // Green
    } else if (leave.status == 'Rejected') {
      statusColor = const Color(0xFFEF4444); // Red
    }

    return DataRow(
      selected: hrProvider.isLeaveBulkSelectMode &&
          hrProvider.selectedLeaveIds.contains(leave.id),
      onSelectChanged: hrProvider.isLeaveBulkSelectMode
          ? (_) => hrProvider.toggleLeaveSelection(leave.id)
          : null,
      cells: [
        // Checkbox cell (only in bulk-select mode)
        if (hrProvider.isLeaveBulkSelectMode)
          DataCell(
            Checkbox(
              value: hrProvider.selectedLeaveIds.contains(leave.id),
              onChanged: (_) => hrProvider.toggleLeaveSelection(leave.id),
            ),
          ),
        // Employee
        DataCell(
          InkWell(
            onTap: () => hrProvider.viewStaffProfile(leave.staffId),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    leave.employeeName.isNotEmpty ? leave.employeeName[0] : 'U',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      leave.employeeName.isNotEmpty
                          ? leave.employeeName
                          : 'Staff ID: ${leave.staffId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB)),
                    ),
                    if (leave.employeeEmail.isNotEmpty)
                      Text(leave.employeeEmail,
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
              color: leave.department == 'Tech'
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              leave.department.isNotEmpty ? leave.department : 'General',
              style: TextStyle(
                color: leave.department == 'Tech'
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFDB2777),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Leave Type
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  leave.isMedical
                      ? Icons.medical_services_outlined
                      : (leave.isSick
                          ? Icons.healing_outlined
                          : Icons.calendar_today),
                  size: 12,
                  color: typeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  leave.leaveType,
                  style: TextStyle(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        // Duration in Days
        DataCell(
          Text(
            '${leave.calculatedDays} ${leave.calculatedDays == 1 ? 'day' : 'days'}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),

        // Dates
        DataCell(
          Text(
            leave.formattedDateRange,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),
        ),

        // Reason
        DataCell(
          Tooltip(
            message: leave.reason.trim().isNotEmpty
                ? leave.reason.trim()
                : 'No reason provided',
            waitDuration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
            child: InkWell(
              onTap: () => _showLeaveDetailsModal(context, leave, hrProvider),
              borderRadius: BorderRadius.circular(4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  leave.reason.trim().isNotEmpty ? leave.reason.trim() : '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF475569)),
                ),
              ),
            ),
          ),
        ),

        // Medical Proof Badge
        DataCell(
          _buildMedicalProofBadge(leave),
        ),

        // Status Badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  leave.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),

        // Actions
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined,
                    size: 18, color: Color(0xFF2563EB)),
                tooltip: 'View Details & Proof',
                onPressed: () =>
                    _showLeaveDetailsModal(context, leave, hrProvider),
              ),
              if (leave.status == 'Pending') ...[
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: hrProvider.isProcessingAction
                      ? null
                      : () => _showApproveDialog(context, leave, hrProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Approve',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: hrProvider.isProcessingAction
                      ? null
                      : () => _showRejectDialog(context, leave, hrProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Reject',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalProofBadge(LeaveRequest leave) {
    if (!leave.isMedical) {
      if (leave.isSick && leave.hasMedicalProof) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 12, color: Color(0xFF059669)),
              SizedBox(width: 4),
              Text(
                'Proof Attached',
                style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }
      return const Text('—', style: TextStyle(color: Colors.grey));
    }
    if (leave.hasMedicalProof) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 12, color: Color(0xFF059669)),
            SizedBox(width: 4),
            Text(
              'Proof Attached',
              style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 12, color: Color(0xFFDC2626)),
            SizedBox(width: 4),
            Text(
              'No Document',
              style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
  }

  // --- Leave Request Details & Medical Proof Modal ---
  void _showLeaveDetailsModal(
      BuildContext context, LeaveRequest leave, HRProvider hrProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description,
                      color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Leave Request Details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('LY SOFTWARE Human Resources Verification',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),

                // Employee & Department Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        leave.employeeName.isNotEmpty
                            ? leave.employeeName[0]
                            : 'U',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.employeeName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A)),
                          ),
                          Text(leave.employeeEmail,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text('Department: ${leave.department}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              Text('Type: ${leave.leaveType}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: leave.status == 'Approved'
                            ? const Color(0xFFECFDF5)
                            : (leave.status == 'Rejected'
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFFFFBEB)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: leave.status == 'Approved'
                              ? const Color(0xFFA7F3D0)
                              : (leave.status == 'Rejected'
                                  ? const Color(0xFFFECACA)
                                  : const Color(0xFFFDE68A)),
                        ),
                      ),
                      child: Text(
                        leave.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: leave.status == 'Approved'
                              ? const Color(0xFF059669)
                              : (leave.status == 'Rejected'
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFD97706)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Timing & Duration details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailStat('Start Date', leave.formattedFromDate),
                      _buildDetailStat('End Date', leave.formattedToDate),
                      _buildDetailStat('Total Days',
                          '${leave.calculatedDays} ${leave.calculatedDays == 1 ? 'day' : 'days'}'),
                      _buildDetailStat(
                          'Submitted On',
                          LeaveRequest.formatLeaveDate(
                              leave.submissionDate.isNotEmpty
                                  ? leave.submissionDate
                                  : leave.fromDate)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Reason section
                const Text('Employee Reason',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    leave.reason.trim().isNotEmpty
                        ? '"${leave.reason.trim()}"'
                        : 'No reason provided',
                    style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF1E293B),
                        height: 1.4),
                  ),
                ),

                // HR Remarks / Rejection Reason
                if (leave.rejectionReason != null &&
                    leave.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('HR Remarks / Rejection Note',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFFDC2626))),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      leave.rejectionReason!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],

                // Medical Proof Section
                if (leave.isMedical) ...[
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.medical_services,
                          size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text('Medical Document & Supporting Evidence',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (leave.hasMedicalProof)
                    _buildMedicalProofViewer(context, leave)
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Color(0xFFD97706), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No medical certificate or supporting document was uploaded by the employee for this medical request.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ] else if (leave.hasMedicalProof) ...[
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.attach_file,
                          size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text('Supporting Evidence / Attachment',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildMedicalProofViewer(context, leave),
                ],
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          if (leave.status == 'Pending') ...[
            ElevatedButton.icon(
              onPressed: hrProvider.isProcessingAction
                  ? null
                  : () {
                      Navigator.pop(dialogCtx);
                      _showRejectDialog(context, leave, hrProvider);
                    },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: hrProvider.isProcessingAction
                  ? null
                  : () {
                      Navigator.pop(dialogCtx);
                      _showApproveDialog(context, leave, hrProvider);
                    },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalProofViewer(BuildContext context, LeaveRequest leave) {
    final fileName = leave.medicalProofFileName ?? 'medical_certificate.jpg';
    final isPdf = leave.medicalProofFileType == 'application/pdf' ||
        fileName.endsWith('.pdf');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isPdf ? Icons.picture_as_pdf : Icons.image,
                  color: isPdf ? Colors.red : Colors.blue, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text(
                        'Confidential medical record • Authorized HR access only',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Security Notice Banner
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: Color(0xFF2563EB)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Protected medical record. Document access is authenticated via Bearer token and restricted to HR Managers.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Document preview / action buttons
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('leave_medical_proof_preview_button'),
                onPressed: () {
                  _showDocumentViewerDialog(context,
                      title: fileName, isPdf: isPdf, leave: leave);
                },
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                label: Text(isPdf
                    ? 'Preview Medical PDF'
                    : 'Preview Medical Certificate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('leave_medical_proof_download_button'),
                onPressed: () => _downloadMedicalProof(context, leave),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download Certificate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF99F6E4)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDocumentViewerDialog(BuildContext context,
      {required String title,
      required bool isPdf,
      required LeaveRequest leave}) {
    MedicalDocumentPreviewDialog.show(
      context,
      leave: leave,
      provider: context.read<HRProvider>(),
    );
  }

  Future<void> _downloadMedicalProof(
      BuildContext context, LeaveRequest leave) async {
    final docUrlOrId = leave.medicalProofUrl ?? leave.id;
    if (docUrlOrId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No medical document reference found for this leave.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final hrProvider = context.read<HRProvider>();
    final fileName = leave.medicalProofFileName ?? 'medical_certificate.pdf';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "$fileName"...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final downloaded = await hrProvider.fetchMedicalDocument(
        docUrlOrId,
        expectedFileName: leave.medicalProofFileName,
        expectedFileType: leave.medicalProofFileType,
      );

      if (!context.mounted) return;

      if (downloaded == null) {
        final err = hrProvider.employeeDocumentsError ??
            'Failed to download medical document from server.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await FileDownloadHelper.downloadFile(
        bytes: downloaded.bytes,
        fileName: fileName,
        mimeType: downloaded.contentType,
      );

      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded "$fileName" successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Approval Dialog with Leave Type and Details ---
  void _showApproveDialog(
      BuildContext context, LeaveRequest leave, HRProvider hrProvider) {
    final leaveName = leave.leaveType.toLowerCase().endsWith('leave')
        ? leave.leaveType
        : '${leave.leaveType} leave';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Color(0xFF10B981), size: 22),
            SizedBox(width: 8),
            Text('Approve Leave Request',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(builder: (context) {
              final dateSpan = leave.formattedFromDate == leave.formattedToDate
                  ? leave.formattedFromDate
                  : '${leave.formattedFromDate} to ${leave.formattedToDate}';
              return Text(
                'Are you sure you want to approve ${leave.employeeName}\'s $leaveName request ($dateSpan)?',
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await hrProvider.approveLeave(leave.id);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Leave request approved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(hrProvider.leavesError ??
                        'Failed to approve leave request'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  // --- Rejection Dialog with Mandatory/Structured Reason ---
  void _showRejectDialog(
      BuildContext context, LeaveRequest leave, HRProvider hrProvider) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final leaveName = leave.leaveType.toLowerCase().endsWith('leave')
        ? leave.leaveType
        : '${leave.leaveType} leave';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Reject Leave Request',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                final dateSpan = leave.formattedFromDate == leave.formattedToDate
                    ? leave.formattedFromDate
                    : '${leave.formattedFromDate} to ${leave.formattedToDate}';
                return Text(
                  'Please provide the reason for rejecting ${leave.employeeName}\'s $leaveName request ($dateSpan).',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                );
              }),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason / HR Remark *',
                  hintText:
                      'e.g. Critical release sprint deadline or insufficient supporting document.',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Rejection reason is required'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final reason = reasonController.text.trim();
                Navigator.pop(ctx);
                final ok = await hrProvider.rejectLeave(leave.id, reason);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Leave request rejected and employee notified.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(hrProvider.leavesError ??
                          'Failed to reject leave request'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
      ],
    );
  }

  // ── Bulk-Selection Helpers ─────────────────────────────────────────────────

  /// True only when status filter is Approved or Rejected (pending is protected).
  bool _canBulkDelete(HRProvider p) =>
      p.leaveStatusFilter == 'Approved' || p.leaveStatusFilter == 'Rejected';

  /// Returns true/false/null (tristate) for the "select all" header checkbox.
  bool? _selectAllCheckboxValue(HRProvider p, List<LeaveRequest> visible) {
    if (visible.isEmpty) return false;
    final eligibleIds = visible.map((l) => l.id).toSet();
    final selected =
        p.selectedLeaveIds.intersection(eligibleIds).length;
    if (selected == 0) return false;
    if (selected == eligibleIds.length) return true;
    return null; // indeterminate
  }

  void _onSelectAllChanged(HRProvider p, List<LeaveRequest> visible) {
    final eligibleIds = visible.map((l) => l.id).toList();
    final allSelected = _selectAllCheckboxValue(p, visible) == true;
    if (allSelected) {
      p.clearLeaveSelection();
    } else {
      p.selectAllLeaves(eligibleIds);
    }
  }

  /// Bulk-action toolbar shown between filters and the table when in selection mode.
  Widget _buildBulkToolbar(
      BuildContext context, HRProvider hrProvider, List<LeaveRequest> leaves) {
    final status = hrProvider.leaveStatusFilter; // 'Approved' or 'Rejected'
    final selectedCount = hrProvider.selectedLeaveIds
        .where((id) => leaves.any((l) => l.id == id))
        .length;
    final isDeleting = hrProvider.isBulkDeletingLeaves;

    return Container(
      key: const ValueKey('leave_bulk_toolbar'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Selection count badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$selectedCount selected',
              key: const ValueKey('leave_selected_count'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),

          // Select All
          TextButton.icon(
            onPressed: isDeleting
                ? null
                : () => _onSelectAllChanged(hrProvider, leaves),
            icon: const Icon(Icons.select_all, size: 16),
            label: const Text('Select All'),
          ),

          // Clear Selection
          if (selectedCount > 0)
            TextButton.icon(
              onPressed:
                  isDeleting ? null : () => hrProvider.clearLeaveSelection(),
              icon: const Icon(Icons.deselect, size: 16),
              label: const Text('Clear Selection'),
            ),

          const Spacer(),

          // Clear Selected button
          if (selectedCount > 0)
            ElevatedButton.icon(
              key: const ValueKey('leave_clear_selected_btn'),
              onPressed: isDeleting
                  ? null
                  : () => _confirmBulkDelete(
                      context,
                      hrProvider,
                      status,
                      selectedCount,
                      clearAll: false),
              icon: isDeleting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.delete_sweep_outlined, size: 16),
              label: Text('Clear Selected ($selectedCount)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),

          const SizedBox(width: 8),

          // Clear All — inside a menu to avoid accidental taps
          PopupMenuButton<String>(
            key: const ValueKey('leave_clear_all_menu'),
            enabled: !isDeleting,
            tooltip: 'More actions',
            onSelected: (val) {
              if (val == 'clear_all') {
                final totalCount = hrProvider.leaveStatusFilter == 'Approved'
                    ? hrProvider.approvedLeavesCount
                    : hrProvider.rejectedLeavesCount;
                _confirmBulkDelete(context, hrProvider, status, totalCount,
                    clearAll: true);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Text('Clear All $status Leaves',
                        style: const TextStyle(color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.more_vert, size: 16, color: Color(0xFF374151)),
                  SizedBox(width: 4),
                  Text('More',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF374151))),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Cancel / Exit selection mode
          OutlinedButton.icon(
            onPressed: isDeleting
                ? null
                : () => hrProvider.setLeaveBulkSelectMode(false),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before performing a bulk delete.
  void _confirmBulkDelete(
    BuildContext context,
    HRProvider hrProvider,
    String status,
    int count, {
    required bool clearAll,
  }) {
    if (count <= 0) return;
    final action = clearAll ? 'Clear All' : 'Clear Selected';
    final description = clearAll
        ? 'This will permanently delete ALL $count $status leave request(s).'
        : 'This will permanently delete the $count selected $status leave request(s).';

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever,
                  color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            Text('$action $status Leaves'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description,
                style:
                    const TextStyle(fontSize: 14, color: Color(0xFF374151))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action is permanent and cannot be undone. Pending requests are never affected.',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              bool ok;
              if (clearAll) {
                ok = await hrProvider.clearAllLeavesByStatus(status);
              } else {
                ok = await hrProvider.bulkDeleteSelectedLeaves(status);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? '$action completed successfully.'
                        : hrProvider.leavesError ??
                            'Failed to delete leave requests.'),
                    backgroundColor:
                        ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_forever, size: 16),
            label: Text('Confirm $action'),
          ),
        ],
      ),
    );
  }
}
