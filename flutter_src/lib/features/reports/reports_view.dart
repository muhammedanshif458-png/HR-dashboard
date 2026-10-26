import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../widgets/header.dart';
import '../../widgets/sidebar.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HRProvider>().loadReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();

    final attData = hrProvider.effectiveAttendanceReport;
    final leaveData = hrProvider.effectiveLeaveReport;

    final isInitialLoading =
        hrProvider.isReportsLoading && !hrProvider.hasLoadedApiReports;
    final hasError =
        hrProvider.reportsError != null && !hrProvider.hasLoadedApiReports;

    return Scaffold(
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'LY SOFTWARE • ANALYTICS & REPORTS',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (hrProvider.hasLoadedApiReports) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 13, color: Color(0xFF16A34A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Live Server Reports',
                                    style: TextStyle(
                                      color: Color(0xFF166534),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'HR Reports & Workforce Analytics',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Executive breakdown of time compliance, medical leaves, and department attendance.',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Refresh Reports',
                      onPressed: hrProvider.isReportsLoading
                          ? null
                          : () => hrProvider.loadReports(),
                      icon: hrProvider.isReportsLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Server-side export is not supported in Backend API Contract v1.0. Viewing live report metrics on-screen.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export Report'),
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
              ],
            ),
            const SizedBox(height: 18),

            // Backend Capability Status Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFF475569), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backend Report Data Sources',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Attendance metrics are loaded from GET /api/hr/reports/attendance. Leave metrics are loaded from GET /api/hr/reports/leaves. WFH Remote Sessions is unsupported because the backend Attendance model does not track workMode.',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (isInitialLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60.0),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              )
            else if (hasError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFDC2626), size: 40),
                    const SizedBox(height: 12),
                    Text(
                      hrProvider.reportsError ??
                          'Failed to retrieve live reports from backend.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stale mock data is hidden to prevent presenting unverified figures as live server reports.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => hrProvider.loadReports(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Summary Cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attendance Compliance Report
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.query_builder,
                                    color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Text(
                                  'Attendance & Punctuality Overview',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildReportRow(
                              'Total Logged Punches',
                              attData.totalPunches.toString(),
                              Colors.blue,
                            ),
                            _buildReportRow(
                              'On-Time Arrivals',
                              attData.onTimeCount.toString(),
                              Colors.green,
                            ),
                            _buildReportRow(
                              'Late Arrivals Logged',
                              attData.lateCount.toString(),
                              Colors.orange,
                            ),
                            _buildReportRow(
                              'WFH Remote Sessions',
                              'Unsupported (No WFH in DB)',
                              Colors.purple,
                              isUnsupported: true,
                            ),
                            _buildReportRow(
                              'Average Hours Worked',
                              '${attData.overallAvgWorkingHours.toStringAsFixed(1)} hrs / day',
                              Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Leaves Report
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.pie_chart_outline,
                                    color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Text(
                                  'Leave Distribution & Types Overview',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildReportRow(
                              'Total Applications',
                              leaveData.totalApplications.toString(),
                              Colors.blueGrey,
                            ),
                            _buildReportRow(
                              'Approved Leave Requests',
                              leaveData.approvedCount.toString(),
                              Colors.green,
                            ),
                            _buildReportRow(
                              'Pending Approvals',
                              leaveData.pendingCount.toString(),
                              Colors.amber,
                            ),
                            _buildReportRow(
                              'Medical / Sick Leaves',
                              leaveData.medicalCount.toString(),
                              Colors.purple,
                            ),
                            _buildReportRow(
                              'Casual Leaves',
                              leaveData.casualCount.toString(),
                              Colors.blue,
                            ),
                            _buildReportRow(
                              'Earned / Annual Leaves',
                              leaveData.earnedCount.toString(),
                              Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Department Breakdown Table (if available from live backend)
              if (attData.departmentSummary.isNotEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.apartment_rounded,
                                color: Color(0xFF2563EB), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Department Working Hours & Attendance Breakdown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1.5),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(1.5),
                          },
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom:
                                        BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Department',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF64748B))),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Status',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF64748B))),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Headcount',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF64748B))),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Total Hours',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF64748B))),
                                ),
                              ],
                            ),
                            ...attData.departmentSummary.map((d) {
                              return TableRow(
                                decoration: const BoxDecoration(
                                  border: Border(
                                      bottom:
                                          BorderSide(color: Color(0xFFF1F5F9))),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Text(d.department,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B))),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Text(d.status,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF334155))),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Text(d.count.toString(),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2563EB))),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Text('${d.totalHours} hrs',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0D9488))),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color,
      {bool isUnsupported = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isUnsupported
                  ? const Color(0xFFF1F5F9)
                  : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: isUnsupported
                  ? Border.all(color: const Color(0xFFCBD5E1))
                  : null,
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isUnsupported ? const Color(0xFF64748B) : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
