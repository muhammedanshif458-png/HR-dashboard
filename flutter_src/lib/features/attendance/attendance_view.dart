import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../models/hr_models.dart';
import '../../core/department_helper.dart';
import '../../utils/date_time_utils.dart';
import '../../widgets/header.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/sidebar.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final TextEditingController _searchController = TextEditingController();

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HRProvider>();
      // The provider survives navigation, so refresh when this screen is
      // reopened instead of showing a potentially stale attendance snapshot.
      if (!provider.isAttendanceLoading) {
        provider.loadAttendance();
      }
      if (!provider.isLateArrivalsLoading) {
        provider.loadLateArrivalsSummary(
          date: provider.attendanceSelectedDate,
        );
      }
    });
  }

  Future<void> _refreshAttendance(HRProvider provider) async {
    await Future.wait([
      provider.loadAttendance(),
      provider.loadLateArrivalsSummary(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hrProvider = context.watch<HRProvider>();
    final attendanceRecords = hrProvider.filteredAttendanceList;

    return Scaffold(
      appBar: const Header(),
      drawer: const AppSidebar(isDrawer: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LY SOFTWARE • TIME & ATTENDANCE',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Attendance Management',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Monitor daily punch logs, check-ins, breaks, working hours, and historical presence records.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                    if (hrProvider.hasLoadedApiAttendance) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_done,
                                size: 14, color: Color(0xFF059669)),
                            SizedBox(width: 6),
                            Text(
                              'Live Server Attendance Active',
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
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: hrProvider.isAttendanceLoading
                      ? null
                      : () => _refreshAttendance(hrProvider),
                  icon: hrProvider.isAttendanceLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync, size: 16),
                  label: Text(hrProvider.isAttendanceLoading
                      ? 'Syncing...'
                      : 'Sync Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Counters
            LayoutBuilder(
              builder: (context, constraints) {
                final isCurrentDayMetric =
                    hrProvider.attendanceTab == 'today' ||
                        hrProvider.attendanceSelectedDate == null;
                final metricDateLabel = isCurrentDayMetric
                    ? 'Today'
                    : _formatDate(hrProvider.attendanceSelectedDate!);
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
                        label: isCurrentDayMetric
                            ? 'Present Today'
                            : 'Present $metricDateLabel',
                        value: hrProvider.presentTodayCount,
                        displayValue: hrProvider.presentTodayDisplayValue,
                        icon: Icons.check_circle_outline,
                        tone: 'green',
                        isActive:
                            hrProvider.attendanceStatusFilter == 'Present',
                        onClick: () => hrProvider.setAttendanceStatusFilter(
                          hrProvider.attendanceStatusFilter == 'Present'
                              ? 'all'
                              : 'Present',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: MetricCard(
                        label: isCurrentDayMetric
                            ? 'Late Arrivals'
                            : 'Late Arrivals • $metricDateLabel',
                        value: hrProvider.lateTodayCount,
                        displayValue: hrProvider.lateArrivalsDisplayValue,
                        icon: Icons.alarm,
                        tone: 'amber',
                        isActive: hrProvider.attendanceStatusFilter == 'Late',
                        onClick: () => hrProvider.setAttendanceStatusFilter(
                          hrProvider.attendanceStatusFilter == 'Late'
                              ? 'all'
                              : 'Late',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: MetricCard(
                        label: isCurrentDayMetric
                            ? 'On Leave Today'
                            : 'On Leave • $metricDateLabel',
                        value: hrProvider.attendanceOnLeaveSummaryCount ??
                            hrProvider.onLeaveTodayCount,
                        displayValue: hrProvider.attendanceOnLeaveDisplayValue,
                        icon: Icons.beach_access,
                        tone: 'blue',
                        isActive:
                            hrProvider.attendanceStatusFilter == 'On Leave',
                        onClick: () => hrProvider.setAttendanceStatusFilter(
                          hrProvider.attendanceStatusFilter == 'On Leave'
                              ? 'all'
                              : 'On Leave',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: MetricCard(
                        label: isCurrentDayMetric
                            ? 'Work From Home (WFH)'
                            : 'WFH • $metricDateLabel',
                        value: hrProvider.attendanceWfhSummaryCount ?? 0,
                        displayValue: hrProvider.attendanceWfhDisplayValue,
                        icon: Icons.home_work_outlined,
                        tone: 'slate',
                        isActive: hrProvider.attendanceWorkModeFilter == 'WFH',
                        onClick: () => hrProvider.setAttendanceWorkModeFilter(
                          hrProvider.attendanceWorkModeFilter == 'WFH'
                              ? 'all'
                              : 'WFH',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            if (hrProvider.lateArrivalsError != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber, color: Color(0xFFB45309)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                    'Late-arrival summary unavailable: ${hrProvider.lateArrivalsError}',
                    style: const TextStyle(color: Color(0xFF92400E)),
                  )),
                  TextButton(
                    onPressed: hrProvider.isLateArrivalsLoading
                        ? null
                        : hrProvider.loadLateArrivalsSummary,
                    child: const Text('Retry'),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Tab Selector: Today's Attendance vs Historical Logs
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(
                    label: hrProvider.attendanceTab == 'today'
                        ? "Today's Attendance (${_formatDate(hrProvider.attendanceTodayDate)})"
                        : hrProvider.attendanceSelectedDate == null
                            ? 'Historical Attendance (All dates)'
                            : 'Historical Attendance (${_formatDate(hrProvider.attendanceSelectedDate!)})',
                    icon: Icons.today,
                    isSelected: hrProvider.attendanceTab == 'today',
                    onTap: () => hrProvider.setAttendanceTab('today'),
                  ),
                  const SizedBox(width: 4),
                  _buildTabButton(
                    label: 'Historical Attendance Logs',
                    icon: Icons.history,
                    isSelected: hrProvider.attendanceTab == 'history',
                    onTap: () => hrProvider.setAttendanceTab('history'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter Bar
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
                      width: 250,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search employee by name...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    hrProvider.setAttendanceSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) =>
                            hrProvider.setAttendanceSearchQuery(val),
                      ),
                    ),

                    // Department Filter
                    Builder(builder: (context) {
                      final deptData = DepartmentHelper.buildFilterDropdown(
                        currentValue: hrProvider.attendanceDeptFilter,
                        departments: hrProvider.departments,
                      );
                      return SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('attendance_dept_${deptData.value}'),
                          isExpanded: true,
                          value: deptData.value,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            labelText: 'Department',
                          ),
                          items: deptData.items,
                          onChanged: (val) {
                            if (val != null) {
                              hrProvider.setAttendanceDeptFilter(val);
                            }
                          },
                        ),
                      );
                    }),

                    // Status Filter
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: hrProvider.attendanceStatusFilter,
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
                              value: 'Present', child: Text('Present')),
                          DropdownMenuItem(
                              value: 'Checked Out', child: Text('Checked Out')),
                          DropdownMenuItem(value: 'Late', child: Text('Late')),
                          DropdownMenuItem(
                              value: 'Absent', child: Text('Absent')),
                          DropdownMenuItem(
                              value: 'On Leave', child: Text('On Leave')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            hrProvider.setAttendanceStatusFilter(val);
                          }
                        },
                      ),
                    ),

                    // Work Mode Filter
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: hrProvider.attendanceWorkModeFilter,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          labelText: 'Work Mode',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Modes')),
                          DropdownMenuItem(
                              value: 'Office', child: Text('Office')),
                          DropdownMenuItem(value: 'WFH', child: Text('WFH')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            hrProvider.setAttendanceWorkModeFilter(val);
                          }
                        },
                      ),
                    ),

                    // Date Picker (For history tab)
                    if (hrProvider.attendanceTab == 'history')
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: hrProvider.attendanceSelectedDate ??
                                hrProvider.attendanceTodayDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2028),
                          );
                          if (picked != null) {
                            hrProvider.setAttendanceSelectedDate(picked);
                          }
                        },
                        icon: const Icon(Icons.event, size: 16),
                        label: Text(
                          hrProvider.attendanceSelectedDate != null
                              ? hrProvider.attendanceSelectedDate!
                                  .toIso8601String()
                                  .split('T')[0]
                              : 'Filter By Date',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),

                    // Reset Filters
                    if (hrProvider.attendanceSearchQuery.isNotEmpty ||
                        hrProvider.attendanceDeptFilter != 'all' ||
                        hrProvider.attendanceStatusFilter != 'all' ||
                        hrProvider.attendanceWorkModeFilter != 'all' ||
                        hrProvider.attendanceSelectedDate != null)
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          hrProvider.setAttendanceSearchQuery('');
                          hrProvider.setAttendanceDeptFilter('all');
                          hrProvider.setAttendanceStatusFilter('all');
                          hrProvider.setAttendanceWorkModeFilter('all');
                          hrProvider.setAttendanceSelectedDate(null);
                        },
                        icon: const Icon(Icons.filter_alt_off, size: 16),
                        label: const Text('Reset'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Error banner if refreshing while records already exist
            if (hrProvider.attendanceError != null &&
                attendanceRecords.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 20, color: Color(0xFFDC2626)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hrProvider.attendanceError!,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF991B1B)),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _refreshAttendance(hrProvider),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Retry'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Attendance Data Table
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: hrProvider.isAttendanceLoading &&
                      (!hrProvider.hasLoadedApiAttendance ||
                          attendanceRecords.isEmpty)
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48.0),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Fetching attendance records from server...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : hrProvider.attendanceError != null &&
                          (!hrProvider.hasLoadedApiAttendance ||
                              attendanceRecords.isEmpty)
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 54, color: Color(0xFFEF4444)),
                              const SizedBox(height: 12),
                              const Text(
                                'Failed to load attendance records',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hrProvider.attendanceError!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => hrProvider.loadAttendance(),
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
                      : attendanceRecords.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(48.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_busy,
                                      size: 54, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No attendance records found',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try clearing the filters or switching to Historical Attendance.',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        hrProvider.loadAttendance(),
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
                                    columns: const [
                                      DataColumn(
                                          label: Text('Employee',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Department',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Date',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Check-In',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Scheduled',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Late By',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Check-Out',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Duration',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Break',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Status',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Mode',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Location',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Action',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ],
                                    rows: attendanceRecords.map((att) {
                                      return _buildAttendanceRow(
                                          context, att, hrProvider);
                                    }).toList(),
                                  ),
                                ),
                                if (hrProvider.hasLoadedApiAttendance &&
                                    hrProvider.attendanceTotalPages > 0) ...[
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Showing ${(hrProvider.attendancePage - 1) * hrProvider.attendanceLimit + (attendanceRecords.isEmpty ? 0 : 1)} to ${(hrProvider.attendancePage - 1) * hrProvider.attendanceLimit + attendanceRecords.length} of ${hrProvider.attendanceTotal} records',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B)),
                                        ),
                                        Row(
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: hrProvider
                                                              .attendancePage >
                                                          1 &&
                                                      !hrProvider
                                                          .isAttendanceLoading
                                                  ? () => hrProvider
                                                      .setAttendancePage(hrProvider
                                                              .attendancePage -
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
                                                'Page ${hrProvider.attendancePage} of ${hrProvider.attendanceTotalPages > 0 ? hrProvider.attendanceTotalPages : 1}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              onPressed: hrProvider
                                                              .attendancePage <
                                                          hrProvider
                                                              .attendanceTotalPages &&
                                                      !hrProvider
                                                          .isAttendanceLoading
                                                  ? () => hrProvider
                                                      .setAttendancePage(hrProvider
                                                              .attendancePage +
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

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildAttendanceRow(
      BuildContext context, Attendance att, HRProvider hrProvider) {
    Color statusColor = const Color(0xFF10B981); // Green
    if (att.isLate || att.status == 'Late') {
      statusColor = const Color(0xFFF59E0B);
    } else if (att.status == 'Checked Out') {
      statusColor = const Color(0xFF3B82F6);
    } else if (att.status == 'Absent') {
      statusColor = const Color(0xFFEF4444);
    } else if (att.status == 'On Leave') {
      statusColor = const Color(0xFF8B5CF6);
    }

    return DataRow(
      cells: [
        // Employee
        DataCell(
          InkWell(
            onTap: () => hrProvider.viewStaffProfile(att.staffId),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    att.employeeName.isNotEmpty ? att.employeeName[0] : 'U',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  att.employeeName.isNotEmpty
                      ? att.employeeName
                      : 'Employee #${att.staffId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
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
              color: att.department == 'Tech'
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              att.department.isNotEmpty ? att.department : 'General',
              style: TextStyle(
                color: att.department == 'Tech'
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFDB2777),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Date
        DataCell(Text(formatAttendanceDate(att.date), style: const TextStyle(fontSize: 12))),

        // Check-in (with Late Arrival badge)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formatAttendanceTime(att.checkInTime),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
              if (att.isLate) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('LATE',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309))),
                ),
              ],
            ],
          ),
        ),

        // Backend-provided scheduled time and authoritative late duration.
        DataCell(Text(_scheduledCheckInDisplay(att),
            style: const TextStyle(fontSize: 12))),
        DataCell(Text(_formatLateDuration(att.minutesLate),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: att.isLate ? const Color(0xFFB45309) : null))),

        // Check-out
        DataCell(Text(
            _formatCheckOutDisplay(att),
            style: const TextStyle(fontSize: 12))),

        // Total Worked Duration
        DataCell(Text(att.workedDuration,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),

        // Break Duration
        DataCell(
          att.isOnBreak
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: const Color(0xFFFCD34D), width: 0.8),
                      ),
                      child: const Text('On Break',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309))),
                    ),
                    if (att.breakDuration.isNotEmpty &&
                        att.breakDuration != '—') ...[
                      const SizedBox(width: 4),
                      Text('(${att.breakDuration})',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ],
                )
              : Text(att.breakDuration,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),

        // Status Badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              att.status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Work Mode
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: att.workMode == 'WFH'
                      ? const Color(0xFFF3E8FF)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: att.workMode == 'WFH'
                        ? const Color(0xFFE9D5FF)
                        : const Color(0xFFBFDBFE),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (att.workMode == 'Office') ...[
                      const Icon(Icons.qr_code_2_rounded,
                          size: 12, color: Color(0xFF2457D6)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      att.workMode == 'Office' ? 'QR Office' : 'Remote / WFH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: att.workMode == 'WFH'
                            ? const Color(0xFF7E22CE)
                            : const Color(0xFF2457D6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Location
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              att.location,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
        ),

        // View Details Action
        DataCell(
          IconButton(
            icon: const Icon(Icons.info_outline,
                size: 18, color: Color(0xFF2563EB)),
            tooltip: 'View Record Details',
            onPressed: () => _showAttendanceDetailsModal(context, att),
          ),
        ),
      ],
    );
  }

  String _formatLateDuration(int? minutes) {
    if (minutes == null || minutes < 0) return '—';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$remainingMinutes min late';
    if (remainingMinutes == 0) return '$hours hr late';
    return '$hours hr $remainingMinutes min late';
  }

  String _formatCheckOutDisplay(Attendance att) {
    if (att.checkOutTime != null &&
        att.checkOutTime!.isNotEmpty &&
        att.checkOutTime != '—') {
      if (att.checkOutTime == 'Active') return 'Active';
      final formatted = formatAttendanceTimeNullable(att.checkOutTime);
      if (formatted != null) return formatted;
    }
    if (att.checkInTime != null &&
        att.checkInTime!.isNotEmpty &&
        att.checkInTime != '—' &&
        att.status != 'Absent' &&
        att.status != 'On Leave') {
      return 'Active';
    }
    return '—';
  }

  String _scheduledCheckInDisplay(Attendance attendance) {
    final time = attendance.scheduledCheckIn;
    if (time == null || time.trim().isEmpty || time.trim() == '—') return '—';
    final formatted = formatAttendanceTime(time);
    final timeZone = attendance.scheduleTimeZone;
    return (timeZone == null || timeZone.isEmpty)
        ? formatted
        : '$formatted ($timeZone)';
  }

  String _scheduledCheckOutDisplay(Attendance attendance) {
    final time = attendance.scheduledCheckOut;
    if (time == null || time.trim().isEmpty || time.trim() == '—') return '—';
    final formatted = formatAttendanceTime(time);
    final timeZone = attendance.scheduleTimeZone;
    return (timeZone == null || timeZone.isEmpty)
        ? formatted
        : '$formatted ($timeZone)';
  }

  void _showAttendanceDetailsModal(BuildContext context, Attendance att) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.timer, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Attendance Record Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('Employee Name', att.employeeName),
              _buildDetailRow('Department', att.department),
              _buildDetailRow('Attendance Date', formatAttendanceDate(att.date)),
              _buildDetailRow(
                  'Check-in Time', formatAttendanceTime(att.checkInTime, fallback: 'Not checked in')),
              _buildDetailRow('Check-out Time',
                  att.checkOutTime != null && att.checkOutTime!.isNotEmpty && att.checkOutTime != '—'
                      ? (att.checkOutTime == 'Active' ? 'Active' : formatAttendanceTime(att.checkOutTime, fallback: att.checkOutTime!))
                      : (att.checkInTime != null && att.checkInTime!.isNotEmpty && att.status != 'Absent' && att.status != 'On Leave'
                          ? 'Active / Still working on premise / remote'
                          : 'Still working on premise / remote')),
              _buildDetailRow('Worked Duration', att.workedDuration),
              _buildDetailRow('Break Duration', att.breakDuration),
              if (att.isOnBreak)
                _buildDetailRow('Break Status', 'Active break in progress (started ${formatAttendanceTime(att.breakStartedAt)})'),
              _buildDetailRow('Attendance Status', att.status),
              _buildDetailRow('Work Mode', att.workMode),
              _buildDetailRow('Punch Location', att.location),
              if (att.scheduledCheckIn != null && att.scheduledCheckIn!.isNotEmpty)
                _buildDetailRow('Scheduled Check-in', _scheduledCheckInDisplay(att)),
              if (att.scheduledCheckOut != null && att.scheduledCheckOut!.isNotEmpty)
                _buildDetailRow('Scheduled Check-out', _scheduledCheckOutDisplay(att)),
              if (att.remarks.isNotEmpty)
                _buildDetailRow('Punch Notes / Remarks', att.remarks),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Read-only record logged from authorized terminal/mobile device. Manual edits are restricted.',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }
}
