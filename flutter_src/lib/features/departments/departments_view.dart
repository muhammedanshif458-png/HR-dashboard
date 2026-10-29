import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../models/department.dart';
import '../../models/staff.dart';
import '../../core/department_helper.dart';
import '../../widgets/header.dart';
import '../../widgets/sidebar.dart';

class DepartmentsView extends StatelessWidget {
  const DepartmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();

    return Scaffold(
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LY SOFTWARE • ORGANIZATIONAL UNITS',
                        style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                      SizedBox(height: 6),
                      Text('Departments & Headcount',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A))),
                      SizedBox(height: 4),
                      Text(
                          'Manage organizational structure, division leads, and active staff distributions.',
                          style: TextStyle(
                              color: Color(0xFF64748B), fontSize: 14)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: hrProvider.isDepartmentsLoading
                      ? null
                      : () => hrProvider.fetchDepartments(),
                  icon: hrProvider.isDepartmentsLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Content: Loading, Error, Empty, or Department Cards Grid
            _buildContent(context, hrProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HRProvider hrProvider) {
    // 1. Loading State (initial or empty list loading)
    if (hrProvider.isDepartmentsLoading && hrProvider.departments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading organizational units...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Full Error State (failed to fetch and no cached data)
    if (hrProvider.departmentsError != null && hrProvider.departments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              const Text(
                'Failed to load departments',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                hrProvider.departmentsError!,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => hrProvider.fetchDepartments(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty State (no departments found)
    if (hrProvider.departments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.domain_disabled_rounded,
                  size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Text(
                'No departments found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'There are currently no organizational units registered.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => hrProvider.fetchDepartments(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Populated Department Cards Grid
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Non-fatal warning if error occurred while using cached/fallback departments
        if (hrProvider.departmentsError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sync warning: Failed to refresh departments from server (${hrProvider.departmentsError}).',
                    style:
                        const TextStyle(color: Color(0xFF92400E), fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => hrProvider.fetchDepartments(),
                  child: const Text('Retry',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E))),
                ),
              ],
            ),
          ),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (isWide) {
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: hrProvider.departments.map((dept) {
                  final cardWidth = (constraints.maxWidth - 20) / 2;
                  return SizedBox(
                    width: cardWidth,
                    child: _buildDeptCard(
                      context: context,
                      hrProvider: hrProvider,
                      dept: dept,
                      unreadCount:
                          hrProvider.getDepartmentUnreadCount(dept.deptKey),
                      onViewStaff: () => hrProvider.navigateToEmployees(
                          deptFilter: DepartmentHelper.toSupportedCanonicalName(dept.title)),
                      onChat: () =>
                          hrProvider.navigateToDepartmentChat(dept.deptKey),
                      onTap: () => _showDepartmentDetailDialog(
                          context, hrProvider, dept),
                    ),
                  );
                }).toList(),
              );
            } else {
              return Column(
                children: hrProvider.departments.map((dept) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildDeptCard(
                      context: context,
                      hrProvider: hrProvider,
                      dept: dept,
                      unreadCount:
                          hrProvider.getDepartmentUnreadCount(dept.deptKey),
                      onViewStaff: () => hrProvider.navigateToEmployees(
                          deptFilter: DepartmentHelper.toSupportedCanonicalName(dept.title)),
                      onChat: () =>
                          hrProvider.navigateToDepartmentChat(dept.deptKey),
                      onTap: () => _showDepartmentDetailDialog(
                          context, hrProvider, dept),
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildDeptCard({
    required BuildContext context,
    required HRProvider hrProvider,
    required Department dept,
    required VoidCallback onViewStaff,
    required VoidCallback onChat,
    required VoidCallback onTap,
    int unreadCount = 0,
  }) {
    final color = dept.color;
    final icon = dept.icon;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: color.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dept.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(dept.subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'View Department Details',
                    child: Icon(Icons.info_outline_rounded,
                        size: 20, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat('Total Members', dept.staffCount.toString()),
                  _buildStat('Active Staff', dept.activeCount.toString()),
                  _buildStat('Unit Status', 'Active Operations'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dept.leadName.isNotEmpty
                          ? dept.leadName
                          : 'Division Lead Unassigned',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewStaff,
                      icon: const Icon(Icons.people_outline, size: 16),
                      label: const Text('View Staff'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onChat,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 16),
                          if (unreadCount > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: Text(
                        unreadCount > 0 ? 'Chat ($unreadCount)' : 'Open Chat',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
      ],
    );
  }

  /// Displays the Department Detail view populated from `GET /api/hr/departments/:deptKey`.
  void _showDepartmentDetailDialog(
      BuildContext context, HRProvider hrProvider, Department initialDept) {
    // Initiate detail fetch using the deptKey
    hrProvider.fetchDepartmentDetail(initialDept.deptKey);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer<HRProvider>(
          builder: (context, provider, child) {
            final dept = provider.selectedDepartmentDetail ?? initialDept;
            final color = dept.color;
            final icon = dept.icon;
            final isLoading = provider.isDepartmentDetailLoading;
            final error = provider.departmentDetailError;

            // Find matching staff members in staff directory
            final staffSource = provider.employeeDirectory.isNotEmpty
                ? provider.employeeDirectory
                : provider.staffList;
            final members = staffSource.where((Staff s) {
              final sDept = s.department.toLowerCase();
              final dKey = dept.deptKey.toLowerCase();
              final dTitle = dept.title.toLowerCase();
              return sDept == dKey ||
                  sDept == dTitle ||
                  dKey.contains(sDept) ||
                  sDept.contains(dKey);
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 580, maxHeight: 680),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dept.title,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        'deptKey: ${dept.deptKey}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dept.subtitle,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(),
                        ),
                      if (error != null)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Live detail sync notice: $error',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFFB91C1C)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Lead & Stats
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 6),
                                const Text(
                                  'Unit Lead: ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569)),
                                ),
                                Expanded(
                                  child: Text(
                                    dept.leadName.isNotEmpty
                                        ? dept.leadName
                                        : 'Unassigned',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStat('Total Members',
                                    dept.staffCount.toString()),
                                _buildStat('Active Staff',
                                    dept.activeCount.toString()),
                                _buildStat('Operational Status', 'Active'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Staff Members List in this unit
                      Text(
                        'Assigned Team Members (${members.length})',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: members.isEmpty
                            ? Center(
                                child: Text(
                                  'No staff members assigned to this department yet.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: members.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final staff = members[index];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          color.withValues(alpha: 0.15),
                                      child: Text(
                                        staff.name.isNotEmpty
                                            ? staff.name[0]
                                            : '?',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: color),
                                      ),
                                    ),
                                    title: Text(staff.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                        '${staff.role} • ${staff.designation}',
                                        style: const TextStyle(fontSize: 11)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: staff.status == 'active'
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        staff.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: staff.status == 'active'
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Dialog Actions
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              provider.navigateToEmployees(
                                  deptFilter: DepartmentHelper
                                      .toSupportedCanonicalName(dept.title));
                            },
                            icon: const Icon(Icons.people_outline, size: 16),
                            label: const Text('View in Staff Directory'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              provider.navigateToDepartmentChat(dept.deptKey);
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
                                size: 16),
                            label: const Text('Department Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
