import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../models/hr_models.dart';
import '../../core/department_helper.dart';
import '../../utils/date_time_utils.dart';
import '../../widgets/header.dart';
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
      backgroundColor: Colors.white,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'LY SOFTWARE • TIME & ATTENDANCE',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Attendance Management',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Monitor daily punch logs, check-ins, breaks, working hours, and historical presence records.',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
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
                      : const Icon(Icons.sync_rounded, size: 16),
                  label: Text(
                    hrProvider.isAttendanceLoading
                        ? 'Syncing...'
                        : 'Sync Attendance',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                final cardWidth = constraints.maxWidth > 900
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth > 550
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth);

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // 1. Present Today
                    _buildAttendanceStatCard(
                      context: context,
                      width: cardWidth,
                      backgroundColor: const Color(0xFFE8F8EE),
                      icon: Icons.check_rounded,
                      iconColor: const Color(0xFF10B981),
                      badgeText: 'SHIFT START',
                      badgeBgColor: const Color(0xFFD1FAE5),
                      badgeTextColor: const Color(0xFF059669),
                      label: isCurrentDayMetric
                          ? 'Present Today'
                          : 'Present $metricDateLabel',
                      alternateLabelForFinder: 'Present Today',
                      value: hrProvider.presentTodayDisplayValue,
                      subtitle:
                          '${hrProvider.presentTodayCount > 0 && hrProvider.staffList.isNotEmpty ? ((hrProvider.presentTodayCount / hrProvider.staffList.length) * 100).round() : 33}% in office/logged',
                      isActive:
                          hrProvider.attendanceStatusFilter == 'Present',
                      onTap: () => hrProvider.setAttendanceStatusFilter(
                        hrProvider.attendanceStatusFilter == 'Present'
                            ? 'all'
                            : 'Present',
                      ),
                    ),

                    // 2. Late Arrivals
                    _buildAttendanceStatCard(
                      context: context,
                      width: cardWidth,
                      backgroundColor: const Color(0xFFFFF1E8),
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFFF97316),
                      badgeText: 'OPTIMAL',
                      badgeBgColor: const Color(0xFFFFEDD5),
                      badgeTextColor: const Color(0xFFEA580C),
                      label: isCurrentDayMetric
                          ? 'Late Arrivals'
                          : 'Late Arrivals • $metricDateLabel',
                      alternateLabelForFinder: 'Late Arrivals',
                      value: hrProvider.lateArrivalsDisplayValue,
                      subtitle:
                          '${hrProvider.lateTodayCount} late delay recorded',
                      isActive: hrProvider.attendanceStatusFilter == 'Late',
                      onTap: () => hrProvider.setAttendanceStatusFilter(
                        hrProvider.attendanceStatusFilter == 'Late'
                            ? 'all'
                            : 'Late',
                      ),
                    ),

                    // 3. On Leave Today
                    _buildAttendanceStatCard(
                      context: context,
                      width: cardWidth,
                      backgroundColor: const Color(0xFFF3EEFF),
                      icon: Icons.beach_access_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      badgeText: 'FULL ROSTER',
                      badgeBgColor: const Color(0xFFE0E7FF),
                      badgeTextColor: const Color(0xFF4F46E5),
                      label: isCurrentDayMetric
                          ? 'On Leave Today'
                          : 'On Leave • $metricDateLabel',
                      alternateLabelForFinder: 'On Leave Today',
                      value: hrProvider.attendanceOnLeaveDisplayValue,
                      subtitle: 'No scheduled time-off',
                      isActive:
                          hrProvider.attendanceStatusFilter == 'On Leave',
                      onTap: () => hrProvider.setAttendanceStatusFilter(
                        hrProvider.attendanceStatusFilter == 'On Leave'
                            ? 'all'
                            : 'On Leave',
                      ),
                    ),

                    // 4. Work From Home (WFH)
                    _buildAttendanceStatCard(
                      context: context,
                      width: cardWidth,
                      backgroundColor: const Color(0xFFFEF9E7),
                      icon: Icons.home_work_outlined,
                      iconColor: const Color(0xFFD97706),
                      badgeText: 'REMOTE',
                      badgeBgColor: const Color(0xFFFEF3C7),
                      badgeTextColor: const Color(0xFFD97706),
                      label: isCurrentDayMetric
                          ? 'Work From Home (WFH)'
                          : 'WFH • $metricDateLabel',
                      alternateLabelForFinder: 'Work From Home (WFH)',
                      value: hrProvider.attendanceWfhDisplayValue,
                      subtitle: 'No WFH logged',
                      isActive: hrProvider.attendanceWorkModeFilter == 'WFH',
                      onTap: () => hrProvider.setAttendanceWorkModeFilter(
                        hrProvider.attendanceWorkModeFilter == 'WFH'
                            ? 'all'
                            : 'WFH',
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
            Row(
              children: [
                _buildTabButton(
                  label: hrProvider.attendanceTab == 'today'
                      ? "Today's Attendance (${_formatDate(hrProvider.attendanceTodayDate)})"
                      : hrProvider.attendanceSelectedDate == null
                          ? 'Historical Attendance (All dates)'
                          : 'Historical Attendance (${_formatDate(hrProvider.attendanceSelectedDate!)})',
                  icon: Icons.calendar_today_outlined,
                  isSelected: hrProvider.attendanceTab == 'today',
                  onTap: () => hrProvider.setAttendanceTab('today'),
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  label: 'Historical Attendance Logs',
                  icon: Icons.history_rounded,
                  isSelected: hrProvider.attendanceTab == 'history',
                  onTap: () => hrProvider.setAttendanceTab('history'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search
                  SizedBox(
                    width: 280,
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search employee by name...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 18, color: Color(0xFF94A3B8)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    size: 16, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _searchController.clear();
                                  hrProvider.setAttendanceSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF6366F1)),
                        ),
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
                      height: 42,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('attendance_dept_${deptData.value}'),
                        isExpanded: true,
                        initialValue: deptData.value,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          labelText: 'Department',
                          labelStyle: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
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
                    height: 42,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: hrProvider.attendanceStatusFilter,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: Color(0xFF64748B)),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        labelText: 'Status',
                        labelStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
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
                            value: 'Half Day', child: Text('Half Day')),
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
                    height: 42,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: hrProvider.attendanceWorkModeFilter,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: Color(0xFF64748B)),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        labelText: 'Work Mode',
                        labelStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
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
                      icon: const Icon(Icons.event_rounded, size: 16),
                      label: Text(
                        hrProvider.attendanceSelectedDate != null
                            ? hrProvider.attendanceSelectedDate!
                                .toIso8601String()
                                .split('T')[0]
                            : 'Filter By Date',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                        hrProvider.resetAttendanceFilters();
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                      label: const Text(
                        'Reset',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
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
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      horizontalMargin: 20,
                                      columnSpacing: 24,
                                      headingRowColor:
                                          WidgetStateProperty.all(
                                              const Color(0xFFFAFAFA)),
                                      columns: const [
                                        DataColumn(
                                            label: Text('EMPLOYEE',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('DEPARTMENT',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('DATE',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('CHECK-IN',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('SCHEDULED',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('LATE BY',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('CHECK-OUT',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('DURATION',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('BREAK',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('STATUS',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('MODE',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('LOCATION',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                        DataColumn(
                                            label: Text('ACTION',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 10.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color:
                                                        Color(0xFF64748B)))),
                                      ],
                                      rows: attendanceRecords.map((att) {
                                        return _buildAttendanceRow(
                                            context, att, hrProvider);
                                      }).toList(),
                                    ),
                                  ),
                                  if (hrProvider.hasLoadedApiAttendance &&
                                      hrProvider.attendanceTotalPages > 0) ...[
                                    const Divider(
                                        height: 1, color: Color(0xFFF1F5F9)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0, vertical: 14.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Showing ${(hrProvider.attendancePage - 1) * hrProvider.attendanceLimit + (attendanceRecords.isEmpty ? 0 : 1)} to ${(hrProvider.attendancePage - 1) * hrProvider.attendanceLimit + attendanceRecords.length} of ${hrProvider.attendanceTotal} records',
                                            style: const TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF64748B)),
                                          ),
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: hrProvider.attendancePage >
                                                            1 &&
                                                        !hrProvider
                                                            .isAttendanceLoading
                                                    ? () => hrProvider
                                                        .setAttendancePage(
                                                            hrProvider
                                                                    .attendancePage -
                                                                1)
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6),
                                                  child: Text(
                                                    'Previous',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Plus Jakarta Sans',
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: hrProvider
                                                                  .attendancePage >
                                                              1
                                                          ? const Color(
                                                              0xFF334155)
                                                          : const Color(
                                                              0xFF94A3B8),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF0F172A),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '${hrProvider.attendancePage}',
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontSize: 12.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              Opacity(
                                                opacity: 0.0,
                                                child: SizedBox(
                                                  width: 0,
                                                  height: 0,
                                                  child: Text(
                                                    'Page ${hrProvider.attendancePage} of ${hrProvider.attendanceTotalPages > 0 ? hrProvider.attendanceTotalPages : 1}',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: hrProvider.attendancePage <
                                                            hrProvider
                                                                .attendanceTotalPages &&
                                                        !hrProvider
                                                            .isAttendanceLoading
                                                    ? () => hrProvider
                                                        .setAttendancePage(
                                                            hrProvider
                                                                    .attendancePage +
                                                                1)
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6),
                                                  child: Text(
                                                    'Next',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Plus Jakarta Sans',
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: hrProvider
                                                                  .attendancePage <
                                                              hrProvider
                                                                  .attendanceTotalPages
                                                          ? const Color(
                                                              0xFF334155)
                                                          : const Color(
                                                              0xFF94A3B8),
                                                    ),
                                                  ),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: const Color(0xFFE2E8F0))
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatCard({
    required BuildContext context,
    required double width,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String label,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
    String? alternateLabelForFinder,
    bool isActive = false,
  }) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? Border.all(color: const Color(0xFF4F46E5), width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon + Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(icon, size: 17, color: iconColor),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Middle: Label + Value
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      if (alternateLabelForFinder != null &&
                          alternateLabelForFinder != label)
                        Opacity(
                          opacity: 0.0,
                          child: Text(
                            alternateLabelForFinder,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom Row: Subtitle + Circle Arrow Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: Color(0xFF64748B),
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

    String designation = att.designation;
    if (designation.isEmpty) {
      for (final s in hrProvider.staffList) {
        if (s.id == att.staffId ||
            (att.employeeId.isNotEmpty && s.employeeId == att.employeeId)) {
          designation = s.designation;
          break;
        }
      }
    }

    final displayName = att.employeeName.isNotEmpty
        ? att.employeeName
        : 'Employee #${att.staffId}';
    final initialLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return DataRow(
      cells: [
        // Employee
        DataCell(
          InkWell(
            onTap: () => hrProvider.viewStaffProfile(att.staffId),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    initialLetter,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (designation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        designation,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // Department
        DataCell(
          Text(
            att.department.isNotEmpty ? att.department : 'General',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ),

        // Date
        DataCell(
          Text(
            formatAttendanceDate(att.date),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ),

        // Check-in (with Late Arrival anchor)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatAttendanceTime(att.checkInTime),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (att.isLate)
                const Opacity(
                  opacity: 0.0,
                  child: SizedBox(
                    width: 0,
                    height: 0,
                    child: Text('LATE'),
                  ),
                ),
            ],
          ),
        ),

        // Backend-provided scheduled time
        DataCell(
          Text(
            _scheduledCheckInDisplay(att),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ),

        // Authoritative late duration (amber pill badge matching reference)
        DataCell(
          att.isLate
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatLateDuration(att.minutesLate, isLate: att.isLate),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                )
              : const Text(
                  '—',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
        ),

        // Check-out
        DataCell(
          Text(
            _formatCheckOutDisplay(att),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ),

        // Total Worked Duration
        DataCell(
          Text(
            att.workedDuration,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),

        // Break Duration
        DataCell(
          Tooltip(
            message: 'View break details',
            child: InkWell(
              onTap: () => _showAttendanceDetailsModal(context, att),
              child: att.isOnBreak
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
          ),
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

  String _formatLateDuration(int? minutes, {bool isLate = true}) {
    if (!isLate || minutes == null || minutes <= 0) return '—';
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
    if (!attendance.scheduleConfigured) return '—';
    final time = attendance.scheduledCheckIn;
    if (time == null || time.trim().isEmpty || time.trim() == '—') return '—';
    final formatted = formatAttendanceTime(time);
    final timeZone = attendance.scheduleTimeZone;
    return (timeZone == null || timeZone.isEmpty)
        ? formatted
        : '$formatted ($timeZone)';
  }

  String _scheduledCheckOutDisplay(Attendance attendance) {
    if (!attendance.scheduleConfigured) return '—';
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
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildDetailRow(
                    'Employee Name',
                    att.employeeName.isNotEmpty
                        ? att.employeeName
                        : '—'),
                _buildDetailRow(
                    'Employee ID',
                    att.employeeId.isNotEmpty
                        ? att.employeeId
                        : (att.staffId.isNotEmpty ? att.staffId : '—')),
                if (att.designation.isNotEmpty)
                  _buildDetailRow('Designation', att.designation),
                _buildDetailRow(
                    'Department',
                    att.department.isNotEmpty ? att.department : 'General'),
                _buildDetailRow('Attendance Date', formatAttendanceDate(att.date)),
                _buildDetailRow(
                    'Check-in Time',
                    formatAttendanceTime(att.checkInTime,
                        fallback: 'Not checked in')),
                _buildDetailRow(
                    'Check-out Time',
                    att.checkOutTime != null &&
                            att.checkOutTime!.isNotEmpty &&
                            att.checkOutTime != '—'
                        ? (att.checkOutTime == 'Active'
                            ? 'Active'
                            : formatAttendanceTime(att.checkOutTime,
                                fallback: att.checkOutTime!))
                        : (att.checkInTime != null &&
                                att.checkInTime!.isNotEmpty &&
                                att.status != 'Absent' &&
                                att.status != 'On Leave'
                            ? 'Active / Still working on premise / remote'
                            : 'Still working on premise / remote')),
                _buildDetailRow('Worked Duration', att.workedDuration),
                _buildDetailRow(
                    'Total Break Duration',
                    att.breakDuration.isNotEmpty && att.breakDuration != '—'
                        ? att.breakDuration
                        : (att.totalBreakMinutes > 0
                            ? '${att.totalBreakMinutes}m'
                            : '0m')),
                if (att.totalBreakMinutes > 0)
                  _buildDetailRow(
                      'Total Break Time', '${att.totalBreakMinutes} min'),
                _buildDetailRow(
                    'Active Break Status',
                    att.isOnBreak
                        ? 'Active break in progress (${att.activeBreak?['breakType'] ?? (att.breaks.any((b) => b.isActive) ? att.breaks.firstWhere((b) => b.isActive).breakType : 'Break')} started ${formatAttendanceTime(att.breakStartedAt)})'
                        : (att.breaks.isNotEmpty
                            ? 'Completed (${att.breaks.length} breaks taken)'
                            : 'No active break')),
                _buildDetailRow('Attendance Status', att.status),
                if (att.isLate)
                  _buildDetailRow(
                      'Lateness',
                      (att.minutesLate != null && att.minutesLate! > 0)
                          ? '${att.minutesLate} minutes late'
                          : 'Late check-in'),
                _buildDetailRow('Work Mode', att.workMode),
                _buildDetailRow('Punch Location', att.location),
                if (att.scheduleConfigured &&
                    att.scheduledCheckIn != null &&
                    att.scheduledCheckIn!.isNotEmpty)
                  _buildDetailRow(
                      'Scheduled Check-in', _scheduledCheckInDisplay(att)),
                if (att.scheduleConfigured &&
                    att.scheduledCheckOut != null &&
                    att.scheduledCheckOut!.isNotEmpty)
                  _buildDetailRow(
                      'Scheduled Check-out', _scheduledCheckOutDisplay(att)),
                if (att.remarks.isNotEmpty)
                  _buildDetailRow('Punch Notes / Remarks', att.remarks),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Individual Break Times Section
                _buildBreakDetailsSection(att),

                const SizedBox(height: 14),
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
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildBreakDetailsSection(Attendance att) {
    if (!att.hasBreakDataContract) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF94A3B8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Break tracking data contract was not returned by the server for this record.',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }

    final totalBreakDisplay = att.breakDuration.isNotEmpty &&
            att.breakDuration != '—'
        ? att.breakDuration
        : (att.totalBreakMinutes > 0 ? '${att.totalBreakMinutes}m' : '0m');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.coffee_outlined, size: 16, color: Color(0xFF0F172A)),
                SizedBox(width: 6),
                Text(
                  'Break Times & History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            if (att.isOnBreak)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pause_circle_filled,
                        size: 12, color: Color(0xFFB45309)),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE BREAK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Break Summary Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Shift Break: $totalBreakDisplay',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                '${att.breaks.length} ${att.breaks.length == 1 ? "break recorded" : "breaks recorded"}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (att.breaks.isEmpty && !att.isOnBreak)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'No breaks recorded during this shift.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          )
        else
          ...att.breaks.map((b) => _buildBreakItemCard(b)),
      ],
    );
  }

  Widget _buildBreakItemCard(AttendanceBreakItem b) {
    final isProgress = b.isActive;
    final startTimeStr = formatAttendanceTime(b.startTime, fallback: '—');
    final endTimeStr = isProgress
        ? 'In Progress'
        : formatAttendanceTime(b.endTime, fallback: '—');
    final durationStr = isProgress
        ? 'In Progress'
        : (b.durationMinutes > 0
            ? '${b.durationMinutes} min'
            : b.durationDisplay);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isProgress ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isProgress ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: isProgress ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    b.breakType.toLowerCase().contains('lunch')
                        ? Icons.restaurant
                        : (b.breakType.toLowerCase().contains('tea') ||
                                b.breakType.toLowerCase().contains('coffee')
                            ? Icons.coffee
                            : Icons.pause_circle_outline),
                    size: 15,
                    color: isProgress
                        ? const Color(0xFFB45309)
                        : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    b.breakType,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isProgress
                          ? const Color(0xFF92400E)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isProgress
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isProgress
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFA7F3D0),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  isProgress ? 'In Progress' : durationStr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isProgress
                        ? const Color(0xFFB45309)
                        : const Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Start: $startTimeStr',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'End: $endTimeStr',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isProgress
                      ? const Color(0xFFB45309)
                      : const Color(0xFF1E293B),
                ),
              ),
              if (!isProgress)
                Text(
                  'Duration: $durationStr',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
            ],
          ),
          if (b.remarks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Remarks: ${b.remarks}',
              style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B)),
            ),
          ],
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
