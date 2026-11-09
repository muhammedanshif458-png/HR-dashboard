import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/hr_provider.dart';
import '../../models/hr_models.dart';
import '../../widgets/header.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/modals.dart';
import '../../widgets/page_header.dart';
import '../../services/api_service.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/birthday_section.dart';
import '../../utils/date_time_utils.dart';

class HRDashboardView extends StatefulWidget {
  const HRDashboardView({super.key});

  @override
  State<HRDashboardView> createState() => _HRDashboardViewState();
}

class _HRDashboardViewState extends State<HRDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final hrProvider = context.read<HRProvider>();
        if (!hrProvider.hasLoadedApiDashboard && ApiService.hasToken) {
          hrProvider.fetchDashboardData();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final metrics = hrProvider.dashboardMetrics;
    final pendingLeaves = hrProvider.apiLeaveRecords
        .where((r) => r.status.toLowerCase() == 'pending')
        .toList();
    final pendingResignations = hrProvider.resignationRequests
        .where((r) => r.status.toLowerCase() == 'pending')
        .toList();
    final filteredStaffList = hrProvider.filteredStaffList;

    return Scaffold(
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Intro
            PageHeader(
              eyebrow: 'LY Software • Workforce Overview',
              title: 'Team Dashboard',
              subtitle:
                  'Enterprise human resources overview, active team metrics, and daily operations.',
              trailing: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 10),
                              Text('Connecting to backend API service...'),
                            ],
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      final success = await hrProvider.fetchDashboardData();
                      if (context.mounted) {
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? '✓ Successfully synced real data from live backend.'
                                  : 'Failed to sync with backend: ${hrProvider.dashboardError ?? "Server offline"}',
                            ),
                            backgroundColor: success
                                ? const Color(0xFF10B981)
                                : const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync Real Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2457D6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            if (hrProvider.dashboardError != null)
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 20, color: Color(0xFFDC2626)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to sync with backend: ${hrProvider.dashboardError}',
                        style: const TextStyle(
                            color: Color(0xFF991B1B), fontSize: 13),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => hrProvider.fetchDashboardData(),
                      icon: const Icon(Icons.refresh,
                          size: 16, color: Color(0xFFDC2626)),
                      label: const Text('Retry',
                          style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // PRIMARY METRICS SECTION
            const Text(
              'PRIMARY METRICS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1100;
                final isMedium = constraints.maxWidth > 700;
                final isSmall = constraints.maxWidth > 500;
                final primaryCardWidth = isWide
                    ? (constraints.maxWidth - 64) / 5
                    : (isMedium
                        ? (constraints.maxWidth - 32) / 3
                        : (isSmall
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth));

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: primaryCardWidth,
                      child: MetricCard(
                        label: 'Total Staff',
                        value: metrics.totalStaff,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.badge_outlined,
                        tone: 'blue',
                        isActive: hrProvider.dashboardFilter == 'all',
                        onClick: () => hrProvider.navigateToEmployees(),
                      ),
                    ),
                    SizedBox(
                      width: primaryCardWidth,
                      child: MetricCard(
                        label: 'Active Staff',
                        value: metrics.activeStaff,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.person_outline,
                        tone: 'green',
                        isActive: hrProvider.dashboardFilter == 'active',
                        onClick: () => hrProvider.navigateToEmployees(
                            statusFilter: 'active'),
                      ),
                    ),
                    SizedBox(
                      width: primaryCardWidth,
                      child: MetricCard(
                        label: 'Present Today',
                        value: metrics.presentToday,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.how_to_reg,
                        tone: 'green',
                        isActive: hrProvider.dashboardFilter == 'present',
                        onClick: () => hrProvider.navigateToAttendance(
                            statusFilter: 'Present'),
                      ),
                    ),
                    SizedBox(
                      width: primaryCardWidth,
                      child: MetricCard(
                        label: 'Work From Home (WFH)',
                        value: metrics.todayWfh,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.home_work_outlined,
                        tone: 'slate',
                        isActive: false,
                        onClick: () => hrProvider.navigateToAttendance(
                            statusFilter: 'all', workMode: 'WFH'),
                      ),
                    ),
                    SizedBox(
                      width: primaryCardWidth,
                      child: MetricCard(
                        label: 'Pending Leaves',
                        value: metrics.pendingLeaves,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.pending_actions,
                        tone: 'amber',
                        isActive: false,
                        onClick: () => hrProvider.navigateToLeaveManagement(
                            statusFilter: 'Pending'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // SECONDARY METRICS SECTION
            const Text(
              'OPERATIONAL METRICS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1100;
                final isMedium = constraints.maxWidth > 700;
                final isSmall = constraints.maxWidth > 500;
                final secondaryCardWidth = isWide
                    ? (constraints.maxWidth - 64) / 5
                    : (isMedium
                        ? (constraints.maxWidth - 32) / 3
                        : (isSmall
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth));

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: secondaryCardWidth,
                      child: MetricCard(
                        label: 'On Leave Today',
                        value: metrics.onLeaveToday,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.beach_access_outlined,
                        tone: 'blue',
                        isActive: hrProvider.dashboardFilter == 'leave',
                        onClick: () => hrProvider.navigateToLeaveManagement(),
                      ),
                    ),
                    SizedBox(
                      width: secondaryCardWidth,
                      child: MetricCard(
                        label: 'Late Check-ins',
                        value: metrics.lateCheckIns,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.access_time_filled,
                        tone: 'amber',
                        isActive: hrProvider.dashboardFilter == 'late',
                        onClick: () => hrProvider.navigateToAttendance(
                            statusFilter: 'Late'),
                      ),
                    ),
                    SizedBox(
                      width: secondaryCardWidth,
                      child: MetricCard(
                        label: 'Not Checked In',
                        value: metrics.notCheckedIn,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.person_search_outlined,
                        tone: 'slate',
                        isActive: false,
                        onClick: () => hrProvider.navigateToAttendance(),
                      ),
                    ),
                    SizedBox(
                      width: secondaryCardWidth,
                      child: MetricCard(
                        label: 'Open Tasks',
                        value: metrics.openTasks,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.check_box_outlined,
                        tone: 'blue',
                        isActive: hrProvider.dashboardFilter == 'tasks',
                        onClick: () => hrProvider.navigateToTasks(),
                      ),
                    ),
                    SizedBox(
                      width: secondaryCardWidth,
                      child: MetricCard(
                        label: 'Resigned (30d)',
                        value: metrics.resignedLast30Days,
                        displayValue: hrProvider.metricDisplayPlaceholder,
                        icon: Icons.person_off_outlined,
                        tone: 'red',
                        isActive: hrProvider.dashboardFilter == 'resigned',
                        onClick: () => hrProvider.navigateToEmployees(
                            statusFilter: 'resigned'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // BIRTHDAY CELEBRATION SECTION
            const BirthdayCelebrationSection(isHRView: true),

            // Pending Reviews Banner
            if (pendingLeaves.isNotEmpty || pendingResignations.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fact_check,
                                size: 20, color: Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            Text(
                              'Requests Pending HR Review (${pendingLeaves.length})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => hrProvider.navigateToLeaveManagement(
                              statusFilter: 'Pending'),
                          icon: const Icon(Icons.arrow_forward,
                              size: 16, color: Color(0xFFD97706)),
                          label: const Text('Open Leave Management Screen',
                              style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pendingLeaves.map((leave) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFFEFF6FF),
                                      child: Text(
                                        leave.employeeName.isNotEmpty
                                            ? leave.employeeName[0]
                                            : 'U',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(children: [
                                          TextSpan(
                                              text: leave.employeeName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A))),
                                          TextSpan(
                                              text: leave.leaveType
                                                      .toLowerCase()
                                                      .endsWith('leave')
                                                  ? ' requested ${leave.leaveType} (${leave.fromDate} to ${leave.toDate}) - '
                                                  : ' requested ${leave.leaveType} leave (${leave.fromDate} to ${leave.toDate}) - '),
                                          TextSpan(
                                              text: '"${leave.reason}"',
                                              style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontStyle: FontStyle.italic)),
                                          if (leave.hasMedicalProof)
                                            const TextSpan(
                                                text:
                                                    ' • [Medical Proof Attached]',
                                                style: TextStyle(
                                                    color: Color(0xFF2563EB),
                                                    fontWeight:
                                                        FontWeight.bold)),
                                        ]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: hrProvider.isProcessingAction
                                        ? null
                                        : () async {
                                            final ok = await hrProvider
                                                .approveLeave(leave.id);
                                            if (ok && context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Leave approved successfully!'),
                                                    backgroundColor:
                                                        Colors.green),
                                              );
                                            }
                                          },
                                    icon: const Icon(Icons.check, size: 14),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: hrProvider.isProcessingAction
                                        ? null
                                        : () => _showQuickRejectDialog(
                                            context, leave, hrProvider),
                                    icon: const Icon(Icons.close, size: 14),
                                    label: const Text('Reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Directory Search & Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('People directory',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    SizedBox(height: 4),
                    Text('Staff members snapshot',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 250,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search staff by name, email...',
                          prefixIcon: Icon(Icons.search, size: 16),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) => hrProvider.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Modals.showAddStaffModal(context);
                      },
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Staff Member'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Staff Table Card
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: hrProvider.isApiStaffLoading && filteredStaffList.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : filteredStaffList.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'No team members found',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sync real data or clear filters.',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(
                                  label: Text('Name',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Department',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Check-in time',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Check-out',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Worked',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Break',
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
                            ],
                            rows: filteredStaffList.map((staff) {
                              final att = hrProvider.apiAttendanceRecords
                                  .where((a) =>
                                      a.matchesStaff(staff) ||
                                      (a.employeeName.isNotEmpty &&
                                          a.employeeName.toLowerCase() ==
                                              staff.name.toLowerCase()))
                                  .firstOrNull;
                              final statusLabel = staff.status == 'resigned'
                                  ? 'Resigned'
                                  : (staff.onLeaveToday
                                      ? 'On leave'
                                      : (att != null
                                          ? (att.isLate ? 'Late' : 'Present')
                                          : 'Not checked in'));
                              final statusColor = statusLabel == 'Present'
                                  ? Colors.green
                                  : (statusLabel == 'Late'
                                      ? Colors.orange
                                      : (statusLabel == 'On leave'
                                          ? Colors.purple
                                          : (statusLabel == 'Resigned'
                                              ? Colors.red
                                              : Colors.grey)));

                              return DataRow(cells: [
                                DataCell(InkWell(
                                  onTap: () =>
                                      hrProvider.viewStaffProfile(staff.id),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(staff.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB))),
                                      Text(staff.email,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                )),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(staff.department,
                                      style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12)),
                                )),
                                DataCell(Text(formatAttendanceTime(att?.checkInTime))),
                                DataCell(Text(att == null
                                    ? '—'
                                    : (att.checkOutTime != null && att.checkOutTime!.isNotEmpty && att.checkOutTime != '—'
                                        ? (att.checkOutTime == 'Active' ? 'Active' : formatAttendanceTime(att.checkOutTime))
                                        : (att.checkInTime != null && att.checkInTime!.isNotEmpty && att.checkInTime != '—' ? 'Active' : '—')))),
                                DataCell(Text(att?.workedDuration ?? '—')),
                                DataCell(Text(att?.breakDuration ?? '—')),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(statusLabel,
                                      style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                )),
                                DataCell(Text(staff.workMode,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569)))),
                              ]);
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickRejectDialog(
      BuildContext context, LeaveRequest leave, HRProvider hrProvider) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Please provide a reason for rejecting ${leave.employeeName}\'s request:'),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'HR Rejection Reason *',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Reason required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final reason = reasonController.text.trim();
                Navigator.pop(ctx);
                await hrProvider.rejectLeave(leave.id, reason);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Leave request rejected.'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
